//! Minimal FRB host — does NOT link rust_lib_bluebubbles (avoids symbol interposition).

use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::path::PathBuf;
use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::{Mutex, OnceLock};

use allo_isolate::ffi::{
    DartCObject, DartCObjectType, DartHandleFinalizer, DartPostCObjectFnType, DartTypedDataType,
};
use anyhow::{Context, Result, bail};
use flutter_rust_bridge::for_generated::Rust2DartAction;
use tokio::sync::oneshot;

const DEFAULT_SO: &str =
    "/var/lib/flatpak/app/app.openbubbles.OpenBubbles/x86_64/stable/active/files/bluebubbles/lib/librust_lib_bluebubbles.so";

const FN_ENCODE_HEX: i32 = 88;
const FN_GENERATE_UDID: i32 = 102;

type PdePrimary = unsafe extern "C" fn(i32, i64, *mut u8, i32, i32);
type StorePost = unsafe extern "C" fn(DartPostCObjectFnType);
type RustVecU8New = unsafe extern "C" fn(i32) -> *mut u8;
type ContentHashFn = unsafe extern "C" fn() -> i32;

static PORT_WAITERS: OnceLock<Mutex<HashMap<i64, oneshot::Sender<Vec<u8>>>>> = OnceLock::new();
static NEXT_PORT: AtomicI64 = AtomicI64::new(1);

struct FlathubLib {
    _lib: libloading::os::unix::Library,
    pde_primary: PdePrimary,
    rust_vec_new: RustVecU8New,
    content_hash: ContentHashFn,
}

fn port_waiters() -> &'static Mutex<HashMap<i64, oneshot::Sender<Vec<u8>>>> {
    PORT_WAITERS.get_or_init(|| Mutex::new(HashMap::new()))
}

unsafe fn copy_typed_data_bytes(
    ty: DartTypedDataType,
    values: *mut u8,
    length: isize,
) -> Option<Vec<u8>> {
    if length <= 0 {
        return Some(Vec::new());
    }
    if ty as i32 != DartTypedDataType::Uint8 as i32 {
        return None;
    }
    Some(std::slice::from_raw_parts(values, length as usize).to_vec())
}

unsafe fn extract_post_bytes(object: *mut DartCObject) -> Option<Vec<u8>> {
    if object.is_null() {
        return None;
    }
    let obj = &*object;
    match obj.ty {
        DartCObjectType::DartTypedData => {
            let td = obj.value.as_typed_data;
            copy_typed_data_bytes(td.ty, td.values, td.length)
        }
        DartCObjectType::DartExternalTypedData => {
            let td = obj.value.as_external_typed_data;
            let bytes = copy_typed_data_bytes(td.ty, td.data, td.length)?;
            let callback: DartHandleFinalizer = td.callback;
            callback(td.data as *mut _, td.peer);
            Some(bytes)
        }
        DartCObjectType::DartArray => {
            let arr = obj.value.as_array;
            if arr.length == 0 || arr.values.is_null() {
                return None;
            }
            extract_post_bytes(*arr.values)
        }
        _ => None,
    }
}

unsafe extern "C" fn host_post_cobject(port: i64, object: *mut DartCObject) -> bool {
    let bytes = match extract_post_bytes(object) {
        Some(b) => b,
        None => return false,
    };
    if !object.is_null() {
        let ty = (*object).ty;
        // ExternalTypedData finalizer runs in extract_post_bytes; skip run_destructors
        // for that variant to avoid double-free (shows up as `free(): invalid pointer`).
        if ty != DartCObjectType::DartExternalTypedData {
            allo_isolate::ffi::run_destructors(&mut *object);
        }
    }
    if let Ok(mut map) = port_waiters().lock() {
        if let Some(tx) = map.remove(&port) {
            let _ = tx.send(bytes);
            return true;
        }
    }
    false
}

fn resolve_library_path() -> Result<PathBuf> {
    if let Ok(path) = std::env::var("OPENBUBBLES_RUST_LIB") {
        let path = PathBuf::from(path);
        if path.exists() {
            return Ok(path);
        }
        bail!("OPENBUBBLES_RUST_LIB does not exist: {}", path.display());
    }
    let path = PathBuf::from(DEFAULT_SO);
    if path.exists() {
        return Ok(path);
    }
    bail!("Flathub library not found at {}", path.display());
}

impl FlathubLib {
    fn load() -> Result<Self> {
        let path = resolve_library_path()?;
        const RTLD_LAZY: libc::c_int = 0x1;
        const RTLD_DEEPBIND: libc::c_int = 0x0008;
        let c_path = CString::new(path.to_string_lossy().as_bytes())
            .context("library path contains interior nul")?;
        let handle = unsafe { libc::dlopen(c_path.as_ptr(), RTLD_LAZY | RTLD_DEEPBIND) };
        if handle.is_null() {
            let err = unsafe { CStr::from_ptr(libc::dlerror()) };
            bail!("dlopen failed: {err:?}");
        }
        let lib = unsafe { libloading::os::unix::Library::from_raw(handle) };

        let store_post = unsafe {
            lib.get::<StorePost>(b"store_dart_post_cobject\0")
                .context("store_dart_post_cobject missing")?
        };
        unsafe { store_post(host_post_cobject) };

        let pde_primary = *unsafe {
            lib.get(b"frb_pde_ffi_dispatcher_primary\0")
                .context("frb_pde_ffi_dispatcher_primary missing")?
        };
        let rust_vec_new = *unsafe {
            lib.get(b"rust_vec_u8_new\0")
                .context("rust_vec_u8_new missing")?
        };
        let content_hash = *unsafe {
            lib.get(b"frb_get_rust_content_hash\0")
                .context("frb_get_rust_content_hash missing")?
        };

        Ok(Self {
            _lib: lib,
            pde_primary,
            rust_vec_new,
            content_hash,
        })
    }

    fn so_content_hash(&self) -> i32 {
        unsafe { (self.content_hash)() }
    }

    fn encode_wire(&self, payload: &[u8]) -> (i32, i32, *mut u8) {
        let data_len = payload.len() as i32;
        let ptr = unsafe { (self.rust_vec_new)(data_len) };
        if !payload.is_empty() {
            unsafe {
                std::ptr::copy_nonoverlapping(payload.as_ptr(), ptr, payload.len());
            }
        }
        (data_len, data_len, ptr)
    }

    fn sse_encode_vec_u8(bytes: &[u8]) -> Vec<u8> {
        let mut out = Vec::new();
        out.extend_from_slice(&(bytes.len() as i32).to_le_bytes());
        out.extend_from_slice(bytes);
        out
    }

    fn decode_string_response(bytes: Vec<u8>) -> Result<String> {
        if bytes.is_empty() {
            bail!("empty response");
        }
        match bytes[0] {
            x if x == Rust2DartAction::Success as u8 => {}
            x if x == Rust2DartAction::Error as u8 => {
                bail!("error: {}", decode_string_payload(&bytes[1..])?);
            }
            x if x == Rust2DartAction::Panic as u8 => {
                bail!("panic: {}", String::from_utf8_lossy(&bytes[1..]));
            }
            x => bail!("unexpected action byte {x}"),
        }
        decode_string_payload(&bytes[1..])
    }

    async fn call_async_string(&self, func_id: i32, wire: Vec<u8>) -> Result<String> {
        let port = NEXT_PORT.fetch_add(1, Ordering::Relaxed);
        let (tx, rx) = oneshot::channel();
        port_waiters().lock().unwrap().insert(port, tx);

        let (data_len, rust_vec_len, ptr) = self.encode_wire(&wire);
        eprintln!(
            "call funcId={func_id} wire_len={data_len} hex={}",
            hex::encode(&wire)
        );
        unsafe {
            (self.pde_primary)(func_id, port, ptr, rust_vec_len, data_len);
        }

        let bytes = tokio::time::timeout(std::time::Duration::from_secs(30), rx)
            .await
            .context("timeout waiting for response")?
            .context("port closed")?;
        eprintln!("response len={} hex={}", bytes.len(), hex::encode(&bytes));
        Self::decode_string_response(bytes)
    }
}

fn decode_string_payload(payload: &[u8]) -> Result<String> {
    if payload.len() < 4 {
        bail!("string payload too short");
    }
    let len = i32::from_le_bytes(payload[0..4].try_into().unwrap());
    if len < 0 {
        bail!("negative string length {len}");
    }
    let end = 4 + len as usize;
    if payload.len() < end {
        bail!("truncated string payload");
    }
    Ok(String::from_utf8(payload[4..end].to_vec())?)
}

mod hex {
    pub fn encode(bytes: &[u8]) -> String {
        bytes.iter().map(|b| format!("{b:02x}")).collect()
    }
}

async fn try_func_id(func_id: i32) -> Result<()> {
    let lib = FlathubLib::load()?;
    let wire = FlathubLib::sse_encode_vec_u8(&[0xde, 0xad]);
    match lib.call_async_string(func_id, wire).await {
        Ok(s) => {
            println!("funcId={func_id} ok: {s:?}");
            Ok(())
        }
        Err(e) => {
            println!("funcId={func_id} err: {e:#}");
            Err(e)
        }
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() >= 2 && args[1] == "try" {
        let func_id: i32 = args.get(2).context("usage: try <funcId>")?.parse()?;
        return try_func_id(func_id).await;
    }

    let lib = FlathubLib::load()?;
    let so = resolve_library_path()?;
    println!("library: {}", so.display());
    let so_hash = lib.so_content_hash();
    println!("so content hash: {so_hash}");
    if so_hash != -1267927268 {
        eprintln!(
            "warning: installed Flatpak .so hash ({so_hash}) differs from ob-cli source (-1267927268).\n\
             FRB funcIds will not match — update git checkout or reinstall matching Flatpak build."
        );
    }

    let udid = lib.call_async_string(FN_GENERATE_UDID, Vec::new()).await?;
    println!("generate_udid: {udid}");

    let hex_empty = lib
        .call_async_string(FN_ENCODE_HEX, FlathubLib::sse_encode_vec_u8(&[]))
        .await?;
    println!("encode_hex([]): {hex_empty:?}");

    let hex_dead = lib
        .call_async_string(FN_ENCODE_HEX, FlathubLib::sse_encode_vec_u8(&[0xde, 0xad]))
        .await?;
    println!("encode_hex([dead]): {hex_dead}");

    println!("ok");
    Ok(())
}
