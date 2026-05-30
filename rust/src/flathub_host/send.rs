//! Send iMessages via the Flathub prebuilt library (real open-absinthe inside).

use std::sync::Arc;
use std::time::Duration;

use anyhow::{Context, Result, bail};

use crate::api::api::{APSWatcher, RegisterState, SharedPushState};
use crate::flathub_host::client::shared;
use crate::flathub_host::client::SOURCE_FRB_CONTENT_HASH;
use crate::frb_generated::SseEncode;
use rustpush::{ConversationData, Message, MessageInst, MessageType, NormalMessage};

pub async fn flathub_send_message(
    data_dir: &str,
    to: &str,
    text: &str,
    from: Option<&str>,
    skip_validate: bool,
    _wait_secs: u64,
) -> Result<()> {
    let lib = shared()?;
    let ids = lib.func_ids();
    let path = data_dir.to_string();

    let restored: Option<(SharedPushState, APSWatcher)> = lib
        .call_async(ids.restore, |s| {
            path.clone().sse_encode(s);
        })
        .await
        .context("failed to restore push state via Flathub library")?;

    let (state, _watcher) = restored.with_context(|| {
        format!(
            "push state restore returned None (data dir: {data_dir}).\n\
             The installed Flatpak library (FRB hash {}) often cannot read hw_info.plist\n\
             written by a newer OpenBubbles build (identity format changed in \"Move to keychain\").\n\
             Update Flatpak when its FRB hash matches source ({SOURCE_FRB_CONTENT_HASH}), or recreate setup with the Flatpak app version.",
            lib.content_hash()
        )
    })?;

    let (_arc_state, state): (Arc<SharedPushState>, SharedPushState) =
        lib.call_sync(ids.dup_daemon, |s| {
            state.sse_encode(s);
        })?;

    wait_for_registration(&lib, &state.client, ids.get_regstate).await?;

    let recipient = normalize_recipient(to);
    let sender = pick_sender(&lib, &state.client, from, ids.get_handles).await?;

    if !skip_validate {
        match lib
            .call_async::<Vec<String>, _>(ids.validate_targets, |s| {
                state.client.clone().sse_encode(s);
                vec![recipient.clone()].sse_encode(s);
                sender.clone().sse_encode(s);
            })
            .await
        {
            Ok(valid) if valid.is_empty() => {
                bail!("{recipient} is not reachable via iMessage");
            }
            Ok(_) => {}
            Err(err) => {
                eprintln!("warning: target validation failed ({err}); sending anyway");
            }
        }
    }

    let conversation = ConversationData {
        participants: vec![recipient.clone(), sender.clone()],
        cv_name: None,
        sender_guid: None,
        after_guid: None,
    };
    let normal = NormalMessage::new(text.to_string(), MessageType::IMessage);
    let message = Message::Message(normal);

    let msg: MessageInst = lib
        .call_async(ids.new_msg, |s| {
            conversation.sse_encode(s);
            sender.clone().sse_encode(s);
            message.sse_encode(s);
        })
        .await
        .context("failed to build message")?;

    let uuid = msg.id.clone();

    let sent: bool = lib
        .call_async(ids.send, |s| {
            state.client.clone().sse_encode(s);
            state.local_broadcast.clone().sse_encode(s);
            msg.sse_encode(s);
        })
        .await
        .context("send failed")?;

    if !sent {
        bail!("send returned false");
    }

    println!("sent {uuid} to {recipient}");
    Ok(())
}

async fn wait_for_registration(
    lib: &crate::flathub_host::client::FlathubLib,
    client: &Arc<rustpush::IMClient>,
    get_regstate: i32,
) -> Result<()> {
    for _ in 0..120 {
        let reg: RegisterState = lib
            .call_async(get_regstate, |s| {
                client.clone().sse_encode(s);
            })
            .await?;
        match reg {
            RegisterState::Registered { .. } => return Ok(()),
            RegisterState::Failed { error, .. } => {
                eprintln!("warning: registration failed: {error}");
                return Ok(());
            }
            RegisterState::Registering => {
                tokio::time::sleep(Duration::from_millis(500)).await;
            }
        }
    }
    eprintln!("warning: still registering after 60s; continuing anyway");
    Ok(())
}

async fn pick_sender(
    lib: &crate::flathub_host::client::FlathubLib,
    client: &Arc<rustpush::IMClient>,
    from: Option<&str>,
    get_handles: i32,
) -> Result<String> {
    if let Some(f) = from {
        return Ok(normalize_sender(f));
    }
    let handles: Vec<String> = lib
        .call_async(get_handles, |s| {
            client.clone().sse_encode(s);
        })
        .await?;
    handles
        .into_iter()
        .next()
        .context("no registered handles found")
}

fn normalize_recipient(raw: &str) -> String {
    if raw.contains('@') {
        if raw.starts_with("mailto:") {
            raw.to_string()
        } else {
            format!("mailto:{raw}")
        }
    } else {
        let digits: String = raw.chars().filter(|c| c.is_ascii_digit() || *c == '+').collect();
        let with_plus = if digits.starts_with('+') {
            digits
        } else {
            format!("+{digits}")
        };
        if with_plus.starts_with("tel:") {
            with_plus
        } else {
            format!("tel:{with_plus}")
        }
    }
}

fn normalize_sender(raw: &str) -> String {
    if raw.contains('@') && !raw.starts_with("mailto:") {
        format!("mailto:{raw}")
    } else if raw.chars().any(|c| c.is_ascii_digit()) && !raw.starts_with("tel:") {
        normalize_recipient(raw)
    } else {
        raw.to_string()
    }
}
