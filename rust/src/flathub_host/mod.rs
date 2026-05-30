//! Send path via Flathub `librust_lib_bluebubbles.so` (FRB wire protocol).
//!
//! Requires OpenBubbles Flatpak installed (library on disk). Close the GUI before sending.

pub mod client;
pub mod func_ids;
pub mod send;

pub use client::{frb_probe, shared};
pub use send::flathub_send_message;
