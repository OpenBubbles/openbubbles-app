use std::collections::HashMap;

pub use rustpush::{DeleteTarget, MoveToRecycleBinMessage, OperatedChat};
pub use rustpush::{NSArrayClass, TextFlags, TextEffect, TextFormat, SupportAction, NSArray, SupportAlert, PrivateDeviceInfo, PermanentDeleteMessage, NormalMessage, MessageType, UpdateExtensionMessage, ErrorMessage, UnsendMessage, EditMessage, PartExtension, IconChangeMessage, RichLinkImageAttachmentSubstitute, ChangeParticipantMessage, ReactMessage, Reaction, ReactMessageType, RenameMessage, LPLinkMetadata, NSURL, LPIconMetadata, LPImageMetadata, LinkMeta, ExtensionApp, NSDictionaryClass, BalloonLayout, Balloon, IndexedMessagePart, AttachmentType, MacOSConfig, Message, MessageTarget, HardwareConfig, APSConnection, APSConnectionResource, APSState, Attachment, AuthPhone, IDSUserIdentity, MMCSFile, MessageInst, MessagePart, MessageParts, OSConfig, RelayConfig, ResourceState};
pub use rustpush::{PushError, IDSUser, IMClient, ConversationData, register};
pub use icloud_auth::{VerifyBody, TrustedPhoneNumber};
pub use icloud_auth::{LoginState, AppleAccount};
pub use rustpush::findmy::{Follow, Address, Location, FoundDevice};

#[repr(C)]
#[frb(mirror(SupportAction))]
pub struct DartSupportAction {
    pub url: String,
    pub button: String,
}

#[repr(C)]
#[frb(mirror(SupportAlert))]
pub struct DartSupportAlert {
    pub title: String,
    pub body: String,
    pub action: Option<SupportAction>,
}

#[frb(mirror(ConversationData))]
#[repr(C)]
pub struct DartConversationData {
    #[frb(non_final)]
    pub participants: Vec<String>,
    #[frb(non_final)]
    pub cv_name: Option<String>,
    #[frb(non_final)]
    pub sender_guid: Option<String>,
    #[frb(non_final)]
    pub after_guid: Option<String>,
}


#[frb(non_opaque, mirror(LoginState))]
#[repr(C)]
pub enum DartLoginState {
    LoggedIn,
    // NeedsSMS2FASent(Send2FAToDevices),
    NeedsDevice2FA,
    Needs2FAVerification,
    NeedsSMS2FA,
    NeedsSMS2FAVerification(VerifyBody),
    NeedsExtraStep(String),
    NeedsLogin,
}

#[repr(C)]
#[frb(type_64bit_int, mirror(MMCSFile))]
pub struct DartMMCSFile {
    pub signature: Vec<u8>,
    pub object: String,
    pub url: String,
    pub key: Vec<u8>,
    pub size: usize
}


#[repr(C)]
#[frb(mirror(AttachmentType))]
pub enum DartAttachmentType {
    Inline(Vec<u8>),
    MMCS(MMCSFile)
}

#[repr(C)]
#[frb(type_64bit_int, mirror(Attachment))]
pub struct DartAttachment {
    pub a_type: AttachmentType,
    pub part: u64,
    pub uti_type: String,
    pub mime: String,
    pub name: String,
    pub iris: bool
}

#[frb(external)]
impl Attachment {
    #[frb(type_64bit_int)]
    pub fn get_size(&self) -> usize { }
}

#[frb(mirror(TextFlags))]
pub struct DartTextFlags {
    bold: bool,
    italic: bool,
    underline: bool,
    strikethrough: bool,
}

#[frb(mirror(TextEffect))]
pub enum DartTextEffect {
    Big = 5,
    Small = 11,
    Shake = 9,
    Nod = 8,
    Explode = 12,
    Ripple = 4,
    Bloom = 6,
    Jitter = 10,
}

#[frb(mirror(TextFormat))]
pub enum DartTextFormat {
    Flags(TextFlags),
    Effect(TextEffect),
}

#[repr(C)]
#[frb(mirror(MessagePart))]
pub enum DartMessagePart {
    Text(String, TextFormat),
    Attachment(Attachment),
    Mention(String, String),
    Object(String),
}

#[repr(C)]
#[frb(type_64bit_int, mirror(PartExtension))]
pub enum DartPartExtension {
    Sticker {
        msg_width: f64,
        rotation: f64, // radians, -pi to +pi
        sai: u64,
        scale: f64,
        update: Option<bool>, // Some(false) for updates
        sli: u64,
        normalized_x: f64,
        normalized_y: f64,
        version: u64,
        hash: String,
        safi: u64,
        effect_type: i64,
        sticker_id: String,
    }
}

#[repr(C)]
#[frb(type_64bit_int, mirror(IndexedMessagePart))]
pub struct DartIndexedMessagePart {
    pub part: MessagePart,
    pub idx: Option<usize>,
    pub ext: Option<PartExtension>,
}

#[frb(mirror(MessageParts))]
#[repr(C)]
pub struct DartMessageParts(pub Vec<IndexedMessagePart>);

#[frb(external)]
impl MessageParts {
    pub fn raw_text(&self) -> String { }
}


#[frb(mirror(MessageType))]
#[repr(C)]
#[derive(PartialEq, Clone)]
pub enum DartMessageType {
    IMessage,
    SMS {
        is_phone: bool,
        using_number: String, // prefixed with tel:
        from_handle: Option<String>,
    }
}

#[repr(C)]
#[frb(mirror(NSDictionaryClass))]
pub enum DartNSDictionaryClass {
    NSDictionary,
    NSMutableDictionary,
}

#[repr(C)]
#[frb(non_opaque, mirror(BalloonLayout))]
pub enum DartBalloonLayout {
    TemplateLayout {
        image_subtitle: String,
        image_title: String,
        caption: String,
        secondary_subcaption: String,
        tertiary_subcaption: String,
        subcaption: String,
        class: NSDictionaryClass,
    }
}

#[repr(C)]
#[frb(non_opaque, mirror(Balloon))]
pub struct DartBalloon {
    pub url: String,
    pub session: Option<String>, // UUID
    pub layout: BalloonLayout,
    pub ld_text: Option<String>,
    pub is_live: bool,

    pub icon: Vec<u8>,
}

#[repr(C)]
#[frb(type_64bit_int, mirror(ExtensionApp))]
pub struct DartExtensionApp {
    pub name: String,
    pub app_id: Option<u64>,
    pub bundle_id: String,

    pub balloon: Option<Balloon>,
}

#[frb(mirror(PermanentDeleteMessage))]
pub struct DartPermanentDeleteMessage {
    pub target: DeleteTarget,
    pub is_scheduled: bool,
}

#[frb(mirror(NormalMessage), type_64bit_int)]
#[repr(C)]
pub struct DartNormalMessage {
    #[frb(non_final)]
    pub parts: MessageParts,
    #[frb(non_final)]
    pub effect: Option<String>,
    #[frb(non_final)]
    pub reply_guid: Option<String>,
    #[frb(non_final)]
    pub reply_part: Option<String>,
    pub service: MessageType,
    #[frb(non_final)]
    pub subject: Option<String>,
    #[frb(non_final)]
    pub app: Option<ExtensionApp>,
    #[frb(non_final)]
    pub link_meta: Option<LinkMeta>,
    #[frb(non_final)]
    pub voice: bool,
    #[frb(non_final)]
    pub scheduled_ms: Option<u64>,
}

#[repr(C)]
#[frb(mirror(NSURL))]
pub struct DartNSURL {
    pub base: String,
    pub relative: String,
}

#[repr(C)]
#[frb(mirror(LPImageMetadata))]
pub struct DartLPImageMetadata {
    pub size: String,
    pub url: NSURL,
    pub version: u8,
}

#[repr(C)]
#[frb(mirror(LPIconMetadata))]
pub struct DartLPIconMetadata {
    pub url: NSURL,
    pub version: u8,
}

#[repr(C)]
#[frb(mirror(RichLinkImageAttachmentSubstitute))]
pub struct DartRichLinkImageAttachmentSubstitute {
    pub mime_type: String,
    pub rich_link_image_attachment_substitute_index: u64,
}

#[repr(C)]
#[frb(mirror(NSArrayClass))]
pub enum DartNSArrayClass {
    NSArray,
    NSMutableArray,
}

// FRB doesn't support generics
// the things i do for this bridge...
#[repr(C)]
#[frb(non_opaque, mirror(NSArray<LPImageMetadata>))]
pub struct NSArrayImageArray {
    pub objects: Vec<LPImageMetadata>,
    pub class: NSArrayClass,
}

#[repr(C)]
#[frb(non_opaque, mirror(NSArray<LPIconMetadata>))]
pub struct NSArrayIconArray {
    pub objects: Vec<LPIconMetadata>,
    pub class: NSArrayClass,
}


#[repr(C)]
#[frb(mirror(LPLinkMetadata))]
pub struct DartLPLinkMetadata {
    pub image_metadata: Option<LPImageMetadata>,
    pub version: u8,
    pub icon_metadata: Option<LPIconMetadata>,
    pub original_url: NSURL,
    pub url: Option<NSURL>,
    pub title: Option<String>,
    pub summary: Option<String>,
    pub image: Option<RichLinkImageAttachmentSubstitute>,
    pub icon: Option<RichLinkImageAttachmentSubstitute>,
    pub images: Option<NSArray<LPImageMetadata>>,
    pub icons: Option<NSArray<LPIconMetadata>>,
}


#[frb(mirror(LinkMeta))]
#[repr(C)]
pub struct DartLinkMeta {
    pub data: LPLinkMetadata,
    pub attachments: Vec<Vec<u8>>,
}

#[repr(C)]
#[frb(mirror(RenameMessage))]
pub struct DartRenameMessage {
    pub new_name: String
}

#[repr(C)]
#[frb(type_64bit_int, mirror(ChangeParticipantMessage))]
pub struct DartChangeParticipantMessage {
    pub new_participants: Vec<String>,
    pub group_version: u64
}

#[repr(C)]
#[frb(mirror(Reaction))]
pub enum DartReaction {
    Heart,
    Like,
    Dislike,
    Laugh,
    Emphasize,
    Question,
    Emoji(String),
    Sticker {
        spec: Option<ExtensionApp>,
        body: MessageParts
    },
}

#[repr(C)]
#[frb(non_opaque, mirror(ReactMessageType))]
pub enum DartReactMessageType {
    React {
        reaction: Reaction,
        enable: bool,
    },
    Extension {
        spec: ExtensionApp,
        body: MessageParts
    },
}

#[repr(C)]
#[frb(type_64bit_int, mirror(ReactMessage))]
pub struct DartReactMessage {
    pub to_uuid: String,
    pub to_part: Option<u64>,
    pub reaction: ReactMessageType,
    pub to_text: String,
}

#[repr(C)]
#[frb(type_64bit_int, mirror(UnsendMessage))]
pub struct DartUnsendMessage {
    pub tuuid: String,
    pub edit_part: u64,
}

#[repr(C)]
#[frb(type_64bit_int, mirror(EditMessage))]
pub struct DartEditMessage {
    pub tuuid: String,
    pub edit_part: u64,
    pub new_parts: MessageParts
}

#[repr(C)]
#[frb(type_64bit_int, mirror(IconChangeMessage))]
pub struct DartIconChangeMessage {
    pub file: Option<MMCSFile>,
    pub group_version: u64
}

#[repr(C)]
#[frb(mirror(UpdateExtensionMessage))]
pub struct DartUpdateExtensionMessage {
    pub for_uuid: String,
    pub ext: PartExtension,
}

#[repr(C)]
#[frb(mirror(ErrorMessage))]
pub struct DartErrorMessage {
    pub for_uuid: String,
    pub status: u64,
    pub status_str: String,
}


#[frb(mirror(OperatedChat))]
#[derive(Clone)]
pub struct DartOperatedChat {
    pub participants: Vec<String>,
    pub group_id: String,
    pub guid: String,
    pub delete_incoming_messages: Option<bool>,
    pub was_reported_as_junk: Option<bool>
}

#[frb(mirror(DeleteTarget))]
#[derive(Clone)]
pub enum DartDeleteTarget {
    Chat(OperatedChat),
    Messages(Vec<String>)
}

#[frb(type_64bit_int, mirror(MoveToRecycleBinMessage))]
#[derive(Clone)]
pub struct DartMoveToRecycleBinMessage {
    target: DeleteTarget,
    recoverable_delete_date: u64,
}

#[repr(C)]
#[frb(non_opaque, mirror(Message))]
pub enum DartMessage {
    Message(NormalMessage),
    RenameMessage(RenameMessage),
    ChangeParticipants(ChangeParticipantMessage),
    React(ReactMessage),
    Delivered,
    Read,
    Typing,
    Unsend(UnsendMessage),
    Edit(EditMessage),
    IconChange(IconChangeMessage),
    StopTyping,
    EnableSmsActivation(bool),
    MessageReadOnDevice,
    SmsConfirmSent(bool),
    MarkUnread, // send for last message from other participant
    PeerCacheInvalidate,
    UpdateExtension(UpdateExtensionMessage),
    Error(ErrorMessage),
    MoveToRecycleBin(MoveToRecycleBinMessage),
    RecoverChat(OperatedChat),
    PermanentDelete(PermanentDeleteMessage),
    Unschedule,
}

#[frb(mirror(MessageTarget))]
#[repr(C)]
pub enum DartMessageTarget {
    Token(Vec<u8>),
    Uuid(String),
}

#[frb(type_64bit_int, mirror(MessageInst))]
#[repr(C)]
pub struct DartIMessage {
    #[frb(non_final)]
    pub id: String,
    #[frb(non_final)]
    pub sender: Option<String>,
    #[frb(non_final)]
    pub conversation: Option<ConversationData>,
    #[frb(non_final)]
    pub message: Message,
    #[frb(non_final)]
    pub sent_timestamp: u64,
    #[frb(non_final)]
    pub target: Option<Vec<MessageTarget>>,
    #[frb(non_final)]
    pub send_delivered: bool,
    #[frb(non_final)]
    pub verification_failed: bool,
}

#[repr(C)]
#[frb(mirror(TrustedPhoneNumber))]
pub struct DartTrustedPhoneNumber {
    pub number_with_dial_code: String,
    pub last_two_digits: String,
    pub push_mode: String,
    pub id: u32
}


#[repr(C)]
#[frb(mirror(PrivateDeviceInfo))]
pub struct DartPrivateDeviceInfo {
    pub uuid: Option<String>,
    pub device_name: Option<String>,
    pub token: Vec<u8>,
    pub is_hsa_trusted: bool,
    pub identites: Vec<String>,
    pub sub_services: Vec<String>,
}


#[frb(mirror(Follow))]
pub struct DartFollow {
    pub create_timestamp: i64,
    pub expires: i64,
    pub id: String,
    pub invitation_accepted_handles: Vec<String>,
    pub invitation_from_handles: Vec<String>,
    pub is_from_messages: bool,
    pub offer_id: Option<String>,
    pub only_in_event: bool,
    pub person_id_hash: String,
    pub secure_locations_capable: bool,
    pub shallow_or_live_secure_locations_capable: bool,
    pub source: String,
    pub tk_permission: bool,
    pub update_timestamp: i64,
    pub fallback_to_legacy_allowed: Option<bool>,
    pub opted_not_to_share: Option<bool>,
    pub last_location: Option<Location>,
    pub locate_in_progress: bool,
}

#[frb(mirror(Location))]
pub struct DartLocation {
    pub address: Option<Address>,
    pub altitude: f64,
    pub floor_level: i64,
    pub horizontal_accuracy: f64,
    pub is_inaccurate: bool,
    pub latitude: f64,
    pub location_id: Option<String>,
    pub location_timestamp: Option<i64>,
    pub longitude: f64,
    pub secure_location_ts: i64,
    pub timestamp: i64,
    pub vertical_accuracy: f64,
    pub position_type: Option<String>,
    pub is_old: Option<bool>,
    pub location_finished: Option<bool>,
}

#[frb(mirror(FoundDevice))]
pub struct DartFoundDevice {
    pub device_model: Option<String>,
    pub low_power_mode: Option<bool>,
    pub passcode_length: Option<i64>,
    pub id: Option<String>,
    pub battery_status: Option<String>,
    pub lost_mode_capable: Option<bool>,
    pub battery_level: Option<f64>,
    pub location_enabled: Option<bool>,
    pub is_considered_accessory: Option<bool>,
    pub location: Option<Location>,
    pub model_display_name: Option<String>,
    pub device_color: Option<String>,
    pub activation_locked: Option<bool>,
    pub rm2_state: Option<i64>,
    pub loc_found_enabled: Option<bool>,
    pub nwd: Option<bool>,
    pub device_status: Option<String>,
    pub fmly_share: Option<bool>,
    pub features: HashMap<String, bool>,
    pub this_device: Option<bool>,
    pub lost_mode_enabled: Option<bool>,
    pub device_display_name: Option<String>,
    pub name: Option<String>,
    pub can_wipe_after_lock: Option<bool>,
    pub is_mac: Option<bool>,
    pub raw_device_model: Option<String>,
    pub ba_uuid: Option<String>,
    pub device_discovery_id: Option<String>,
    pub scd: Option<bool>,
    pub location_capable: Option<bool>,
    pub wipe_in_progress: Option<bool>,
    pub dark_wake: Option<bool>,
    pub device_with_you: Option<bool>,
    pub max_msg_char: Option<i64>,
    pub device_class: Option<String>,
}

#[frb(mirror(Address))]
pub struct DartAddress {
    pub administrative_area: Option<String>,
    pub country: String,
    pub country_code: String,
    pub formatted_address_lines: Option<Vec<String>>,
    pub locality: Option<String>,
    pub state_code: Option<String>,
    pub street_address: Option<String>,
    pub street_name: Option<String>,
}

