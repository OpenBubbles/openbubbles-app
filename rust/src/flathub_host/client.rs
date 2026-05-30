//! Runtime client for the Flathub `librust_lib_bluebubbles.so` via FRB wire protocol.

use std::collections::HashMap;
use std::ffi::CString;
use std::os::unix::ffi::OsStrExt;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::{Arc, Mutex, OnceLock};

use allo_isolate::ffi::{DartCObject, DartCObjectType, DartPostCObjectFnType};
use anyhow::{Context, Result, bail};
use flutter_rust_bridge::for_generated::{
    Dart2RustMessageSse, Rust2DartAction, SseDeserializer, SseSerializer, WireSyncRust2DartSse,
    vec_from_leak_ptr,
};
use libloading::os::unix::Symbol;
use tokio::sync::oneshot;

use crate::frb_generated::SseDecode;

type PdePrimary = unsafe extern "C" fn(i32, i64, *mut u8, i32, i32);
type PdeSync = unsafe extern "C" fn(i32, *mut u8, i32, i32) -> WireSyncRust2DartSse;
type StorePost = unsafe extern "C" fn(DartPostCObjectFnType);
type FreeSyncWire = unsafe extern "C" fn(WireSyncRust2DartSse);
type RustVecU8New = unsafe extern "C" fn(i32) -> *mut u8;
type RustVecU8Free = unsafe extern "C" fn(*mut u8, i32);

const DEFAULT_SO: &str = "/var/lib/flatpak/app/app.openbubbles.OpenBubbles/x86_64/stable/active/files/bluebubbles/lib/librust_lib_bluebubbles.so";

static PORT_WAITERS: OnceLock<Mutex<HashMap<i64, oneshot::Sender<Vec<u8>>>>> = OnceLock::new();
static NEXT_PORT: AtomicI64 = AtomicI64::new(1);

fn port_waiters() -> &'static Mutex<HashMap<i64, oneshot::Sender<Vec<u8>>>> {
    PORT_WAITERS.get_or_init(|| Mutex::new(HashMap::new()))
}

unsafe fn extract_post_bytes(object: *mut DartCObject) -> Option<Vec<u8>> {
    if object.is_null() {
        return None;
    }
    let obj = &*object;
    match obj.ty {
        DartCObjectType::DartTypedData => {
            let td = obj.value.as_typed_data;
            let len = td.length as usize;
            if td.ty as i32 != allo_isolate::ffi::DartTypedDataType::Uint8 as i32 {
                return None;
            }
            Some(std::slice::from_raw_parts(td.values, len).to_vec())
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
        allo_isolate::ffi::run_destructors(&mut *object);
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
    rust_vec_free: RustVecU8Free,
}

impl FlathubLib {
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
            let err = unsafe { std::ffi::CStr::from_ptr(libc::dlerror()) };
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
        let rust_vec_free = *unsafe {
            lib.get(b"rust_vec_u8_free\0")
                .context("rust_vec_u8_free not found")?
        };

        Ok(Self {
            _lib: lib,
            pde_primary: pde_primary_fn,
            pde_sync: pde_sync_fn,
            free_sync: free_sync_fn,
            rust_vec_new,
            rust_vec_free,
        })
    }

    fn encode_wire(&self, encode: impl FnOnce(&mut SseSerializer)) -> (i32, i32, *mut u8) {
        let mut serializer = SseSerializer::new();
        encode(&mut serializer);
        let vec = serializer.cursor.into_inner();
        let data_len = vec.len() as i32;
        let ptr = unsafe { (self.rust_vec_new)(data_len) };
        if ptr.is_null() {
            panic!("rust_vec_u8_new returned null");
        }
        unsafe {
            std::ptr::copy_nonoverlapping(vec.as_ptr(), ptr, vec.len());
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
        // leak for deserializer; small error strings only
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
