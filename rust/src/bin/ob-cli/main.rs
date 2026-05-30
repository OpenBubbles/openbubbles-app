//! OpenBubbles CLI — send iMessages and manage push state from the terminal.
//!
//! Uses the same on-disk state as the Flathub app:
//!   ~/.var/app/app.openbubbles.OpenBubbles/data/bluebubbles/
//!
//! Close the OpenBubbles GUI before running (single-writer on APS + ObjectBox).
//!
//! **Send** uses the Flathub prebuilt `librust_lib_bluebubbles.so` (FRB wire protocol)
//! because open-absinthe is not available for local builds. Override library path with
//! `OPENBUBBLES_RUST_LIB`. Other commands use the local Rust build.

mod objectbox_store;

use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::Duration;

use anyhow::{Context, Result, bail};
use clap::{Parser, Subcommand};
use rust_lib_bluebubbles::api::api::{
    APSWatcher, PollResult, PushMessage, RegisterState, SharedPushState, cancel_poll,
    get_handles, get_my_phone_handles, get_regstate, recv_wait, send, validate_targets,
};
use rust_lib_bluebubbles::init_logger;
use rustpush::{ConversationData, Message, MessageInst, MessageType, NormalMessage};
use serde::Deserialize;
use tokio::sync::mpsc;
use tokio::time::timeout;

#[derive(Parser)]
#[command(name = "ob-cli", about = "OpenBubbles command-line interface")]
struct Cli {
    /// OpenBubbles data directory (defaults to Flatpak path)
    #[arg(long, env = "OPENBUBBLES_DATA_DIR")]
    data_dir: Option<PathBuf>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Send an iMessage
    Send {
        /// Recipient phone (+1303...) or email
        to: String,
        /// Message body
        text: String,
        /// Sender handle (mailto:... or tel:...); defaults to first registered handle
        #[arg(long)]
        from: Option<String>,
        /// Skip iMessage target validation (may still fail at send time)
        #[arg(long)]
        skip_validate: bool,
        /// Seconds to wait for send confirmation
        #[arg(long, default_value = "30")]
        timeout: u64,
    },
    /// List registered iMessage handles
    Handles,
    /// Show registration and account status
    Status,
    /// Listen for incoming push messages
    Daemon {
        /// Emit one JSON object per line
        #[arg(long)]
        json: bool,
    },
    /// Query local chat database (ObjectBox)
    Chats {
        #[command(subcommand)]
        action: ChatsAction,
    },
}

#[derive(Subcommand)]
enum ChatsAction {
    /// List conversations
    List {
        #[arg(long, default_value = "50")]
        limit: usize,
        #[arg(long)]
        json: bool,
    },
    /// Show a conversation and recent messages
    Show {
        /// Chat GUID (e.g. iMessage;-;user@example.com)
        guid: String,
        #[arg(long, default_value = "20")]
        limit: usize,
        #[arg(long)]
        json: bool,
    },
}

#[derive(Deserialize)]
struct SharedPreferences {
    #[serde(rename = "flutter.finishedSetup", default)]
    finished_setup: bool,
    #[serde(rename = "flutter.macIsMine", default)]
    mac_is_mine: bool,
    #[serde(rename = "flutter.iCloudAccount", default)]
    icloud_account: Option<String>,
    #[serde(rename = "flutter.userName", default)]
    user_name: Option<String>,
}

fn default_data_dir() -> PathBuf {
    dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join(".var/app/app.openbubbles.OpenBubbles/data/bluebubbles")
}

fn resolve_data_dir(cli: &Cli) -> PathBuf {
    cli.data_dir.clone().unwrap_or_else(default_data_dir)
}

fn preflight(data_dir: &Path, require_exclusive: bool) -> Result<()> {
    for name in ["hw_info.plist", "id.plist", "gsa.plist"] {
        let path = data_dir.join(name);
        if !path.exists() {
            bail!("missing {name} in {} — complete OpenBubbles setup first", data_dir.display());
        }
    }

    if require_exclusive {
        let lock = data_dir.join("bluebubbles.lck");
        if lock.exists() {
            bail!(
                "OpenBubbles appears to be running ({} exists).\n\
                 Close the app first: flatpak kill app.openbubbles.OpenBubbles",
                lock.display()
            );
        }
        let ob_lock = data_dir.join("objectbox/lock.mdb");
        if ob_lock.exists() {
            // lock.mdb always exists when store was opened; check if data.mdb is locked via process
            if std::process::Command::new("flatpak")
                .args(["ps"])
                .output()
                .ok()
                .and_then(|o| String::from_utf8(o.stdout).ok())
                .is_some_and(|s| s.contains("app.openbubbles.OpenBubbles"))
            {
                bail!("OpenBubbles Flatpak is running. Close it before using ob-cli.");
            }
        }
    }

    Ok(())
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

struct App {
    state: Arc<SharedPushState>,
    events: mpsc::UnboundedReceiver<PushMessage>,
    _poll: tokio::task::JoinHandle<()>,
}

async fn start_app(data_dir: &Path) -> Result<App> {
    let path = data_dir.to_string_lossy().into_owned();
    init_logger(data_dir);
    let (state, watcher) = SharedPushState::restore(path)
        .await
        .context("failed to restore push state")?;
    let state = Arc::new(state);
    let (event_tx, event_rx) = mpsc::unbounded_channel();
    let poll = spawn_poll_loop(state.clone(), watcher, event_tx);
    tokio::time::sleep(Duration::from_millis(300)).await;
    Ok(App {
        state,
        events: event_rx,
        _poll: poll,
    })
}

async fn wait_for_registration(app: &App, max_secs: u64) -> Result<()> {
    for _ in 0..max_secs * 2 {
        match get_regstate(&app.state.client).await? {
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
    eprintln!("warning: still registering after {max_secs}s; continuing anyway");
    Ok(())
}

async fn shutdown_app(app: App) {
    cancel_poll(&app.state.cancel_poll);
    let _ = app._poll.await;
}

fn spawn_poll_loop(
    state: Arc<SharedPushState>,
    mut watcher: APSWatcher,
    event_tx: mpsc::UnboundedSender<PushMessage>,
) -> tokio::task::JoinHandle<()> {
    tokio::spawn(async move {
        loop {
            match recv_wait(&mut watcher, &state).await {
                PollResult::Stop => break,
                PollResult::Cont(Some(msg)) => {
                    let _ = event_tx.send(msg);
                }
                PollResult::Cont(None) => {}
            }
        }
    })
}

fn message_summary(msg: &MessageInst) -> String {
    match &msg.message {
        Message::Message(normal) => normal.parts.raw_text(),
        Message::RenameMessage(m) => format!("renamed chat to {}", m.new_name),
        Message::React(_) => "reaction".to_string(),
        Message::Edit(m) => m.new_parts.raw_text(),
        Message::Typing(typing, _) => {
            if *typing {
                "typing".to_string()
            } else {
                "stopped typing".to_string()
            }
        }
        Message::Read => "read".to_string(),
        Message::Delivered => "delivered".to_string(),
        _ => "(system message)".to_string(),
    }
}

fn print_push_message(msg: &PushMessage, json: bool) {
    match msg {
        PushMessage::IMessage(inst) => {
            let from = inst.sender.as_deref().unwrap_or("unknown");
            let text = message_summary(inst);
            if json {
                println!(
                    "{}",
                    serde_json::json!({
                        "type": "message",
                        "from": from,
                        "text": text,
                        "guid": inst.id,
                        "timestamp": inst.sent_timestamp,
                    })
                );
            } else {
                let ts = chrono::DateTime::from_timestamp(
                    (inst.sent_timestamp / 1000) as i64,
                    ((inst.sent_timestamp % 1000) * 1_000_000) as u32,
                )
                .map(|dt| dt.format("%Y-%m-%d %H:%M:%S").to_string())
                .unwrap_or_else(|| inst.sent_timestamp.to_string());
                println!("{ts} from {from}: {text}");
            }
        }
        PushMessage::SendConfirm { uuid, error } => {
            if json {
                println!(
                    "{}",
                    serde_json::json!({
                        "type": "send_confirm",
                        "guid": uuid,
                        "error": error,
                    })
                );
            } else if let Some(err) = error {
                eprintln!("send failed ({uuid}): {err}");
            } else {
                eprintln!("send confirmed ({uuid})");
            }
        }
        PushMessage::RegistrationState(reg) => {
            if json {
                let state = match reg {
                    RegisterState::Registered { next_s } => {
                        serde_json::json!({"status": "registered", "next_s": next_s})
                    }
                    RegisterState::Registering => {
                        serde_json::json!({"status": "registering"})
                    }
                    RegisterState::Failed { retry_wait, error } => {
                        serde_json::json!({"status": "failed", "error": error, "retry_wait": retry_wait})
                    }
                };
                println!("{}", serde_json::json!({"type": "registration", "state": state}));
            } else {
                print_registration(reg);
            }
        }
        _ => {
            if json {
                println!(r#"{{"type":"other"}}"#);
            }
        }
    }
}

async fn cmd_handles(app: &App) -> Result<()> {
    wait_for_registration(app, 60).await?;
    let handles = get_handles(&app.state.client).await?;
    let phone_handles = get_my_phone_handles(&app.state.client).await?;
    println!("Handles:");
    for h in &handles {
        println!("  {h}");
    }
    if !phone_handles.is_empty() {
        println!("Phone handles:");
        for h in &phone_handles {
            println!("  {h}");
        }
    }
    Ok(())
}

async fn cmd_status(data_dir: &Path, app: &App) -> Result<()> {
    let reg = get_regstate(&app.state.client).await?;
    let prefs_path = data_dir.join("shared_preferences.json");
    let prefs: SharedPreferences = if prefs_path.exists() {
        serde_json::from_str(&std::fs::read_to_string(&prefs_path)?)?
    } else {
        SharedPreferences {
            finished_setup: false,
            mac_is_mine: false,
            icloud_account: None,
            user_name: None,
        }
    };

    println!("Data dir: {}", data_dir.display());
    println!("Setup finished: {}", prefs.finished_setup);
    println!("Mac is mine: {}", prefs.mac_is_mine);
    if let Some(account) = &prefs.icloud_account {
        println!("Apple ID: {account}");
    }
    if let Some(name) = &prefs.user_name {
        println!("Name: {name}");
    }
    print_registration(&reg);
    Ok(())
}

fn print_registration(reg: &RegisterState) {
    match reg {
        RegisterState::Registered { next_s } => {
            println!("Registration: registered (next refresh in {next_s}s)");
        }
        RegisterState::Registering => println!("Registration: registering…"),
        RegisterState::Failed { retry_wait, error } => {
            println!("Registration: failed ({error})");
            if let Some(wait) = retry_wait {
                println!("  retry in {wait}s");
            }
        }
    }
}

async fn pick_sender(app: &App, from: Option<&str>) -> Result<String> {
    if let Some(f) = from {
        return Ok(normalize_sender(f));
    }
    let handles = get_handles(&app.state.client).await?;
    handles
        .into_iter()
        .next()
        .context("no registered handles found")
}

async fn cmd_send(
    app: &mut App,
    to: &str,
    text: &str,
    from: Option<&str>,
    skip_validate: bool,
    wait_secs: u64,
) -> Result<()> {
    wait_for_registration(app, 60).await?;
    let recipient = normalize_recipient(to);
    let sender = pick_sender(app, from).await?;

    if !skip_validate {
        match validate_targets(
            &app.state.client,
            vec![recipient.clone()],
            sender.clone(),
        )
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
    let msg = MessageInst::new(conversation, &sender, Message::Message(normal));

    let uuid = msg.id.clone();
    send(&app.state.client, &app.state.local_broadcast, msg)
        .await
        .context("send failed")?;

    let confirm = timeout(Duration::from_secs(wait_secs), async {
        loop {
            if let Some(PushMessage::SendConfirm { uuid: got, error }) = app.events.recv().await {
                if got == uuid {
                    return error;
                }
            }
        }
    })
    .await;

    match confirm {
        Ok(Some(err)) => bail!("message send failed: {err}"),
        Ok(None) => {
            println!("sent {uuid} to {recipient}");
            Ok(())
        }
        Err(_) => bail!("timed out waiting for send confirmation ({wait_secs}s)"),
    }
}

async fn cmd_daemon(app: &mut App, json: bool) -> Result<()> {
    if !json {
        eprintln!("listening for messages (Ctrl+C to stop)…");
    }
    while let Some(msg) = app.events.recv().await {
        print_push_message(&msg, json);
    }
    Ok(())
}

fn cmd_chats_list(data_dir: &Path, limit: usize, json: bool) -> Result<()> {
    let store = data_dir.join("objectbox");
    let chats = objectbox_store::list_chats(&store, limit)?;
    objectbox_store::print_chats_table(&chats, json);
    Ok(())
}

fn cmd_chats_show(data_dir: &Path, guid: &str, limit: usize, json: bool) -> Result<()> {
    let store = data_dir.join("objectbox");
    let (chat, messages) = objectbox_store::show_chat(&store, guid, limit)?;
    objectbox_store::print_chat_show(&chat, &messages, json);
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    let data_dir = resolve_data_dir(&cli);

    match &cli.command {
        Commands::Chats { action } => {
            preflight(&data_dir, true)?;
            match action {
                ChatsAction::List { limit, json } => cmd_chats_list(&data_dir, *limit, *json),
                ChatsAction::Show { guid, limit, json } => {
                    cmd_chats_show(&data_dir, guid, *limit, *json)
                }
            }
        }
        Commands::Handles => {
            preflight(&data_dir, true)?;
            let app = start_app(&data_dir).await?;
            let result = cmd_handles(&app).await;
            shutdown_app(app).await;
            result
        }
        Commands::Status => {
            preflight(&data_dir, false)?;
            let app = start_app(&data_dir).await?;
            let result = cmd_status(&data_dir, &app).await;
            shutdown_app(app).await;
            result
        }
        Commands::Send {
            to,
            text,
            from,
            skip_validate,
            timeout: wait_secs,
        } => {
            preflight(&data_dir, true)?;
            rust_lib_bluebubbles::flathub_host::flathub_send_message(
                &data_dir.to_string_lossy(),
                to,
                text,
                from.as_deref(),
                *skip_validate,
                *wait_secs,
            )
            .await
        }
        Commands::Daemon { json } => {
            preflight(&data_dir, true)?;
            let mut app = start_app(&data_dir).await?;
            let result = cmd_daemon(&mut app, *json).await;
            shutdown_app(app).await;
            result
        }
    }
}
