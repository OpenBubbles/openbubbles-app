use std::{collections::BTreeSet, fmt::{Debug, Display}, path::PathBuf, sync::{Arc, RwLock}};

use aes_gcm::{AeadInPlace, Aes256Gcm, KeyInit, Nonce};
use keystore::{EcCurve, EcKeystoreKey, EncryptMode, KeyType, Keystore, KeystoreAccessRules, KeystoreDeriveKey, KeystoreDigest, KeystoreError, KeystorePadding, backup::{BackupKeystore, BackupKeystoreState}, init_keystore, keystore, software::{SoftwareKeystore, SoftwareKeystoreState}};
use openssl::{bn::BigNumContext, ec::{EcGroup, EcKey, EcPoint, PointConversionForm}, encrypt::Encrypter, hash::MessageDigest, nid::Nid, pkey::{PKey, Public}, rsa::{Padding, Rsa}};
use rustpush::cloudkit_proto::base64_encode;
use uniffi::UnexpectedUniFFICallbackError;
use std::str::FromStr;
use rasn::{types::{Any, GeneralizedTime, SequenceOf, SetOf}, AsnType, Decode, Encode};
use log::{debug, error, info, warn};


#[uniffi::remote(Enum)]
pub enum EcCurve {
    P256,
    P384,
}

#[uniffi::remote(Enum)]
pub enum KeyType {
    Rsa(u16),
    Ec(EcCurve),
    Aes(u16),
}

#[uniffi::remote(Enum)]
pub enum KeystorePadding {
    PKCS1,
    OAEP {
        md: KeystoreDigest,
        mgf1: KeystoreDigest,
    },
    None
}

#[uniffi::remote(Enum)]
pub enum EncryptMode {
    Rsa (KeystorePadding),
    Gcm,
}

#[uniffi::remote(Enum)]
pub enum KeystoreDigest {
    Sha384,
    Sha256,
    Sha1,
}

#[uniffi::remote(Record)]
pub struct KeystoreAccessRules {
    pub block_modes: Vec<EncryptMode>,
    pub digests: Vec<KeystoreDigest>,
    pub encryption_paddings: Vec<KeystorePadding>,
    pub mgf1_digests: Vec<KeystoreDigest>,
    pub signature_padding: Vec<KeystorePadding>,
    pub require_user: bool,
    pub can_agree: bool,
    pub can_sign: bool,
    pub can_encrypt: bool,
    pub can_decrypt: bool,
}

#[derive(uniffi::Error, Debug)]
pub enum NativeKeystoreError {
    NativeError(String)
}

impl Display for NativeKeystoreError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::NativeError(native) => write!(f, "{native}")
        }
    }
}

impl Into<KeystoreError> for NativeKeystoreError {
    fn into(self) -> KeystoreError {
        match self {
            Self::NativeError(native) => KeystoreError::KeystoreError(native),
        }
    }
}

impl From<uniffi::UnexpectedUniFFICallbackError> for NativeKeystoreError {
    fn from(e: uniffi::UnexpectedUniFFICallbackError) -> Self {
        NativeKeystoreError::NativeError(e.reason)
    }
}

#[uniffi::export]
pub fn finish_unlock() {
    keystore().as_lockable().expect("WHAT NOT LOCKABLE??").unlock().expect("unlocking failed!")
}

#[uniffi::export]
pub fn is_locked() -> bool {
    if let Some(lockable) = keystore().as_lockable() {
        lockable.is_locked()
    } else {
        false
    }
}

#[uniffi::export]
pub fn do_lock() {
    if let Some(lockable) = keystore().as_lockable() {
        lockable.lock().expect("unlocking failed!")
    }
}

#[uniffi::export]
pub fn recover_keychain() {
    if let Some(lockable) = keystore().as_lockable() {
        lockable.recover().expect("unlocking failed!")
    }
}

pub fn supports_import(keystore: &NativeKeystoreHolder) -> Result<bool, KeystoreError> {
    if !keystore.keystore.supports_import().map_err(|e| <NativeKeystoreError as Into<KeystoreError>>::into(e))? {
        return Ok(false)
    }

    let enc = Rsa::generate(1024)?;
    let key = PKey::from_rsa(enc)?;

    keystore.destroy_key("test:import")?;
    keystore.import_key("test:import", KeyType::Rsa(1024), &key.private_key_to_der()?, KeystoreAccessRules {
        signature_padding: vec![KeystorePadding::PKCS1],
        digests: vec![KeystoreDigest::Sha1],
        can_sign: true,
        ..Default::default()
    })?;

    // this was added in android 12, make sure our keymaster supports it
    keystore.destroy_key("test:ec")?;
    let curve = EcGroup::from_curve_name(Nid::SECP384R1)?;
    let test_ec = EcKey::generate(&curve)?;
    keystore.import_key("test:ec", KeyType::Ec(EcCurve::P384), &test_ec.private_key_to_der()?, KeystoreAccessRules {
        can_agree: true,
        digests: vec![KeystoreDigest::Sha384, KeystoreDigest::Sha256],
        ..Default::default()
    })?;
    let other_key = EcKey::generate(&curve)?;
    let mut context = BigNumContext::new()?;
    let ephermeral_sender = other_key.public_key().to_bytes(&curve, PointConversionForm::UNCOMPRESSED, &mut context)?;
    keystore.derive("test:ec", &ephermeral_sender)?;

    keystore.destroy_key("test:ec")?;
    keystore.destroy_key("test:import")?;

    // Test AES 256 wrapped key import (fails on some MediaTek TEEs)
    keystore.destroy_key("test:aes")?;
    let aes_key: [u8; 32] = rand::random();
    keystore.import_key("test:aes", KeyType::Aes(256), &aes_key, KeystoreAccessRules {
        block_modes: vec![EncryptMode::Gcm],
        can_encrypt: true,
        can_decrypt: true,
        ..Default::default()
    })?;
    keystore.destroy_key("test:aes")?;

    Ok(true)
}

#[uniffi::export]
pub fn setup_keystore(dir: String, keystore: Arc<dyn NativeKeystore>) {
    let dir = PathBuf::from_str(&dir).unwrap();
    let keystore_path = dir.join("keystore.plist");
    let soft_keystore = dir.join("keystore_s.plist");

    let keystore = NativeKeystoreHolder {
        keystore,
    };

    let has_support = if keystore_path.exists() {
        true
    } else if soft_keystore.exists() {
        false
    } else {
        let software = supports_import(&keystore);
        info!("Hardware check {software:?}");
        matches!(software, Ok(true))
    };

    info!("Using hardware {has_support}");

    if has_support {
        let (state, key) = if let Ok(existing) = plist::from_file(&keystore_path) {
            (existing, None)
        } else {
            let (keystore, key) = BackupKeystoreState::new(&keystore).expect("Failed to initialize keystore!");
            (keystore, Some(key))
        };

        init_keystore(BackupKeystore {
            state: RwLock::new(state),
            update_state: Box::new(move |state| {
                plist::to_file_xml(&keystore_path, state).unwrap();
            }),
            hardware: keystore,
            unlocked_key: RwLock::new(key),
        });
    } else {
        let state: SoftwareKeystoreState = plist::from_file(&soft_keystore).unwrap_or_default();
        init_keystore(SoftwareKeystore {
            state: RwLock::new(state),
            update_state: Box::new(move |state| {
                plist::to_file_xml(&soft_keystore, state).unwrap();
            }),
            encryptor: keystore,
        });
    }
}

#[uniffi::export(with_foreign)]
pub trait NativeKeystore: Send + Sync + Debug + 'static {
    fn supports_import(&self) -> Result<bool, NativeKeystoreError>;

    fn create_key(&self, alias: String, r#type: KeyType, access_rules: KeystoreAccessRules) -> Result<(), NativeKeystoreError>;
    fn destroy_key(&self, alias: String) -> Result<(), NativeKeystoreError>;
    fn list_keys(&self) -> Result<Vec<String>, NativeKeystoreError>;

    // priv key can be EC private key in DER, raw AES key bytes
    // or a DER RSA private key.
    fn import_key(&self, alias: String, r#type: KeyType, wrapped_key: Vec<u8>, access_rules: KeystoreAccessRules) -> Result<(), NativeKeystoreError>;
    fn get_import_wrap_key(&self) -> Result<Vec<u8>, NativeKeystoreError>;
    fn get_key_type(&self, alias: String) -> Result<Option<KeyType>, NativeKeystoreError>;
    
    fn sign(&self, alias: String, digest: KeystoreDigest, padding: KeystorePadding, data: Vec<u8>) -> Result<Vec<u8>, NativeKeystoreError>;
    fn verify(&self, alias: String, digest: KeystoreDigest, padding: KeystorePadding, data: Vec<u8>, sig: Vec<u8>) -> Result<bool, NativeKeystoreError>;
    // returns in DER
    fn get_public_key(&self, alias: String) -> Result<Vec<u8>, NativeKeystoreError>;
    // peer is a EC public key starting with 02, 03, or 04
    fn derive(&self, alias: String, peer: Vec<u8>) -> Result<Vec<u8>, NativeKeystoreError>;

    fn encrypt(&self, alias: String, plaintext: Vec<u8>, mode: EncryptMode) -> Result<Vec<u8>, NativeKeystoreError>;
    fn decrypt(&self, alias: String, ciphertext: Vec<u8>, mode: EncryptMode) -> Result<Vec<u8>, NativeKeystoreError>;
}

#[derive(AsnType, Encode, Decode, Default)]
struct AuthorizationList {
    #[rasn(tag(explicit(context, 1)))]
    purpose: Option<SetOf<u32>>,
    #[rasn(tag(explicit(context, 2)))]
    algorithm: Option<u32>,
    #[rasn(tag(explicit(context, 3)))]
    key_size: Option<u32>,
    #[rasn(tag(explicit(context, 4)))]
    block_mode: Option<SetOf<u32>>,
    #[rasn(tag(explicit(context, 5)))]
    digest: Option<SetOf<u32>>,
    #[rasn(tag(explicit(context, 6)))]
    padding: Option<SetOf<u32>>,
    #[rasn(tag(explicit(context, 8)))]
    min_mac_length: Option<u32>,
    #[rasn(tag(explicit(context, 10)))]
    ec_curve: Option<u32>,
    #[rasn(tag(explicit(context, 203)))]
    mgf_digest: Option<SetOf<u32>>,
    #[rasn(tag(explicit(context, 503)))]
    no_auth_required: Option<()>,
    #[rasn(tag(explicit(context, 504)))]
    user_auth_type: Option<u32>,
    #[rasn(tag(explicit(context, 505)))]
    auth_timeout: Option<u32>,
}

enum HardwareAuthenticatorType {
    NONE = 0,
    PASSWORD = 1 << 0,
    FINGERPRINT = 1 << 1,
    // Additional entries must be powers of 2.
    // ANY = 0xFFFFFFFF,
}

enum KeyPurpose {
    /* Usable with 3DES and AES keys. */
    Encrypt = 0,

    /* Usable with RSA, 3DES and AES keys. */
    Decrypt = 1,

    /* Usable with RSA, EC and HMAC keys. */
    Sign = 2,

    /* Usable with HMAC keys. */
    Verify = 3,

    /* 4 is reserved */

    /* Usable with wrapping keys. */
    WrapKey = 5,

    /* Key Agreement, usable with EC keys. */
    AgreeKey = 6,

    /* Usable as an attestation signing key.  Keys with this purpose must not have any other
     * purpose; if they do, key generation/import must be rejected with
     * ErrorCode::INCOMPATIBLE_PURPOSE. (Rationale: If key also included KeyPurpose::SIGN, then
     * it could be used to sign arbitrary data, including any tbsCertificate, and so an
     * attestation produced by the key would have no security properties.)
     */
    AttestKey = 7,
}

enum Algorithm {
    /** Asymmetric algorithms. */
    Rsa = 1,
    /** 2 removed, do not reuse. */
    Ec = 3,

    /** Block cipher algorithms */
    Aes = 32,
    TripleDes = 33,

    /** MAC algorithms */
    Hmac = 128,
}

enum BlockMode {
    /*
     * Unauthenticated modes, usable only for encryption/decryption and not generally recommended
     * except for compatibility with existing other protocols.
     */
    Ecb = 1,
    Cbc = 2,
    Ctr = 3,

    /*
     * Authenticated modes, usable for encryption/decryption and signing/verification.  Recommended
     * over unauthenticated modes for all purposes.
     */
    Gcm = 32,
}

enum Digest {
    None = 0,
    Md5 = 1,
    Sha1 = 2,
    Sha224 = 3,
    Sha256 = 4,
    Sha384 = 5,
    Sha512 = 6,
}

enum PaddingMode {
    None = 1,
    RsaOaep = 2,
    RsaPss = 3,
    RsaPkcs1Encrypt = 4,
    RsaPkcs1Sign = 5,
    Pkcs7 = 64,
}

enum AndroidEcCurve {
    P224 = 0,
    P256 = 1,
    P384 = 2,
    P521 = 3,
    Curve25519 = 4,
}

enum KeyFormat {
    /** X.509 certificate format, for public key export. */
    X509 = 0,
    /** PKCS#8 format, asymmetric key pair import. */
    PKCS8 = 1,
    /**
     * Raw bytes, for symmetric key import, and for import of raw asymmetric keys for curve 25519.
     */
    RAW = 3,
}

impl Digest {
    fn from_keystore(digest: &KeystoreDigest) -> Self {
        match digest {
            KeystoreDigest::Sha1 => Self::Sha1,
            KeystoreDigest::Sha256 => Self::Sha256,
            KeystoreDigest::Sha384 => Self::Sha384,
        }
    }
}

impl AuthorizationList {
    fn from_auth_rules(r#type: KeyType, rules: &KeystoreAccessRules) -> Self {
        let mut purpose_set = BTreeSet::new();
        if rules.can_agree {
            purpose_set.insert(KeyPurpose::AgreeKey as u32);
        }
        if rules.can_decrypt {
            purpose_set.insert(KeyPurpose::Decrypt as u32);
        }
        if rules.can_encrypt {
            purpose_set.insert(KeyPurpose::Encrypt as u32);
        }
        if rules.can_sign {
            purpose_set.insert(KeyPurpose::Sign as u32);
        }
        Self {
            purpose: Some(purpose_set),
            algorithm: Some(match r#type {
                KeyType::Aes(_) => Algorithm::Aes,
                KeyType::Ec(_) => Algorithm::Ec,
                KeyType::Rsa(_) => Algorithm::Rsa,
            } as u32),
            key_size: Some(match r#type {
                KeyType::Aes(k) => k,
                KeyType::Ec(EcCurve::P256) => 256,
                KeyType::Ec(EcCurve::P384) => 384,
                KeyType::Rsa(k) => k,
            } as u32),
            block_mode: if rules.block_modes.is_empty() { None } else { Some(rules.block_modes.iter().map(|m| match m {
                EncryptMode::Gcm => BlockMode::Gcm,
                EncryptMode::Rsa(_) => BlockMode::Ecb,
                _ => panic!("Bad block mode!")
            } as u32).collect()) },
            digest: if rules.digests.is_empty() { None } else { 
                Some(rules.digests.iter().map(|m| Digest::from_keystore(m) as u32).collect())
            },
            min_mac_length: if rules.block_modes.iter().any(|b| matches!(b, EncryptMode::Gcm)) { Some(128) } else { None },
            padding: if rules.signature_padding.is_empty() && rules.encryption_paddings.is_empty() { Some(std::iter::once(PaddingMode::None as u32).collect()) } else {
                Some(rules.signature_padding.iter().map(|m| match m {
                    KeystorePadding::None => PaddingMode::None,
                    KeystorePadding::OAEP { .. } => PaddingMode::RsaOaep,
                    KeystorePadding::PKCS1 => PaddingMode::RsaPkcs1Sign,
                } as u32).chain(rules.encryption_paddings.iter().map(|m| match m {
                    KeystorePadding::None => PaddingMode::None,
                    KeystorePadding::OAEP { .. } => PaddingMode::RsaOaep,
                    KeystorePadding::PKCS1 => PaddingMode::RsaPkcs1Encrypt,
                } as u32)).collect()) 
            },
            ec_curve: match r#type {
                KeyType::Ec(EcCurve::P256) => Some(AndroidEcCurve::P256 as u32),
                KeyType::Ec(EcCurve::P384) => Some(AndroidEcCurve::P384 as u32),
                _ => None
            },
            mgf_digest: if rules.mgf1_digests.is_empty() { None } else { Some(rules.mgf1_digests.iter().map(|m| Digest::from_keystore(m) as u32).collect()) },
            no_auth_required: if rules.require_user { None } else { Some(()) },
            user_auth_type: if rules.require_user { Some(HardwareAuthenticatorType::PASSWORD as u32 ^ HardwareAuthenticatorType::FINGERPRINT as u32) } else { None },
            auth_timeout: if rules.require_user { Some(0) } else { None },
        }
    }
}

#[derive(AsnType, Encode, Decode, Default)]
struct KeyDescription {
    key_format: u32,
    key_params: AuthorizationList
}

#[derive(AsnType, Encode, Decode, Default)]
struct KeyWrapper {
    version: u32,
    encrypted_transport_key: rasn::types::OctetString,
    initialization_vector: rasn::types::OctetString,
    key_description: KeyDescription,
    encrypted_key: rasn::types::OctetString,
    tag: rasn::types::OctetString,
}

fn wrap_import_key(r#type: KeyType, pub_key: Rsa<Public>, priv_key: &[u8], access_rules: &KeystoreAccessRules) -> Result<Vec<u8>, KeystoreError> {
    let desc = KeyDescription {
        key_format: match r#type {
            KeyType::Aes(_) => KeyFormat::RAW,
            KeyType::Ec(_) => KeyFormat::PKCS8,
            KeyType::Rsa(_) => KeyFormat::PKCS8,
        } as u32,
        key_params: AuthorizationList::from_auth_rules(r#type, access_rules),
    };

    let priv_key = match r#type {
        KeyType::Aes(_) => priv_key.to_vec(),
        // convert to PKCS#8
        KeyType::Ec(_) => {
            let priv_key = PKey::from_ec_key(EcKey::private_key_from_der(priv_key)?)?;
            priv_key.private_key_to_pkcs8()?
        },
        KeyType::Rsa(_) => {
            let priv_key = PKey::from_rsa(Rsa::private_key_from_der(priv_key)?)?;
            priv_key.private_key_to_pkcs8()?
        },
    };

    let aes_key: [u8; 32] = rand::random();

    let pkey = PKey::from_rsa(pub_key)?;
    let mut encrypter = Encrypter::new(&pkey.as_ref())?;
    encrypter.set_rsa_padding(Padding::PKCS1_OAEP)?;
    encrypter.set_rsa_oaep_md(MessageDigest::sha256())?;
    encrypter.set_rsa_mgf1_md(MessageDigest::sha1())?;

    let len = encrypter.encrypt_len(&aes_key)?;
    let mut rsa_cipher = vec![0; len];
    let encrypted_len = encrypter.encrypt(&aes_key, &mut rsa_cipher)?;
    rsa_cipher.truncate(encrypted_len);

    let iv: [u8; 12] = rand::random();

    let mut priv_encrypted = priv_key.to_vec();

    let gcm = Aes256Gcm::new_from_slice(&aes_key).expect("Failed to bulild gcm");
    let tag = gcm.encrypt_in_place_detached(&Nonce::from_slice(&iv), &rasn::der::encode(&desc).expect("Failed to encode?"), &mut priv_encrypted).expect("Failed to encrypt");

    let wrapper = KeyWrapper {
        version: 0,
        encrypted_transport_key: rsa_cipher.into(),
        initialization_vector: iv.to_vec().into(),
        key_description: desc,
        encrypted_key: priv_encrypted.into(),
        tag: tag.to_vec().into(),
    };

    Ok(rasn::der::encode(&wrapper).expect("Failed to encode?"))
}

pub struct NativeKeystoreHolder {
    keystore: Arc<dyn NativeKeystore>
}

impl Keystore for NativeKeystoreHolder {
    fn create_key(&self, alias: &str, r#type: KeyType, access_rules: KeystoreAccessRules) -> Result<(), keystore::KeystoreError> {
        info!("Keystore creating key {alias}");
        self.keystore.create_key(alias.to_owned(), r#type, access_rules).map_err(|e| e.into())
    }

    fn destroy_key(&self, alias: &str) -> Result<(), KeystoreError> {
        info!("Keystore destroying key {alias}");
        self.keystore.destroy_key(alias.to_owned()).map_err(|e| e.into())
    }

    fn list_keys(&self) -> Result<Vec<String>, KeystoreError> {
        self.keystore.list_keys().map_err(|e| e.into())
    }

    fn set_secret(&self, _alias: &str, _secret: &[u8]) -> Result<(), KeystoreError> {
        Err(KeystoreError::NotSupported)
    }

    fn get_secret(&self, _alias: &str) -> Result<Option<Vec<u8>>, KeystoreError> {
        Err(KeystoreError::NotSupported)
    }

    fn delete_secret(&self, _alias: &str) -> Result<(), KeystoreError> {
        Err(KeystoreError::NotSupported)
    }

    fn import_key(&self, alias: &str, r#type: KeyType, priv_key: &[u8], access_rules: KeystoreAccessRules) -> Result<(), KeystoreError> {
        info!("Keystore importing alias {alias}");
        let rsa = Rsa::public_key_from_der(&self.keystore.get_import_wrap_key().map_err(|e| <NativeKeystoreError as Into<KeystoreError>>::into(e))?)?;

        let wrapped = wrap_import_key(r#type, rsa, priv_key, &access_rules)?;
        info!("wrapped asn.1 {}", base64_encode(&wrapped));

        self.keystore.import_key(alias.to_owned(), r#type, wrapped, access_rules).map_err(|e| e.into())
    }

    fn get_key_type(&self, alias: &str) -> Result<Option<KeyType>, KeystoreError> {
        let res = self.keystore.get_key_type(alias.to_owned()).map_err(|e| e.into());
        info!("sitch {alias} {res:?}");
        res
    }

    fn sign(&self, alias: &str, digest: KeystoreDigest, padding: KeystorePadding, data: &[u8]) -> Result<Vec<u8>, KeystoreError> {
        self.keystore.sign(alias.to_owned(), digest, padding, data.to_vec()).map_err(|e| e.into())
    }

    fn verify(&self, alias: &str, digest: KeystoreDigest, padding: KeystorePadding, data: &[u8], sig: &[u8]) -> Result<bool, KeystoreError> {
        self.keystore.verify(alias.to_owned(), digest, padding, data.to_vec(), sig.to_vec()).map_err(|e| e.into())
    }

    fn get_public_key(&self, alias: &str) -> Result<Vec<u8>, KeystoreError> {
        self.keystore.get_public_key(alias.to_owned()).map_err(|e| e.into())
    }

    fn derive(&self, alias: &str, peer: &[u8]) -> Result<Vec<u8>, KeystoreError> {
        let group = EcGroup::from_curve_name(match peer.len() {
            33 | 65 => Nid::X9_62_PRIME256V1,
            97 | 49 => Nid::SECP384R1,
            _ => return Err(KeystoreError::KeystoreError("Unknown key size!".to_owned())),
        })?;

        let mut num_context_ref = BigNumContext::new()?;
        let point = EcPoint::from_bytes(&group, peer, &mut num_context_ref)?;
        let pub_key = EcKey::from_public_key(&group, &point)?;
        
        self.keystore.derive(alias.to_owned(), pub_key.public_key_to_der()?).map_err(|e| e.into())
    }

    fn encrypt(&self, alias: &str, plaintext: &[u8], mode: &mut EncryptMode) -> Result<Vec<u8>, KeystoreError> {
        self.keystore.encrypt(alias.to_owned(), plaintext.to_vec(), *mode).map_err(|e| e.into())
    }

    fn decrypt(&self, alias: &str, ciphertext: &[u8], mode: &EncryptMode) -> Result<Vec<u8>, KeystoreError> {
        self.keystore.decrypt(alias.to_owned(), ciphertext.to_vec(), *mode).map_err(|e| e.into())
    }
}
