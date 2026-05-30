//! Runtime client for the Flathub `librust_lib_bluebubbles.so` via FRB wire protocol.

use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::os::unix::ffi::OsStrExt;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::{Arc, Mutex, OnceLock};

use allo_isolate::ffi::{
    DartCObject, DartCObjectType, DartHandleFinalizer, DartPostCObjectFnType, DartTypedDataType,
};
use anyhow::{Context, Result, bail};
use flutter_rust_bridge::for_generated::{
    Dart2RustMessageSse, Rust2DartAction, SseDeserializer, SseSerializer, WireSyncRust2DartSse,
    vec_from_leak_ptr,
};
use libloading::os::unix::Symbol;
use tokio::sync::oneshot;

use crate::flathub_host::func_ids::{FuncIds, func_ids_for_hash};
use crate::frb_generated::{SseDecode, SseEncode, FLUTTER_RUST_BRIDGE_CODEGEN_CONTENT_HASH};

type PdePrimary = unsafe extern "C" fn(i32, i64, *mut u8, i32, i32);
type PdeSync = unsafe extern "C" fn(i32, *mut u8, i32, i32) -> WireSyncRust2DartSse;
type StorePost = unsafe extern "C" fn(DartPostCObjectFnType);
type FreeSyncWire = unsafe extern "C" fn(WireSyncRust2DartSse);
type RustVecU8New = unsafe extern "C" fn(i32) -> *mut u8;
type ContentHashFn = unsafe extern "C" fn() -> i32;

const DEFAULT_SO: &str = "/var/lib/flatpak/app/app.openbubbles.OpenBubbles/x86_64/stable/active/files/bluebubbles/lib/librust_lib_bluebubbles.so";

/// FRB codegen hash for the current git checkout (`frb_generated.rs`).
pub const SOURCE_FRB_CONTENT_HASH: i32 = FLUTTER_RUST_BRIDGE_CODEGEN_CONTENT_HASH;

static PORT_WAITERS: OnceLock<Mutex<HashMap<i64, oneshot::Sender<Vec<u8>>>>> = OnceLock::new();
static NEXT_PORT: AtomicI64 = AtomicI64::new(1);

fn port_waiters() -> &'static Mutex<HashMap<i64, oneshot::Sender<Vec<u8>>>> {
    PORT_WAITERS.get_or_init(|| Mutex::new(HashMap::new()))
}

unsafe fn copy_typed_data_bytes(ty: DartTypedDataType, values: *mut u8, length: isize) -> Option<Vec<u8>> {
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
            let first = *arr.values;
            extract_post_bytes(first)
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

pub fn resolve_library_path() -> Result<PathBuf> {
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
    bail!(
        "Flathub OpenBubbles library not found at {}.\n\
         Install: flatpak install flathub app.openbubbles.OpenBubbles\n\
         Or set OPENBUBBLES_RUST_LIB to librust_lib_bluebubbles.so",
        path.display()
    );
}

pub struct FlathubLib {
    _lib: libloading::os::unix::Library,
    pde_primary: PdePrimary,
    pde_sync: PdeSync,
    free_sync: FreeSyncWire,
    rust_vec_new: RustVecU8New,
    content_hash: i32,
    func_ids: FuncIds,
}

impl FlathubLib {
    pub fn content_hash(&self) -> i32 {
        self.content_hash
    }

    pub fn func_ids(&self) -> FuncIds {
        self.func_ids
    }

    pub fn load() -> Result<Self> {
        let path = resolve_library_path()?;
        Self::load_from(&path)
    }

    pub fn load_from(path: &Path) -> Result<Self> {
        // RTLD_DEEPBIND (0x8): resolve symbols inside the .so first, avoiding
        // interposition from rustpush/open-absinthe stub linked into ob-cli.
        const RTLD_LAZY: libc::c_int = 0x1;
        const RTLD_DEEPBIND: libc::c_int = 0x0008;
        let c_path = CString::new(path.as_os_str().as_bytes())
            .context("library path contains interior nul")?;
        let handle = unsafe { libc::dlopen(c_path.as_ptr(), RTLD_LAZY | RTLD_DEEPBIND) };
        if handle.is_null() {
            let err = unsafe { CStr::from_ptr(libc::dlerror()) };
            bail!("failed to dlopen {}: {err:?}", path.display());
        }
        let lib = unsafe { libloading::os::unix::Library::from_raw(handle) };

        let store_post: Symbol<StorePost> = unsafe {
            lib.get(b"store_dart_post_cobject\0")
                .context("store_dart_post_cobject not found in library")?
        };
        unsafe { store_post(host_post_cobject) };

        let pde_primary_fn = *unsafe {
            lib.get(b"frb_pde_ffi_dispatcher_primary\0")
                .context("frb_pde_ffi_dispatcher_primary not found")?
        };
        let pde_sync_fn = *unsafe {
            lib.get(b"frb_pde_ffi_dispatcher_sync\0")
                .context("frb_pde_ffi_dispatcher_sync not found")?
        };
        let free_sync_fn = *unsafe {
            lib.get(b"free_wire_sync_rust2dart_sse\0")
                .context("free_wire_sync_rust2dart_sse not found")?
        };
        let rust_vec_new = *unsafe {
            lib.get(b"rust_vec_u8_new\0")
                .context("rust_vec_u8_new not found")?
        };
        let content_hash_fn: Symbol<ContentHashFn> = unsafe {
            lib.get(b"frb_get_rust_content_hash\0")
                .context("frb_get_rust_content_hash not found")?
        };
        let content_hash = unsafe { content_hash_fn() };
        let func_ids = func_ids_for_hash(content_hash)?;
        if content_hash != SOURCE_FRB_CONTENT_HASH {
            eprintln!(
                "note: Flathub library FRB hash ({content_hash}) differs from ob-cli source ({SOURCE_FRB_CONTENT_HASH}); using Flathub funcIds."
            );
        }

        Ok(Self {
            _lib: lib,
            pde_primary: pde_primary_fn,
            pde_sync: pde_sync_fn,
            free_sync: free_sync_fn,
            rust_vec_new,
            content_hash,
            func_ids,
        })
    }

    fn encode_wire(&self, encode: impl FnOnce(&mut SseSerializer)) -> (i32, i32, *mut u8) {
        let mut serializer = SseSerializer::new();
        encode(&mut serializer);
        let bytes = serializer.cursor.into_inner();
        let data_len = bytes.len() as i32;
        let ptr = unsafe { (self.rust_vec_new)(data_len) };
        if !bytes.is_empty() {
            unsafe {
                std::ptr::copy_nonoverlapping(bytes.as_ptr(), ptr, bytes.len());
            }
        }
        (data_len, data_len, ptr)
    }

    fn decode_response<T: SseDecode>(bytes: Vec<u8>) -> Result<T> {
        if bytes.is_empty() {
            bail!("empty response from Flathub library");
        }
        let action = bytes[0];
        if action == Rust2DartAction::Panic as u8 {
            bail!(
                "Flathub library panicked: {}",
                String::from_utf8_lossy(&bytes[1..])
            );
        }
        if action == Rust2DartAction::Error as u8 {
            let msg = decode_error_payload(&bytes[1..])?;
            bail!("Flathub library error: {msg}");
        }
        if action != Rust2DartAction::Success as u8 {
            bail!("unexpected FRB action byte: {action}");
        }
        let payload = bytes[1..].to_vec();
        let data_len = payload.len() as i32;
        let mut buf = payload;
        let p = buf.as_mut_ptr();
        let len = data_len;
        std::mem::forget(buf);
        let message = unsafe { Dart2RustMessageSse::from_wire(p, len, data_len) };
        let mut deserializer = SseDeserializer::new(message);
        let value = T::sse_decode(&mut deserializer);
        deserializer.end();
        Ok(value)
    }

    pub async fn call_async<T, F>(&self, func_id: i32, encode: F) -> Result<T>
    where
        T: SseDecode,
        F: FnOnce(&mut SseSerializer),
    {
        let port = NEXT_PORT.fetch_add(1, Ordering::Relaxed);
        let (tx, rx) = oneshot::channel();
        port_waiters().lock().unwrap().insert(port, tx);

        let (data_len, rust_vec_len, ptr) = self.encode_wire(encode);
        unsafe {
            (self.pde_primary)(func_id, port, ptr, rust_vec_len, data_len);
        }

        let bytes = tokio::time::timeout(std::time::Duration::from_secs(120), rx)
            .await
            .context("timed out waiting for Flathub library response")?
            .context("Flathub library port closed without response")?;

        Self::decode_response(bytes)
    }

    pub async fn call_async_no_args<T>(&self, func_id: i32) -> Result<T>
    where
        T: SseDecode,
    {
        self.call_async(func_id, |_| {}).await
    }

    pub fn call_sync<T, F>(&self, func_id: i32, encode: F) -> Result<T>
    where
        T: SseDecode,
        F: FnOnce(&mut SseSerializer),
    {
        let (data_len, rust_vec_len, ptr) = self.encode_wire(encode);
        let wire = unsafe { (self.pde_sync)(func_id, ptr, rust_vec_len, data_len) };
        let bytes = unsafe { vec_from_leak_ptr(wire.ptr, wire.len) };
        unsafe { (self.free_sync)(wire) };
        Self::decode_response(bytes)
    }
}

fn decode_error_payload(payload: &[u8]) -> Result<String> {
    if payload.is_empty() {
        return Ok("unknown error".to_string());
    }
    let (ptr, rust_vec_len) = {
        let payload = payload.to_vec();
        let data_len = payload.len() as i32;
        let mut buf = payload;
        let len = buf.len() as i32;
        let p = buf.as_mut_ptr();
        std::mem::forget(buf);
        (p, len)
    };
    let message = unsafe { Dart2RustMessageSse::from_wire(ptr, rust_vec_len, rust_vec_len) };
    let mut deserializer = SseDeserializer::new(message);
    let s = String::sse_decode(&mut deserializer);
    deserializer.end();
    Ok(s)
}

static FLATHUB: OnceLock<Result<Arc<FlathubLib>, String>> = OnceLock::new();

pub fn shared() -> Result<Arc<FlathubLib>> {
    FLATHUB
        .get_or_init(|| FlathubLib::load().map(Arc::new).map_err(|e| e.to_string()))
        .clone()
        .map_err(|e| anyhow::anyhow!(e))
}

/// Smoke-test FRB wire calls against the Flathub library (no APS state required).
pub async fn frb_probe(verbose: bool) -> Result<()> {
    let lib = shared()?;
    let ids = lib.func_ids();
    let so = resolve_library_path()?;
    println!("library: {}", so.display());
    println!("so frb content hash: {}", lib.content_hash());
    println!("source frb content hash: {SOURCE_FRB_CONTENT_HASH}");

    let udid: String = lib.call_async_no_args(ids.generate_udid).await?;
    println!("generate_udid: {udid}");

    let hex_empty: String = lib
        .call_async(ids.encode_hex, |s| {
            Vec::<u8>::new().sse_encode(s);
        })
        .await?;
    if hex_empty != "" {
        bail!("encode_hex([]) expected empty string, got {hex_empty:?}");
    }
    if verbose {
        println!("encode_hex([]): ok");
    }

    let hex_dead: String = lib
        .call_async(ids.encode_hex, |s| {
            vec![0xde_u8, 0xad].sse_encode(s);
        })
        .await?;
    if hex_dead != "dead" {
        bail!("encode_hex([0xde,0xad]) expected \"dead\", got {hex_dead:?}");
    }
    println!("encode_hex([0xde,0xad]): {hex_dead}");
    println!("frb probe ok");
    Ok(())
}
