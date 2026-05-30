//! FRB dispatcher funcIds keyed by `frb_get_rust_content_hash()` from the loaded `.so`.

use anyhow::{Result, bail};

use crate::frb_generated::FLUTTER_RUST_BRIDGE_CODEGEN_CONTENT_HASH;

#[derive(Debug, Clone, Copy)]
pub struct FuncIds {
    pub restore: i32,
    pub dup_daemon: i32,
    pub get_regstate: i32,
    pub get_handles: i32,
    pub validate_targets: i32,
    pub new_msg: i32,
    pub send: i32,
    pub encode_hex: i32,
    pub generate_udid: i32,
}

/// Flathub OpenBubbles 1.15.0 — hash from `fb597ad9b^` (`Move to keychain` parent).
const FLATHUB_1_15_0: FuncIds = FuncIds {
    restore: 202,
    dup_daemon: 83,
    get_regstate: 120,
    get_handles: 117,
    validate_targets: 225,
    new_msg: 149,
    send: 193,
    encode_hex: 88,
    generate_udid: 102,
};

/// Current git checkout (`frb_generated.rs`).
const SOURCE_TREE: FuncIds = FuncIds {
    restore: 229,
    dup_daemon: 93,
    get_regstate: 134,
    get_handles: 128,
    validate_targets: 255,
    new_msg: 166,
    send: 220,
    encode_hex: 98,
    generate_udid: 112,
};

pub fn func_ids_for_hash(hash: i32) -> Result<FuncIds> {
    match hash {
        -208244658 => Ok(FLATHUB_1_15_0),
        h if h == FLUTTER_RUST_BRIDGE_CODEGEN_CONTENT_HASH => Ok(SOURCE_TREE),
        other => bail!(
            "unsupported FRB content hash {other} from Flathub library.\n\
             Known hashes: Flathub 1.15.0 (-208244658), current source ({FLUTTER_RUST_BRIDGE_CODEGEN_CONTENT_HASH}).\n\
             Reinstall matching Flatpak or update this checkout."
        ),
    }
}
