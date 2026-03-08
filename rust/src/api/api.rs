

use std::{borrow::{Borrow, BorrowMut}, collections::HashSet, fs::{self, File}, future::Future, io::{Cursor, Read, Write}, ops::Deref, panic, str::FromStr, sync::{Arc, OnceLock, Weak}, time::Duration, u64};
pub use std::time::SystemTime;
use anyhow::anyhow;
use flutter_rust_bridge::{DartFnFuture, IntoDart, JoinHandle, frb};
#[cfg(not(target_os = "android"))]
use keystore::software::{SoftwareEncryptor, SoftwareKeystore};
use keystore::{AesKeystoreKey, EcCurve, EcKeystoreKey, EncryptMode, KeystoreAccessRules, KeystoreDigest, KeystoreEncryptKey, KeystorePadding, RsaKey, init_keystore, keystore};
pub use rustpush::{default_provider, ArcAnisetteClient, LoginClientInfo, DefaultAnisetteProvider};
use log::{debug, error, info, warn};
use plist::{Data, Dictionary};
pub use plist::Value;
use sha2::Digest;

pub use tokio::sync::Mutex;
pub use std::path::PathBuf;
use prost::Message as prostMessage;
use serde::{Deserialize, Deserializer, Serialize, Serializer};
use tokio::{runtime::Runtime, select, sync::{broadcast, mpsc, watch, RwLock}};
pub use mpsc::Sender;
pub use rustpush::{APSMessage, CircleClientSession, CircleServerSession, EntitlementAuthState, IDSNGMIdentity, LoginDelegate, MADRID_SERVICE, TokenProvider, authenticate_apple, authenticate_phone, authenticate_smsless, cloud_messages::CloudMessagesClient, cloudkit::{CloudKitClient, CloudKitState}, facetime::{FACETIME_SERVICE, FTClient, FTState, VIDEO_SERVICE}, findmy::{FindMyClient, FindMyState, FindMyStateManager, MULTIPLEX_SERVICE}, keychain::{KeychainClient, KeychainClientState}, login_apple_delegates, name_photo_sharing::ProfilesClient, sharedstreams::{AssetMetadata, FFMpegFilePackager, FileMetadata, FilePackager, PreparedAsset, PreparedFile, SharedStreamClient, SharedStreamsState, SyncController, SyncManager, SyncState}, statuskit::{ChannelInterestToken, StatusKitClient, StatusKitState, StatusKitStatus}};
use rustpush::{AnisetteProvider, cloudkit_proto::{CuttlefishSerializedKey, base64_encode}, findmy::SharedBeaconClient, keychain::{CloudKey, CurrentBottle, SivKey}};
pub use rustpush::findmy::{FindMyFriendsClient, FindMyPhoneClient};
pub use rustpush::sharedstreams::{SharedAlbum, SyncStatus};
pub use rustpush::cloudkit_proto::EscrowData;
pub use rustpush::passwords::PasswordManager;
use uniffi::HandleAlloc;
use rand::Rng;
use uuid::Uuid;
use rustpush::KeyCache;
use std::io::Seek;
use async_recursion::async_recursion;
use base64::prelude::*;
pub use rustpush::IdmsAuthListener;
pub use broadcast::Receiver;

use crate::{RUNTIME, frb_generated::{SseEncode, StreamSink}, init_logger, native::{HANDLE_WIFI_NETWORKS, PACKAGER_LOCK, PackagedFile, QUEUED_MESSAGES}};

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

pub fn do_first_time_init(path: String) {
    let dir = PathBuf::from_str(&path).unwrap();

    init_logger(&dir);
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

pub trait SeekRead: Seek + Read {}
impl<T: Seek + Read> SeekRead for T {}

#[derive(Serialize, Deserialize, Clone)]
pub struct SavedHardwareState {
    pub push: APSState,
    #[serde(serialize_with = "bin_serialize", deserialize_with = "bin_deserialize")]
    pub identity: Vec<u8>,
    pub os_config: JoinedOSConfig,
}

#[frb(sync)]
pub fn decode_identity(identity: &[u8]) -> anyhow::Result<IDSNGMIdentity> {
    Ok(IDSNGMIdentity::restore(identity, "openbubbles")?)
}

pub fn bin_serialize<S>(x: &[u8], s: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    s.serialize_bytes(x)
}

fn bin_deserialize_16<'de, D>(d: D) -> Result<[u8; 16], D::Error>
where
    D: Deserializer<'de>,
{
    let s: Data = Deserialize::deserialize(d)?;
    let s: Vec<u8> = s.into();
    Ok(s.try_into().unwrap())
}

pub fn bin_deserialize<'de, D>(d: D) -> Result<Vec<u8>, D::Error>
where
    D: Deserializer<'de>,
{
    let s: Data = Deserialize::deserialize(d)?;
    Ok(s.into())
}

#[cfg(not(target_os = "android"))]
pub type MyFilePackager = FFMpegFilePackager;

#[cfg(target_os = "android")]
pub type MyFilePackager = FFIFilePackager;

#[derive(Default)]
pub struct FFIFilePackager {

}

#[frb(sync)]
pub fn decode_extension_app(bp: &[u8], bid: &str) -> anyhow::Result<ExtensionApp> {
    Ok(ExtensionApp::from_bp(bp, bid)?)
}

#[frb(sync)]
pub fn encode_extension_app(app: &ExtensionApp) -> anyhow::Result<(Vec<u8>, Option<Vec<u8>>)> {
    Ok(app.to_raw()?)
}

impl FilePackager for FFIFilePackager {
    type Reader = Box<dyn SeekRead + Send + Sync>;
    async fn get_files(&mut self, path: PathBuf) -> Result<PreparedAsset<Self::Reader>, PushError> {
        info!("Preparing to package {}", PACKAGER_LOCK.get().is_some());
        let processed = PACKAGER_LOCK.get().expect("No FFI packager!").get_file(path.to_str().unwrap().to_string());

        info!("Packaged");
        let inner = match processed {
            PackagedFile::Failure(failure) => {
                return Err(PushError::FilePackageError(failure))
            },
            PackagedFile::Info(info) => info
        };

        let is_video = inner.duration.is_some();
        let file = PreparedFile::<Box<dyn SeekRead + Send + Sync>>::new(Box::new(File::open(&path)?), FileMetadata {
            width: inner.width as usize,
            height: inner.height as usize,
            uti_type: if is_video { "public.mpeg-4".to_string() } else { "public.jpeg".to_string() },
            video_type: if is_video { Some("720p".to_string()) } else { None },
            asset_metadata: if !is_video { Some(AssetMetadata {
                asset_type: "derivative".to_string(),
                asset_type_flags: 2,
            }) } else { None },
        }).await?;

        let mut prepared_files = vec![file];

        if let Some(thumbnail) = inner.thumbnail {
            let thumbnail = PreparedFile::<Box<dyn SeekRead + Send + Sync>>::new(Box::new(Cursor::new(thumbnail)), FileMetadata {
                width: inner.width as usize,
                height: inner.height as usize,
                uti_type: "public.jpeg".to_string(),
                video_type: Some("PosterFrame".to_string()),
                asset_metadata: None,
            }).await?;
            prepared_files.push(thumbnail);
        }


        Ok(PreparedAsset {
            files: prepared_files,
            name: path.file_name().unwrap().to_str().unwrap().to_string(),
            date_created: fs::metadata(path)?.created().unwrap_or(SystemTime::now()),
            video_duration: inner.duration,
            guid: Uuid::new_v4().to_string().to_uppercase(),
        })
    }
}

pub struct ActiveCircleSession {
    session: CircleServerSession<DefaultAnisetteProvider>,
    atxnid: String,
    txnid: String,
    init_message: Option<IdmsCircleMessage>,
    otp: u32,
}

pub fn service_from_ptr(ptr: String) -> Option<SharedPushState> {
    let pointer: u64 = ptr.parse().unwrap();
    info!("using state {pointer}");
    let service = unsafe {
        Weak::from_raw(pointer as *const SharedPushState)
    };
    service.upgrade().map(|s| (*s).clone())
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

fn migrate(path: String) -> bool {
    let dir = PathBuf::from_str(&path).unwrap();
    let hw_config_path = dir.join("hw_info.plist");

    if let Ok(mut item) = plist::from_file::<_, Dictionary>(&hw_config_path) {
        if let Some(v) = item.get("os_config") {
            let config: JoinedOSConfig = plist::from_value(v).expect("got os ");
            if let Some(Value::Dictionary(dict)) = item.get_mut("push") {
                if let Some(Value::Dictionary(item)) = dict.get_mut("keypair") {
                    if let Some(private) = item.get_mut("private") {
                        if let Value::Data(cert) = private {
                            let handle = format!("activation:{}", config.get_serial_number());
                            RsaKey::import(&handle, 1024, cert, KeystoreAccessRules {
                                signature_padding: vec![KeystorePadding::PKCS1],
                                digests: vec![KeystoreDigest::Sha1],
                                can_sign: true,
                                ..Default::default()
                            }).expect("failed to import RSA");
                            *private = Value::String(handle);
                            plist::to_file_xml(&hw_config_path, &item).expect("failed to save!");
                        }
                    }
                }
            }
        }
        if let Some(value) = item.get_mut("identity") {
            if value.as_dictionary().is_some() {
                let identity: IDSNGMIdentity = plist::from_value(&value).expect("NGM Identity parse");
                *value = Value::Data(identity.save("openbubbles").expect("Failed to save"));
                plist::to_file_xml(&hw_config_path, &item).expect("failed to save!");
            }
        }
    }

    let id_path = dir.join("id.plist");
    if let Ok(mut users) = plist::from_file::<_, Vec<Dictionary>>(&id_path) {
        let mut modified = false;
        for user in &mut users {
            let user_id = user.get("user_id").unwrap().as_string().unwrap().to_string();
            if let Some(Value::Dictionary(item)) = user.get_mut("auth_keypair") {
                if let Some(private) = item.get_mut("private") {
                    if let Value::Data(cert) = private {
                        let handle = format!("ids:{user_id}");
                        RsaKey::import(&handle, 2048, cert, KeystoreAccessRules {
                            signature_padding: vec![KeystorePadding::PKCS1],
                            digests: vec![KeystoreDigest::Sha1],
                            can_sign: true,
                            ..Default::default()
                        }).expect("failed to import RSA");
                        *private = Value::String(handle);
                        modified = true;
                    }
                }
            }
            if let Some(Value::Dictionary(item)) = user.get_mut("registration") {
                for service in item.values_mut() {
                    if let Some(Value::Dictionary(item)) = service.as_dictionary_mut().unwrap().get_mut("id_keypair") {
                        if let Some(private) = item.get_mut("private") {
                            if let Value::Data(cert) = private {
                                let handle = format!("ids:{user_id}");
                                *private = Value::String(handle);
                            }
                        }
                    }
                }
            }
        }
        if modified {
            plist::to_file_xml(&id_path, &users).expect("failed to save!");
        }
    }

    let cloudkit_path = dir.join("keychain.plist");
    if let Ok(mut users) = plist::from_file::<_, Dictionary>(&cloudkit_path) {
        let anisette_path = dir.join("anisette_test/state.plist");
        if let Ok(AnisetteState { provisioned: Some(ProvisionedAnisette { mid, .. }), .. }) = plist::from_file::<_, AnisetteState>(&anisette_path) {
            let mid = base64_encode(mid.as_ref());
            let mut migrate = false;
            let dsid = users.get("dsid").unwrap().as_string().unwrap().to_string();
            if let Some(Value::Dictionary(item)) = users.get_mut("user_identity") {
                if let Some(private) = item.get_mut("signing_key") {
                    if let Value::Data(cert) = private {
                        let handle = format!("keychain:signing:{mid}");
                        EcKeystoreKey::import(&handle, EcCurve::P384, &cert, KeystoreAccessRules {
                            can_sign: true,
                            digests: vec![KeystoreDigest::Sha384, KeystoreDigest::Sha256],
                            ..Default::default()
                        }).expect("Failed to import EC");
                        *private = Value::String(handle);
                        migrate = true;
                    }
                }
                if let Some(private) = item.get_mut("encryption_key") {
                    if let Value::Data(cert) = private {
                        let handle = format!("keychain:encryption:{mid}");
                        EcKeystoreKey::import(&handle, EcCurve::P384, &cert, KeystoreAccessRules {
                            can_agree: true,
                            digests: vec![KeystoreDigest::Sha384, KeystoreDigest::Sha256],
                            ..Default::default()
                        }).expect("Failed to import EC");
                        *private = Value::String(handle);
                    }
                }
            }
            if migrate {
                if let Some(private) = users.get_mut("current_bottle") {
                    // convert escrowed_signing_key to data from vec u8
                    #[derive(Deserialize)]
                    struct BadBottle {
                        escrowed_signing_key: Vec<u8>,
                    }
                    let bad: BadBottle = plist::from_value(&private).expect("bottle Identity parse");
                    let dict = private.as_dictionary_mut().unwrap();
                    dict.insert("escrowed_signing_key".to_string(), Value::Data(bad.escrowed_signing_key));

                    let identity: CurrentBottle = plist::from_value(&private).expect("bottle Identity parse");
                    *private = Value::Data(identity.save(&dsid).expect("Failed to save"));
                }
                if let Some(Value::Array(items)) = users.get_mut("keystore") {
                    let keystore = SivKey(keystore().ensure_secret(&format!("keychain:cloudkey-access-key:{}", dsid), 64).expect("wha"));
                    for key in items {
                        let Value::Data(data) = key else { continue };
                        let serialized = CuttlefishSerializedKey::decode(&mut Cursor::new(data)).expect("failed to decode");
                        let cloud = CloudKey::from_serialized_key(serialized, &keystore);
                        *key = plist::to_value(&cloud).expect("Faield to serizsdf");
                    }
                }
                if let Some(Value::Dictionary(dict)) = users.get_mut("items") {
                    dict.clear();
                }
                plist::to_file_xml(&cloudkit_path, &users).expect("failed to save!");
            }
        }
    }

    let gsa_path = dir.join("gsa.plist");
    if let Ok(mut account) = plist::from_file::<_, Dictionary>(&gsa_path) {
        if let Some(Value::Data(password)) = account.remove("password") {
            account.insert("encrypted_password".to_string(), Value::Data(GSAConfig::encrypt(&password).expect("Undo").into()));
            plist::to_file_xml(&gsa_path, &account).expect("failed to save!");

            let findmy = dir.join("findmy.plist");
            if let Ok(users) = plist::from_file::<_, FindMyState>(&findmy) {
                std::fs::write(findmy, users.encode().expect("what")).unwrap();
            }
        }
    }

    false
}

#[frb(sync)]
pub fn new_ngm_identity() -> anyhow::Result<IDSNGMIdentity> {
    Ok(IDSNGMIdentity::new()?)
}

#[frb(sync)]
pub fn read_hardware(path: String) -> Option<SavedHardwareState> {
    let dir = PathBuf::from_str(&path).unwrap();
    let hw_config_path = dir.join("hw_info.plist");

    plist::from_file::<_, SavedHardwareState>(&hw_config_path).ok()
}

#[frb(sync)]
pub fn reset_anisette(path: String) {
    let dir = PathBuf::from_str(&path).unwrap();

    let anisette_dir = dir.join("anisette_test");
    if anisette_dir.exists() {
        fs::remove_dir_all(dir.join("anisette_test")).expect("failed to remvoe anisette");
    }
}

pub async fn make_anisette(path: String, config: &JoinedOSConfig, conn: &APSConnection) -> ArcAnisetteClient<DefaultAnisetteProvider> {
    let dir = PathBuf::from_str(&path).unwrap();

    default_provider(get_login_config(&dir, config, conn).await, dir.join("anisette_test"))
}

#[frb(sync)]
pub fn restore_users(path: String) -> Option<Vec<IDSUser>> {
    let dir = PathBuf::from_str(&path).unwrap();

    let id_path = dir.join("id.plist");
    plist::from_file::<_, Vec<IDSUser>>(&id_path).ok()
}

#[frb(sync)]
pub fn save_users(users: &Vec<IDSUser>, path: String) {
    let dir = PathBuf::from_str(&path).unwrap();
    let id_path = dir.join("id.plist");

    plist::to_file_xml(id_path, users).unwrap();
}

pub async fn make_imclient(path: String, conn: &APSConnection, users: &Vec<IDSUser>, identity: &IDSNGMIdentity) -> Arc<IMClient> {
    let dir = PathBuf::from_str(&path).unwrap();
    let id_path = dir.join("id.plist");

    let incident_path = dir.join("incident");
    if !incident_path.exists() {
        if plist::from_file::<_, KeyCache>(dir.join("id_cache.plist")).is_ok() {
            let _ = fs::File::create(dir.join("incident_affected"));
        }
        let _ = fs::File::create(incident_path);
    }

    Arc::new(IMClient::new(conn.clone(), users.clone(), identity.clone(),
    &[&MADRID_SERVICE, &MULTIPLEX_SERVICE, &FACETIME_SERVICE, &VIDEO_SERVICE], dir.join("id_cache.plist"), conn.os_config.clone(), Box::new(move |updated_keys| {
        println!("updated keys!!!");
        std::fs::write(&id_path, plist_to_string(&updated_keys).unwrap()).unwrap();
    })).await)
}

pub struct APSWatcher {
    reg_state: watch::Receiver<ResourceState>,
    cancel_poll_recv: mpsc::Receiver<()>,
    local_messages: mpsc::Receiver<PushMessage>,
    inq_queue: broadcast::Receiver<APSMessage>,
}


#[frb(sync)]
pub fn build_watcher(conn: &APSConnection, client: &Arc<IMClient>) -> (mpsc::Sender<()>, Arc<mpsc::Sender<PushMessage>>, APSWatcher) {
    import_watcher(conn.messages_cont.subscribe(), client)
}

#[frb(sync)]
pub fn import_watcher(queue: broadcast::Receiver<APSMessage>, client: &Arc<IMClient>) -> (mpsc::Sender<()>, Arc<mpsc::Sender<PushMessage>>, APSWatcher) {
    let (cancel_send, cancel_recv) = mpsc::channel::<()>(1);
    let (sender, recv) = mpsc::channel(999);

    (cancel_send, Arc::new(sender), APSWatcher {
        reg_state: client.identity.resource_state.subscribe(),
        cancel_poll_recv: cancel_recv,
        local_messages: recv,
        inq_queue: queue,
    })
}

#[frb(sync)]
pub fn subscribe_conn(conn: &APSConnection) -> broadcast::Receiver<APSMessage> {
    conn.messages_cont.subscribe()
}

#[frb(ignore)]
pub struct DaemonData {
    pub watcher: APSWatcher,
    pub state: SharedPushState,
}

#[frb(sync)]
pub fn send_daemon(state: SharedPushState, watcher: APSWatcher) -> (String, SharedPushState) {
    let data = DaemonData {
        watcher,
        state: state.clone()
    };

    let num = Box::into_raw(Box::new(data)) as u64;

    info!("emitting pointer {num}");

    (num.to_string(), state)
}

#[frb(sync)]
pub fn dup_daemon_desk(state: SharedPushState) -> (Arc<SharedPushState>, SharedPushState) {
    (Arc::new(state.clone()), state)
}

#[frb(non_opaque)]
#[derive(Clone)]
pub struct SharedPushState {
    // core config
    pub os_config: JoinedOSConfig,
    pub cancel_poll: mpsc::Sender<()>,
    pub conf_dir: String,
    pub local_broadcast: Arc<mpsc::Sender<PushMessage>>,

    // core services
    pub anisette: ArcAnisetteClient<DefaultAnisetteProvider>,
    pub conn: APSConnection,
    pub icloud_services: Option<SharedICloudServices>,
    
    // APN services
    pub client: Arc<IMClient>,
    pub ft_client: Arc<FTClient>,
    pub idms_client: Arc<IdmsAuthListener>,

    // state
    pub active_circle_sessions: Arc<Mutex<Vec<ActiveCircleSession>>>,
    pub client_session: Arc<Mutex<Option<CircleClientSession<DefaultAnisetteProvider>>>>,
}

pub async fn make_idms(conn: &APSConnection) -> Arc<IdmsAuthListener> {
    IdmsAuthListener::new(conn.clone()).await.into()
}

#[frb(non_opaque)]
#[derive(Clone)]
pub struct SharedICloudServices {
    pub account: Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>,
    pub token_provider: Arc<TokenProvider<DefaultAnisetteProvider>>,

    pub cloudkit_client: Option<Arc<CloudKitClient<DefaultAnisetteProvider>>>,
    pub keychain: Option<Arc<KeychainClient<DefaultAnisetteProvider>>>,
    pub profiles_client: Arc<ProfilesClient<DefaultAnisetteProvider>>,
    pub fmfd: Option<Arc<FindMyClient<DefaultAnisetteProvider>>>,
    pub sharedstreams: Option<SyncManager<DefaultAnisetteProvider, MyFilePackager>>,
    pub cloud_messages_client: Option<Arc<CloudMessagesClient<DefaultAnisetteProvider>>>,
    pub statuskit_client: Arc<StatusKitClient<DefaultAnisetteProvider>>,
}

impl SharedPushState {
    pub async fn restore(path: String) -> Option<(Self, APSWatcher)> {
        info!("restroing");
        let dir = PathBuf::from_str(&path).unwrap();
        let keystore = dir.join("keystore.plist");

        #[cfg(not(target_os = "android"))]
        init_keystore(SoftwareKeystore {
            state: plist::from_file(&keystore).unwrap_or_default(),
            update_state: Box::new(move |state| {
                plist::to_file_xml(&keystore, state).unwrap();
            }),
            encryptor: SoftwareEncryptor(*b"desktopisinsecureyoushouldn'tber"),
        });

        if let Err(err) = panic::catch_unwind(|| {
            migrate(path.clone());
        }) {

            if let Some(s) = err.downcast_ref::<&str>() {
                info!("Panic message: {}", s);
            } else if let Some(s) = err.downcast_ref::<String>() {
                info!("Panic message: {}", s);
            } else {
                info!("Panic occurred, but message has unknown type");
            }

            panic!("panicked")
        }

        let hardware = read_hardware(path.clone())?;
        let users = restore_users(path.clone())?;
        let config = &hardware.os_config;
        let identity = IDSNGMIdentity::restore(hardware.identity.as_ref(), "openbubbles").ok()?;
        let (conn, _) = setup_push(config, &identity, Some(hardware.push.clone()), path.clone()).await;
        let client = make_imclient(path.clone(), &conn, &users, &identity).await;
        let anisette = make_anisette(path.clone(), config, &conn).await;

        let account = restore_account(path.clone(), &anisette, config, &conn).await;

        info!("account {}", account.is_some());
        

        let (cancel_poll, local_broadcast, watcher) = build_watcher(&conn, &client);

        Some((Self {
            os_config: config.clone(),
            cancel_poll,
            conf_dir: path.clone(),
            local_broadcast,

            anisette: anisette.clone(),
            conn: conn.clone(),
            icloud_services: if let Some(account) = &account {
                let token_provider = make_token_provider(account, config);
                let cloudkit = make_cloudkit(path.clone(), &anisette, config, &token_provider).await.expect("todo remove");
                let keychain = make_keychain(path.clone(), &cloudkit, &anisette, config, &token_provider);

                Some(SharedICloudServices {
                    account: account.clone(),
                    token_provider: token_provider.clone(),

                    cloudkit_client: Some(cloudkit.clone()),
                    keychain: keychain.clone(),
                    profiles_client: make_profiles(&cloudkit).await,
                    fmfd: if let Some(keychain) = &keychain {
                        make_findmy(path.clone(), &token_provider, &conn, &cloudkit, &keychain, &anisette, config, &client).await
                    } else { None },
                    sharedstreams: make_shared_streams(path.clone(), &conn, &anisette, config, &token_provider).await,
                    cloud_messages_client: if let Some(keychain) = &keychain {
                        Some(make_cloud_messages_client(&cloudkit, &keychain))
                    } else { None },
                    statuskit_client: make_statuskit(path.clone(), &token_provider, &conn, config, &client).await,
                })
            } else { None },

            ft_client: make_facetime(path.clone(), &conn, &client).await,
            client,
            idms_client: make_idms(&conn).await,
            
            active_circle_sessions: make_circle_sessions(),
            client_session: make_client_session(None),
        }, watcher))
    }
}

#[frb(sync)]
pub fn make_client_session(circle: Option<CircleClientSession<DefaultAnisetteProvider>>) -> Arc<Mutex<Option<CircleClientSession<DefaultAnisetteProvider>>>> {
    Arc::new(Mutex::new(circle))
}

#[frb(sync)]
pub fn make_circle_sessions() -> Arc<Mutex<Vec<ActiveCircleSession>>> {
    Arc::new(Mutex::new(vec![]))
}


pub async fn restore_account(path: String, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, config: &JoinedOSConfig, conn: &APSConnection) -> Option<Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>> {
    let dir = PathBuf::from_str(&path).unwrap();
    

    let mut state = plist::from_file::<_, GSAConfig>(&dir.join("gsa.plist")).ok()?;

    let mut apple_account =
            AppleAccount::new_with_anisette(get_login_config(&dir, config, conn).await, anisette.clone()).expect("aacbf?");
        
    apple_account.username = Some(state.username.clone());
    apple_account.hashed_password = state.get_password().ok();

    if state.postdata_done.is_none() {
        info!("Updating postdata");
        let _ = apple_account.update_postdata("Apple Device", None, &["icloud", "imessage", "facetime"]).await;
        state.postdata_done = Some(true);
        plist::to_file_xml(dir.join("gsa.plist"), &state).unwrap();
    }

    Some(Arc::new(Mutex::new(apple_account)))
}

#[frb(sync)]
pub fn make_token_provider(account: &Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>, config: &JoinedOSConfig) -> Arc<TokenProvider<DefaultAnisetteProvider>> {
    TokenProvider::new(account.clone(), config.config())
}

pub async fn make_shared_streams(path: String, conn: &APSConnection, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, 
        config: &JoinedOSConfig, token: &Arc<TokenProvider<DefaultAnisetteProvider>>) -> Option<SyncManager<DefaultAnisetteProvider, MyFilePackager>> {
    let dir = PathBuf::from_str(&path).unwrap();

    let stream_path = dir.join("sharedstreams.plist");

    let state = plist::from_file(&stream_path).ok()?;

    let client = SharedStreamClient::new(state, Box::new(move |update| {
        plist::to_file_xml(&stream_path, update).unwrap();
    }), token.clone(), conn.clone(), anisette.clone(), config.config()).await;


    let sync = SyncController::new(client, dir.join("sync.plist"), MyFilePackager::default(), Duration::from_secs(60 * 30)).await;
    subscribe_streams(sync.clone());

    Some(sync)
}

pub async fn make_cloudkit(path: String, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, config: &JoinedOSConfig, token_provider: &Arc<TokenProvider<DefaultAnisetteProvider>>) -> Option<Arc<CloudKitClient<DefaultAnisetteProvider>>> {
    let dir = PathBuf::from_str(&path).unwrap();

    let cloudkit_path = dir.join("cloudkit.plist");

    let state = plist::from_file(&cloudkit_path).ok()?;
    let cloudkit = Arc::new(CloudKitClient {
        state: RwLock::new(state),
        anisette: anisette.clone(),
        config: config.config(),
        token_provider: token_provider.clone()
    });

    Some(cloudkit)
}

pub async fn make_profiles(cloudkit: &Arc<CloudKitClient<DefaultAnisetteProvider>>) -> Arc<ProfilesClient<DefaultAnisetteProvider>> {
    Arc::new(ProfilesClient::new(cloudkit.clone()))
}

pub async fn make_facetime(path: String, conn: &APSConnection, client: &Arc<IMClient>) -> Arc<FTClient> {
    let dir = PathBuf::from_str(&path).unwrap();
    let facetime_path = dir.join("facetime.plist");
    let state: FTState = plist::from_file(&facetime_path).unwrap_or_default();
    Arc::new(FTClient::new(state, Box::new(move |state| {
        plist::to_file_xml(&facetime_path, state).expect("Failed to serialize plist!");
    }), conn.clone(), client.identity.clone(), conn.os_config.clone()).await)
}

pub async fn make_statuskit(path: String, provider: &Arc<TokenProvider<DefaultAnisetteProvider>>, conn: &APSConnection, config: &JoinedOSConfig, client: &Arc<IMClient>) -> Arc<StatusKitClient<DefaultAnisetteProvider>> {
    let dir = PathBuf::from_str(&path).unwrap();

    let path = dir.join("statuskit.plist");
    let state: StatusKitState = plist::from_file(&path).unwrap_or_default();
    StatusKitClient::new(state, Box::new(move |state| {
        plist::to_file_xml(&path, state).unwrap();
    }), provider.clone(), conn.clone(), config.config(), client.identity.clone()).await
}

#[frb(sync)]
pub fn make_keychain(path: String, cloudkit: &Arc<CloudKitClient<DefaultAnisetteProvider>>, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, config: &JoinedOSConfig, token_provider: &Arc<TokenProvider<DefaultAnisetteProvider>>) -> Option<Arc<KeychainClient<DefaultAnisetteProvider>>> {
    let dir = PathBuf::from_str(&path).unwrap();
    let cloudkit_path = dir.join("keychain.plist");

    if let Err(e) = plist::from_file::<_, KeychainClientState>(&cloudkit_path) {
        info!("Failed to desrialized {e}");
    }

    let state: KeychainClientState = plist::from_file(&cloudkit_path).ok()?;

    Some(Arc::new(KeychainClient {
        anisette: anisette.clone(),
        token_provider: token_provider.clone(),
        state: RwLock::new(state),
        config: config.config(),
        update_state: Box::new(move |update| {
            plist::to_file_xml(&cloudkit_path, update).unwrap();
        }),
        container: tokio::sync::Mutex::new(None),
        security_container: tokio::sync::Mutex::new(None),
        client: cloudkit.clone(),
    }))
}

#[frb(sync)]
pub fn make_cloud_messages_client(cloudkit: &Arc<CloudKitClient<DefaultAnisetteProvider>>, keychain: &Arc<KeychainClient<DefaultAnisetteProvider>>) -> Arc<CloudMessagesClient<DefaultAnisetteProvider>> {
    Arc::new(CloudMessagesClient::new(cloudkit.clone(), keychain.clone()))
}

pub async fn make_findmy(path: String, token_provider: &Arc<TokenProvider<DefaultAnisetteProvider>>, conn: &APSConnection, cloudkit: &Arc<CloudKitClient<DefaultAnisetteProvider>>, keychain: &Arc<KeychainClient<DefaultAnisetteProvider>>, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, config: &JoinedOSConfig, client: &Arc<IMClient>) -> Option<Arc<FindMyClient<DefaultAnisetteProvider>>> {
    let dir = PathBuf::from_str(&path).unwrap();
    let id_path = dir.join("findmy.plist");
    let state = FindMyState::restore(&fs::read(&id_path).ok()?).ok()?;

    Some(Arc::new(FindMyClient::new(conn.clone(), cloudkit.clone(), keychain.clone(), config.config(), Arc::new(FindMyStateManager {
        state: Mutex::new(state),
        update: Box::new(move |state| {
            fs::write(&id_path, state).expect("Failed to serialize plist!");
        }),
    }), token_provider.clone(), anisette.clone(), client.identity.clone()).await.unwrap()))
}

async fn shared_items<P: AnisetteProvider + Send + Sync + 'static, F: FilePackager + Send + Sync + 'static>(manager: &SyncManager<P, F>, seen_paths: &mut HashSet<PathBuf>) -> HashSet<PathBuf> {
    let paths = manager.sync_states.lock().await.values().map(|v| v.folder.clone()).collect::<Vec<_>>();
    let mut new = HashSet::new();
    seen_paths.retain(|a| fs::exists(a).is_ok_and(|a| a));
    for path in paths {
        let Ok(read) = fs::read_dir(path) else { continue };
        for file in read {
            let Ok(result) = file else { continue };
            if seen_paths.contains(&result.path()) { continue }
            seen_paths.insert(result.path());
            new.insert(result.path());
        }
    }
    new
}

fn subscribe_streams<P: AnisetteProvider + Send + Sync + 'static, F: FilePackager + Send + Sync + 'static>(manager: SyncManager<P, F>) {
    tokio::spawn(async move {
        let mut seen_paths = HashSet::new();
        shared_items(&manager, &mut seen_paths).await;
        let mut generated_sub = manager.generated_signal.subscribe();
        let manager_ref = Arc::downgrade(&manager);
        drop(manager);
        while let Ok(_) = generated_sub.recv().await {
            // drain any accumulations
            while let Ok(_) = generated_sub.try_recv() { }

            info!("Starting diff");
            let Some(manager) = manager_ref.upgrade() else { break };
            let new = shared_items(&manager, &mut seen_paths).await;
            info!("New files {:?}", new);
            if let Some(packager) = PACKAGER_LOCK.get() {
                packager.scan_files(new.into_iter().map(|a| a.to_str().expect("Path not str??").to_string()).collect());
            }
            info!("Diffed");
        }
    });
}

#[frb(sync)]
pub fn duplicate_user(user: &IDSUser) -> IDSUser {
    user.clone()
}

pub async fn register_ids(path: String, config: &JoinedOSConfig, aps: &APSConnection, identity: &IDSNGMIdentity, mut users: Vec<IDSUser>) -> anyhow::Result<(Option<Vec<IDSUser>>, Option<SupportAlert>)> {
    let dir = PathBuf::from_str(&path).unwrap();

    if let Err(err) = register(&*config.config(), &*aps.state.read().await, &[&MADRID_SERVICE, &MULTIPLEX_SERVICE, &FACETIME_SERVICE, &VIDEO_SERVICE], &mut users, identity).await {
        return if let PushError::CustomerMessage(support) = err {
            Ok((None, Some(support)))
        } else {
            Err(anyhow!(err))
        }
    }
    let id_path = dir.join("id.plist");
    std::fs::write(&id_path, plist_to_string(&users).unwrap()).unwrap();

    Ok((Some(users), None))
}

pub async fn set_identity(state_path: String, config: &JoinedOSConfig, identity: &IDSNGMIdentity) {
    let state_path = PathBuf::from_str(&state_path).unwrap().join("hw_info.plist");
    let state = SavedHardwareState {
        push: Default::default(),
        os_config: config.clone(),
        identity: identity.save("openbubbles").expect("failed to save").into(),
    };
    std::fs::write(&state_path, plist_to_string(&state).unwrap()).unwrap();
}

pub async fn setup_push(config: &JoinedOSConfig, identity: &IDSNGMIdentity, state: Option<APSState>, state_path: String) -> (APSConnection, Option<PushError>) {
    let state_path = PathBuf::from_str(&state_path).unwrap().join("hw_info.plist");
    let (conn, error) = APSConnectionResource::new(config.config(), state).await;

    let saved_identity = identity.save("openbubbles").expect("failed to save");
    if error.is_none() {
        let state = SavedHardwareState {
            push: conn.state.read().await.clone(),
            os_config: config.clone(),
            identity: saved_identity.clone().into(),
        };
        std::fs::write(&state_path, plist_to_string(&state).unwrap()).unwrap();
    }

    let mut to_refresh = conn.generated_signal.subscribe();
    let reconn_conn = Arc::downgrade(&conn);
    let config_ref = config.clone();
    tokio::spawn(async move {
        loop {
            match to_refresh.recv().await {
                Ok(()) => {
                    let Some(conn) = reconn_conn.upgrade() else { break };
                    // update keys
                    let state = SavedHardwareState {
                        push: conn.state.read().await.clone(),
                        os_config: config_ref.clone(),
                        identity: saved_identity.clone().into(),
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

#[derive(Serialize, Deserialize)]
pub struct AnisetteState {
    #[serde(serialize_with = "bin_serialize", deserialize_with = "bin_deserialize_16")]
    keychain_identifier: [u8; 16],
    provisioned: Option<ProvisionedAnisette>,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct ProvisionedAnisette {
    client_secret: Data,
    mid: Data,
    metadata: Data,
    rinfo: String,
    #[serde(default)]
    flavor: ProvisionedFlavor,
}

#[derive(Serialize, Deserialize, Clone, Default)]
pub enum ProvisionedFlavor {
    #[default]
    Mac,
    IOS,
}

async fn get_login_config(conf_dir: &PathBuf, conf: &JoinedOSConfig, conn: &APSConnection) -> LoginClientInfo {
    let anisette_dir = conf_dir.join("anisette_test");
    let config_path = anisette_dir.join("state.plist");

    let require_mac = if let Ok(decoded) = plist::from_file::<_, AnisetteState>(config_path) {
        matches!(decoded.provisioned, Some(ProvisionedAnisette { flavor: ProvisionedFlavor::Mac, .. }))
    } else {
        false
    };

    conf.get_gsa_config(&*conn.state.read().await, require_mac)
}

pub async fn configure_app_review(path: String) -> anyhow::Result<()> {
    let path = PathBuf::from_str(&path).unwrap();

    std::fs::write(path.join("id.plist"), include_str!("id_testing.plist"))?;
    std::fs::write(path.join("hw_info.plist"), include_str!("hw_testing.plist"))?;


    // let state = SharedPushState::restore(path)
    Ok(())
}

pub fn encode_hex(bytes: &[u8]) -> String {
    use std::fmt::Write;
    let mut s = String::with_capacity(bytes.len() * 2);
    for &b in bytes {
        write!(&mut s, "{:02x}", b).unwrap();
    }
    s
}

pub struct HwExtra {
    pub version: String,
    pub protocol_version: u32,
    pub device_id: String,
    pub icloud_ua: String,
    pub aoskit_version: String,
}

pub fn generate_udid() -> String {
    let udid: [u8; 32] = rand::thread_rng().gen();
    encode_hex(&udid).to_uppercase()
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
        udid: Some(generate_udid()),
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
        udid: Some(generate_udid()),
    })))
}

pub async fn validate_relay(config_ref: &JoinedOSConfig) -> anyhow::Result<Option<String>> {
    let Err(PushError::RelayError(_, message)) = config_ref.generate_validation_data().await else { return Ok(match config_ref {
        JoinedOSConfig::MacOS(macos) => None,
        JoinedOSConfig::Relay(relay) => Some(relay.code.clone())
    }) };
    if !message.contains("Subscription not active!") && !message.contains("Ticket not activated!") && !message.contains("Sorry, your hosted device is currently offline!") {
        info!("Validation failed {message}");
        return Ok(None);
    }
    Ok(match config_ref {
        JoinedOSConfig::MacOS(macos) => None,
        JoinedOSConfig::Relay(relay) => Some(relay.code.clone())
    })
}

pub fn parse_transcript_poster(payload: Vec<u8>) -> anyhow::Result<SimplifiedTranscriptPoster> {
    Ok(SimplifiedTranscriptPoster::parse_payload(&payload)?)
}

pub fn pack_transcript_poster(mut payload: SimplifiedTranscriptPoster) -> anyhow::Result<Vec<u8>> {
    Ok(payload.to_payload()?)
}

pub fn parse_poster(poster: IMessagePosterRecord) -> anyhow::Result<SimplifiedIncomingCallPoster> {
    Ok(SimplifiedIncomingCallPoster::from_poster(&poster)?)
}

pub fn from_poster(mut poster: SimplifiedIncomingCallPoster) -> anyhow::Result<IMessagePosterRecord> {
    Ok(poster.to_poster()?)
}

// simple round trip to rust clones object
#[frb(sync)]
pub fn clone_poster(poster: SimplifiedIncomingCallPoster) -> anyhow::Result<SimplifiedIncomingCallPoster> {
    Ok(poster)
}

#[frb(sync)]
pub fn clone_transcript_poster(poster: SimplifiedTranscriptPoster) -> anyhow::Result<SimplifiedTranscriptPoster> {
    Ok(poster)
}

pub fn transcript_poster_save(poster: SimplifiedTranscriptPoster) -> anyhow::Result<Vec<u8>> {
    Ok(plist_to_bin(&poster)?)
}

pub fn from_transcript_poster_save(poster: Vec<u8>) -> anyhow::Result<SimplifiedTranscriptPoster> {
    debug!("Before");
    let got = plist::from_bytes(&poster)?;
    debug!("After");
    Ok(got)
}

pub fn parse_poster_save(poster: SimplifiedIncomingCallPoster) -> anyhow::Result<Vec<u8>> {
    Ok(plist_to_bin(&poster)?)
}

pub fn from_poster_save(poster: Vec<u8>) -> anyhow::Result<SimplifiedIncomingCallPoster> {
    debug!("Before");
    let got = match plist::from_bytes(&poster) {
        Ok(poster) => poster,
        Err(_) => {
            let result: SimplifiedPoster = plist::from_bytes(&poster)?;

            #[derive(Deserialize)]
            struct Extras {
                text_metadata: WallpaperMetadata,
                low_res: Data,
            }
            let extras: Extras = plist::from_bytes(&poster)?;
            SimplifiedIncomingCallPoster {
                poster: result,
                text_metadata: extras.text_metadata,
                low_res: extras.low_res.into(),
            }
        }
    };
    debug!("After");
    Ok(got)
}

pub struct DeviceInfo {
    pub name: String,
    pub serial: String,
    pub os_version: String,
    pub encoded_data: Option<Vec<u8>>,
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
        udid: Some(generate_udid()),
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



#[frb(sync)]
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

#[frb(sync)]
pub fn ns_null() -> Vec<u8> {
    plist_to_bin(&Value::String("$null".to_string())).unwrap()
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
    NewPhotostream(SharedAlbum),
    FaceTime(FTMessage),
    StatusUpdate(StatusKitMessage),
    Idms(IdmsMessage),
    TwoFaAuthEvent(bool),
    CircleFinishEvent,
    BeaconShared {
        sender: String,
        beacon: String,
        attributes: BeaconAttributes,
    }
}

#[frb(sync)]
pub fn get_password_manager(keychain: &Arc<KeychainClient<DefaultAnisetteProvider>>) -> PasswordManager<DefaultAnisetteProvider> {
    PasswordManager::new(keychain.clone())
}

pub async fn sync_passwords(passwords: &PasswordManager<DefaultAnisetteProvider>) -> anyhow::Result<()> {
    passwords.sync_passwords().await?;

    let wifi_networks: HashMap<String, String> = get_wifi_passwords(passwords).await.into_values()
        .map(|p| (p.acct, String::from_utf8(p.data).expect("bad password!"))).collect();

    if let Some(handle) = HANDLE_WIFI_NETWORKS.get() {
        handle.handle_wifi_networks(wifi_networks);
    }

    Ok(())
}

pub async fn get_passwords(passwords: &PasswordManager<DefaultAnisetteProvider>) -> HashMap<String, PasswordManagerMeta> {
    passwords.get_password_entries().await
}

pub async fn get_passkeys(passwords: &PasswordManager<DefaultAnisetteProvider>) -> HashMap<String, Passkey> {
    passwords.get_password_entries().await
}

pub async fn get_wifi_passwords(passwords: &PasswordManager<DefaultAnisetteProvider>) -> HashMap<String, WifiPassword> {
    passwords.get_password_entries().await
}

pub async fn save_password(passwords: &PasswordManager<DefaultAnisetteProvider>, id: String, entry: &PasswordManagerMeta) -> anyhow::Result<()> {
    Ok(passwords.insert_password(&id, entry).await?)
}

pub async fn save_passkey(passwords: &PasswordManager<DefaultAnisetteProvider>, id: String, entry: &Passkey) -> anyhow::Result<()> {
    Ok(passwords.insert_password_entry(&id, entry).await?)
}

pub async fn save_wifi_password(passwords: &PasswordManager<DefaultAnisetteProvider>, id: String, entry: &WifiPassword) -> anyhow::Result<()> {
    Ok(passwords.insert_password_entry(&id, entry).await?)
}

pub async fn delete_password(passwords: &PasswordManager<DefaultAnisetteProvider>, id: String) -> anyhow::Result<()> {
    Ok(passwords.delete_password(&id).await?)
}

pub async fn delete_passkey(passwords: &PasswordManager<DefaultAnisetteProvider>, id: String) -> anyhow::Result<()> {
    Ok(passwords.delete_password_entry::<Passkey>(&id).await?)
}

pub async fn delete_wifi_password(passwords: &PasswordManager<DefaultAnisetteProvider>, id: String) -> anyhow::Result<()> {
    Ok(passwords.delete_password_entry::<WifiPassword>(&id).await?)
}

async fn handle_photostream(client: &SharedStreamClient<DefaultAnisetteProvider>, changes: Vec<String>, local: &Arc<mpsc::Sender<PushMessage>>) {
    let lock = &client.state.read().await.albums;
    for change in changes {
        let Some(item) = lock.iter().find(|a| &a.albumguid == &change) else { continue };
        if item.sharingtype == "pending" {
            local.send(PushMessage::NewPhotostream(item.clone())).await.expect("Dropped?");
        }
    }
}

pub async fn update_account_headers(account: &Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>) -> anyhow::Result<String> {
    let account = account.lock().await;

    Ok(account.request_update_account().await?)
}

pub async fn get_anisette_headers(state: &ArcAnisetteClient<DefaultAnisetteProvider>, config: &JoinedOSConfig) -> anyhow::Result<HashMap<String, String>> {
    let mut headers = state.lock().await.get_headers().await?.clone();
    headers.insert("X-Mme-Client-Info".to_string(), config.get_adi_mme_info("com.apple.AuthKit/1 (com.apple.findmy/375.20)", !headers["X-Mme-Client-Info"].contains("iPhone OS")));
    Ok(headers)
}

pub async fn get_contacts_headers(path: String, state: &ArcAnisetteClient<DefaultAnisetteProvider>, token_provider: &Arc<TokenProvider<DefaultAnisetteProvider>>, config: &JoinedOSConfig) -> anyhow::Result<HashMap<String, String>> {
    let dir = PathBuf::from_str(&path).unwrap();

    // I know it's the wrong answer. Stop looking at me!
    let id_path = dir.join("sharedstreams.plist");
    let findmy_state: SharedStreamsState = plist::from_file(id_path)?;
    
    let mut headers = state.lock().await.get_headers().await?.clone();
    headers.insert("X-Mme-Client-Info".to_string(), config.get_adi_mme_info("com.apple.AuthKit/1 (com.apple.AddressBookSourceSync/2695.500.71)", !headers["X-Mme-Client-Info"].contains("iPhone OS")));
    
    headers.insert("X-APPLE-FAMILY-AUTH-TOKEN".to_string(), token_provider.get_gsa_token("com.apple.gs.icloud.family.auth").await.expect("no Family auth token?"));
    let mme_token = token_provider.get_mme_token("mmeAuthToken").await?;
    headers.insert("Authorization".to_string(), format!("X-MobileMe-AuthToken {}", base64_encode(format!("{}:{}", &findmy_state.dsid, mme_token).as_bytes())));

    Ok(headers)
}

pub async fn get_entitlements(config: &JoinedOSConfig, conn: &APSConnection, mccmnc: String, subscriber: String, imei: String, process_challenge: impl Fn(String) -> DartFnFuture<String>) -> anyhow::Result<IDSUser> {
    let mut entitlementstate = EntitlementAuthState::new(subscriber, mccmnc, imei);

    let entitlements = entitlementstate.get_entitlements(&*config.config(), &conn, |challenge| async move {
        Ok(process_challenge(challenge).await)
    }).await?;

    let user = authenticate_smsless(&entitlements.phone, &entitlements.host, &*config.config(), &conn).await?;

    Ok(user)
}

pub async fn get_albums(lock: &SyncManager<DefaultAnisetteProvider, MyFilePackager>, refresh: bool) -> anyhow::Result<(Vec<SharedAlbum>, Vec<String>)> {
    if refresh {
        let _ = lock.client.get_changes().await?;

        let nameless_albums: Vec<_> = lock.client.state.read().await.albums.iter().filter(|album| album.name.is_none()).map(|album| album.albumguid.clone()).collect();
        for album in nameless_albums {
            lock.client.get_album_summary(&album).await?;
        }
    }

    let albums_ref = lock.client.state.read().await.albums.clone();
    let extras = lock.dirty_map.lock().await.iter().map(|a| a.0.clone()).collect();
    Ok((albums_ref, extras))
}

pub async fn subscribe(lock: &SyncManager<DefaultAnisetteProvider, MyFilePackager>, guid: String) -> anyhow::Result<Vec<SharedAlbum>> {
    let _ = lock.client.subscribe(&guid).await?;

    let albums_ref = lock.client.state.read().await.albums.clone();
    Ok(albums_ref)
}

pub async fn unsubscribe(lock: &SyncManager<DefaultAnisetteProvider, MyFilePackager>, guid: String) -> anyhow::Result<Vec<SharedAlbum>> {
    let _ = lock.unsubscribe(&guid).await?;

    let albums_ref = lock.client.state.read().await.albums.clone();
    Ok(albums_ref)
}

pub async fn subscribe_token(lock: &SyncManager<DefaultAnisetteProvider, MyFilePackager>, token: String) -> anyhow::Result<Vec<SharedAlbum>> {
    let _ = lock.client.subscribe_token(&token).await?;

    let albums_ref = lock.client.state.read().await.albums.clone();
    Ok(albums_ref)
}

pub async fn add_album(lock: &SyncManager<DefaultAnisetteProvider, MyFilePackager>, guid: String, folder: String) -> anyhow::Result<Vec<SharedAlbum>> {
    lock.add_album(guid, PathBuf::from_str(&folder).unwrap()).await;

    let albums_ref = lock.client.state.read().await.albums.clone();
    Ok(albums_ref)
}

pub async fn remove_album(lock: &SyncManager<DefaultAnisetteProvider, MyFilePackager>, guid: String) -> anyhow::Result<Vec<SharedAlbum>> {
    debug!("b");
    lock.remove_album(guid).await;
    debug!("c");
    let albums_ref = lock.client.state.read().await.albums.clone();
    debug!("d");
    Ok(albums_ref)
}

pub async fn get_syncstatus(lock: &SyncManager<DefaultAnisetteProvider, MyFilePackager>) -> anyhow::Result<(HashMap<String, SyncStatus>, Option<(String, u64)>)> {
    let statuses = lock.sync_statuses.borrow().clone();

    let mut f: Option<(String, u64)> = None;
    if let ResourceState::Failed(failure) = &*lock.resource_state.borrow() {
        f = Some((format!("{}", failure.error), failure.retry_wait.unwrap_or(u64::MAX)))
    }

    Ok((statuses, f))
}

pub async fn sync_now(lock: &SyncManager<DefaultAnisetteProvider, MyFilePackager>) -> anyhow::Result<()> {
    lock.refresh_now().await?;

    Ok(())
}


pub async fn ft_sessions(facetime: &Arc<FTClient>) -> anyhow::Result<Vec<FTSession>> {
    let sessions = facetime.state.read().await;
    Ok(sessions.sessions.values().cloned().collect())
}

pub async fn get_ft_link(facetime: &Arc<FTClient>, usage: String) -> anyhow::Result<String> {
    let handles = facetime.identity.get_handles().await.to_vec();
    
    let handle = handles[0].clone();
    Ok(facetime.get_link_for_usage(&handle, &usage).await?)
}

pub async fn use_link_for(facetime: &Arc<FTClient>, old_usage: String, usage: String) -> anyhow::Result<()> {
    Ok(facetime.use_link_for(&old_usage, &usage).await?)
}

pub async fn clear_links(facetime: &Arc<FTClient>) -> anyhow::Result<()> {
    Ok(facetime.clear_links().await?)
}

pub async fn get_2fa_code(anisette: &ArcAnisetteClient<DefaultAnisetteProvider>) -> anyhow::Result<u32> {
    info!("third lock");
    let code = anisette.lock().await.provider.get_2fa_code().await?;
    info!("fouth lock");
    Ok(code)
}

pub async fn teardown_2fa(account: &Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>, action: String, txnid: String) -> anyhow::Result<()> {
    let mut account = account.lock().await;
    account.teardown(&action, 100, &txnid).await?;
    Ok(())
}

pub async fn answer_ft_request(facetime: &Arc<FTClient>, request: LetMeInRequest, approved_group: Option<String>) -> anyhow::Result<()> {
    facetime.respond_letmein(request, approved_group.as_ref().map(|a| a.as_str())).await?;
    Ok(())
}

pub async fn decline_facetime(facetime: &Arc<FTClient>, guid: String) -> anyhow::Result<()> {
    let mut lock = facetime.state.write().await;
    let state = lock.sessions.get_mut(&guid).expect("state");
    facetime.ensure_allocations(state, &[]).await?;
    facetime.decline_invite(state).await?;
    Ok(())
}

pub async fn create_facetime(facetime: &Arc<FTClient>, uuid: String, handle: String, participants: Vec<String>) -> anyhow::Result<()> {
    facetime.create_session(uuid, handle, &participants).await?;
    Ok(())
}

pub async fn cancel_facetime(facetime: &Arc<FTClient>, guid: String) -> anyhow::Result<()> {
    let mut lock = facetime.state.write().await;
    let state = lock.sessions.get_mut(&guid).expect("state");
    facetime.unprop_conv(state).await?;
    Ok(())
}

pub async fn validate_targets_facetime(state: &Arc<IMClient>, targets: Vec<String>, sender: String) -> anyhow::Result<Vec<String>> {
    Ok(state.identity.validate_targets(&targets, "com.apple.private.alloy.facetime.multi", &sender).await?)
}

pub async fn certify_delivery(state: &Arc<IMClient>, context: CertifiedContext, notify: bool) -> anyhow::Result<()> {
    state.identity.certify_delivery("com.apple.madrid", &context, notify).await?;
    Ok(())
}

pub async fn report_messages(state: &Arc<IMClient>, handle: String, messages: Vec<ReportMessage>) -> anyhow::Result<()> {
    state.identity.report_spam(&handle, &messages).await?;
    Ok(())
}

pub fn encode_profile_message(p: &ShareProfileMessage) -> String {
    plist_to_string(&p).unwrap()
}

pub fn decode_profile_message(s: String) -> anyhow::Result<ShareProfileMessage> {
    Ok(plist::from_bytes(s.as_bytes())?)
}

pub async fn fetch_profile(profiles: &Arc<ProfilesClient<DefaultAnisetteProvider>>, message: &ShareProfileMessage) -> anyhow::Result<IMessageNicknameRecord> {
    Ok(profiles.get_record(message).await?)
}

pub async fn set_profile(profiles: &Arc<ProfilesClient<DefaultAnisetteProvider>>, record: IMessageNicknameRecord, mut existing: Option<ShareProfileMessage>) -> anyhow::Result<ShareProfileMessage> {
    profiles.set_record(record, &mut existing).await?;
    Ok(existing.expect("No profile set??"))
}

pub async fn invite_to_channel(status: &Arc<StatusKitClient<DefaultAnisetteProvider>>, handle: String, to: HashMap<String, StatusKitPersonalConfig>) -> anyhow::Result<()> {
    Ok(status.invite_to_channel(&handle, to).await?)
}

pub async fn reset_channel_keys(status: &Arc<StatusKitClient<DefaultAnisetteProvider>>) -> anyhow::Result<()> {
    Ok(status.reset_keys().await)
}

pub async fn request_handles(status: &Arc<StatusKitClient<DefaultAnisetteProvider>>, to: Vec<String>) -> anyhow::Result<Option<ChannelInterestToken>> {
    Ok(if to.is_empty() { None } else { Some(status.request_handles(&to).await) })
}

pub async fn set_status(status: &Arc<StatusKitClient<DefaultAnisetteProvider>>, new_status: Option<String>) -> anyhow::Result<()> {
    status.share_status(&StatusKitStatus {
        active: new_status.is_none(),
        id: new_status,
    }).await?;
    Ok(())
}

pub enum PollResult {
    Stop,
    Cont(Option<PushMessage>),
}

// returns false to skip the message because our adsid is wrong
async fn handle_2fa(state: &SharedPushState, signin: &IdmsRequestedSignIn) -> bool {
    let Some(services) = &state.icloud_services else {
        warn!("Ignoring circle message for no account!");
        return false;
    };

    let account = &services.account;

    let mut lock = account.lock().await;
    if lock.spd.is_none() {
        // trigger gsa flow
        lock.get_token("com.apple.gs.idms.pet").await;
        if lock.spd.is_none() {
            warn!("Dropping message because GSA flow failed!");
            return false;
        }
    }
    let adsid = lock.spd.as_ref().unwrap().get("adsid").expect("no adsid???s").as_string().unwrap();
    if adsid != &signin.adsid {
        warn!("Dropping 2fa code for account because adsid is wrong {adsid} {}", signin.adsid);
        return false;
    }
    drop(lock);
    true
}

async fn handle_circle(state: &SharedPushState, signin: &Option<IdmsRequestedSignIn>, msg: &IdmsCircleMessage) {
    if msg.step % 2 == 0 {
        // this is a client step (we are the client)
        let mut locked = state.client_session.lock().await;
        let Some(client) = &mut *locked else {
            warn!("Ignoring unknown circle client session");
            return
        };
        match client.handle_circle_request(msg).await {
            Err(e) => {
                warn!("error {e}");
            },
            Ok(Some(LoginState::LoggedIn)) => {
                // we are done
                *locked = None;
                let _ = state.local_broadcast.send(PushMessage::CircleFinishEvent).await;
                info!("Finished client circle!");
            },
            _ => info!("Did circle step {}", msg.step),
        }
        return
    }

    let mut circle_lock = state.active_circle_sessions.lock().await;
    if !circle_lock.iter().any(|a| a.atxnid == msg.atxnid) {
        if msg.step != 1 {
            warn!("Ignoring middle session!");
            return;
        }
        let Some(signin) = signin else { return };
        let push_token = state.conn.get_token().await;
        let Some(account) = &state.icloud_services else {
            warn!("Ignoring circle message for no account!");
            return;
        };

        let mut lock = account.account.lock().await;
        if lock.spd.is_none() {
            // trigger gsa flow
            lock.get_token("com.apple.gs.idms.pet").await;
            if lock.spd.is_none() {
                warn!("Dropping message because GSA flow failed!");
                return;
            }
        }
        let dsid = lock.spd.as_ref().unwrap().get("DsPrsId").expect("no dsid???s").as_unsigned_integer().unwrap();
        drop(lock);

        let mut rng = rand::thread_rng();
        let otp: u32 = rng.gen_range(0..1_000_000);
        let session = CircleServerSession::new(dsid, otp, account.account.clone(), push_token, account.keychain.clone());
        circle_lock.push(ActiveCircleSession {
            session,
            atxnid: msg.atxnid.clone(),
            txnid: signin.txnid.clone(),
            init_message: Some(msg.clone()),
            otp,
        });
        if circle_lock.len() > 5 {
            circle_lock.remove(0);
        }
        // wait for user to manually click approve to handle request
        return;
    }

    match circle_lock.iter_mut().find(|a| a.atxnid == msg.atxnid).unwrap().session.handle_circle_request(msg).await {
        Err(e) => {
            warn!("error {e}");
        },
        Ok(success) => {
            // login
            if msg.step == 3 {
                let _ = state.local_broadcast.send(PushMessage::TwoFaAuthEvent(success)).await;
            }
        }
    }

    if msg.step == 5 {
        // last step, delete entry after
        circle_lock.retain(|a| a.atxnid != msg.atxnid);
    }
}

pub async fn approve_circle(state: &Arc<Mutex<Vec<ActiveCircleSession>>>, account: &Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>, txnid: String) -> anyhow::Result<u32> {
    let mut circle_lock = state.lock().await;
    let Some(item) = circle_lock.iter_mut().find(|a| a.txnid == txnid) else {
        let account = account.lock().await;
        let code = account.anisette.lock().await.provider.get_2fa_code().await?;
        return Ok(code);
    };
    let Some(msg) = item.init_message.take() else {
        return Err(anyhow!("Idms init message missing for approve!"));
    };
    let otp = item.otp;
    drop(circle_lock);
    let state_ref = state.clone();
    RUNTIME.spawn(async move {
        let mut circle_lock = state_ref.lock().await;
        let Some(item) = circle_lock.iter_mut().find(|a| a.txnid == txnid) else {
            warn!("Session disappeared??");
            return
        };
        if let Err(e) = item.session.handle_circle_request(&msg).await {
            warn!("cirlce error {e}");
            return;
        }
    });
    Ok(otp)
}

pub async fn recv_wait(watcher: &mut APSWatcher, state: &Arc<SharedPushState>) -> PollResult {
    if watcher.cancel_poll_recv.try_recv().is_ok() {
        return PollResult::Stop;
    }
    select! {
        msg = watcher.inq_queue.recv() => {
            let msg = msg.unwrap();
            if let Some(icloud) = &state.icloud_services {
                if let Some(fmfd) = &icloud.fmfd {
                    match fmfd.handle(msg.clone()).await {
                        Ok(mut items) => {
                            if !items.is_empty() {
                                let item = items.remove(0);
                                return PollResult::Cont(Some(PushMessage::BeaconShared {
                                    sender: item.0,
                                    beacon: item.1,
                                    attributes: item.2,
                                }))
                            }
                        },
                        Err(e) => {
                            warn!("FMF import error {e}");
                        }
                    }
                }
                if let Some(photostream) = &icloud.sharedstreams {
                    if let Ok(Some(changes)) = photostream.handle(msg.clone()).await {
                        handle_photostream(&photostream.client, changes, &state.local_broadcast).await;
                    }
                }
                match icloud.statuskit_client.handle(msg.clone()).await {
                    Err(e) => {
                        error!("Statuskit handle error {e}");
                        return PollResult::Cont(None);
                    },
                    Ok(None) => {},
                    Ok(Some(msg)) => {
                        return PollResult::Cont(Some(PushMessage::StatusUpdate(msg)))
                    }
                }
            }
            match state.idms_client.handle(msg.clone()) {
                Err(e) => {
                    error!("IDMS handle error {e}");
                    return PollResult::Cont(None);
                },
                Ok(None) => {},
                Ok(Some(IdmsMessage::CircleRequest(circle, req))) => {
                    if let Some(req) = &req {
                        if !handle_2fa(&state, req).await { return PollResult::Cont(None) }
                    }
                    debug!("Circle here");
                    handle_circle(&state, &req, &circle).await;
                    if let Some(req) = req {
                        return PollResult::Cont(Some(PushMessage::Idms(IdmsMessage::RequestedSignIn(req))))
                    }
                },
                Ok(Some(IdmsMessage::RequestedSignIn(s))) => {
                    if !handle_2fa(&state, &s).await { return PollResult::Cont(None) }
                    return PollResult::Cont(Some(PushMessage::Idms(IdmsMessage::RequestedSignIn(s))))
                },
                Ok(Some(msg)) => {
                    return PollResult::Cont(Some(PushMessage::Idms(msg)))
                }
            }
            let ft_msg = state.ft_client.handle(msg.clone()).await;
            match ft_msg {
                Ok(Some(msg)) => return PollResult::Cont(Some(PushMessage::FaceTime(msg))),
                Ok(None) => {},
                Err(err) => {
                    // log and ignore for now
                    error!("ft err {}", err);
                    return PollResult::Cont(None);
                }
            }
            let msg = state.client.handle(msg).await;
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
        _reg_state = watcher.reg_state.changed() => {
            PollResult::Cont(Some(PushMessage::RegistrationState(get_regstate(&state.client).await.unwrap())))
        }
        reader = watcher.local_messages.recv() => {
            PollResult::Cont(Some(reader.unwrap()))
        },
        _cancel = watcher.cancel_poll_recv.recv() => {
            PollResult::Stop
        }
    }
}

pub async fn send(state: &Arc<IMClient>, local: &Arc<mpsc::Sender<PushMessage>>, mut msg: MessageInst) -> anyhow::Result<bool> {
    let result = state.send(&mut msg).await?;
    info!("send_finish");

    let local = local.clone();
    if let Some(handle) = result.handle {
        let uuid = msg.id.clone();
        tokio::spawn(async move {
            let result = handle.await.unwrap();
            info!("Finished handle {}", uuid);
            let maybeerr = result.err().map(|err| format!("{}", err));
            let _ = local.send(PushMessage::SendConfirm { uuid, error: maybeerr }).await;
        });
        Ok(true)
    } else {
        Ok(false)
    }
}

pub async fn get_handles(state: &Arc<IMClient>) -> anyhow::Result<Vec<String>> {
    Ok(state.identity.get_handles().await.to_vec())
}

pub async fn get_my_phone_handles(state: &Arc<IMClient>) -> anyhow::Result<Vec<String>> {
    Ok(state.identity.get_my_phone_handles().await.to_vec())
}

pub async fn do_reregister(state: &Arc<IMClient>) -> anyhow::Result<()> {
    state.identity.refresh_now().await?;
    Ok(())
}

pub async fn new_msg(conversation: ConversationData, sender: String, message: Message) -> MessageInst {
    MessageInst::new(conversation, &sender, message)
}

pub async fn validate_targets(state: &Arc<IMClient>, targets: Vec<String>, sender: String) -> anyhow::Result<Vec<String>> {
    Ok(state.identity.validate_targets(&targets, "com.apple.madrid", &sender).await?)
}

#[frb(type_64bit_int)]
pub struct TransferProgress {
    pub prog: usize,
    pub total: usize,
    pub attachment: Option<Attachment>
}

pub async fn download_attachment(sink: StreamSink<TransferProgress>, aps: &APSConnection, attachment: Attachment, path: String) {
    wrap_sink(&sink, || async {
        println!("donwloading file {}", path);
        let path = std::path::Path::new(&path);
        let prefix = path.parent().unwrap();
        std::fs::create_dir_all(prefix)?;
        let mut file = std::fs::File::create(path)?;
        attachment.get_attachment(aps, &mut file, |prog, total| {
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

pub async fn download_mmcs(sink: StreamSink<TransferProgress>, aps: &APSConnection, attachment: MMCSFile, path: String) {
    wrap_sink(&sink, || async {
        let path = std::path::Path::new(&path);
        let prefix = path.parent().unwrap();
        std::fs::create_dir_all(prefix)?;

        let mut file = std::fs::File::create(path)?;
        attachment.get_attachment(aps, &mut file, |prog, total| {
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

pub async fn upload_mmcs(sink: StreamSink<MMCSTransferProgress>, aps: &APSConnection, path: String) {
    wrap_sink(&sink, || async {
        let mut file = std::fs::File::open(path)?;
        let prepared = MMCSFile::prepare_put(&mut file).await?;
        file.rewind()?;
        let attachment = MMCSFile::new(aps, &prepared, file, |prog, total| {
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

pub async fn upload_attachment(sink: StreamSink<TransferProgress>, aps: &APSConnection, path: String, mime: String, uti: String, name: String) {
    wrap_sink(&sink, || async {

        let mut file = std::fs::File::open(path)?;
        let prepared = MMCSFile::prepare_put(&mut file).await?;
        file.rewind()?;
        let attachment = Attachment::new_mmcs(aps, &prepared, file, &mime, &uti, &name,|prog, total| {
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

pub async fn get_token(state: &APSConnection) -> Vec<u8> {
    state.get_token().await.to_vec()
}

pub fn save_user(user: &IDSUser) -> anyhow::Result<String> {
    Ok(plist_to_string(user)?)
}

pub fn restore_user(user: String) -> anyhow::Result<IDSUser> {
    info!("Got user {user}");
    Ok(plist::from_reader(Cursor::new(user))?)
}

pub async fn make_find_my_phone(path: String, config: &JoinedOSConfig, aps: &APSConnection, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, provider: &Arc<TokenProvider<DefaultAnisetteProvider>>) -> anyhow::Result<FindMyPhoneClient<DefaultAnisetteProvider>> {
    let dir = PathBuf::from_str(&path).unwrap();

    let id_path = dir.join("sharedstreams.plist");
    let state: SharedStreamsState = plist::from_file(id_path)?;

    Ok(FindMyPhoneClient::new(&*config.config(), state.dsid.clone(), aps.clone(), anisette.clone(), provider.clone()).await?)
}

pub async fn get_devices(client: &mut FindMyPhoneClient<DefaultAnisetteProvider>) -> Vec<FoundDevice> {
    client.devices.clone()
}

pub async fn refresh_devices(config: &JoinedOSConfig, client: &mut FindMyPhoneClient<DefaultAnisetteProvider>) -> anyhow::Result<Vec<FoundDevice>> {
    client.refresh(&*config.config()).await?;
    Ok(client.devices.clone())
}

pub async fn make_find_my_friends(path: String, config: &JoinedOSConfig, aps: &APSConnection, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, provider: &Arc<TokenProvider<DefaultAnisetteProvider>>) -> anyhow::Result<FindMyFriendsClient<DefaultAnisetteProvider>> {
    let dir = PathBuf::from_str(&path).unwrap();

    let id_path = dir.join("sharedstreams.plist");
    let state: SharedStreamsState = plist::from_file(id_path)?;

    let fmf_client = FindMyFriendsClient::new(&*config.config(), state.dsid.clone(), provider.clone(), aps.clone(), anisette.clone(), false).await?;
    Ok(fmf_client)
}

#[frb(type_64bit_int)]
pub struct DartBeaconShareInfo {
    pub share_id: String,
    pub acceptance_state: i64,
    pub owner_handle: String,
}

#[frb(type_64bit_int)]
pub struct DartBeacon {
    pub naming: BeaconNamingRecord,
    pub last_report: Option<LocationReport>,
    pub product_id: i64,
    pub battery_level: Option<i64>,
    pub vendor_id: i64,
    pub model: String,
    pub system_version: String,
    pub id: String,
    pub shared: Option<DartBeaconShareInfo>,
}

pub async fn accept_beacon_share(items: &Arc<FindMyClient<DefaultAnisetteProvider>>, share: String) -> anyhow::Result<()> {
    Ok(items.accept_item_share(&share).await?)
}

pub async fn delete_beacon_share(items: &Arc<FindMyClient<DefaultAnisetteProvider>>, share: String) -> anyhow::Result<()> {
    Ok(items.delete_shared_item(&share, true).await?)
}

pub async fn get_beacon_items(items: &Arc<FindMyClient<DefaultAnisetteProvider>>) -> anyhow::Result<Vec<DartBeacon>> {
    items.sync_item_positions().await?;

    let records = items.state.state.lock().await;

    Ok(records.accessories.iter().map(|(id, a)| DartBeacon {
        naming: a.naming.clone(),
        last_report: a.last_report.clone(),
        product_id: a.master_record.product_id,
        battery_level: Some(a.master_record.battery_level),
        vendor_id: a.master_record.vendor_id,
        model: a.master_record.model.clone(),
        system_version: a.master_record.system_version.clone(),
        id: id.clone(),
        shared: None,
    }).chain(records.share_state.circles_member.iter().filter_map(|(id, circle)| {
        let a = records.share_state.shared_beacons.get(&circle.beacon_identifier)?;
        let def_state = SharedBeaconClient::default();
        let client_state = records.share_state.shared_beacons_client.get(&circle.beacon_identifier).unwrap_or(&def_state);
        Some(DartBeacon {
            naming: BeaconNamingRecord {
                emoji: client_state.attributes.emoji.clone(),
                name: client_state.attributes.name.clone(),
                role_id: client_state.attributes.role_id,
                associated_beacon: id.clone(),
            },
            last_report: client_state.last_report.clone(),
            product_id: a.product_id,
            battery_level: None,
            vendor_id: a.vendor_id,
            model: a.model.clone(),
            system_version: a.system_version.clone(),
            id: circle.beacon_identifier.clone(),
            shared: Some(DartBeaconShareInfo {
                share_id: id.clone(),
                acceptance_state: circle.acceptance_state,
                owner_handle: a.owner_handle.clone(),
            }),
        })
    })).collect())
}

pub async fn update_beacon_name(items: &Arc<FindMyClient<DefaultAnisetteProvider>>, naming_record: &BeaconNamingRecord) -> anyhow::Result<()> {
    items.update_beacon_name(naming_record).await?;

    Ok(())
}

pub async fn get_following(client: &mut FindMyFriendsClient<DefaultAnisetteProvider>) -> Vec<Follow> {
    client.following.clone()
}

pub async fn refresh_following(config: &JoinedOSConfig, client: &mut FindMyFriendsClient<DefaultAnisetteProvider>) -> anyhow::Result<Vec<Follow>> {
    client.refresh(&*config.config()).await?;
    Ok(client.following.clone())
}

pub async fn select_friend(config: &JoinedOSConfig, client: &mut FindMyFriendsClient<DefaultAnisetteProvider>, friend: Option<String>) -> anyhow::Result<Vec<Follow>> {
    client.selected_friend = friend;
    client.refresh(&*config.config()).await?;
    Ok(client.following.clone())
}

pub async fn select_background_friend(fmfd: &Arc<FindMyClient<DefaultAnisetteProvider>>, friend: Option<String>) -> anyhow::Result<Vec<Follow>> {
    let mut x = fmfd.daemon.lock().await;
    x.selected_friend = friend;
    Ok(x.following.clone())
}

pub async fn get_background_following(fmfd: &Arc<FindMyClient<DefaultAnisetteProvider>>) -> Vec<Follow> {
    let x = fmfd.daemon.lock().await.following.clone();
    x
}

pub async fn refresh_background_following(state: &Arc<FindMyClient<DefaultAnisetteProvider>>, config: &JoinedOSConfig) -> anyhow::Result<Vec<Follow>> {
    let mut x = state.daemon.lock().await;
    x.refresh(&*config.config()).await?;
    Ok(x.following.clone())
}

#[frb(type_64bit_int)]
pub struct QuotaInfo {
    pub total_bytes: u64,
    pub available_bytes: u64,
    pub messages_bytes: u64,
}

pub async fn get_quota_info(info: &Arc<TokenProvider<DefaultAnisetteProvider>>) -> anyhow::Result<QuotaInfo> {
    let storage_info = info.get_storage_info().await?;
    Ok(QuotaInfo {
        total_bytes: storage_info.storage_data.quota_info_in_bytes.total_quota, 
        available_bytes: storage_info.storage_data.quota_info_in_bytes.total_available, 
        messages_bytes: storage_info.storage_usage_by_media.iter().find(|m| &m.media_key == "messages").map(|m| m.usage_in_bytes).unwrap_or(0),
    })
}

#[derive(Serialize, Deserialize)]
struct GSAConfig {
    username: String,
    encrypted_password: Data,
    postdata_done: Option<bool>,
}

impl GSAConfig {
    fn get_password(&self) -> Result<Vec<u8>, PushError> {
        let key = AesKeystoreKey::ensure(&format!("gsa:password"), 256, KeystoreAccessRules {
            block_modes: vec![EncryptMode::Gcm],
            can_encrypt: true,
            can_decrypt: true,
            ..Default::default()
        })?;
        let encoded = key.decrypt(self.encrypted_password.as_ref(), &mut EncryptMode::Gcm)?;
        Ok(encoded)
    }

    fn encrypt(password: &[u8]) -> Result<Data, PushError> {
        let key = AesKeystoreKey::ensure(&format!("gsa:password"), 256, KeystoreAccessRules {
            block_modes: vec![EncryptMode::Gcm],
            can_encrypt: true,
            can_decrypt: true,
            ..Default::default()
        })?;
        let encoded = key.encrypt(password, &mut EncryptMode::Gcm)?;
        Ok(encoded.into())
    }
}

pub async fn do_login(path: String, account: &Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>, cookie: Option<String>, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, os_config: &JoinedOSConfig) -> anyhow::Result<IDSUser> {
    let mut account = account.lock().await;
    
    let conf_dir = PathBuf::from_str(&path).unwrap();

    account.update_postdata("Apple Device", None, &["icloud", "imessage", "facetime"]).await?;
    
    let Some(pet) = account.get_pet() else { return Err(anyhow!("No pet!")) };
    let Some(spd) = &account.spd else { return Err(anyhow!("No spd!")) };

    debug!("Got spd {:?}", spd);
    let adsid = spd.get("adsid").ok_or(anyhow!("No adsid!"))?.as_string().unwrap();
    let acname = spd.get("acname").ok_or(anyhow!("No acname!"))?.as_string().unwrap().to_string();
    let dsid = spd.get("DsPrsId").ok_or(anyhow!("No dsid!"))?.as_unsigned_integer().unwrap().to_string();
    
    let delegates = login_apple_delegates(account.username.as_ref().unwrap(), &pet, adsid, cookie.as_ref().map(|i| i.as_str()), &mut *anisette.lock().await, &*os_config.config(), &[LoginDelegate::IDS, LoginDelegate::MobileMe]).await?;

    plist::to_file_xml(conf_dir.join("gsa.plist"), &GSAConfig {
        username: account.username.clone().unwrap(),
        encrypted_password: GSAConfig::encrypt(&account.hashed_password.clone().unwrap())?,
        postdata_done: Some(true),
    }).unwrap();

    let path = conf_dir.join("statuskit.plist");
    std::fs::write(&path, plist_to_string(&StatusKitState {
        my_key: None,
        ..plist::from_file(&path).unwrap_or_default()
    }).unwrap()).unwrap();
    
    let mobileme = delegates.mobileme.unwrap();
    let findmy = FindMyState::new(dsid.clone());

    let id_path = conf_dir.join("findmy.plist");
    if !id_path.exists() {
        std::fs::write(id_path, findmy.encode()?).unwrap();
    }

    let shared_streams = SharedStreamsState::new(dsid.clone(), &mobileme);
    if let Some(shared_streams) = shared_streams {
        let id_path = conf_dir.join("sharedstreams.plist");
        if !id_path.exists() {
            std::fs::write(id_path, plist_to_string(&shared_streams).unwrap()).unwrap(); 
        }
    } else {
        warn!("missing shared streams tokens!");
    }

    let cloudkitstate = CloudKitState::new(dsid.clone());
    if let Some(cloudkitstate) = cloudkitstate {
        let id_path = conf_dir.join("cloudkit.plist");
        if !id_path.exists() {
            std::fs::write(id_path, plist_to_string(&cloudkitstate).unwrap()).unwrap();
        }
    } else {
        warn!("missing cloudkit tokens!");
    }

    let keychain = KeychainClientState::new(dsid.clone(), adsid.to_string(), &mobileme);
    if let Some(keychain) = keychain {
        let id_path = conf_dir.join("keychain.plist");
        if !id_path.exists() {
            std::fs::write(id_path, plist_to_string(&keychain).unwrap()).unwrap();
        }
    } else {
        warn!("missing keychain tokens!");
    }

    debug!("Spd finish parse");

    let user = authenticate_apple(delegates.ids.unwrap(), &*os_config.config()).await?;
    Ok(user)
}

#[frb(sync)]
pub fn get_available_user(path: String) -> Option<String> {
    let conf_dir = PathBuf::from_str(&path).unwrap();
    plist::from_file::<_, GSAConfig>(&conf_dir.join("gsa.plist")).ok().map(|i| i.username)
}

pub async fn try_auth(path: String, conf: &JoinedOSConfig, conn: &APSConnection, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, creds: Option<(String, String)>) -> anyhow::Result<(Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>, LoginState, Option<IDSUser>)> {
    let conf_dir = PathBuf::from_str(&path).unwrap();
    info!("Here");
    let mut apple_account =
        AppleAccount::new_with_anisette(get_login_config(&conf_dir, conf, conn).await, anisette.clone())?;
    
    let result = if let Some((username, password)) = creds {
        reset_user(&path);

        let mut password_hasher = sha2::Sha256::new();
        password_hasher.update(&password.as_bytes());
        let hashed_password = password_hasher.finalize();
        (username, hashed_password.to_vec())
    } else {
        let state = plist::from_file::<_, GSAConfig>(&conf_dir.join("gsa.plist"))?;
        (state.username.clone(), state.get_password()?)
    };

    let mut login_state = apple_account.login_email_pass(&result.0, &result.1).await?;

    info!("Here3");

    let account = Arc::new(Mutex::new(apple_account));

    let mut user = None;
    let pet = account.lock().await.get_pet();
    if let Some(pet) = pet {
        info!("Here4");
        let identity = do_login(path, &account, None, anisette, conf).await?;
        info!("Here5");
        user = Some(identity);

        // who needs extra steps when you have a PET, amirite?
        println!("confirmed login {:?}", login_state);
        if matches!(login_state, LoginState::NeedsExtraStep(_)) {
            login_state = LoginState::LoggedIn;
        }
    }
    info!("Here6");


    Ok((account, login_state, user))
}

pub async fn auth_phone(conn: &APSConnection, config: &JoinedOSConfig, number: String, sig: Vec<u8>) -> anyhow::Result<IDSUser> {
    let identity = authenticate_phone(&number, AuthPhone {
        push_token: conn.get_token().await.to_vec().into(),
        sigs: vec![sig.into()]
    }, &*config.config()).await?;

    Ok(identity)
}

pub async fn send_2fa_to_devices(state: &Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>, conn: &APSConnection) -> anyhow::Result<(CircleClientSession<DefaultAnisetteProvider>, LoginState, Option<String>)> {
    let account = state.lock().await;

    let spd = account.spd.as_ref().unwrap();
    let dsid = spd["DsPrsId"].as_unsigned_integer().unwrap();

    drop(account);

    let client_session = CircleClientSession::new(dsid, state.clone(), conn.get_token().await).await?;
    let sid = client_session.session_id.clone();

    Ok((client_session, LoginState::Needs2FAVerification, sid))
}

#[frb(type_64bit_int)]
pub struct ViableBottle {
    pub escrow: EscrowData,
    pub numeric_length: u64,
    pub device_name: String,
    pub model_class: String,
}

pub async fn is_in_clique(keychain: &Arc<KeychainClient<DefaultAnisetteProvider>>) -> bool {
    keychain.is_in_clique().await
}

pub async fn join_clique_with_bottle(keychain: &Arc<KeychainClient<DefaultAnisetteProvider>>, bottle: &EscrowData, password: String, device_password: String) -> anyhow::Result<()> {
    keychain.join_clique_from_escrow(bottle, password.as_bytes(), device_password.as_bytes()).await?;
    Ok(())
}

pub async fn reset_clique(keychain: &Arc<KeychainClient<DefaultAnisetteProvider>>, cloud_messages: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>, device_password: String) -> anyhow::Result<()> {
    keychain.reset_clique(device_password.as_bytes()).await?;

    cloud_messages.reset().await?;
    Ok(())
}

pub async fn get_bottles(keychain: &Arc<KeychainClient<DefaultAnisetteProvider>>) -> anyhow::Result<Vec<ViableBottle>> {
    let bottles = keychain.get_viable_bottles().await?;
    Ok(bottles.into_iter().filter_map(|b| {
        let client_metadata = b.1.client_metadata.as_dictionary()?;
        Some(ViableBottle {
            escrow: b.0,
            numeric_length: client_metadata.get("SecureBackupNumericPassphraseLength").and_then(|i| i.as_unsigned_integer()).unwrap_or(0),
            device_name: client_metadata.get("device_name").and_then(|i| i.as_string()).unwrap_or("No Name").to_string(),
            model_class: client_metadata.get("device_model_class").and_then(|i| i.as_string()).unwrap_or("iMac").to_string(),
        })
    }).collect())
}

pub fn encode_summary_info(info: &MessageSummaryInfo) -> Vec<u8> {
    plist_to_bin(info).unwrap()
}

pub fn decode_summary_info(info: &[u8]) -> MessageSummaryInfo {
    plist::from_bytes(info).unwrap()
}

use rustpush::{coder_encode_flattened, coder_decode_flattened};

#[frb(sync)]
pub fn attachment_to_cloud(att: &Attachment) -> Option<MMCSAttachmentMeta> {
    att.into()
}

#[frb(sync)]
pub fn nscoder_encode(value: &[StCollapsedValue]) -> Vec<u8> {
    coder_encode_flattened(value)
}

#[frb(sync)]
pub fn nscoder_decode(data: &[u8]) -> Vec<StCollapsedValue> {
    coder_decode_flattened(data)
}

#[frb(sync)]
pub fn save_cloud_chat(value: &CloudChat) -> Vec<u8> {
    plist_to_bin(&value).unwrap()
}

#[frb(sync)]
pub fn restore_cloud_chat(data: &[u8]) -> CloudChat {
    plist::from_bytes(data).unwrap()
}

pub async fn sync_chats(
    cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>,
    continuation_token: Option<Vec<u8>>,
) -> anyhow::Result<(Vec<u8>, HashMap<String, Option<CloudChat>>, i32)> {
    Ok(cloud_messages_client.sync_chats(continuation_token).await?)
}

pub async fn save_chats(
    cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>,
    chats: HashMap<String, CloudChat>,
) -> anyhow::Result<HashMap<String, bool>> {
    Ok(cloud_messages_client.save_chats(chats).await?.into_iter().map(|(a, b)| (a, b.is_ok())).collect())
}

pub async fn delete_chats(
    cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>,
    chats: &[String],
) -> anyhow::Result<()> {
    Ok(cloud_messages_client.delete_chats(chats).await?)
}

pub async fn sync_messages(
    cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>,
    continuation_token: Option<Vec<u8>>,
) -> anyhow::Result<(Vec<u8>, HashMap<String, Option<CloudMessage>>, i32)> {
    Ok(cloud_messages_client.sync_messages(continuation_token).await?)
}

pub async fn save_messages(
    cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>,
    messages: HashMap<String, CloudMessage>,
) -> anyhow::Result<HashMap<String, bool>> {
    Ok(cloud_messages_client.save_messages(messages).await?.into_iter().map(|(a, b)| (a, b.is_ok())).collect())
}

pub async fn delete_messages(
    cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>,
    messages: &[String],
) -> anyhow::Result<()> {
    Ok(cloud_messages_client.delete_messages(messages).await?)
}

#[frb(sync)]
pub fn decode_message_info(data: &[u8]) -> anyhow::Result<MessageSummaryInfo> {
    Ok(plist::from_bytes(data)?)
}

#[frb(sync)]
pub fn encode_message_info(info: &MessageSummaryInfo) -> Vec<u8> {
    plist_to_bin(info).unwrap()
}

#[frb(external)]
impl MessageFlags {
    #[frb(sync)]
    pub fn bits(&self) -> i64 { }
    #[frb(sync)]
    pub fn from_bits_truncate(val: i64) -> Self { }
}

pub async fn sync_attachments(
    cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>,
    continuation_token: Option<Vec<u8>>,
) -> anyhow::Result<(Vec<u8>, HashMap<String, Option<CloudAttachment>>, i32)> {
    Ok(cloud_messages_client.sync_attachments(continuation_token).await?)
}

pub async fn save_attachments(
    cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>,
    attachments: HashMap<String, CloudAttachment>,
) -> anyhow::Result<HashMap<String, bool>> {
    Ok(cloud_messages_client.save_attachments(attachments).await?.into_iter().map(|(a, b)| (a, b.is_ok())).collect())
}

pub async fn delete_attachments(
    cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>,
    attachments: &[String],
) -> anyhow::Result<()> {
    Ok(cloud_messages_client.delete_attachments(attachments).await?)
}

pub async fn count_records(
    cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>,
) -> anyhow::Result<CloudMessageSummary> {
    Ok(cloud_messages_client.count_records().await?)
}

pub async fn download_cloud_attachments(cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>, files: Vec<(String, String)>) -> anyhow::Result<()> {
    let mut map = HashMap::new();
    for (file, record) in files {
        info!("here {}", file);
        let path = std::path::Path::new(&file);
        let prefix = path.parent().unwrap();
        std::fs::create_dir_all(prefix)?;

        info!("created {}", file);

        map.insert(record, std::fs::File::create(file)?);
    }

    cloud_messages_client.download_attachment(map).await?;
    Ok(())
}

#[frb(sync, type_64bit_int)]
pub fn systemtime_to_millis(time: SystemTime) -> u64 {
    time.duration_since(SystemTime::UNIX_EPOCH).unwrap().as_millis() as u64
}

#[frb(sync)]
pub fn utm_now() -> SystemTime {
    SystemTime::now()
}

#[frb(sync)]
pub fn date_now() -> plist::Date {
    SystemTime::now().into()
}

#[frb(sync, type_64bit_int)]
pub fn date_to_ms(date: &plist::Date) -> u64 {
    let systemtime: SystemTime = date.clone().into();
    systemtime.duration_since(SystemTime::UNIX_EPOCH).unwrap().as_millis() as u64
}

#[frb(sync, type_64bit_int)]
pub fn ms_to_date(ms: u64) -> plist::Date {
    let time = SystemTime::UNIX_EPOCH + Duration::from_millis(ms);
    time.into()
}

pub async fn download_cloud_group_photos(cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>, files: Vec<(String, String)>) -> anyhow::Result<()> {

    let mut map = HashMap::new();
    for (file, record) in files {
        let path = std::path::Path::new(&file);
        let prefix = path.parent().unwrap();
        std::fs::create_dir_all(prefix)?;

        map.insert(record, std::fs::File::create(file)?);
    }

    cloud_messages_client.download_group_photo(map).await?;
    Ok(())
}

pub async fn upload_cloud_attachments(cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>, files: Vec<(String, String)>) -> anyhow::Result<HashMap<String, Asset>> {

    let mut to_upload = vec![];
    let mut hashes = vec![];
    for (file, record) in &files {
        let prepared = cloud_messages_client.prepare_file(std::fs::File::open(file)?).await?;
        hashes.push(prepared.total_sig.clone());
        to_upload.push((prepared, std::fs::File::open(file)?, record.clone()));
    }
    
    let results = cloud_messages_client.upload_attachments(to_upload).await?;

    let mut finish = HashMap::new();
    for result in results {
        let idx = hashes.iter().position(|h| h == result.signature.as_ref().unwrap()).unwrap();
        finish.insert(files[idx].1.clone(), result);
    }

    Ok(finish)
}

pub async fn upload_group_photo(cloud_messages_client: &Arc<CloudMessagesClient<DefaultAnisetteProvider>>, files: Vec<(String, String)>) -> anyhow::Result<HashMap<String, Asset>> {

    let mut to_upload = vec![];
    let mut hashes = vec![];
    for (file, record) in &files {
        let prepared = cloud_messages_client.prepare_file(std::fs::File::open(file)?).await?;
        hashes.push(prepared.total_sig.clone());
        to_upload.push((prepared, std::fs::File::open(file)?, record.clone()));
    }
    
    let results = cloud_messages_client.upload_group_photo(to_upload).await?;

    let mut finish = HashMap::new();
    for result in results {
        let idx = hashes.iter().position(|h| h == result.signature.as_ref().unwrap()).unwrap();
        finish.insert(files[idx].1.clone(), result);
    }

    Ok(finish)
}

pub async fn change_escrow_password(keychain: &Arc<KeychainClient<DefaultAnisetteProvider>>, device_password: String) -> anyhow::Result<()> {
    keychain.change_escrow_password(device_password.as_bytes()).await?;
    Ok(())
}

pub async fn circle_setup_clique(client: &Arc<Mutex<Option<CircleClientSession<DefaultAnisetteProvider>>>>, keychain: &Arc<KeychainClient<DefaultAnisetteProvider>>, device_password: String) -> anyhow::Result<bool> {
    let mut locked = client.lock().await;

    let Some(inner) = &mut *locked else { return Ok(true) };
    if let Err(e) = inner.setup_trusted_peers(keychain.clone(), device_password.as_bytes()).await {
        if let PushError::CircleOver = &e {
            return Ok(true)
        }
        return Err(e.into())
    }
    Ok(false)
}

pub async fn verify_2fa(path: String, client: &mut CircleClientSession<DefaultAnisetteProvider>, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, os_config: &JoinedOSConfig, account: &Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>, watcher: &mut broadcast::Receiver<APSMessage>, idms: &Arc<IdmsAuthListener>, code: String) -> anyhow::Result<(LoginState, Option<IDSUser>)> {
    client.send_code(&code).await?;

    // todo add timeout
    let mut login_state = tokio::time::timeout(Duration::from_secs(30), async {
        Ok::<_, PushError>(loop {
            let msg = watcher.recv().await.unwrap();
            if let Some(test) = idms.handle(msg)? {
                match test {
                    IdmsMessage::CircleRequest(c, _) => {
                        if let Some(state) = client.handle_circle_request(&c).await? {
                            break state;
                        }
                    },
                    _ => { }
                }
            }
        })
    }).await.map_err(|_| anyhow!("Timed Out!"))??;

    let mut user = None;
    let pet = account.lock().await.get_pet();
    if let Some(pet) = pet {
        let identity = do_login(path, &account, None, anisette, os_config).await?;
        user = Some(identity);

        // who needs extra steps when you have a PET, amirite?
        println!("confirmed login {:?}", login_state);
        if matches!(login_state, LoginState::NeedsExtraStep(_)) {
            login_state = LoginState::LoggedIn;
        }
    }

    Ok((login_state, user))
}



pub async fn get_2fa_sms_opts(state: &Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>) -> anyhow::Result<(Vec<TrustedPhoneNumber>, Option<LoginState>)> {
    let account = state.lock().await;
    let extras = account.get_auth_extras().await?;
    Ok((
        extras.trusted_phone_numbers,
        extras.new_state
    ))
}

pub async fn send_2fa_sms(locked: Option<CircleClientSession<DefaultAnisetteProvider>>, account: &Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>, phone_id: u32) -> anyhow::Result<LoginState> {
    if let Some(l) = locked {
        l.cancel().await?;
    }

    let account = account.lock().await;
    Ok(account.send_sms_2fa_to_devices(phone_id).await?)
}

pub async fn verify_2fa_sms(path: String, account_mut: &Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>, anisette: &ArcAnisetteClient<DefaultAnisetteProvider>, config: &JoinedOSConfig, body: &VerifyBody, code: String) -> anyhow::Result<(LoginState, Option<IDSUser>)> {
    let mut account = account_mut.lock().await;
    let mut login_state = account.verify_sms_2fa(code, body.clone()).await?;

    let mut user = None;
    if let Some(pet) = account.get_pet() {
        drop(account);
        let identity = do_login(path, &account_mut, None, anisette, config).await?;
        user = Some(identity);

        // who needs extra steps when you have a PET, amirite?
        println!("confirmed login {:?}", login_state);
        if matches!(login_state, LoginState::NeedsExtraStep(_)) {
            login_state = LoginState::LoggedIn;
        }
    }

    Ok((login_state, user))
}

pub async fn validate_cert(conn: &APSConnection, user: &IDSUser) -> anyhow::Result<Vec<String>> {
    let x = Ok(user.get_possible_handles(&*conn.state.read().await).await?);
    info!("Validated cert");
    x
}

#[frb(sync)]
pub fn cancel_poll(cancel: &mpsc::Sender<()>) {
    let _ = cancel.try_send(());
}

fn reset_user(path: &str) {
    let dir = PathBuf::from_str(path).unwrap();

    let _ = std::fs::remove_file(dir.join("gsa.plist"));
    let _ = std::fs::remove_file(dir.join("findmy.plist"));
    let _ = std::fs::remove_file(dir.join("facetime.plist"));
    let _ = std::fs::remove_file(dir.join("cloudkit.plist"));
    let _ = std::fs::remove_file(dir.join("keychain.plist"));
    let _ = std::fs::remove_file(dir.join("sharedstreams.plist"));

    let path = dir.join("statuskit.plist");
    std::fs::write(&path, plist_to_string(&StatusKitState {
        my_key: None,
        ..plist::from_file(&path).unwrap_or_default()
    }).unwrap()).unwrap();
}

pub async fn reset_state(cancel: &mpsc::Sender<()>, path: String, config: &JoinedOSConfig, aps: &APSConnection, account: Option<Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>>, reset_hw: bool, logout: bool) -> anyhow::Result<()> {
    // tell any poll to stop
    let _ = cancel.try_send(());
    let dir = PathBuf::from_str(&path).unwrap();

    info!("c");
    if logout {
        if let Some(hardware) = read_hardware(path.clone()) {
            // try deregistering from iMessage, but if it fails we don't really care
            if let Ok(identity) = IDSNGMIdentity::restore(hardware.identity.as_ref(), "openbubbles") {
                let _ = register(&*config.config(), &*aps.state.read().await, &[], &mut [], &identity).await;
            }
        }
        if let Some(account) = &account {
            let _ = account.lock().await.logout_all("Apple Device").await;
        }

        reset_user(&path);
    }
    let _ = std::fs::remove_file(dir.join("id.plist"));
    if let Ok(mut cache) = plist::from_file::<_, Dictionary>(dir.join("id_cache.plist")) {
        // keep replay counters which are nessesary if our identity doesn't change
        cache.get_mut("cache").expect("No cache?").as_dictionary_mut().unwrap().clear();
        plist::to_file_xml(dir.join("id_cache.plist"), &cache)?;
    }

    if reset_hw {
        let _ = std::fs::remove_file(dir.join("hw_info.plist"));
        let _ = std::fs::remove_file(dir.join("id_cache.plist")); // our identity is wiped so we can wipe our counters too
        let _ = std::fs::remove_file(dir.join("statuskit.plist"));
    }

    Ok(())
}

pub async fn invalidate_id_cache(client: &Arc<IMClient>) -> anyhow::Result<()> {
    client.identity.invalidate_id_cache().await;
    Ok(())
}

#[frb(sync)]
pub fn close_client(client: &Arc<IMClient>) {
    client.identity.close();
}

#[frb(sync)]
pub fn close_aps(aps: &APSConnection) {
    aps.close();
}

#[frb(sync)]
pub fn close_syncmanager(shared: &SyncManager<DefaultAnisetteProvider, MyFilePackager>) {
    shared.close();
}

// NOTE, breaks linux registration for some god stupid awful reason
// only valid before registration
pub async fn get_user_name(state: &Arc<Mutex<AppleAccount<DefaultAnisetteProvider>>>) -> anyhow::Result<String> {
    let (first, last) = state.lock().await.get_name();
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

pub async fn get_regstate(state: &Arc<IMClient>) -> anyhow::Result<RegisterState> {
    let mutex_ref = state.identity.resource_state.borrow().clone();
    Ok(match &mutex_ref {
        ResourceState::Generating => RegisterState::Registering,
        ResourceState::Generated => RegisterState::Registered {
            next_s: state.identity.calculate_rereg_time_s().await
        },
        ResourceState::Failed(failure) =>
            RegisterState::Failed { retry_wait: failure.retry_wait, error: format!("{}", failure.error) },
        ResourceState::Closed => RegisterState::Failed { retry_wait: None, error: "Closed".to_owned() }
    })
}

pub async fn convert_token_to_uuid(state: &Arc<IMClient>, handle: String, token: Vec<u8>) -> anyhow::Result<String> {
    let uuid = state.identity.token_to_uuid(&handle, &token).await?;
    Ok(uuid)
}


pub async fn get_sms_targets(state: &Arc<IMClient>, handle: String, refresh: bool) -> anyhow::Result<Vec<PrivateDeviceInfo>> {
    let targets = state.identity.get_sms_targets(&handle, refresh).await?;
    Ok(targets)
}
