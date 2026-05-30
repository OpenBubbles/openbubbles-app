//! Send iMessages via the Flathub prebuilt library (real open-absinthe inside).

use std::sync::Arc;
use std::time::Duration;

use anyhow::{Context, Result, bail};

use crate::api::api::{APSWatcher, RegisterState, SharedPushState};
use crate::flathub_host::client::shared;
use crate::frb_generated::SseEncode;
use rustpush::{ConversationData, Message, MessageInst, MessageType, NormalMessage};

const FN_RESTORE: i32 = 229;
const FN_DUP_DAEMON: i32 = 93;
const FN_GET_REGSTATE: i32 = 134;
const FN_GET_HANDLES: i32 = 128;
const FN_VALIDATE_TARGETS: i32 = 255;
const FN_NEW_MSG: i32 = 166;
const FN_SEND: i32 = 220;

pub async fn flathub_send_message(
    data_dir: &str,
    to: &str,
    text: &str,
    from: Option<&str>,
    skip_validate: bool,
    _wait_secs: u64,
) -> Result<()> {
    let lib = shared()?;

    // Sanity-check FRB wire path with a trivial call before restore.
    let hex: String = lib
        .call_async(98, |s| {
            Vec::<u8>::new().sse_encode(s);
        })
        .await
        .context("FRB sanity check (encode_hex) failed")?;
    eprintln!("debug: FRB ok (encode_hex={hex:?})");

    let path = data_dir.to_string();

    let restored: Option<(SharedPushState, APSWatcher)> = lib
        .call_async(FN_RESTORE, |s| {
            path.clone().sse_encode(s);
        })
        .await
        .context("failed to restore push state via Flathub library")?;

    let (state, _watcher) = restored.context("push state restore returned None")?;

    let (_arc_state, state): (Arc<SharedPushState>, SharedPushState) =
        lib.call_sync(FN_DUP_DAEMON, |s| {
            state.sse_encode(s);
        })?;

    wait_for_registration(&lib, &state.client).await?;

    let recipient = normalize_recipient(to);
    let sender = pick_sender(&lib, &state.client, from).await?;

    if !skip_validate {
        match lib
            .call_async::<Vec<String>, _>(FN_VALIDATE_TARGETS, |s| {
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
        .call_async(FN_NEW_MSG, |s| {
            conversation.sse_encode(s);
            sender.clone().sse_encode(s);
            message.sse_encode(s);
        })
        .await
        .context("failed to build message")?;

    let uuid = msg.id.clone();

    let sent: bool = lib
        .call_async(FN_SEND, |s| {
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
) -> Result<()> {
    for _ in 0..120 {
        let reg: RegisterState = lib
            .call_async(FN_GET_REGSTATE, |s| {
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
) -> Result<String> {
    if let Some(f) = from {
        return Ok(normalize_sender(f));
    }
    let handles: Vec<String> = lib
        .call_async(FN_GET_HANDLES, |s| {
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
