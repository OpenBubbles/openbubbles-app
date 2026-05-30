//! Read-only access to OpenBubbles ObjectBox chat/message data (LMDB + FlatBuffers).

use std::collections::{HashMap, HashSet};
use std::path::Path;

use anyhow::{Context, Result, bail};
use heed::{EnvFlags, EnvOpenOptions, types::Bytes};
use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
pub struct ChatRow {
    pub id: i64,
    pub guid: String,
    pub chat_identifier: Option<String>,
    pub title: Option<String>,
    pub display_name: Option<String>,
    pub last_message_ms: Option<i64>,
}

#[derive(Debug, Clone, Serialize)]
pub struct MessageRow {
    pub id: i64,
    pub guid: Option<String>,
    pub text: Option<String>,
    pub date_created_ms: Option<i64>,
    pub is_from_me: bool,
    pub chat_id: i64,
}

fn root_offset(data: &[u8]) -> Option<usize> {
    if data.len() < 4 {
        return None;
    }
    let off = u32::from_le_bytes(data[data.len() - 4..].try_into().ok()?) as usize;
    if off == 0 || off >= data.len() {
        return None;
    }
    Some(off)
}

fn vtable_field_ptr(data: &[u8], table_off: usize, vtable_slot: u16) -> Option<usize> {
    if table_off + 4 > data.len() {
        return None;
    }
    let vtable_rel = i16::from_le_bytes(data[table_off..table_off + 2].try_into().ok()?);
    let vtable_off = (table_off as i32).wrapping_sub(vtable_rel as i32) as usize;
    if vtable_off + vtable_slot as usize + 2 > data.len() {
        return None;
    }
    let field_off =
        u16::from_le_bytes(data[vtable_off + vtable_slot as usize..vtable_off + vtable_slot as usize + 2].try_into().ok()?);
    if field_off == 0 {
        return None;
    }
    Some(table_off + field_off as usize)
}

fn read_string_field(data: &[u8], table_off: usize, vtable_slot: u16) -> Option<String> {
    let field_ptr = vtable_field_ptr(data, table_off, vtable_slot)?;
    if field_ptr + 4 > data.len() {
        return None;
    }
    let str_rel = u32::from_le_bytes(data[field_ptr..field_ptr + 4].try_into().ok()?) as usize;
    let str_off = field_ptr.wrapping_add(str_rel);
    if str_off + 4 > data.len() {
        return None;
    }
    let len = u32::from_le_bytes(data[str_off..str_off + 4].try_into().ok()?) as usize;
    let start = str_off + 4;
    if start + len > data.len() {
        return None;
    }
    Some(String::from_utf8_lossy(&data[start..start + len]).into_owned())
}

fn read_i64_field(data: &[u8], table_off: usize, vtable_slot: u16) -> Option<i64> {
    let field_ptr = vtable_field_ptr(data, table_off, vtable_slot)?;
    if field_ptr + 8 > data.len() {
        return None;
    }
    Some(i64::from_le_bytes(
        data[field_ptr..field_ptr + 8].try_into().ok()?,
    ))
}

fn read_bool_field(data: &[u8], table_off: usize, vtable_slot: u16) -> Option<bool> {
    let field_ptr = vtable_field_ptr(data, table_off, vtable_slot)?;
    if field_ptr >= data.len() {
        return None;
    }
    Some(data[field_ptr] != 0)
}

fn try_parse_chat_at(data: &[u8], table_off: usize) -> Option<ChatRow> {
    let guid = read_string_field(data, table_off, 8).unwrap_or_default();
    let chat_identifier = read_string_field(data, table_off, 12);
    let is_chat = guid.starts_with("iMessage;")
        || chat_identifier
            .as_deref()
            .is_some_and(|id| id.ends_with("/iMessage") || id.contains('@') || id.starts_with('+'));
    if !is_chat {
        return None;
    }
    let resolved_guid = if guid.is_empty() {
        chat_identifier
            .as_ref()
            .map(|id| format!("iMessage;-;{}", id.trim_end_matches("/iMessage")))
            .unwrap_or_default()
    } else {
        guid
    };
    if resolved_guid.is_empty() {
        return None;
    }
    Some(ChatRow {
        id: read_i64_field(data, table_off, 4).unwrap_or(0),
        guid: resolved_guid,
        chat_identifier,
        title: read_string_field(data, table_off, 32),
        display_name: read_string_field(data, table_off, 34),
        last_message_ms: read_i64_field(data, table_off, 26),
    })
}

fn try_parse_chat(data: &[u8]) -> Option<ChatRow> {
    if let Some(off) = root_offset(data) {
        if let Some(chat) = try_parse_chat_at(data, off) {
            return Some(chat);
        }
    }
    // ObjectBox may store objects with a small header before the flatbuffer root.
    for skip in [0usize, 4, 8, 12, 16] {
        if skip >= data.len() {
            continue;
        }
        if let Some(off) = root_offset(&data[skip..]) {
            if let Some(chat) = try_parse_chat_at(data, skip + off) {
                return Some(chat);
            }
        }
    }
    None
}

fn extract_ident_before_imessage(s: &str, pos: usize) -> Option<String> {
    let before = &s[..pos];
    let ident: String = before
        .chars()
        .rev()
        .take_while(|c| {
            c.is_ascii_alphanumeric() || *c == '+' || *c == '@' || *c == '.' || *c == '-'
        })
        .collect::<String>()
        .chars()
        .rev()
        .collect();
    if ident.len() >= 5 && (ident.contains('@') || ident.starts_with('+')) {
        Some(ident)
    } else {
        None
    }
}

fn fallback_list_chats(store_dir: &Path) -> Result<Vec<ChatRow>> {
    let data = std::fs::read(store_dir.join("data.mdb"))
        .context("failed to read objectbox data.mdb")?;
    let s = String::from_utf8_lossy(&data);
    let mut seen = HashSet::new();
    let mut rows = Vec::new();
    let mut idx = 0;
    while let Some(pos) = s[idx..].find("/iMessage") {
        let abs = idx + pos;
        if let Some(ident) = extract_ident_before_imessage(&s, abs) {
            if seen.insert(ident.clone()) {
                rows.push(ChatRow {
                    id: 0,
                    guid: format!("iMessage;-;{ident}"),
                    chat_identifier: Some(format!("{ident}/iMessage")),
                    title: None,
                    display_name: Some(ident),
                    last_message_ms: None,
                });
            }
        }
        idx = abs + 9;
    }
    Ok(rows)
}

fn chat_matches(chat: &ChatRow, needle: &str) -> bool {
    if chat.guid == needle {
        return true;
    }
    if chat.chat_identifier.as_deref() == Some(needle) {
        return true;
    }
    let normalized = needle
        .trim_start_matches("iMessage;-;")
        .trim_start_matches("iMessage;+;")
        .trim_start_matches("tel:")
        .trim_start_matches("mailto:");
    chat.guid.contains(normalized)
        || chat
            .chat_identifier
            .as_deref()
            .is_some_and(|id| id.contains(normalized))
        || chat
            .display_name
            .as_deref()
            .is_some_and(|n| n.contains(normalized))
}

fn try_parse_message(data: &[u8]) -> Option<MessageRow> {
    let table_off = root_offset(data)?;
    // Messages have a guid but not the iMessage;-; prefix on the chat guid field.
    let guid = read_string_field(data, table_off, 8);
    let text = read_string_field(data, table_off, 14);
    let date_created_ms = read_i64_field(data, table_off, 20);
    if guid.is_none() && text.is_none() && date_created_ms.is_none() {
        return None;
    }
    let chat_id = read_i64_field(data, table_off, 80).unwrap_or(0);
    if chat_id == 0 && text.is_none() {
        return None;
    }
    Some(MessageRow {
        id: read_i64_field(data, table_off, 4).unwrap_or(0),
        guid,
        text,
        date_created_ms,
        is_from_me: read_bool_field(data, table_off, 26).unwrap_or(false),
        chat_id,
    })
}

fn merge_chats(mut chats: Vec<ChatRow>) -> Vec<ChatRow> {
    let mut by_guid = HashMap::new();
    for chat in chats.drain(..) {
        by_guid
            .entry(chat.guid.clone())
            .and_modify(|existing: &mut ChatRow| {
                if existing.last_message_ms.unwrap_or(0) < chat.last_message_ms.unwrap_or(0) {
                    existing.last_message_ms = chat.last_message_ms;
                }
                if existing.title.is_none() {
                    existing.title = chat.title.clone();
                }
                if existing.display_name.is_none() {
                    existing.display_name = chat.display_name.clone();
                }
                if existing.id == 0 {
                    existing.id = chat.id;
                }
            })
            .or_insert(chat);
    }
    by_guid.into_values().collect()
}

fn load_all_chats(store_dir: &Path) -> Result<Vec<ChatRow>> {
    let mut chats = scan_values(store_dir, try_parse_chat)?;
    if chats.is_empty() {
        chats = fallback_list_chats(store_dir)?;
    } else {
        chats.extend(fallback_list_chats(store_dir)?);
    }
    Ok(merge_chats(chats))
}

fn open_env(store_dir: &Path) -> Result<heed::Env> {
    if !store_dir.join("data.mdb").exists() {
        bail!("ObjectBox store not found at {}", store_dir.display());
    }
    unsafe {
        EnvOpenOptions::new()
            .map_size(1024 * 1024 * 1024)
            .max_dbs(256)
            .flags(EnvFlags::READ_ONLY)
            .open(store_dir)
            .context("failed to open ObjectBox LMDB store (is OpenBubbles running?)")
    }
}

fn scan_values<F, T>(store_dir: &Path, mut parse: F) -> Result<Vec<T>>
where
    F: FnMut(&[u8]) -> Option<T>,
{
    let env = open_env(store_dir)?;
    let mut results = Vec::new();
    let rtxn = env.read_txn()?;

    let db_names: Vec<Option<&str>> = vec![None, Some("objects"), Some("Objects"), Some("data")];
    for db_name in db_names {
        let db: heed::Database<Bytes, Bytes> = match env.open_database(&rtxn, db_name) {
            Ok(Some(db)) => db,
            _ => continue,
        };
        let mut cursor = db.iter(&rtxn)?;
        while let Some((_key, value)) = cursor.next().transpose()? {
            if let Some(item) = parse(value) {
                results.push(item);
            }
        }
    }

    Ok(results)
}

pub fn list_chats(store_dir: &Path, limit: usize) -> Result<Vec<ChatRow>> {
    let mut chats = load_all_chats(store_dir)?;
    chats.sort_by(|a, b| {
        b.last_message_ms
            .unwrap_or(0)
            .cmp(&a.last_message_ms.unwrap_or(0))
    });
    chats.truncate(limit);
    Ok(chats)
}

pub fn show_chat(store_dir: &Path, guid: &str, message_limit: usize) -> Result<(ChatRow, Vec<MessageRow>)> {
    let chat = load_all_chats(store_dir)?
        .into_iter()
        .find(|c| chat_matches(c, guid))
        .with_context(|| format!("chat not found: {guid}"))?;

    let mut messages: Vec<MessageRow> = scan_values(store_dir, try_parse_message)?
        .into_iter()
        .filter(|m| m.chat_id == chat.id)
        .collect();
    messages.sort_by(|a, b| {
        a.date_created_ms
            .unwrap_or(0)
            .cmp(&b.date_created_ms.unwrap_or(0))
    });
    if messages.len() > message_limit {
        let skip = messages.len() - message_limit;
        messages = messages.split_off(skip);
    }
    Ok((chat, messages))
}

pub fn format_chat_label(chat: &ChatRow) -> String {
    chat.display_name
        .clone()
        .or_else(|| chat.title.clone())
        .or_else(|| chat.chat_identifier.clone())
        .unwrap_or_else(|| chat.guid.clone())
}

pub fn format_timestamp(ms: Option<i64>) -> String {
    match ms {
        Some(ms) => chrono::DateTime::from_timestamp_millis(ms)
            .map(|dt| dt.format("%Y-%m-%d %H:%M:%S").to_string())
            .unwrap_or_else(|| ms.to_string()),
        None => "-".to_string(),
    }
}

pub fn print_chats_table(chats: &[ChatRow], json: bool) {
    if json {
        println!("{}", serde_json::to_string_pretty(chats).unwrap());
        return;
    }
    println!("{:<40} {:<24} {}", "GUID", "LAST", "TITLE");
    for chat in chats {
        println!(
            "{:<40} {:<24} {}",
            chat.guid,
            format_timestamp(chat.last_message_ms),
            format_chat_label(chat)
        );
    }
}

pub fn print_chat_show(chat: &ChatRow, messages: &[MessageRow], json: bool) {
    if json {
        println!(
            "{}",
            serde_json::to_string_pretty(&serde_json::json!({
                "chat": chat,
                "messages": messages,
            }))
            .unwrap()
        );
        return;
    }
    println!("Chat: {}", format_chat_label(chat));
    println!("GUID: {}", chat.guid);
    if let Some(id) = &chat.chat_identifier {
        println!("Identifier: {id}");
    }
    println!();
    for msg in messages {
        let dir = if msg.is_from_me { "me" } else { "them" };
        println!(
            "[{}] {} ({}): {}",
            format_timestamp(msg.date_created_ms),
            dir,
            msg.guid.as_deref().unwrap_or("-"),
            msg.text.as_deref().unwrap_or("")
        );
    }
}
