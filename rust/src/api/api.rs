

use std::{borrow::{Borrow, BorrowMut}, fs, future::Future, io::{Cursor, Write}, ops::Deref, path::{Path, PathBuf}, str::FromStr, sync::{Arc, OnceLock}, time::Duration};

use anyhow::anyhow;
use flutter_rust_bridge::{frb, IntoDart, JoinHandle};
use icloud_auth::{default_provider, ArcAnisetteClient, LoginClientInfo};
use plist::{Data, Dictionary};
pub use plist::Value;


use prost::Message as prostMessage;
use serde::{Deserialize, Deserializer, Serialize, Serializer};
use tokio::{runtime::Runtime, select, sync::{broadcast, mpsc, oneshot::{self, Sender}, watch, Mutex, RwLock}};
use rustpush::{authenticate_apple, authenticate_phone, findmy::{FindMyClient, FindMyState, MULTIPLEX_SERVICE}, login_apple_delegates, APSMessage, LoginDelegate, MADRID_SERVICE};

pub use rustpush::findmy::{FindMyFriendsClient, FindMyPhoneClient};
pub use icloud_auth::DefaultAnisetteProvider;
use uniffi::{deps::log::{info, error}, HandleAlloc};
use uuid::Uuid;
use std::io::Seek;
use async_recursion::async_recursion;

use crate::{frb_generated::{SseEncode, StreamSink}, init_logger, native::QUEUED_MESSAGES, RUNTIME};

use flutter_rust_bridge::for_generated::{SimpleHandler, SimpleExecutor, NoOpErrorListener, SimpleThreadPool, BaseAsyncRuntime, lazy_static};

pub type MyHandler = SimpleHandler<SimpleExecutor<NoOpErrorListener, SimpleThreadPool, MyAsyncRuntime>, NoOpErrorListener>;

include!("./mirrors.rs");

#[derive(Debug, Default)]
pub struct MyAsyncRuntime();

impl BaseAsyncRuntime for MyAsyncRuntime {
    fn spawn<F>(&self, future: F) -> JoinHandle<F::Output>
    where
        F: Future + Send + 'static,
        F::Output: Send + 'static,
    {
        RUNTIME.spawn(future)
    }
}

lazy_static! {
    pub static ref FLUTTER_RUST_BRIDGE_HANDLER: MyHandler = {
        MyHandler::new(
            SimpleExecutor::new(NoOpErrorListener, Default::default(), Default::default()),
            NoOpErrorListener,
        )
    };
}

#[frb(opaque)]
#[derive(Serialize, Deserialize, Clone)]
#[serde(tag = "type")]
pub enum JoinedOSConfig {
    MacOS(Arc<MacOSConfig>),
    Relay(Arc<RelayConfig>),
}

impl JoinedOSConfig {
    fn config(&self) -> Arc<dyn OSConfig> {
        match self {
            Self::MacOS(conf) => conf.clone(),
            Self::Relay(conf) => conf.clone(),
        }
    }
}

impl Deref for JoinedOSConfig {
    type Target = dyn OSConfig;

    fn deref(&self) -> &Self::Target {
        match self {
            Self::MacOS(conf) => conf.as_ref(),
            Self::Relay(conf) => conf.as_ref(),
        }
    }
}

#[derive(Serialize, Deserialize, Clone)]
struct SavedHardwareState {
    push: APSState,
    identity: IDSUserIdentity,
    os_config: JoinedOSConfig,
}

pub enum RegistrationPhase {
    WantsOSConfig,
    WantsRegister,
    Registered,
}

#[frb(ignore)]
pub struct InnerPushState {
    pub anisette: Option<ArcAnisetteClient<DefaultAnisetteProvider>>,
    pub conn: Option<APSConnection>,
    pub inq_queue: Option<Mutex<broadcast::Receiver<APSMessage>>>,
    pub client: Option<IMClient>,
    pub fmfd: Option<FindMyClient<DefaultAnisetteProvider>>,
    pub conf_dir: PathBuf,
    pub os_config: Option<JoinedOSConfig>,
    pub account: Option<AppleAccount<DefaultAnisetteProvider>>,
    pub cancel_poll: Mutex<Option<Sender<()>>>,
    pub identity: Option<IDSUserIdentity>,
    pub local_messages: Mutex<mpsc::Receiver<PushMessage>>,
    pub local_broadcast: mpsc::Sender<PushMessage>,
    pub reg_state: Option<Mutex<watch::Receiver<ResourceState>>>,
}

#[frb(opaque)]
pub struct PushState (RwLock<InnerPushState>);

pub async fn new_push_state(dir: String) -> Arc<PushState> {
    let dir = PathBuf::from_str(&dir).unwrap();
    init_logger(&dir);
    let (sender, recv) = mpsc::channel(999);
    // flutter_rust_bridge::setup_default_user_utils();
    let state = PushState(RwLock::new(InnerPushState {
        anisette: None,
        conn: None,
        client: None,
        inq_queue: None,
        reg_state: None,
        fmfd: None,
        conf_dir: dir,
        os_config: None,
        account: None,
        cancel_poll: Mutex::new(None),
        identity: None,
        local_broadcast: sender,
        local_messages: Mutex::new(recv),
    }));
    restore(&state).await;
    Arc::new(state)
}

pub fn service_from_ptr(ptr: String) -> Arc<PushState> {
    let pointer: u64 = ptr.parse().unwrap();
    info!("using state {pointer}");
    let service = unsafe {
        Arc::from_raw(pointer as *const PushState)
    };
    service
}

fn plist_to_buf<T: serde::Serialize>(value: &T) -> Result<Vec<u8>, plist::Error> {
    let mut buf: Vec<u8> = Vec::new();
    let writer = Cursor::new(&mut buf);
    plist::to_writer_xml(writer, &value)?;
    Ok(buf)
}

fn plist_to_string<T: serde::Serialize>(value: &T) -> Result<String, plist::Error> {
    plist_to_buf(value).map(|val| String::from_utf8(val).unwrap())
}

fn plist_to_bin<T: serde::Serialize>(value: &T) -> Result<Vec<u8>, plist::Error> {
    let mut buf: Vec<u8> = Vec::new();
    let writer = Cursor::new(&mut buf);
    plist::to_writer_binary(writer, &value)?;
    Ok(buf)
}

async fn restore(curr_state: &PushState) {
    if !matches!(curr_state.get_phase().await, RegistrationPhase::WantsOSConfig) {
        panic!("Wrong phase! (restore)")
    }

    let mut inner = curr_state.0.write().await;

    let hw_config_path = inner.conf_dir.join("hw_info.plist");
    let id_path = inner.conf_dir.join("id.plist");

    info!("restoring now");

    // migrate
    if let Ok(config) = plist::from_file::<_, SavedHardwareState>(&inner.conf_dir.join("config.plist")) {
        std::fs::write(&hw_config_path, plist_to_string(&config).unwrap()).unwrap();
        let data: Value = plist::from_file(&inner.conf_dir.join("config.plist")).unwrap();
        std::fs::write(&id_path, plist_to_string(&data.as_dictionary().unwrap().get("users").unwrap()).unwrap()).unwrap();
        std::fs::remove_file(inner.conf_dir.join("config.plist")).unwrap();
        info!("migrated!");
    }

    if let Ok(mut value) = plist::from_file::<_, Dictionary>(&hw_config_path) {
        let os_config = value["os_config"].as_dictionary_mut().unwrap();
        if !os_config.contains_key("type") {
            os_config.insert("type".to_string(), Value::String("MacOS".to_string()));
        }
        std::fs::write(&hw_config_path, plist_to_string(&value).unwrap()).unwrap();
        info!("migrated two!");
    }

    // second migrate
    if let Ok(mut users) = plist::from_file::<_, Vec<Dictionary>>(&id_path) {
        for user in &mut users {
            if user.contains_key("handles") {
                // migrate!
                let handles = user.remove("handles").unwrap();
                let identity = user.get_mut("identity").unwrap().as_dictionary_mut().unwrap();
                let id_keypair = identity.remove("id_keypair").unwrap();

                let registration = Dictionary::from_iter([
                    ("id_keypair", id_keypair),
                    ("handles", handles),
                ].into_iter());
                user.insert("registration".to_string(), Value::Dictionary(registration));

                info!("migrated!")
            }
        }
        std::fs::write(&id_path, plist_to_string(&users).unwrap()).unwrap();
    }

    if let Ok(mut value) = plist::from_file::<_, Dictionary>(&hw_config_path) {
        if !value.contains_key("identity") {
            if let Ok(users) = plist::from_file::<_, Vec<Dictionary>>(&id_path) {
                // get first phone user or first user
                if let Some(user) = users.iter()
                    .find(|user| user["user_id"].as_string().unwrap().starts_with("P:")).or(users.first()) {
                    
                    value.insert("identity".to_string(), user["identity"].clone());
                    std::fs::write(&hw_config_path, plist_to_string(&value).unwrap()).unwrap();

                    info!("migrated identity!");
                }
            }
        }
    }

    if let Ok(mut users) = plist::from_file::<_, Vec<Dictionary>>(&id_path) {
        for user in &mut users {
            let registration = user.get_mut("registration").unwrap().as_dictionary_mut().unwrap();
            if !registration.contains_key("com.apple.madrid") {
                // migrate!
                *registration = Dictionary::from_iter([
                    ("com.apple.madrid", Value::Dictionary(registration.clone()))
                ]);
            }
        }
        std::fs::write(&id_path, plist_to_string(&users).unwrap()).unwrap();
    }

    let Ok(state) = plist::from_file::<_, SavedHardwareState>(&hw_config_path) else { return };

    // even if we failed on the initial connection, we don't care cuz we're restoring.
    inner.os_config = Some(state.os_config);
    inner.identity = Some(state.identity.clone());
    let (connection, _err) = setup_push(inner.os_config.as_ref().unwrap(), &state.identity, Some(&state.push), hw_config_path).await;
    inner.inq_queue = Some(Mutex::new(connection.messages_cont.subscribe()));
    inner.conn = Some(connection);
    let provider = Some(default_provider(inner.os_config.as_ref().unwrap().get_gsa_config(&*inner.conn.as_ref().unwrap().state.read().await), inner.conf_dir.join("anisette_test")));
    inner.anisette = provider;

    // id may not exist yet; that's fine
    let Ok(users) = plist::from_file::<_, Vec<IDSUser>>(&id_path) else { return };

    inner.client = Some(IMClient::new(inner.conn.as_ref().unwrap().clone(), users, state.identity, 
        &[&MADRID_SERVICE, &MULTIPLEX_SERVICE], inner.conf_dir.join("id_cache.plist"), inner.os_config.as_ref().unwrap().config(), Box::new(move |updated_keys| {
            println!("updated keys!!!");
            std::fs::write(&id_path, plist_to_string(&updated_keys).unwrap()).unwrap();
        })).await);
    
    inner.reg_state = Some(Mutex::new(inner.client.as_ref().unwrap().identity.resource_state.subscribe()));
    
    let id_path = inner.conf_dir.join("findmy.plist");

    if let Ok(state) = plist::from_file(id_path) {
        inner.fmfd = Some(FindMyClient::new(inner.conn.as_ref().unwrap().clone(), inner.os_config.as_ref().unwrap().config(), state, inner.anisette.clone().unwrap(), inner.client.as_ref().unwrap().identity.clone()).await.unwrap());
    }
}

pub async fn can_find_my(state: &Arc<PushState>) -> anyhow::Result<bool> {
    let inner = state.0.read().await;
    let id_path = inner.conf_dir.join("findmy.plist");
    Ok(plist::from_file::<_, FindMyState>(id_path).is_ok())
}

pub async fn register_ids(state: &Arc<PushState>, users: &Vec<IDSUser>) -> anyhow::Result<Option<SupportAlert>> {
    let mut users = users.clone(); // don't take ownership in case of failure
    if !matches!(state.get_phase().await, RegistrationPhase::WantsRegister) {
        panic!("Wrong phase! (register_ids)")
    }
    let mut inner = state.0.write().await;
    let conn_state = inner.conn.as_ref().unwrap().clone();

    if let Err(err) = register(inner.os_config.as_deref().unwrap(), &*conn_state.state.read().await, &[&MADRID_SERVICE, &MULTIPLEX_SERVICE], &mut users, inner.identity.as_ref().unwrap()).await {
        return if let PushError::CustomerMessage(support) = err {
            Ok(Some(support))
        } else {
            Err(anyhow!(err))
        }
    }
    let id_path = inner.conf_dir.join("id.plist");
    std::fs::write(&id_path, plist_to_string(&users).unwrap()).unwrap();

    inner.client = Some(IMClient::new(conn_state, users, inner.identity.clone().unwrap(), &[&MADRID_SERVICE, &MULTIPLEX_SERVICE], inner.conf_dir.join("id_cache.plist"), inner.os_config.as_ref().unwrap().config(), Box::new(move |updated_keys| {
        std::fs::write(&id_path, plist_to_string(&updated_keys).unwrap()).unwrap();
    })).await);

    inner.reg_state = Some(Mutex::new(inner.client.as_ref().unwrap().identity.resource_state.subscribe()));

    let id_path = inner.conf_dir.join("findmy.plist");
    if let Ok(state) = plist::from_file(id_path) {
        inner.fmfd = Some(FindMyClient::new(inner.conn.as_ref().unwrap().clone(), inner.os_config.as_ref().unwrap().config(), state, inner.anisette.clone().unwrap(), inner.client.as_ref().unwrap().identity.clone()).await.unwrap());
    }

    Ok(None)
}

async fn setup_push(config: &JoinedOSConfig, identity: &IDSUserIdentity, state: Option<&APSState>, state_path: PathBuf) -> (APSConnection, Option<PushError>) {
    let (conn, error) = APSConnectionResource::new(config.config(), state.cloned()).await;

    if error.is_none() {
        let state = SavedHardwareState {
            push: conn.state.read().await.clone(),
            os_config: config.clone(),
            identity: identity.clone(),
        };
        std::fs::write(&state_path, plist_to_string(&state).unwrap()).unwrap();
    }

    let mut to_refresh = conn.generated_signal.subscribe();
    let reconn_conn = Arc::downgrade(&conn);
    let config_ref = config.clone();
    let ident_ref = identity.clone();
    tokio::spawn(async move {
        loop {
            match to_refresh.recv().await {
                Ok(()) => {
                    let Some(conn) = reconn_conn.upgrade() else { break };
                    // update keys
                    let state = SavedHardwareState {
                        push: conn.state.read().await.clone(),
                        os_config: config_ref.clone(),
                        identity: ident_ref.clone(),
                    };
                    std::fs::write(&state_path, plist_to_string(&state).unwrap()).unwrap();
                },
                Err(broadcast::error::RecvError::Lagged(_)) => continue,
                Err(broadcast::error::RecvError::Closed) => break,
            }
        }
    });

    (conn, error)
}

async fn get_login_config(inner: &InnerPushState) -> LoginClientInfo {
    inner.os_config.as_ref().unwrap().get_gsa_config(&*inner.conn.as_ref().unwrap().state.read().await)
}

pub async fn configure_app_review(state: &Arc<PushState>) -> anyhow::Result<()> {
    let inner = state.0.write().await;
    std::fs::write(inner.conf_dir.join("id.plist"), include_str!("id_testing.plist"))?;
    std::fs::write(inner.conf_dir.join("hw_info.plist"), include_str!("hw_testing.plist"))?;
    drop(inner);
    restore(state).await;
    Ok(())
}

pub async fn configure_macos(state: &Arc<PushState>, config: &JoinedOSConfig) -> anyhow::Result<()> {
    let config = config.clone();
    let mut inner = state.0.write().await;
    inner.os_config = Some(config.clone());
    inner.identity = Some(IDSUserIdentity::new()?);
    // delete anisette provisioning to prevent 6005's
    let anisette_dir = inner.conf_dir.join("anisette_test");
    if anisette_dir.exists() {
        fs::remove_dir_all(inner.conf_dir.join("anisette_test"))?;
    }
    let conf_path = inner.conf_dir.join("hw_info.plist");
    let (connection, err) = setup_push(inner.os_config.as_ref().unwrap(), inner.identity.as_ref().unwrap(), None, conf_path).await;
    if let Some(err) = err {
        return Err(err.into())
    }
    inner.inq_queue = Some(Mutex::new(connection.messages_cont.subscribe()));
    inner.conn = Some(connection);
    let provider = Some(default_provider(get_login_config(&*inner).await, inner.conf_dir.join("anisette_test")));
    inner.anisette = provider;
    Ok(())
}

pub async fn refresh_token(state: &Arc<PushState>) -> anyhow::Result<()> {
    let mut inner = state.0.write().await;

    let InnerPushState { identity: Some(identity), os_config: Some(os_config), .. } = &*inner else {
        return Err(anyhow!("No indentity!"))
    };
    let conf_path = inner.conf_dir.join("hw_info.plist");
    let (connection, err) = setup_push(os_config, identity, None, conf_path).await;
    if let Some(err) = err {
        return Err(err.into())
    }
    inner.inq_queue = Some(Mutex::new(connection.messages_cont.subscribe()));
    inner.conn = Some(connection);
    
    Ok(())
}

pub struct HwExtra {
    pub version: String,
    pub protocol_version: u32,
    pub device_id: String,
    pub icloud_ua: String,
    pub aoskit_version: String,
}

pub fn config_from_validation_data(data: Vec<u8>, extra: HwExtra) -> anyhow::Result<JoinedOSConfig> {
    let inner = HardwareConfig::from_validation_data(&data)?;
    Ok(JoinedOSConfig::MacOS(Arc::new(MacOSConfig {
        inner,
        version: extra.version,
        protocol_version: extra.protocol_version,
        device_id: extra.device_id,
        icloud_ua: extra.icloud_ua,
        aoskit_version: extra.aoskit_version,
    })))
}

pub async fn config_from_relay(code: String, host: String, token: &Option<String>) -> anyhow::Result<JoinedOSConfig> {
    Ok(JoinedOSConfig::Relay(Arc::new(RelayConfig {
        version: RelayConfig::get_versions(&host, &code, token).await?,
        icloud_ua: "com.apple.iCloudHelper/282 CFNetwork/1408.0.4 Darwin/22.5.0".to_string(),
        aoskit_version: "com.apple.AOSKit/282 (com.apple.accountsd/113)".to_string(),
        dev_uuid: Uuid::new_v4().to_string(),
        protocol_version: 1660,
        host: host.clone(),
        code: code.clone(),
        beeper_token: token.clone(),
    })))
}

pub struct DeviceInfo {
    pub name: String,
    pub serial: String,
    pub os_version: String,
    pub encoded_data: Option<Vec<u8>>,
}

pub async fn get_device_info_state(state: &Arc<PushState>) -> anyhow::Result<DeviceInfo> {
    let locked = state.0.read().await;
    get_device_info(locked.os_config.as_ref().unwrap())
}

pub async fn get_config_state(state: &Arc<PushState>) -> Option<JoinedOSConfig> {
    let locked = state.0.read().await;
    locked.os_config.clone()
}

pub fn get_device_info(config: &JoinedOSConfig) -> anyhow::Result<DeviceInfo> {
    let debug_info = config.get_debug_meta();
    Ok(DeviceInfo {
        name: debug_info.hardware_version.clone(),
        serial: debug_info.serial_number.clone(),
        os_version: debug_info.user_version.clone(),
        encoded_data: match config {
            JoinedOSConfig::MacOS(config) => {
                let copied = config.as_ref().clone();
                Some(crate::bbhwinfo::HwInfo {
                    inner: Some(crate::bbhwinfo::hw_info::InnerHwInfo {
                        product_name: copied.inner.product_name,
                        io_mac_address: copied.inner.io_mac_address.to_vec(),
                        platform_serial_number: copied.inner.platform_serial_number,
                        platform_uuid: copied.inner.platform_uuid,
                        root_disk_uuid: copied.inner.root_disk_uuid,
                        board_id: copied.inner.board_id,
                        os_build_num: copied.inner.os_build_num,
                        platform_serial_number_enc: copied.inner.platform_serial_number_enc,
                        platform_uuid_enc: copied.inner.platform_uuid_enc,
                        root_disk_uuid_enc: copied.inner.root_disk_uuid_enc,
                        rom: copied.inner.rom,
                        rom_enc: copied.inner.rom_enc,
                        mlb: copied.inner.mlb,
                        mlb_enc: copied.inner.mlb_enc
                    }),
                    version: copied.version,
                    protocol_version: copied.protocol_version as i32,
                    device_id: copied.device_id,
                    icloud_ua: copied.icloud_ua,
                    aoskit_version: copied.aoskit_version,
                }.encode_to_vec())
            },
            JoinedOSConfig::Relay(_) => None
        }
    })
}

pub fn config_from_encoded(encoded: Vec<u8>) -> anyhow::Result<JoinedOSConfig> {
    let copied = crate::bbhwinfo::HwInfo::decode(&mut Cursor::new(encoded))?;
    let inner = copied.inner.unwrap();
    Ok(JoinedOSConfig::MacOS(Arc::new(MacOSConfig {
        inner: HardwareConfig {
            product_name: inner.product_name,
            io_mac_address: inner.io_mac_address.try_into().unwrap(),
            platform_serial_number: inner.platform_serial_number,
            platform_uuid: inner.platform_uuid,
            root_disk_uuid: inner.root_disk_uuid,
            board_id: inner.board_id,
            os_build_num: inner.os_build_num,
            platform_serial_number_enc: inner.platform_serial_number_enc,
            platform_uuid_enc: inner.platform_uuid_enc,
            root_disk_uuid_enc: inner.root_disk_uuid_enc,
            rom: inner.rom,
            rom_enc: inner.rom_enc,
            mlb: inner.mlb,
            mlb_enc: inner.mlb_enc
        },
        version: copied.version,
        protocol_version: copied.protocol_version as u32,
        device_id: copied.device_id,
        icloud_ua: copied.icloud_ua,
        aoskit_version: copied.aoskit_version,
    })))
}


pub async fn ptr_to_dart(ptr: String) -> Option<PushMessage> {
    let pointer: u64 = ptr.parse().unwrap();
    info!("using pointer {pointer}");
    QUEUED_MESSAGES.lock().await.1.get(&pointer).cloned()
}

pub async fn complete_msg(ptr: String) {
    let pointer: u64 = ptr.parse().unwrap();
    info!("finishing pointer {pointer}");
    QUEUED_MESSAGES.lock().await.1.remove(&pointer);
}




pub fn restore_attachment(data: String) -> Attachment {
    plist::from_reader_xml(Cursor::new(data)).unwrap()
}

pub fn save_attachment(att: &Attachment) -> String {
    plist_to_string(att).unwrap()
}

pub fn create_image_array(img: LPImageMetadata) -> NSArray<LPImageMetadata> {
    NSArray {
        objects: vec![img],
        class: NSArrayClass::NSArray,
    }
}

pub fn create_icon_array(img: LPIconMetadata) -> NSArray<LPIconMetadata> {
    NSArray {
        objects: vec![img],
        class: NSArrayClass::NSArray,
    }
}



#[repr(C)]
#[derive(Clone)]
pub enum PushMessage {
    IMessage(MessageInst),
    SendConfirm {
        uuid: String,
        error: Option<String>,
    },
    RegistrationState(RegisterState),
}

pub enum PollResult {
    Stop,
    Cont(Option<PushMessage>),
}

pub async fn recv_wait(state: &Arc<PushState>) -> PollResult {
    if !matches!(state.get_phase().await, RegistrationPhase::Registered) {
        panic!("Wrong phase! (recv_wait)")
    }
    let (send, recv) = oneshot::channel();
    let recv_path = state.0.read().await;
    let mut local_lock = recv_path.local_messages.lock().await;
    *recv_path.cancel_poll.lock().await = Some(send);
    let mut inq_lock = recv_path.inq_queue.as_ref().unwrap().lock().await;
    let mut reg_state = recv_path.reg_state.as_ref().unwrap().lock().await;
    select! {
        msg = inq_lock.recv() => {
            let msg = msg.unwrap();
            if let Some(fmfd) = &recv_path.fmfd {
                let _ = fmfd.handle(msg.clone()).await;
            }
            let msg = recv_path.client.as_ref().expect("no client??/").handle(msg).await;
            *recv_path.cancel_poll.lock().await = None;
            let msg = match msg {
                Ok(Some(msg)) => Some(PushMessage::IMessage(msg)),
                Ok(None) => None,
                Err(err) => {
                    // log and ignore for now
                    error!("{}", err);
                    return PollResult::Cont(None);
                }
            };
            PollResult::Cont(msg)
        },
        _reg_state = reg_state.changed() => {
            drop(inq_lock);
            drop(reg_state);
            drop(local_lock);
            drop(recv_path);
            PollResult::Cont(Some(PushMessage::RegistrationState(get_regstate(state).await.unwrap())))
        }
        reader = local_lock.recv() => {
            PollResult::Cont(Some(reader.unwrap()))
        },
        _cancel = recv => {
            PollResult::Stop
        }
    }
}

pub async fn send(state: &Arc<PushState>, mut msg: MessageInst) -> anyhow::Result<bool> {
    if !matches!(state.get_phase().await, RegistrationPhase::Registered) {
        panic!("Wrong phase! (send)")
    }
    println!("sending_1");
    let state_cpy = state.clone();
    let inner = state.0.read().await;
    println!("sending_2");
    let result = inner.client.as_ref().unwrap().send(&mut msg).await?;
    println!("send_finish");

    if let Some(handle) = result.handle {
        let uuid = msg.id.clone();
        tokio::spawn(async move {
            let result = handle.await.unwrap();
            info!("Finished handle");
            let locked = state_cpy.0.read().await;
            let maybeerr = result.err().map(|err| format!("{}", err));
            let _ = locked.local_broadcast.send(PushMessage::SendConfirm { uuid, error: maybeerr }).await;
        });
        Ok(true)
    } else {
        Ok(false)
    }
}

pub async fn get_handles(state: &Arc<PushState>) -> anyhow::Result<Vec<String>> {
    if !matches!(state.get_phase().await, RegistrationPhase::Registered) {
        panic!("Wrong phase! (send)")
    }
    Ok(state.0.read().await.client.as_ref().unwrap().identity.get_handles().await.to_vec())
}

pub async fn do_reregister(state: &Arc<PushState>) -> anyhow::Result<()> {
    if !matches!(state.get_phase().await, RegistrationPhase::Registered) {
        panic!("Wrong phase! (send)")
    }
    state.0.read().await.client.as_ref().unwrap().identity.refresh_now().await?;
    Ok(())
}

pub async fn new_msg(state: &Arc<PushState>, conversation: ConversationData, sender: String, message: Message) -> MessageInst {
    if !matches!(state.get_phase().await, RegistrationPhase::Registered) {
        panic!("Wrong phase! (new_msg)")
    }
    MessageInst::new(conversation, &sender, message)
}

pub async fn validate_targets(state: &Arc<PushState>, targets: Vec<String>, sender: String) -> anyhow::Result<Vec<String>> {
    if !matches!(state.get_phase().await, RegistrationPhase::Registered) {
        panic!("Wrong phase! (validate_targets)")
    }
    Ok(state.0.read().await.client.as_ref().unwrap().identity.validate_targets(&targets, "com.apple.madrid", &sender).await?)
}

pub async fn get_phase(state: &Arc<PushState>) -> RegistrationPhase {
    state.get_phase().await
}

#[frb(type_64bit_int)]
pub struct TransferProgress {
    pub prog: usize,
    pub total: usize,
    pub attachment: Option<Attachment>
}

pub async fn download_attachment(sink: StreamSink<TransferProgress>, state: &Arc<PushState>, attachment: Attachment, path: String) {
    wrap_sink(&sink, || async {
        let inner = state.0.read().await;
        println!("donwloading file {}", path);
        let path = std::path::Path::new(&path);
        let prefix = path.parent().unwrap();
        std::fs::create_dir_all(prefix)?;
        let mut file = std::fs::File::create(path)?;
        attachment.get_attachment(inner.conn.as_ref().unwrap(), &mut file, &mut |prog, total| {
            println!("donwloading file {} of {}", prog, total);
            sink.add(TransferProgress {
                prog,
                total,
                attachment: None
            }).unwrap();
        }).await?;
        file.flush()?;
        Ok(())
    }).await
}

pub async fn download_mmcs(sink: StreamSink<TransferProgress>, state: &Arc<PushState>, attachment: MMCSFile, path: String) {
    wrap_sink(&sink, || async {
        let inner = state.0.read().await;
        let path = std::path::Path::new(&path);
        let prefix = path.parent().unwrap();
        std::fs::create_dir_all(prefix)?;

        let mut file = std::fs::File::create(path)?;
        attachment.get_attachment(inner.conn.as_ref().unwrap(), &mut file, &mut |prog, total| {
            sink.add(TransferProgress {
                prog,
                total,
                attachment: None
            }).unwrap();
        }).await?;
        file.flush()?;
        Ok(())
    }).await
}

async fn wrap_sink<Fut, T: SseEncode + Send + Sync>(sink: &StreamSink<T>, f: impl FnOnce() -> Fut)
    where Fut: Future<Output = anyhow::Result<()>> {
    if let Err(err) = f().await {
        sink.add_error(err).unwrap();
    }
}

#[frb(type_64bit_int)]
pub struct MMCSTransferProgress {
    pub prog: usize,
    pub total: usize,
    pub file: Option<MMCSFile>
}

pub async fn upload_mmcs(sink: StreamSink<MMCSTransferProgress>, state: &Arc<PushState>, path: String) {
    wrap_sink(&sink, || async {
        let inner = state.0.read().await;

        let mut file = std::fs::File::open(path)?;
        let prepared = MMCSFile::prepare_put(&mut file).await?;
        file.rewind()?;
        let attachment = MMCSFile::new(inner.conn.as_ref().unwrap(), &prepared, &mut file, &mut |prog, total| {
            sink.add(MMCSTransferProgress {
                prog,
                total,
                file: None
            }).unwrap();
        }).await?;
        sink.add(MMCSTransferProgress { prog: 0, total: 0, file: Some(attachment) }).unwrap();
        Ok(())
    }).await
}

pub async fn upload_attachment(sink: StreamSink<TransferProgress>, state: &Arc<PushState>, path: String, mime: String, uti: String, name: String) {
    wrap_sink(&sink, || async {
        let inner = state.0.read().await;

        let mut file = std::fs::File::open(path)?;
        let prepared = MMCSFile::prepare_put(&mut file).await?;
        file.rewind()?;
        let attachment = Attachment::new_mmcs(inner.conn.as_ref().unwrap(), &prepared, &mut file, &mime, &uti, &name, &mut |prog, total| {
            sink.add(TransferProgress {
                prog,
                total,
                attachment: None
            }).unwrap();
        }).await?;
        sink.add(TransferProgress { prog: 0, total: 0, attachment: Some(attachment) }).unwrap();
        Ok(())
    }).await
}

pub async fn get_token(state: &Arc<PushState>) -> Vec<u8> {
    let connection = state.0.read().await.conn.as_ref().unwrap().clone();

    connection.get_token().await.to_vec()
}

pub fn save_user(user: &IDSUser) -> anyhow::Result<String> {
    Ok(plist_to_string(user)?)
}

pub fn restore_user(user: String) -> anyhow::Result<IDSUser> {
    Ok(plist::from_reader(Cursor::new(user))?)
}

pub async fn make_find_my_phone(state: &Arc<PushState>) -> anyhow::Result<FindMyPhoneClient<DefaultAnisetteProvider>> {
    let inner = state.0.read().await;

    let id_path = inner.conf_dir.join("findmy.plist");
    let state: FindMyState = plist::from_file(id_path)?;
    
    Ok(FindMyPhoneClient::new(inner.os_config.as_deref().unwrap(), state, inner.conn.clone().unwrap(), inner.anisette.clone().unwrap()).await?)
}

pub async fn get_devices(client: &mut FindMyPhoneClient<DefaultAnisetteProvider>) -> Vec<FoundDevice> {
    client.devices.clone()
}

pub async fn refresh_devices(state: &Arc<PushState>, client: &mut FindMyPhoneClient<DefaultAnisetteProvider>) -> anyhow::Result<Vec<FoundDevice>> {
    let inner = state.0.read().await;
    client.refresh(inner.os_config.as_deref().unwrap()).await?;
    Ok(client.devices.clone())
}

pub async fn make_find_my_friends(state: &Arc<PushState>) -> anyhow::Result<FindMyFriendsClient<DefaultAnisetteProvider>> {
    let inner = state.0.read().await;

    let id_path = inner.conf_dir.join("findmy.plist");
    let state: FindMyState = plist::from_file(id_path)?;
    
    Ok(FindMyFriendsClient::new(inner.os_config.as_deref().unwrap(), state, inner.conn.clone().unwrap(), inner.anisette.clone().unwrap(), false).await?)
}

pub async fn get_following(client: &mut FindMyFriendsClient<DefaultAnisetteProvider>) -> Vec<Follow> {
    client.following.clone()
}

pub async fn refresh_following(state: &Arc<PushState>, client: &mut FindMyFriendsClient<DefaultAnisetteProvider>) -> anyhow::Result<Vec<Follow>> {
    let inner = state.0.read().await;
    client.refresh(inner.os_config.as_deref().unwrap()).await?;
    Ok(client.following.clone())
}

pub async fn select_friend(state: &Arc<PushState>, client: &mut FindMyFriendsClient<DefaultAnisetteProvider>, friend: Option<String>) -> anyhow::Result<Vec<Follow>> {
    let inner = state.0.read().await;
    client.selected_friend = friend;
    client.refresh(inner.os_config.as_deref().unwrap()).await?;
    Ok(client.following.clone())
}

pub async fn select_background_friend(state: &Arc<PushState>, friend: Option<String>) -> anyhow::Result<Vec<Follow>> {
    let inner = state.0.read().await;
    let mut x = inner.fmfd.as_ref().unwrap().daemon.lock().await;
    x.selected_friend = friend;
    Ok(x.following.clone())
}

pub async fn get_background_following(state: &Arc<PushState>) -> Vec<Follow> {
    let inner = state.0.read().await;
    let x = inner.fmfd.as_ref().unwrap().daemon.lock().await.following.clone();
    x
}

pub async fn refresh_background_following(state: &Arc<PushState>) -> anyhow::Result<Vec<Follow>> {
    let inner = state.0.read().await;
    let mut x = inner.fmfd.as_ref().unwrap().daemon.lock().await;
    x.refresh(inner.os_config.as_deref().unwrap()).await?;
    Ok(x.following.clone())
}

async fn do_login(conf_dir: &Path, username: &str, pet: &str, spd: &Dictionary, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, os_config: &dyn OSConfig) -> anyhow::Result<IDSUser> {
    let delegates = login_apple_delegates(username, pet, spd["adsid"].as_string().unwrap(), &mut *anisette.lock().await, os_config, &[LoginDelegate::IDS, LoginDelegate::MobileMe]).await.unwrap();

    let mobileme = delegates.mobileme.unwrap();
    let findmy = FindMyState::new(spd["DsPrsId"].as_unsigned_integer().unwrap().to_string(), spd["acname"].as_string().unwrap().to_string(), &mobileme);

    let id_path = conf_dir.join("findmy.plist");
    std::fs::write(id_path, plist_to_string(&findmy).unwrap()).unwrap();

    let user = authenticate_apple(delegates.ids.unwrap(), os_config).await.unwrap();
    Ok(user)
}

pub async fn try_auth(state: &Arc<PushState>, username: String, password: String) -> anyhow::Result<(LoginState, Option<IDSUser>)> {
    let mut inner = state.0.write().await;
    let mut apple_account = 
        AppleAccount::new_with_anisette(get_login_config(&*inner).await, inner.anisette.clone().unwrap())?;
    let mut login_state = apple_account.login_email_pass(&username, &password).await?;

    let mut user = None;
    if let Some(pet) = apple_account.get_pet() {
        let identity = do_login(&inner.conf_dir, username.trim(), &pet, apple_account.spd.as_ref().unwrap(), inner.anisette.as_ref().unwrap(), inner.os_config.as_deref().unwrap()).await?;
        user = Some(identity);
        
        // who needs extra steps when you have a PET, amirite?
        println!("confirmed login {:?}", login_state);
        if matches!(login_state, LoginState::NeedsExtraStep(_)) {
            login_state = LoginState::LoggedIn;
        }
    }

    inner.account = Some(apple_account);
    
    Ok((login_state, user))
}

pub async fn auth_phone(state: &Arc<PushState>, number: String, sig: Vec<u8>) -> anyhow::Result<IDSUser> {
    let inner = state.0.read().await;

    let identity = authenticate_phone(&number, AuthPhone {
        push_token: inner.conn.as_deref().unwrap().get_token().await.to_vec().into(),
        sigs: vec![sig.into()]
    }, inner.os_config.as_deref().unwrap()).await?;

    Ok(identity)
}

pub async fn send_2fa_to_devices(state: &Arc<PushState>) -> anyhow::Result<LoginState> {
    let inner = state.0.read().await;
    let account = inner.account.as_ref().unwrap();
    Ok(account.send_2fa_to_devices().await?)
    
}

pub async fn verify_2fa(state: &Arc<PushState>, code: String) -> anyhow::Result<(LoginState, Option<IDSUser>)> {
    let mut inner = state.0.write().await;
    let account = inner.account.as_mut().unwrap();
    let mut login_state = account.verify_2fa(code).await?;
    let account = inner.account.as_ref().unwrap();
    
    let mut user = None;
    if let Some(pet) = account.get_pet() {
        let identity = do_login(&inner.conf_dir, account.username.as_ref().unwrap().trim(), &pet, account.spd.as_ref().unwrap(), inner.anisette.as_ref().unwrap(), inner.os_config.as_deref().unwrap()).await?;
        user = Some(identity);
        
        // who needs extra steps when you have a PET, amirite?
        println!("confirmed login {:?}", login_state);
        if matches!(login_state, LoginState::NeedsExtraStep(_)) {
            login_state = LoginState::LoggedIn;
        }
    }

    Ok((login_state, user))
}



pub async fn get_2fa_sms_opts(state: &Arc<PushState>) -> anyhow::Result<(Vec<TrustedPhoneNumber>, Option<LoginState>)> {
    let inner = state.0.read().await;
    let account = inner.account.as_ref().unwrap();
    let extras = account.get_auth_extras().await?;
    Ok((
        extras.trusted_phone_numbers,
        extras.new_state
    ))
}

pub async fn send_2fa_sms(state: &Arc<PushState>, phone_id: u32) -> anyhow::Result<LoginState> {
    let inner = state.0.read().await;
    let account = inner.account.as_ref().unwrap();
    Ok(account.send_sms_2fa_to_devices(phone_id).await?)
}

pub async fn verify_2fa_sms(state: &Arc<PushState>, body: &VerifyBody, code: String) -> anyhow::Result<(LoginState, Option<IDSUser>)> {
    let mut inner = state.0.write().await;
    let account = inner.account.as_mut().unwrap();
    let mut login_state = account.verify_sms_2fa(code, body.clone()).await?;
    let account = inner.account.as_ref().unwrap();
    
    let mut user = None;
    if let Some(pet) = account.get_pet() {
        let identity = do_login(&inner.conf_dir, account.username.as_ref().unwrap().trim(), &pet, account.spd.as_ref().unwrap(), inner.anisette.as_ref().unwrap(), inner.os_config.as_deref().unwrap()).await?;
        user = Some(identity);
        
        // who needs extra steps when you have a PET, amirite?
        println!("confirmed login {:?}", login_state);
        if matches!(login_state, LoginState::NeedsExtraStep(_)) {
            login_state = LoginState::LoggedIn;
        }
    }

    Ok((login_state, user))
}

pub async fn validate_cert(state: &Arc<PushState>, user: &IDSUser) -> anyhow::Result<Vec<String>> {
    let inner = state.0.read().await;
    let x = Ok(user.get_possible_handles(&*inner.conn.as_ref().unwrap().state.read().await).await?);
    x
}

pub async fn reset_state(state: &Arc<PushState>, reset_hw: bool) -> anyhow::Result<()> {
    // tell any poll to stop
    let inner = state.0.read().await;
    if let Some(cancel) = inner.cancel_poll.lock().await.take() {
        cancel.send(()).unwrap();
    }
    drop(inner);
    let mut inner = state.0.write().await;
    info!("a");
    let conn_state = inner.conn.as_ref().unwrap().clone();
    info!("b {:?}", inner.os_config.is_some());
    inner.client = None;
    inner.fmfd = None;
    inner.reg_state = None;
    // try deregistering from iMessage, but if it fails we don't really care
    let _ = register(inner.os_config.as_deref().unwrap(), &*conn_state.state.read().await, &[], &mut [], inner.identity.as_ref().unwrap()).await;
    info!("c");
    inner.account = None;
    let _ = std::fs::remove_file(inner.conf_dir.join("id.plist"));
    let _ = std::fs::remove_file(inner.conf_dir.join("findmy.plist"));
    let _ = std::fs::remove_file(inner.conf_dir.join("id_cache.plist"));

    if reset_hw {
        inner.inq_queue = None;
        inner.conn = None;
        inner.os_config = None;
        let _ = std::fs::remove_file(inner.conf_dir.join("hw_info.plist"));
    }

    Ok(())
}

pub async fn invalidate_id_cache(state: &Arc<PushState>) -> anyhow::Result<()> {
    let inner = state.0.read().await;
    inner.client.as_ref().unwrap().identity.invalidate_id_cache().await;
    Ok(())
}

impl PushState {
    async fn get_phase(&self) -> RegistrationPhase {
        let inner = self.0.read().await;
        if inner.os_config.is_none() {
            return RegistrationPhase::WantsOSConfig
        }
        if inner.client.is_none() {
            return RegistrationPhase::WantsRegister
        }
        RegistrationPhase::Registered
    }
}

// NOTE, breaks linux registration for some god stupid awful reason
// only valid before registration
pub async fn get_user_name(state: &Arc<PushState>) -> anyhow::Result<String> {
    let inner = state.0.read().await;
    let (first, last) = inner.account.as_ref().unwrap().get_name();
    Ok(format!("{first} {last}"))
}


#[derive(Clone)]
#[frb(type_64bit_int)]
pub enum RegisterState {
    Registered {
        next_s: i64,
    },
    Registering,
    Failed {
        retry_wait: Option<u64>,
        error: String
    }
}

pub async fn get_regstate(state: &Arc<PushState>) -> anyhow::Result<RegisterState> {
    let inner = state.0.read().await;
    let mutex_ref = inner.client.as_ref().unwrap().identity.resource_state.borrow().clone();
    Ok(match &mutex_ref {
        ResourceState::Generating => RegisterState::Registering,
        ResourceState::Generated => RegisterState::Registered {
            next_s: inner.client.as_ref().unwrap().identity.calculate_rereg_time_s().await
        },
        ResourceState::Failed(failure) => 
            RegisterState::Failed { retry_wait: failure.retry_wait, error: format!("{}", failure.error) },
    })
}

pub async fn convert_token_to_uuid(state: &Arc<PushState>, handle: String, token: Vec<u8>) -> anyhow::Result<String> {
    let inner = state.0.read().await;
    let uuid = inner.client.as_ref().unwrap().identity.token_to_uuid(&handle, &token).await?;
    Ok(uuid)
}


pub async fn get_sms_targets(state: &Arc<PushState>, handle: String, refresh: bool) -> anyhow::Result<Vec<PrivateDeviceInfo>> {
    let inner = state.0.read().await;
    let targets = inner.client.as_ref().unwrap().identity.get_sms_targets(&handle, refresh).await?;
    Ok(targets)
}
