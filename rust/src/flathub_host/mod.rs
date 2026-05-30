//! Send path via Flathub `librust_lib_bluebubbles.so` (FRB wire protocol).
//!
//! Requires OpenBubbles Flatpak installed (library on disk). Close the GUI before sending.

pub mod client;
pub mod send;

pub use send::flathub_send_message;
