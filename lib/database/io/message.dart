import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:async_task/async_task.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:collection/collection.dart';
import 'package:dlibphonenumber/generated/metadata/phone_number/CH.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:metadata_fetch/metadata_fetch.dart';
// (needed when generating objectbox model code)
// ignore: unnecessary_import
import 'package:objectbox/objectbox.dart';
import 'package:supercharged/supercharged.dart';
import 'package:telephony_plus/telephony_plus.dart';
import 'package:telephony_plus/src/models/attachment.dart' as TelephonyAttachment;
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:tuple/tuple.dart';
import 'dart:typed_data';

const IS_FINISHED               = 1 << 0; // this one probably, although there are some unset in db, all are set on local db
const IS_EMOTE                  = 1 << 1;
const IS_FROM_ME                = 1 << 2;
const IS_EMPTY                  = 1 << 3;
const IS_DELAYED                = 1 << 5;
const IS_AUTO_REPLY             = 1 << 6;
const IS_PREPARED               = 1 << 11;
const IS_DELIVERED              = 1 << 12;
const IS_READ                   = 1 << 13;
const IS_SYSTEM_MESSAGE         = 1 << 14;
const IS_SENT                   = 1 << 15;
const HAS_DD_RESULTS            = 1 << 16;
const IS_SERVICE_MESSAGE        = 1 << 17;
const IS_FORWARD                = 1 << 18;
const WAS_DOWNGRADED            = 1 << 19;
const WAS_DATA_DETECTED         = 1 << 20;
const IS_AUDIO_MESSAGE          = 1 << 21;
const IS_PLAYED                 = 1 << 22;
const IS_EXPIRABLE              = 1 << 24;
const MESSAGE_SOURCE            = 1 << 25;
const IS_CORRUPT                = 1 << 26;
const IS_SPAM                   = 1 << 27;
const HAS_UNKNOWN_MENTION       = 1 << 28;
const IS_STEWIE                 = 1 << 33;
const WAS_DELIVERED_QUIETLY     = 1 << 34;
const DID_NOTIFY_RECIPIENT      = 1 << 35;
const WAS_DETONATED             = 1 << 36;
const IS_KT_VERIFIED            = 1 << 37;
const IS_CRITICAL               = 1 << 38;
const IS_SOS                    = 1 << 39;
const IS_PENDING_SATELLITE_SEND = 1 << 41;
const NEEDS_RELAY               = 1 << 42;
const SENT_OR_RECEIVED_OFF_GRID = 1 << 43;

/// Async method to fetch attachments
class GetMessageAttachments extends AsyncTask<List<dynamic>, Map<String, List<Attachment?>>> {
  final List<dynamic> stuff;

  GetMessageAttachments(this.stuff);

  @override
  AsyncTask<List<dynamic>, Map<String, List<Attachment?>>> instantiate(List<dynamic> parameters,
      [Map<String, SharedData>? sharedData]) {
    return GetMessageAttachments(parameters);
  }

  @override
  List<dynamic> parameters() {
    return stuff;
  }

  @override
  FutureOr<Map<String, List<Attachment?>>> run() {
    /// Pull args from input and create new instances of store and boxes
    List<int> messageIds = stuff[0];
    final Map<String, List<Attachment?>> map = {};
    return Database.runInTransaction(TxMode.read, () {
      /// Query the [amJoinBox] for relevant attachment IDs
      final messages = Database.messages.getMany(messageIds);

      /// Add the attachments to the map with some clever list operations
      map.addEntries(messages.mapIndexed((index, e) => MapEntry(e!.guid!, e.dbAttachments)));
      return map;
    });
  }
}

/// Async method to get chats from objectbox
class BulkSaveNewMessages extends AsyncTask<List<dynamic>, List<Message>> {
  final List<dynamic> params;

  BulkSaveNewMessages(this.params);

  @override
  AsyncTask<List<dynamic>, List<Message>> instantiate(List<dynamic> parameters, [Map<String, SharedData>? sharedData]) {
    return BulkSaveNewMessages(parameters);
  }

  @override
  List<dynamic> parameters() {
    return params;
  }

  @override
  FutureOr<List<Message>> run() {
    return Database.runInTransaction(TxMode.write, () {
      // NOTE: This assumes that handles and chats will already be created and in the database
      // 0. Create map for the messages and attachments to save
      // 1. Check for existing attachments and save new ones
      // 2. Fetch all inserted/existing attachments based on input
      // 3. Create map of inserted/existing attachments
      // 4. Check for existing messages & create list of new messages to save
      // 5. Fetch all handles and map the old handle ROWIDs from each message to the new ones based on the original ROWID
      // 6. Relate the attachments to the messages
      // 7. Save all messages (and handle/attachment relationships)
      // 8. Get the inserted messages
      // 9. Check inserted messages for associated message GUIDs & update hasReactions flag
      // 10. Save the updated associated messages
      // 11. Update the associated chat's last message

      /// Takes the list of messages from [params] and saves it
      /// to the objectbox Database.
      Chat inputChat = params[0];
      List<Message> inputMessages = params[1];
      List<String> inputMessageGuids = inputMessages.map((element) => element.guid!).toList();

      // 0. Create map for the messages and attachments to save
      Map<String, Attachment> attachmentsToSave = {};
      Map<String, List<String>> messageAttachments = {};
      for (final msg in inputMessages) {
        for (final a in msg.attachments) {
          if (!attachmentsToSave.containsKey(a!.guid)) {
            attachmentsToSave[a.guid!] = a;
          }

          if (!messageAttachments.containsKey(a.guid)) {
            messageAttachments[msg.guid!] = [];
          }

          if (!messageAttachments[msg.guid]!.contains(a.guid)) {
            messageAttachments[msg.guid]?.add(a.guid!);
          }
        }
      }

      // 1. Check for existing attachments and save new ones
      Map<String, Attachment> attachmentMap = {};
      if (attachmentsToSave.isNotEmpty) {
        List<String> inputAttachmentGuids = attachmentsToSave.values.map((e) => e.guid).whereNotNull().toList();
        QueryBuilder<Attachment> attachmentQuery = Database.attachments.query(Attachment_.guid.oneOf(inputAttachmentGuids));
        List<String> existingAttachmentGuids =
            attachmentQuery.build().find().map((e) => e.guid).whereNotNull().toList();

        // Insert the attachments that don't yet exist
        List<Attachment> attachmentsToInsert = attachmentsToSave.values
            .where((element) => !existingAttachmentGuids.contains(element.guid))
            .whereNotNull()
            .toList();
        Database.attachments.putMany(attachmentsToInsert);

        // 2. Fetch all inserted/existing attachments based on input
        QueryBuilder<Attachment> attachmentQuery2 = Database.attachments.query(Attachment_.guid.oneOf(inputAttachmentGuids));
        List<Attachment> attachments = attachmentQuery2.build().find().whereNotNull().toList();

        // 3. Create map of inserted/existing attachments
        for (final a in attachments) {
          attachmentMap[a.guid!] = a;
        }
      }

      // 4. Check for existing messages & create list of new messages to save
      QueryBuilder<Message> query = Database.messages.query(Message_.guid.oneOf(inputMessageGuids));
      List<String> existingMessageGuids = query.build().find().map((e) => e.guid!).toList();
      inputMessages = inputMessages.where((element) => !existingMessageGuids.contains(element.guid)).toList();

      // 5. Fetch all handles and map the old handle ROWIDs from each message to the new ones based on the original ROWID
      List<Handle> handles = Database.handles.getAll();

      for (final msg in inputMessages) {
        msg.chat.target = inputChat;
        msg.handle = handles.firstWhereOrNull((e) => e.originalROWID == msg.handleId);
      }

      // 6. Relate the attachments to the messages
      for (final msg in inputMessages) {
        final relatedAttachments =
            messageAttachments[msg.guid]?.map((e) => attachmentMap[e]).whereNotNull().toList() ?? [];
        msg.attachments = relatedAttachments;
        msg.dbAttachments.addAll(relatedAttachments);
      }

      // 7. Save all messages (and handle/attachment relationships)
      Database.messages.putMany(inputMessages);

      // 8. Get the inserted messages
      QueryBuilder<Message> messageQuery = Database.messages.query(Message_.guid.oneOf(inputMessageGuids));
      List<Message> messages = messageQuery.build().find().toList();

      // 9. Check inserted messages for associated message GUIDs & update hasReactions flag
      Map<String, Message> messagesToUpdate = {};
      for (final message in messages) {
        // Update the handles from our cache
        message.handle = handles.firstWhereOrNull((element) => element.originalROWID == message.handleId);

        // Continue if there isn't an associated message GUID to process
        if ((message.associatedMessageGuid ?? '').isEmpty) continue;

        // Find the associated message in the DB and update the hasReactions flag
        List<Message> associatedMessages =
            Message.find(cond: Message_.guid.equals(message.associatedMessageGuid!)).toList();
        if (associatedMessages.isNotEmpty) {
          // Toggle the hasReactions flag
          Message messageWithReaction = messagesToUpdate[associatedMessages[0].guid] ?? associatedMessages[0];
          messageWithReaction.hasReactions = true;

          // Make sure the current message has the associated message in it's list, and the hasReactions
          // flag is set as well
          Message reactionMessage = messagesToUpdate[message.guid!] ?? message;
          for (var e in messageWithReaction.associatedMessages) {
            if (e.guid == messageWithReaction.guid) {
              e.hasReactions = true;
              break;
            }
          }

          // Update the cached values
          messagesToUpdate[messageWithReaction.guid!] = messageWithReaction;
          messagesToUpdate[reactionMessage.guid!] = reactionMessage;
        }
      }

      // 10. Save the updated associated messages
      if (messagesToUpdate.isNotEmpty) {
        try {
          Database.messages.putMany(messagesToUpdate.values.toList());
        } catch (ex) {
          print('Failed to put associated messages into DB: ${ex.toString()}');
        }
      }

      // 11. Update the associated chat's last message
      messages.sort(Message.sort);
      bool isNewer = false;

      // If the message was saved correctly, update this chat's latestMessage info,
      // but only if the incoming message's date is newer
      if (messages.isNotEmpty) {
        final first = messages.first;
        if (first.id != null || kIsWeb) {
          isNewer = first.dateCreated!.isAfter(inputChat.latestMessage.dateCreated!);
          if (isNewer) {
            inputChat.latestMessage = first;
            if (!first.isFromMe! && !cm.isChatActive(inputChat.guid)) {
              inputChat.toggleHasUnread(true);
            }
          }
        }
      }

      return messages;
    });
  }
}

@Entity()
class Message {
  int? id;
  int? originalROWID;

  @Index(type: IndexType.value)
  @Unique()
  String? guid;

  int? handleId;
  int? otherHandle;
  String? text;
  String? subject;
  String? country;

  @Index()
  DateTime? dateCreated;

  bool? isFromMe;
  // Data detector results
  bool? hasDdResults;
  DateTime? datePlayed;
  int? itemType;
  String? groupTitle;
  int? groupActionType;
  String? balloonBundleId;
  String? associatedMessageGuid;
  int? associatedMessagePart;
  String? associatedMessageType;
  String? expressiveSendStyleId;
  String? associatedMessageEmoji;
  Handle? handle;
  bool hasAttachments;
  bool hasReactions;
  DateTime? dateDeleted;
  Map<String, dynamic>? metadata;
  String? threadOriginatorGuid;
  String? threadOriginatorPart;
  List<Attachment?> attachments = [];
  List<Message> associatedMessages = [];
  bool? bigEmoji;
  List<AttributedBody> attributedBody;
  List<MessageSummaryInfo> messageSummaryInfo;
  PayloadData? payloadData;
  bool hasApplePayloadData;
  bool wasDeliveredQuietly;
  bool didNotifyRecipient;
  bool isBookmarked;
  bool verificationFailed;
  DateTime? dateScheduled;
  // service that is sending this message.
  // null if message is not in progress of sending
  // if service is mismatched with current running service, something crashed. Mark as failed.
  String? sendingServiceId;

  String? amkSessionId; // for sessioned messages
  bool hasBeenForwarded; // local SMS forwarding, used to keep track of this message needs to be sent locally via SMS
  String? stagingGuid;

  String? ckRecordId;
  // used differently from chat syncState, used to mark messages we have crawled
  bool ckSyncState = false;

  final RxInt _error = RxInt(0);
  int get error => _error.value;
  set error(int i) => _error.value = i;

  final Rxn<DateTime> _dateRead = Rxn<DateTime>();
  DateTime? get dateRead => _dateRead.value;
  set dateRead(DateTime? d) => _dateRead.value = d;

  final Rxn<DateTime> _dateDelivered = Rxn<DateTime>();
  DateTime? get dateDelivered => _dateDelivered.value;
  set dateDelivered(DateTime? d) => _dateDelivered.value = d;

  final RxBool _isDelivered = RxBool(false);
  bool get isDelivered => (dateDelivered != null) ? true : _isDelivered.value;
  set isDelivered(bool b) => _isDelivered.value = b;

  final Rxn<DateTime> _dateEdited = Rxn<DateTime>();
  DateTime? get dateEdited => _dateEdited.value;
  set dateEdited(DateTime? d) => _dateEdited.value = d;

  @Backlink('message')
  final dbAttachments = ToMany<Attachment>();

  final chat = ToOne<Chat>();

  String? get dbAttributedBody => jsonEncode(attributedBody.map((e) => e.toMap()).toList());
  set dbAttributedBody(String? json) => attributedBody = json == null
      ? <AttributedBody>[] : (jsonDecode(json) as List).map((e) => AttributedBody.fromMap(e)).toList();

  String? get dbMessageSummaryInfo => jsonEncode(messageSummaryInfo.map((e) => e.toJson()).toList());
  set dbMessageSummaryInfo(String? json) => messageSummaryInfo = json == null
      ? <MessageSummaryInfo>[] : (jsonDecode(json) as List).map((e) => MessageSummaryInfo.fromJson(e)).toList();

  String? get dbPayloadData => payloadData == null
      ? null : jsonEncode(payloadData!.toJson());
  set dbPayloadData(String? json) => payloadData = json == null
      ? null : PayloadData.fromJson(jsonDecode(json));

  String? get dbMetadata => metadata == null
      ? null : jsonEncode(metadata);
  set dbMetadata(String? json) => metadata = json == null
      ? null : jsonDecode(json) as Map<String, dynamic>;

  DateTime? get chatViewDate => dateScheduled ?? dateCreated;

  // prevents saving, used for SMS forwarding
  @Transient()
  bool temp = false;


  Future<void> forwardIfNessesary(Chat chat, {bool markFailed = false}) async {
    if (hasBeenForwarded || !chat.isTextForwarding || !(isFromMe ?? true)) return;
    if (!await chat.shouldRoute()) return;


    hasBeenForwarded = true;
    save(chat: chat);

    pushService.disableOutgoingSms = true;

    try {
      // if we are forwarding, we do not persist to disk. Therefore we don't care about temp guids
      var attachments = fetchAttachments()!;
      bool useMMS = chat.participants.length > 1 || attachments.isNotEmpty;
      int status;
      try {
        if (useMMS) {
          status = await TelephonyPlus().sendMMS(
            addresses: chat.participants.map((e) => e.address).filter((e) => e.isPhoneNumber).toList(),
            message: text?.trim() == "" ? null : text,
            threadId: chat.telephonyId,
            attachments: await Future.wait(attachments.map((e) => e!.toTelephony()).toList())
          );
        } else {
          status = await TelephonyPlus().sendSMS(
            address: chat.participants.first.address,
            threadId: chat.telephonyId,
            message: text!,
          );
        }
      } catch (_) {
        // No native status means the forwarding attempt did not complete. Let
        // the transport retry instead of permanently suppressing forwarding.
        hasBeenForwarded = false;
        save(chat: chat);
        rethrow;
      }
      if (status != -1) {
        await (backend as RustPushBackend).confirmSmsSent(this, chat, false);
        hasBeenForwarded = false;
        save(chat: chat);
        if (markFailed) {

          if (!ls.isAlive || !(cm.getChatController(chat.guid)?.isAlive ?? false)) {
            await notif.createFailedToSend(chat);
          }
          return;
        } else {
          throw Exception("failed to send sms with status $status!");
        }
      }
      await (backend as RustPushBackend).confirmSmsSent(this, chat, true);
    } finally {
      (() async {
        await Future.delayed(const Duration(seconds: 5));
        pushService.disableOutgoingSms = false;
      })();
    }
  }

  Message({
    this.id,
    this.originalROWID,
    this.guid,
    this.handleId,
    this.otherHandle,
    this.text,
    this.subject,
    this.country,
    int? error,
    this.dateCreated,
    DateTime? dateRead,
    DateTime? dateDelivered,
    bool? isDelievered,
    this.isFromMe = true,
    this.hasDdResults = false,
    this.datePlayed,
    this.itemType = 0,
    this.groupTitle,
    this.groupActionType = 0,
    this.balloonBundleId,
    this.associatedMessageGuid,
    this.associatedMessagePart,
    this.associatedMessageType,
    this.expressiveSendStyleId,
    this.handle,
    this.hasAttachments = false,
    this.hasReactions = false,
    this.attachments = const [],
    this.associatedMessages = const [],
    this.dateDeleted,
    this.metadata,
    this.threadOriginatorGuid,
    this.threadOriginatorPart,
    this.attributedBody = const [],
    this.messageSummaryInfo = const [],
    this.payloadData,
    this.hasApplePayloadData = false,
    DateTime? dateEdited,
    this.wasDeliveredQuietly = false,
    this.didNotifyRecipient = false,
    this.isBookmarked = false,
    this.hasBeenForwarded = false,
    this.stagingGuid,
    this.amkSessionId,
    this.verificationFailed = false,
    this.sendingServiceId,
    this.associatedMessageEmoji,
    this.dateScheduled,
    this.temp = false,
    this.ckRecordId,
  }) {
      if (handle != null && handleId == null) handleId = handle!.originalROWID;
      if (error != null) _error.value = error;
      if (dateRead != null) _dateRead.value = dateRead;
      if (dateDelivered != null) _dateDelivered.value = dateDelivered;
      if (dateEdited != null) _dateEdited.value = dateEdited;
      if (isDelievered != null) _isDelivered.value = isDelievered;
      if (attachments.isEmpty) attachments = [];
      if (associatedMessages.isEmpty) associatedMessages = [];
      if (attributedBody.isEmpty) attributedBody = [];
      if (messageSummaryInfo.isEmpty) messageSummaryInfo = [];
  }

  factory Message.fromMap(Map<String, dynamic> json) {
    final attachments = (json['attachments'] as List? ?? []).map((a) => Attachment.fromMap(a!.cast<String, Object>())).toList();

    List<AttributedBody> attributedBody = [];
    if (json["attributedBody"] != null) {
      if (json['attributedBody'] is Map) {
        json['attributedBody'] = [json['attributedBody']!.cast<String, Object>()];
      }
      try {
        attributedBody = (json['attributedBody'] as List).map((a) => AttributedBody.fromMap(a!.cast<String, Object>())).toList();
      } catch (e, stack) {
        Logger.error('Failed to parse attributed body!', error: e, trace: stack);
      }
    }

    Map<String, dynamic> metadata = {};
    if (!isNullOrEmpty(json["metadata"])) {
      if (json["metadata"] is String) {
        try {
          metadata = jsonDecode(json["metadata"]);
        } catch (_) {}
      } else {
        metadata = json["metadata"]?.cast<String, Object>();
      }
    }

    List<MessageSummaryInfo> msi = [];
    try {
      msi = (json['messageSummaryInfo'] as List? ?? []).map((e) => MessageSummaryInfo.fromJson(e!.cast<String, Object>())).toList();
    } catch (e, stack) {
      Logger.error('Failed to parse summary info!', error: e, trace: stack);
    }

    PayloadData? payloadData;
    try {
      payloadData = json['payloadData'] == null ? null : PayloadData.fromJson(json['payloadData']);
    } catch (e, s) {
      Logger.error('Failed to parse payload data!', error: e, trace: s);
    }

    return Message(
      id: json["ROWID"] ?? json['id'],
      originalROWID: json["originalROWID"],
      guid: json["guid"],
      handleId: json["handleId"] ?? 0,
      otherHandle: json["otherHandle"],
      text: sanitizeString(attributedBody.firstOrNull?.string ?? json["text"]),
      subject: json["subject"],
      country: json["country"],
      error: json["error"] ?? json["_error"] ?? 0,
      dateCreated: parseDate(json["dateCreated"]),
      dateRead: parseDate(json["dateRead"]),
      dateDelivered: parseDate(json["dateDelivered"]),
      isDelievered: json["isDelivered"] ?? false,
      isFromMe: json['isFromMe'] == true,
      hasDdResults: json['hasDdResults'] == true,
      datePlayed: parseDate(json["datePlayed"]),
      itemType: json["itemType"],
      groupTitle: json["groupTitle"],
      groupActionType: json["groupActionType"] ?? 0,
      balloonBundleId: json["balloonBundleId"],
      associatedMessageGuid: json["associatedMessageGuid"]?.toString().replaceAll("bp:", "").split("/").last,
      associatedMessagePart: json["associatedMessagePart"] ?? int.tryParse(json["associatedMessageGuid"].toString().replaceAll("p:", "").split("/").first),
      associatedMessageType: json["associatedMessageType"],
      expressiveSendStyleId: json["expressiveSendStyleId"],
      handle: json['handle'] != null ? Handle.fromMap(json['handle']!.cast<String, Object>()) : null,
      hasAttachments: attachments.isNotEmpty || json['hasAttachments'] == true,
      attachments: (json['attachments'] as List? ?? []).map((a) => Attachment.fromMap(a!.cast<String, Object>())).toList(),
      hasReactions: json['hasReactions'] == true,
      dateDeleted: parseDate(json["dateDeleted"]),
      metadata: metadata is String ? null : metadata,
      threadOriginatorGuid: json['threadOriginatorGuid'],
      threadOriginatorPart: json['threadOriginatorPart'],
      attributedBody: attributedBody,
      messageSummaryInfo: msi,
      payloadData: payloadData,
      hasApplePayloadData: json['hasApplePayloadData'] == true || payloadData != null,
      dateEdited: parseDate(json["dateEdited"]),
      wasDeliveredQuietly: json['wasDeliveredQuietly'] ?? false,
      didNotifyRecipient: json['didNotifyRecipient'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
      hasBeenForwarded: json['hasBeenForwarded'] ?? false,
      stagingGuid: json['stagingGuid'],
      amkSessionId: json['amkSessionId'],
      verificationFailed: json['verificationFailed'],
      sendingServiceId: json['sendingServiceId'],
      associatedMessageEmoji: json['associatedMessageEmoji'],
      dateScheduled: parseDate(json['dateScheduled']),
      ckRecordId: json['ckRecordId'],
    );
  }

  List<Tuple2<RegExp, String>> inferReactionMap = [
    Tuple2(RegExp(r'^\s*Liked “(.*)”\s*$'), ReactionTypes.LIKE),
    Tuple2(RegExp(r'^\s*Removed a like from “(.*)”\s*$'), "-${ReactionTypes.LIKE}"),
    Tuple2(RegExp(r'^\s*Loved “(.*)”\s*$'), ReactionTypes.LOVE),
    Tuple2(RegExp(r'^\s*Removed a heart from “(.*)”\s*$'), "-${ReactionTypes.LOVE}"),
    Tuple2(RegExp(r'^\s*Disliked “(.*)”\s*$'), ReactionTypes.DISLIKE),
    Tuple2(RegExp(r'^\s*Removed a dislike from “(.*)”\s*$'), "-${ReactionTypes.DISLIKE}"),
    Tuple2(RegExp(r'^\s*Laughed at “(.*)”\s*$'), ReactionTypes.LAUGH),
    Tuple2(RegExp(r'^\s*Removed a laugh from “(.*)”\s*$'), "-${ReactionTypes.LAUGH}"),
    Tuple2(RegExp(r'^\s*Emphasized “(.*)”\s*$'), ReactionTypes.EMPHASIZE),
    Tuple2(RegExp(r'^\s*Removed an exclamation from “(.*)”\s*$'), "-${ReactionTypes.EMPHASIZE}"),
    Tuple2(RegExp(r'^\s*Questioned “(.*)”\s*$'), ReactionTypes.QUESTION),
    Tuple2(RegExp(r'^\s*Removed a question mark from “(.*)”\s*$'), "-${ReactionTypes.QUESTION}"),
    Tuple2(RegExp(r'^\s*Reacted ([^\s]+) to “(.*)”\s*$'), ReactionTypes.EMOJI),
    Tuple2(RegExp(r'^\s*Removed ([^\s]+) from “(.*)”\s*$'), "-${ReactionTypes.EMOJI}"),
  ];

  void inferReaction(Chat chat) {
    if (associatedMessageGuid != null) return; // already associated
    for (var reaction in inferReactionMap) {
      var match = reaction.item1.firstMatch(text!);
      if (match == null) continue;
      var query = (Database.messages.query(Message_.text.equals(match[match.groupCount > 1 ? 2 : 1]!).and(Message_.chat.equals(chat.id!)))
        ..order(Message_.dateCreated, flags: Order.descending))
        .build();
      query.limit = 1;
      var msg = query.findFirst();
      query.close();
    
      if (msg == null) return;
      associatedMessageGuid = msg.guid!;
      associatedMessagePart = 0;
      associatedMessageType = reaction.item2;
      if (match.groupCount > 1) {
        associatedMessageEmoji = match[1]!;
      }
      return;
    }
  }

  List<MessagePart> attributedBodyToMessagePart(AttributedBody body) {
    final mainString = body.string;
    final list = <MessagePart>[];
    body.runs.sort((a, b) => a.range.first.compareTo(b.range.first));
    body.runs.forEachIndexed((i, e) {
      if (e.attributes?.messagePart == null) return;
      final existingPart = list.firstWhereOrNull((element) => element.part == e.attributes!.messagePart!);
      if (existingPart != null) {
        final newText = mainString.substring(e.range.first, e.range.first + e.range.last);
        final currentLength = existingPart.text?.length ?? 0;
        existingPart.text = (existingPart.text ?? "") + newText;
        existingPart.annotations.add(Annotation(
          mentionedAddress: e.attributes?.mention,
          range: [currentLength, currentLength + e.range.last],
          bold: e.attributes?.bold,
          italic: e.attributes?.italic,
          underline: e.attributes?.underline,
          strikethrough: e.attributes?.strikethrough,
          textEffect: e.attributes?.textEffect,
        ));
        existingPart.annotations.sort((a, b) => a.range.first.compareTo(b.range.first));
      } else {
        list.add(MessagePart(
          subject: i == 0 ? subject : null,
          text: e.isAttachment ? null : mainString.substring(e.range.first, e.range.first + e.range.last),
          attachments: e.isAttachment && (chat.target != null || cm.activeChat != null)
              ? [
                  ms(chat.target?.guid ?? cm.activeChat!.chat.guid)
                          .struct
                          .getAttachment(e.attributes!.attachmentGuid!) ??
                      Attachment.findOne(e.attributes!.attachmentGuid!)
                ].where((e) => e != null).map((e) => e!).toList()
              : [],
          annotations: [
                  Annotation(
                    mentionedAddress: e.attributes?.mention,
                    bold: e.attributes?.bold,
                    italic: e.attributes?.italic,
                    underline: e.attributes?.underline,
                    strikethrough: e.attributes?.strikethrough,
                    textEffect: e.attributes?.textEffect,
                    range: [0, e.range.last],
                  )
                ],
          part: e.attributes!.messagePart!,
        ));
      }
    });
    return list;
  }

  List<MessagePart> buildMessageParts() {
    List<MessagePart> parts = [];
    if (guid?.startsWith("error") ?? false) {
      Logger.debug("hi");
    }
    // go through the attributed body
    if (attributedBody.firstOrNull?.runs.isNotEmpty ?? false) {
      parts = attributedBodyToMessagePart(attributedBody.first);
    }
    // add edits
    if (messageSummaryInfo.firstOrNull?.editedParts.isNotEmpty ?? false) {
      for (int part in messageSummaryInfo.first.editedParts) {
        final edits = messageSummaryInfo.first.editedContent[part.toString()] ?? [];
        final existingPart = parts.firstWhereOrNull((element) => element.part == part);
        if (existingPart != null) {
          existingPart.edits.addAll(edits
              .where((e) => e.text?.values.isNotEmpty ?? false)
              .map((e) => attributedBodyToMessagePart(e.text!.values.first).firstOrNull)
              .where((e) => e != null)
              .map((e) => e!)
              .toList());
          if (existingPart.edits.isNotEmpty) {
            existingPart.edits.removeLast();
          }
        }
      }
    }
    // add unsends
    if (messageSummaryInfo.firstOrNull?.retractedParts.isNotEmpty ?? false) {
      for (int part in messageSummaryInfo.first.retractedParts) {
        final existing = parts.indexWhere((e) => e.part == part);
        if (existing >= 0) {
          parts.removeAt(existing);
        }
        parts.add(MessagePart(
          part: part,
          isUnsent: true,
        ));
      }
    }
    if (parts.isEmpty) {
      if (!hasApplePayloadData && !isLegacyUrlPreview && !isGroupEvent) {
        parts.addAll(attachments.mapIndexed((index, e) => MessagePart(
              attachments: [e!],
              part: index,
            )));
      } else if (isInteractive) {
        parts.add(MessagePart(
          part: 0,
        ));
      }

      if (fullText.isNotEmpty || isGroupEvent) {
        parts.add(MessagePart(
          subject: subject,
          text: text,
          part: parts.length,
        ));
      }
    }
    parts.sort((a, b) => a.part.compareTo(b.part));
    return parts;
  }

  /// Save a single message - prefer [bulkSave] for multiple messages rather
  /// than iterating through them
  Message save({Chat? chat, bool updateIsBookmarked = false, bool updateSendingServiceId = false}) {
    if (kIsWeb || temp) return this;
    Database.runInTransaction(TxMode.write, () {
      Message? existing = Message.findOne(guid: guid);
      if (existing != null) {
        id = existing.id;
        text ??= existing.text;
        // delivered can sometimes come before sending, don't let it get overwritten
        if (existing.dateDelivered != null && dateDelivered == null) {
          dateDelivered = existing.dateDelivered;
        }
        if (existing.dateRead != null && dateRead == null) {
          dateRead = existing.dateRead;
        }
      }

      // Save the participant & set the handle ID to the new participant
      if (handle == null && handleId != null) {
        handle = Handle.findOne(originalROWID: handleId);
      }
      // Save associated messages or the original message (depending on whether
      // this message is a reaction or regular message
      if (associatedMessageType != null && associatedMessageGuid != null) {
        Message? associatedMessage = Message.findOne(guid: associatedMessageGuid);
        if (associatedMessage != null) {
          associatedMessage.hasReactions = true;
          associatedMessage.save();
        }
      } else if (!hasReactions) {
        Message? reaction = Message.findOne(associatedMessageGuid: guid);
        if (reaction != null) {
          hasReactions = true;
        }
      }
      if (!updateIsBookmarked) {
        isBookmarked = existing?.isBookmarked ?? isBookmarked;
      }
      if (!updateSendingServiceId) {
        sendingServiceId = existing?.sendingServiceId ?? sendingServiceId;
      }

      try {
        if (chat != null) this.chat.target = chat;
        id = Database.messages.put(this);
      } on UniqueViolationException catch (_) {}
    });
    return this;
  }

  static Future<List<Message>> bulkSaveNewMessages(Chat chat, List<Message> messages) async {
    if (kIsWeb) throw Exception("Web does not support saving messages!");

    final task = BulkSaveNewMessages([chat, messages]);
    return (await createAsyncTask<List<Message>>(task)) ?? [];
  }

  /// Save a list of messages
  static List<Message> bulkSave(List<Message> messages) {
    Database.runInTransaction(TxMode.write, () {
      /// Find existing messages and match them to the messages to save, where
      /// possible
      List<Message> existingMessages = Message.find(cond: Message_.guid.oneOf(messages.map((e) => e.guid!).toList()));
      for (Message m in messages) {
        final existingMessage = existingMessages.firstWhereOrNull((e) => e.guid == m.guid);
        if (existingMessage != null) {
          m.id = existingMessage.id;
          m.text ??= existingMessage.text;
        }
      }

      /// Save the messages and update their IDs
      /// We do this first because we might want these same messages to show up
      /// in the next queries
      final ids = Database.messages.putMany(messages);
      for (int i = 0; i < messages.length; i++) {
        messages[i].id = ids[i];
      }

      /// Find associated messages or original messages
      List<Message> associatedMessages =
          Message.find(cond: Message_.guid.oneOf(messages.map((e) => e.associatedMessageGuid ?? "").toList()));
      List<Message> originalMessages =
          Message.find(cond: Message_.associatedMessageGuid.oneOf(messages.map((e) => e.guid!).toList()));

      /// Iterate thru messages and update the associated message or the original
      /// message, and update original message handle data
      for (Message m in messages) {
        if (m.associatedMessageType != null && m.associatedMessageGuid != null) {
          final associatedMessageList = associatedMessages.where((e) => e.guid == m.associatedMessageGuid);
          for (Message am in associatedMessageList) {
            am.hasReactions = true;
          }
        } else if (!m.hasReactions) {
          final originalMessage = originalMessages.firstWhereOrNull((e) => e.associatedMessageGuid == m.guid);
          if (originalMessage != null) {
            m.hasReactions = true;
          }
        }
      }
      associatedMessages.removeWhere((message) {
        Message? _message = messages.firstWhereOrNull((e) => e.guid == message.guid);
        _message?.hasReactions = message.hasReactions;
        return _message != null;
      });
      try {
        /// Update the original messages and associated messages
        final ids = Database.messages.putMany(messages..addAll(associatedMessages));
        for (int i = 0; i < messages.length; i++) {
          messages[i].id = ids[i];
        }
      } on UniqueViolationException catch (_) {}
    });
    return messages;
  }

  /// Replace a temp message with the message from the server
  static Future<Message> replaceMessage(String? oldGuid, Message newMessage) async {
    if (newMessage.temp) throw Exception("Attempting to persist temp message!");
    Message? existing = Message.findOne(guid: oldGuid);
    if (existing == null) {
      throw Exception("Cannot replace on a null existing message!!");
    }

    // We just need to update the timestamps & error
    if (existing.guid != newMessage.guid) {
      existing.guid = newMessage.guid;
    }
    if (newMessage.text != null) {
      existing.text = newMessage.text;
    }
    
    existing._dateDelivered.value = newMessage._dateDelivered.value ?? existing._dateDelivered.value;
    existing._isDelivered.value = newMessage._isDelivered.value;
    existing._dateRead.value = newMessage._dateRead.value ?? existing._dateRead.value;
    existing._dateEdited.value = newMessage._dateEdited.value ?? existing._dateEdited.value;
    existing.attributedBody = newMessage.attributedBody.isNotEmpty ? newMessage.attributedBody : existing.attributedBody;
    existing.messageSummaryInfo = newMessage.messageSummaryInfo.isNotEmpty ? newMessage.messageSummaryInfo : existing.messageSummaryInfo;
    existing.payloadData = newMessage.payloadData ?? existing.payloadData;
    existing.wasDeliveredQuietly = newMessage.wasDeliveredQuietly ? newMessage.wasDeliveredQuietly : existing.wasDeliveredQuietly;
    existing.didNotifyRecipient = newMessage.didNotifyRecipient ? newMessage.didNotifyRecipient : existing.didNotifyRecipient;
    existing._error.value = newMessage._error.value;
    existing.stagingGuid = newMessage.stagingGuid;
    existing.verificationFailed = newMessage.verificationFailed;
    existing.amkSessionId = newMessage.amkSessionId;
    if (existing.dateScheduled != null && newMessage.dateScheduled == null) {
      existing.dateCreated = newMessage.dateCreated;
    }
    existing.dateScheduled = newMessage.dateScheduled;

    try {
      Database.messages.put(existing, mode: PutMode.update);
    } catch (ex, stack) {
      Logger.error('Failed to replace message! This is likely due to a unique constraint being violated.', error: ex, trace: stack);
    }
    return existing;
  }

  Message updateMetadata(Metadata? metadata) {
    if (kIsWeb || id == null) return this;
    this.metadata = metadata!.toJson();
    save();
    return this;
  }

  Message setPlayedDate({DateTime? timestamp}) {
    datePlayed = timestamp ?? DateTime.now().toUtc();
    save();
    return this;
  }

  /// Fetch attachments for a single message. Prefer using [fetchAttachmentsByMessages]
  /// or [fetchAttachmentsByMessagesAsync] when working with a list of messages.
  List<Attachment?>? fetchAttachments({ChatLifecycleManager? currentChat}) {
    if (attachments.isNotEmpty) {
      return attachments;
    }

    return Database.runInTransaction(TxMode.read, () {
      attachments = dbAttachments;
      return attachments;
    });
  }

  /// Get the chat associated with the message
  Chat? getChat() {
    if (kIsWeb) return null;
    return Database.runInTransaction(TxMode.read, () {
      return chat.target;
    });
  }

  String convertAttachmentGuid(String guid) {
    if (guid.startsWith("at")) {
      var items = guid.split("_");
      guid = "${items[2]}_${items[1]}";
    }
    return guid;
  }

  String unconvertAttachmentGuid(String guid) {
    var items = guid.split("_");
    if (items.length == 1) return guid;
    return "at_${items[1]}_${items[0]}";
  }

  Uint8List? encodeAttributedBody(List<AttributedBody> body, bool noAttachments) {
    if (body.isEmpty) return null;
    return api.nscoderEncode(value: body.map((b) => api.NSAttributedString(
      text: b.string,
      ranges: b.runs.filter((run) => !noAttachments || run.attributes?.attachmentGuid == null).map((run) => (run.range[1], api.NSDictionaryTypedCoder(field0: {
        if (run.attributes?.messagePart != null)
        "__kIMMessagePartAttributeName": api.NSNumber(field0: run.attributes!.messagePart!).encode(),
        if (run.attributes?.attachmentGuid != null)
        "__kIMFileTransferGUIDAttributeName": api.NSString(field0: unconvertAttachmentGuid(run.attributes!.attachmentGuid!)).encode(),
        if (run.attributes?.mention != null)
        "__kIMMentionConfirmedMention": api.NSString(field0: run.attributes!.mention!).encode(),
        if (run.attributes?.audioTranscript != null)
        "IMAudioTranscription": api.NSString(field0: run.attributes!.audioTranscript!).encode(),
        if (run.attributes?.textEffect != null)
        "__kIMTextEffectAttributeName": api.NSNumber(field0: run.attributes!.textEffect!).encode(),
        if (run.attributes?.bold != null)
        "__kIMTextBoldAttributeName": api.NSNumber(field0: run.attributes!.bold! ? 1 : 0).encode(),
        if (run.attributes?.italic != null)
        "__kIMTextItalicAttributeName": api.NSNumber(field0: run.attributes!.italic! ? 1 : 0).encode(),
        if (run.attributes?.italic != null)
        "__kIMTextStrikethroughAttributeName": api.NSNumber(field0: run.attributes!.italic! ? 1 : 0).encode(),
        if (run.attributes?.underline != null)
        "__kIMTextUnderlineAttributeName": api.NSNumber(field0: run.attributes!.underline! ? 1 : 0).encode(),
      }))).toList()
    ).encode()).toList());
  }

  List<AttributedBody> decodeAttributedBody(Uint8List? data) {
    if (data == null) return [];
    return api.nscoderDecode(data: data).map((val) {
      var decoded = api.NSAttributedString.decode(val: val);
      int length = 0;
      return AttributedBody(
        string: decoded.text,
        runs: decoded.ranges.map((r) {
          var start = length;
          length += r.$1;
          return Run(
            range: [start, r.$1],
            attributes: Attributes(
              messagePart: r.$2.field0["__kIMMessagePartAttributeName"] == null ? null : api.NSNumber.decode(val: r.$2.field0["__kIMMessagePartAttributeName"]!).field0,
              attachmentGuid: r.$2.field0["__kIMFileTransferGUIDAttributeName"] == null ? null : convertAttachmentGuid(api.NSString.decode(val: r.$2.field0["__kIMFileTransferGUIDAttributeName"]!).field0),
              mention: r.$2.field0["__kIMMentionConfirmedMention"] == null ? null : api.NSString.decode(val: r.$2.field0["__kIMMentionConfirmedMention"]!).field0,
              audioTranscript: r.$2.field0["IMAudioTranscription"] == null ? null : api.NSString.decode(val: r.$2.field0["IMAudioTranscription"]!).field0,
              textEffect: r.$2.field0["__kIMTextEffectAttributeName"] == null ? null : api.NSNumber.decode(val: r.$2.field0["__kIMTextEffectAttributeName"]!).field0,
              bold: r.$2.field0["__kIMTextBoldAttributeName"] == null ? null : api.NSNumber.decode(val: r.$2.field0["__kIMTextBoldAttributeName"]!).field0 == 1,
              italic: r.$2.field0["__kIMTextItalicAttributeName"] == null ? null : api.NSNumber.decode(val: r.$2.field0["__kIMTextItalicAttributeName"]!).field0 == 1,
              strikethrough: r.$2.field0["__kIMTextStrikethroughAttributeName"] == null ? null : api.NSNumber.decode(val: r.$2.field0["__kIMTextStrikethroughAttributeName"]!).field0 == 1,
              underline: r.$2.field0["__kIMTextUnderlineAttributeName"] == null ? null : api.NSNumber.decode(val: r.$2.field0["__kIMTextUnderlineAttributeName"]!).field0 == 1,
            )
          );
        }).toList()
      );
    }).toList();
  }

  api.CloudMessage toCloud(bool noAttachments) {
    int? amt;
    if (associatedMessageType == "sticker") {
      amt = 2;
    } else if (associatedMessageType != null) {
      var itemRaw = associatedMessageType!.replaceFirst("-", "");
      var idx = ReactionTypes.toList().indexOf(itemRaw);
      amt = idx + (associatedMessageType!.startsWith("-") ? 3000 : 2000);
    }

    // attributebody is null here, should really be Liked "text", but i am lazy
    if (attributedBody.isEmpty && associatedMessageType != null) {
      attributedBody = [AttributedBody.raw(" ")];
    }

    if (noAttachments && attributedBody.isNotEmpty && attributedBody[0].runs.every((run) => run.attributes?.attachmentGuid != null)) {
      throw Exception("No Attachments!");
    }

    var p = payloadData?.appData?.firstOrNull != null ? api.encodeExtensionApp(app: pushService.dataToApp(payloadData!)).$2 : null;
    return api.CloudMessage(
      utm: api.utmNow(),
      type: associatedMessageGuid != null ? 2 : 1,
      error: error, 
      chatId: chat.target!.isGroup ? chat.target!.cloudGuid ?? chat.target!.guid : "iMessage;-;${chat.target!.chatIdentifier}", 
      sender: isFromMe == true ? "" : getHandle()?.address ?? "", 
      time: RustPushBBUtils.nsSinceAppleEpoch(dateCreated!), 
      msgProto2: threadOriginatorGuid != null ? api.encodeMessageproto2(messageproto2: api.MessageProto2(
        reply: "r:$threadOriginatorPart:$threadOriginatorGuid"
      )) : null,
      // this assumes it was sent with this handle, but, cmon, just go along with me...
      destinationCallerId: chat.target!.usingHandle!.replaceFirst("mailto:", "").replaceFirst("tel:", ""), 
      msgProto: api.encodeMessageproto(messageproto: api.MessageProto(
        unk1: 1,
        subject: subject, 
        text: attributedBody[0].string, 
        attributedBody: encodeAttributedBody(attributedBody, noAttachments),
        balloonBundleId: balloonBundleId,
        payloadData: p != null ? Uint8List.fromList(gzip.decode(p)) : null,
        messageSummaryInfo: messageSummaryInfo.isEmpty ? null : api.encodeMessageInfo(info: api.MessageSummaryInfo(
          ec: messageSummaryInfo.first.editedContent.map((key, value) => 
            MapEntry(key, value.map((i) => api.MessageEdit(
              t: encodeAttributedBody(i.text!.values, noAttachments)!, 
              d: i.date!,
            )).toList())), 
          ep: Uint32List.fromList(messageSummaryInfo.first.editedParts), 
          otr: messageSummaryInfo.first.originalTextRange.map((key, value) => MapEntry(key, api.MessageEditRange(lo: value[0], le: value[1]))), 
          rp: Uint32List.fromList(messageSummaryInfo.first.retractedParts), 
          euh: [],
          amc: 0,
          ust: true,
        )),
        effect: expressiveSendStyleId,
        dateRead: dateRead != null ? RustPushBBUtils.nsSinceAppleEpoch(dateRead!) : 0,
        unk10: 0,
        unk11: 0,
        dateDelivered: dateDelivered != null ? RustPushBBUtils.nsSinceAppleEpoch(dateDelivered!) : 0,
        unk14: 0,
        associatedMessageType: amt,
        associatedMessageGuid: associatedMessageGuid != null ? "p:$associatedMessagePart/$associatedMessageGuid" : null,
        associatedMessageRangeLength: associatedMessagePart != null ? Message.findOne(guid: associatedMessageGuid!)?.attributedBody[0].runs.firstWhere((r) => r.attributes!.messagePart == associatedMessagePart).range[1] : null,
        associatedMessageRangeLocation: associatedMessagePart != null ? Message.findOne(guid: associatedMessageGuid!)?.attributedBody[0].runs.firstWhere((r) => r.attributes!.messagePart == associatedMessagePart).range[0] : null
      )),
      flags: api.MessageFlags.fromBitsTruncate(val: 
        IS_FINISHED |
        ((isFromMe ?? false) ? IS_FROM_ME : 0) |
        (isDelivered ? IS_DELIVERED : 0) |
        (dateRead != null ? IS_READ : 0) |
        IS_SENT | 
        (hasBeenForwarded ? IS_FORWARD : 0) |
        WAS_DATA_DETECTED
      ), 
      guid: guid!, 
      msgProto3: api.encodeMessageproto3(messageproto3: const api.MessageProto3(unk2: 0, unk3: 0)),
      service: chat.target!.isRpSms ? "SMS" : "iMessage",
      msgProto4: api.encodeMessageproto4(messageproto4: api.MessageProto4(
        associatedMessageEmoji: associatedMessageEmoji,
        service: chat.target!.isRpSms ? "SMS" : "iMessage", 
        scheduleType: 0, 
        scheduleState: 0, 
        groupId: chat.target!.guid, 
        sentOrReceivedOffGrid: 0
      ))
    );
  }

  void applyFromCloud(api.CloudMessage c, String cloudkitId) {
    Chat? chat;
    if (c.chatId.contains(";")) {
      final query = Database.chats.query(Chat_.chatIdentifier.equals(c.chatId.split(";")[2])).build();
      chat = query.findFirst();
      query.close();
    } else {
      final query = Database.chats.query(Chat_.cloudGuid.equals(c.chatId)).build();
      chat = query.findFirst();
      query.close();
      
      chat ??= Chat.findByRustGuid(c.chatId);
    }

    if (chat?.isRpSms ?? true) return;

    ckRecordId = cloudkitId;

    error = c.error;
    handle = RustPushBBUtils.rustHandleToBB(c.sender);
    handleId = handle!.originalROWID;
    dateCreated = RustPushBBUtils.fromNsSinceAppleEpoch(c.time);
    var proto1 = api.decodeMessageproto(wrapped: c.msgProto);
    subject = proto1.subject;
    text = proto1.text;
    attributedBody = decodeAttributedBody(proto1.attributedBody);
    hasAttachments = attributedBody.firstOrNull?.runs.any((run) => run.attributes?.attachmentGuid != null) ?? false;
    // urls are a whole weird system, ignore for now.
    var eraseBalloonBundle = proto1.balloonBundleId == "com.apple.messages.URLBalloonProvider";
    balloonBundleId = proto1.balloonBundleId;
    if (eraseBalloonBundle) {
      balloonBundleId = null; // we don't support this at the moment.
    }
    
    try {
      payloadData = proto1.payloadData != null && !eraseBalloonBundle ? pushService.appToData(api.decodeExtensionApp(bp: gzip.encode(proto1.payloadData!), bid: proto1.balloonBundleId!)) : null;
    } catch (e, s) {
      Logger.warn(
        "Failed to decode extension payload for bundle ${proto1.balloonBundleId ?? "unknown"} (${proto1.payloadData?.length ?? 0} bytes)",
        error: e,
        trace: s,
      );
    }
    hasApplePayloadData = proto1.payloadData != null && !eraseBalloonBundle;

    if (proto1.messageSummaryInfo != null) {
      var summary = api.decodeMessageInfo(data: proto1.messageSummaryInfo!);
      messageSummaryInfo = [MessageSummaryInfo(
        retractedParts: summary.rp.toList(), 
        editedContent: summary.ec.map((key, value) => MapEntry(key, value.map((i) => EditedContent(text: Content(values: decodeAttributedBody(i.t)), date: i.d)).toList())), 
        originalTextRange: summary.otr.map((key, value) => MapEntry(key, [value.lo, value.le])), 
        editedParts: summary.ep.toList(),
      )];
    } else {
      messageSummaryInfo = [];
    }
    expressiveSendStyleId = proto1.effect;
    dateRead = proto1.dateRead == null || proto1.dateRead == 0 ? null : RustPushBBUtils.fromNsSinceAppleEpoch(proto1.dateRead!);
    dateDelivered = proto1.dateDelivered == null || proto1.dateDelivered == 0 ? null : RustPushBBUtils.fromNsSinceAppleEpoch(proto1.dateDelivered!);
    if (proto1.associatedMessageType != null) {
      if (proto1.associatedMessageType == 2) {
        associatedMessageType = "sticker";
      } else if (proto1.associatedMessageType! >= 2000 && proto1.associatedMessageType! < 3000) {
        associatedMessageType = ReactionTypes.toList()[proto1.associatedMessageType! - 2000];
      } else if (proto1.associatedMessageType! >= 3000 && proto1.associatedMessageType! < 4000) {
        associatedMessageType = "-${ReactionTypes.toList()[proto1.associatedMessageType! - 3000]}";
      }
    }
    associatedMessageGuid = proto1.associatedMessageGuid;
    associatedMessagePart = attributedBody.firstOrNull?.runs.firstWhereOrNull((b) => b.range[0] == proto1.associatedMessageRangeLocation && b.range[1] == proto1.associatedMessageRangeLength)?.attributes?.messagePart;
    guid = c.guid;
    var bits = c.flags.bits();
    isFromMe = (bits & IS_FROM_ME) != 0;

    if (c.msgProto2 != null) {
      var proto2 = api.decodeMessageproto2(wrapped: c.msgProto2!);
      if (proto2.reply != null && proto2.reply!.startsWith("r:")) {
        var parts = proto2.reply!.split(":");
        threadOriginatorGuid = parts.last;
        threadOriginatorPart = parts.slice(1, parts.length - 1).join(":");
      }
    }
    
    if (c.msgProto4 != null) {
      var proto4 = api.decodeMessageproto4(wrapped: c.msgProto4!);
      associatedMessageEmoji = proto4.associatedMessageEmoji;
    }
    
    save(chat: chat);
  }

  /// Fetch reactions
  Message fetchAssociatedMessages({MessagesService? service, bool shouldRefresh = false}) {
    associatedMessages = Message.find(cond: Message_.associatedMessageGuid.equals(guid ?? ""));
    associatedMessages = MessageHelper.normalizedAssociatedMessages(associatedMessages);
    if (threadOriginatorGuid != null) {
      final existing = service?.struct.getMessage(threadOriginatorGuid!);
      final threadOriginator = existing ?? Message.findOne(guid: threadOriginatorGuid);
      threadOriginator?.handle ??= threadOriginator.getHandle();
      if (threadOriginator != null) associatedMessages.add(threadOriginator);
      if (existing == null && threadOriginator != null) service?.struct.addThreadOriginator(threadOriginator);
    }
    associatedMessages.sort((a, b) => a.originalROWID == null || b.originalROWID == null ? 0 : a.originalROWID!.compareTo(b.originalROWID!));
    return this;
  }

  Handle? getHandle() {
    if (kIsWeb || handleId == 0 || handleId == null) return null;
    return Handle.findOne(originalROWID: handleId!);
  }

  static Message? findOne({String? guid, String? associatedMessageGuid}) {
    if (kIsWeb) return null;
    if (guid != null) {
      final query = Database.messages.query(Message_.guid.equals(guid)).build();
      query.limit = 1;
      final result = query.findFirst();
      query.close();
      result?.handle = result.getHandle();
      if (result == null) {
        final query = Database.messages.query(Message_.stagingGuid.equals(guid)).build();
        query.limit = 1;
        final result = query.findFirst();
        query.close();
        result?.handle = result.getHandle();
        return result;
      }
      return result;
    } else if (associatedMessageGuid != null) {
      final query = Database.messages.query(Message_.associatedMessageGuid.equals(associatedMessageGuid)).build();
      query.limit = 1;
      final result = query.findFirst();
      query.close();
      result?.handle = result.getHandle();
      return result;
    }
    return null;
  }

  /// Find a list of messages by the specified condition, or return all messages
  /// when no condition is specified
  static List<Message> find({Condition<Message>? cond}) {
    final query = Database.messages.query(cond).build();
    return query.find();
  }

  /// Delete a message and remove all instances of that message in the DB
  static void delete(String guid) {
    if (kIsWeb) return;
    Database.runInTransaction(TxMode.write, () {
      final query = Database.messages.query(Message_.guid.equals(guid)).build();
      final result = query.findFirst();
      query.close();
      if (result?.id != null) {
        if (result?.ckRecordId != null && !pushService.syncStopDelete) {
          var list = ss.prefs.getStringList("messageDeletionIds-1") ?? [];
          list.add(result!.ckRecordId!);
          ss.prefs.setStringList("messageDeletionIds-1", list);
        }
        Database.messages.remove(result!.id!);
      }
    });
  }

  static void softDelete(String guid) async {
    if (kIsWeb) return;
    Message? toDelete = Message.findOne(guid: guid);
    if (toDelete != null) await backend.moveToRecycleBin(toDelete.chat.target!, toDelete);
    toDelete?.dateDeleted = DateTime.now().toUtc();
    toDelete?.save();
  }

  /// This is purely because some Macs incorrectly report the dateCreated time
  static int sort(Message a, Message b, {bool descending = true}) {
    late DateTime aDateToUse;

    if (a.dateScheduled != null) {
      aDateToUse = a.dateScheduled!;
    } else if (a.dateDelivered == null) {
      aDateToUse = a.dateCreated!;
    } else {
      aDateToUse = a.dateCreated!.isBefore(a.dateDelivered!) ? a.dateCreated! : a.dateDelivered!;
    }

    late DateTime bDateToUse;
    if (b.dateScheduled != null) {
      bDateToUse = b.dateScheduled!;
    } else if (b.dateDelivered == null) {
      bDateToUse = b.dateCreated!;
    } else {
      bDateToUse = b.dateCreated!.isBefore(b.dateDelivered!) ? b.dateCreated! : b.dateDelivered!;
    }

    return descending ? bDateToUse.compareTo(aDateToUse) : aDateToUse.compareTo(bDateToUse);
  }

  String get fullText => sanitizeString([subject, text].where((e) => !isNullOrEmpty(e)).join("\n"));

  // first condition is for macOS < 11 and second condition is for macOS >= 11
  bool get isLegacyUrlPreview => (balloonBundleId == "com.apple.messages.URLBalloonProvider" && hasDdResults!)
      || ((hasDdResults! || isFromMe!) && (text ?? "").trim().isURL);

  String? get url => text?.replaceAll("\n", " ").split(" ").firstWhereOrNull((String e) => e.hasUrl);

  bool get isInteractive => balloonBundleId != null && !isLegacyUrlPreview;

  String get interactiveText {
    String text = "";

    if (payloadData?.urlData != null && payloadData!.urlData!.isNotEmpty && payloadData?.urlData?.first.url != null) {
      return payloadData!.urlData!.first.url!; // do not show summary for Android's open link functionality
    }

    final temp = balloonBundleIdMap[balloonBundleId?.split(":").first] ?? (balloonBundleId?.split(":").first ?? "Unknown");
    if (temp is Map) {
      text = temp[balloonBundleId?.split(":").last] ?? ((balloonBundleId?.split(":").last ?? "Unknown"));
    } else {
      text = temp.toString();
    }
    return text;
  }

  String? get interactiveMediaPath {
    final extension = balloonBundleId!.contains("com.apple.Digital") ? ".mov" : balloonBundleId!.contains("com.apple.Handwriting") ? ".png" : null;
    return "${fs.appDocDir.path}/messages/$guid/embedded-media/$balloonBundleId$extension";
  }

  bool get isGroupEvent => groupTitle != null || (itemType ?? 0) > 0 || (groupActionType ?? 0) > 0;

  String get groupEventText {
    String text = "Unknown group event";
    String name = handle?.displayName ?? 'You';

    String? other = "someone";
    if (otherHandle != null && isParticipantEvent) {
      other = Handle.findOne(originalROWID: otherHandle)?.displayName;
    }

    if (itemType == 1) {
      if (groupActionType == 0) {
        text = "$name added $other to the conversation";
      } else if (groupActionType == 1) {
        text = "$name removed $other from the conversation";
      }
    } else if (itemType == 2) {
      if (groupTitle != null) {
        text = "$name named the conversation \"$groupTitle\"";
      } else {
        text = "$name removed the name from the conversation";
      }
    } else if (itemType == 3) {
      if (groupActionType == null || groupActionType == 0) {
        text = "$name left the conversation";
      } else if (groupActionType == 1) {
        text = "$name changed the group photo";
      } else if (groupActionType == 2) {
        text = "$name removed the group photo";
      }
    } else if (itemType == 4 && groupActionType == 0) {
      text = "$name shared ${name == "You" ? "your" : "their"} location";
    } else if (itemType == 5) {
      text = "$name kept an audio message";
    } else if (itemType == 6) {
      text = "$name started a FaceTime call";
    } else if (itemType == 7) {
      if (groupActionType == 1) {
        text = "$name changed the background";
      } else {
        text = "$name removed the background";
      }
    }

    return text;
  }

  bool get isParticipantEvent => isGroupEvent && ((itemType == 1 && [0, 1].contains(groupActionType)) || [2, 3].contains(itemType));

  bool get isBigEmoji => bigEmoji ?? MessageHelper.shouldShowBigEmoji(fullText);

  List<Attachment> get realAttachments => attachments.where((e) => e != null && e.mimeType != null).cast<Attachment>().toList();

  List<Attachment> get previewAttachments => attachments.where((e) => e != null && e.mimeType == null).cast<Attachment>().toList();

  List<Message> get reactions => associatedMessages.where((item) =>
      ReactionTypes.toList().contains(item.associatedMessageType?.replaceAll("-", ""))).toList();

  Indicator get indicatorToShow {
    if (!isFromMe!) return Indicator.NONE;
    if (dateRead != null) return Indicator.READ;
    if (isDelivered) return Indicator.DELIVERED;
    if (dateDelivered != null) return Indicator.DELIVERED;
    if (dateScheduled != null) return Indicator.SCHEDULED;
    if (dateCreated != null) return Indicator.SENT;
    return Indicator.NONE;
  }

  bool get hasAudioTranscript => attributedBody.any((i) => i.runs.any((e) => e.attributes?.audioTranscript != null));

  bool showTail(Message? newer) {
    // if there is no newer, or if the newer is a different sender
    if (newer == null || !sameSender(newer) || newer.isGroupEvent) return true;
    // if newer is over a minute newer
    return newer.dateCreated!.difference(dateCreated!).inMinutes.abs() > 1;
  }

  bool sameSender(Message? other) {
    return (isFromMe! && isFromMe == other?.isFromMe) || (!isFromMe! && !(other?.isFromMe ?? true) && handleId == other?.handleId);
  }

  void generateTempGuid() {
    guid = "temp-${randomString(8)}";
  }

  /// Find how many messages exist in the DB for a chat
  static int? countForChat(Chat? chat) {
    if (kIsWeb || chat == null || chat.id == null) return 0;
    return chat.messages.length;
  }

  Message mergeWith(Message otherMessage) {
    return Message.merge(this, otherMessage);
  }

  /// Get what shape the reply line should be
  LineType getLineType(Message? olderMessage, Message threadOriginator) {
    if (olderMessage?.threadOriginatorGuid != threadOriginatorGuid) olderMessage = threadOriginator;
    if (isFromMe! && (olderMessage?.isFromMe ?? false)) {
      return LineType.meToMe;
    } else if (!isFromMe! && (olderMessage?.isFromMe ?? false)) {
      return LineType.meToOther;
    } else if (isFromMe! && !(olderMessage?.isFromMe ?? false)) {
      return LineType.otherToMe;
    } else {
      return LineType.otherToOther;
    }
  }

  /// Get whether the reply line from the message should connect to the message below
  bool shouldConnectLower(Message? olderMessage, Message? newerMessage, Message threadOriginator) {
    // if theres no newer message or it isn't part of the thread, don't connect
    if (newerMessage == null || newerMessage.threadOriginatorGuid != threadOriginatorGuid) return false;
    // if the line is from me to other or from other to other, don't connect lower.
    // we only want lines ending at messages to me to connect downwards (this
    // helps simplify some things and prevent rendering mistakes)
    if (getLineType(olderMessage, threadOriginator) == LineType.meToOther ||
        getLineType(olderMessage, threadOriginator) == LineType.otherToOther) return false;
    // if the lower message isn't from me, then draw the connecting line
    // (if the message is from me, that message will draw a connecting line up
    // rather than this message drawing one downwards).
    return isFromMe != newerMessage.isFromMe;
  }

  String replyPart(int part) {
    Run run = attributedBody[0].runs.firstWhere((run) => run.attributes?.messagePart == part);
    return "$part:${run.range[0]}:${run.range[1]}";
  }

  int get normalizedThreadPart =>
      int.tryParse(threadOriginatorPart?.split(':').first ?? '') ?? 0;

  bool connectToUpper() => threadOriginatorGuid != null;

  bool showUpperMessage(Message olderMessage) {
    // find the part count of the older message
    final olderPartCount = getActiveMwc(olderMessage.guid!)?.parts.length ?? 1;
    // make sure the older message is none of the following:
    // 1) thread originator
    // 2) part of the thread with the same thread partIndex
    // OR
    // 1) It is the thread originator but the part is not the last part of the older message
    // 2) It is part of the thread but has multiple parts
    return (olderMessage.guid != threadOriginatorGuid && (olderMessage.threadOriginatorGuid != threadOriginatorGuid || olderMessage.normalizedThreadPart != normalizedThreadPart))
        || (olderMessage.guid == threadOriginatorGuid && normalizedThreadPart != olderPartCount - 1)
        || (olderMessage.threadOriginatorGuid == threadOriginatorGuid && olderPartCount > 1);
  }

  bool connectToLower(Message newerMessage) {
    final thisPartCount = getActiveMwc(guid!)?.parts.length ?? 1;
    if (newerMessage.isFromMe != isFromMe) return false;
    if (newerMessage.normalizedThreadPart != thisPartCount - 1) return false;
    if (threadOriginatorGuid != null) {
      return newerMessage.threadOriginatorGuid == threadOriginatorGuid;
    } else {
      return newerMessage.threadOriginatorGuid == guid;
    }
  }

  /// Get whether the reply line from the message should connect to the message above
  bool shouldConnectUpper(Message? olderMessage, Message threadOriginator) {
    // if theres no older message, or it isn't a part of the thread (make sure
    // to check that it isn't actually an outlined bubble representing the
    // thread originator), don't connect
    if (olderMessage == null ||
        (olderMessage.threadOriginatorGuid != threadOriginatorGuid && !upperIsThreadOriginatorBubble(olderMessage))) {
      return false;
    }
    // if the older message is the outlined bubble, or the originator is from
    // someone else and the message is from me, then draw the connecting line
    // (the second condition might be redundant / unnecessary but I left it in
    // just in case)
    if (upperIsThreadOriginatorBubble(olderMessage) ||
        (!threadOriginator.isFromMe! && isFromMe!) ||
        getLineType(olderMessage, threadOriginator) == LineType.meToMe ||
        getLineType(olderMessage, threadOriginator) == LineType.otherToMe) return true;
    // if the upper message is from me, then draw the connecting line
    // (if the message is not from me, that message will draw a connecting line
    // down rather than this message drawing one upwards).
    return isFromMe == olderMessage.isFromMe;
  }

  /// Get whether the upper bubble is actually the thread originator as the
  /// outlined bubble
  bool upperIsThreadOriginatorBubble(Message? olderMessage) {
    return olderMessage?.threadOriginatorGuid != threadOriginatorGuid;
  }

  /// Calculate the size of the message bubble by calculating text size or
  /// attachment size
  Size getBubbleSize(BuildContext context,
      {double? maxWidthOverride, double? minHeightOverride, String? textOverride}) {
    // cache this value because the calculation can be expensive
    if (MessagesService.cachedBubbleSizes[guid!] != null) return MessagesService.cachedBubbleSizes[guid!]!;
    // if attachment, then grab width / height
    if (fullText.isEmpty && (attachments).isNotEmpty) {
      return Size(
          attachments
              .map((e) => e!.width)
              .fold(0, (p, e) => max(p, (e ?? ns.width(context) / 2).toDouble()) + 28),
          attachments
              .map((e) => e!.height)
              .fold(0, (p, e) => max(p, (e ?? ns.width(context) / 2).toDouble())));
    }
    // initialize constraints for text rendering
    final fontSizeFactor = isBigEmoji ? bigEmojiScaleFactor : 1.0;
    final constraints = BoxConstraints(
      maxWidth: maxWidthOverride ?? ns.width(context) * MessageWidgetController.maxBubbleSizeFactor - 30,
      minHeight: minHeightOverride ?? Theme.of(context).textTheme.bodySmall!.fontSize! * fontSizeFactor,
    );
    final renderParagraph = RichText(
      text: TextSpan(
        text: textOverride ?? fullText,
        style: context.theme.textTheme.bodySmall!.apply(color: Colors.white, fontSizeFactor: fontSizeFactor),
      ),
    ).createRenderObject(context);
    // get the text size
    Size size = renderParagraph.getDryLayout(constraints);
    // if the text is shorter than the full width, add 28 to account for the
    // container margins
    if (size.height < context.theme.textTheme.bodySmall!.fontSize! * 2 * fontSizeFactor ||
        (subject != null && size.height < context.theme.textTheme.bodySmall!.fontSize! * 3 * fontSizeFactor)) {
      size = Size(size.width + 28, size.height);
    }
    // if we have a URL preview, extend to the full width
    if (isLegacyUrlPreview) {
      size = Size(ns.width(context) * 2 / 3 - 30, size.height);
    }
    // if we have reactions, account for the extra height they add
    if (hasReactions) {
      size = Size(size.width, size.height + 25);
    }
    // add 16 to the height to account for container margins
    size = Size(size.width, size.height + 16);
    // cache the value
    MessagesService.cachedBubbleSizes[guid!] = size;
    return size;
  }

  static Message merge(Message existing, Message newMessage) {
    existing.id ??= newMessage.id;
    existing.guid ??= newMessage.guid;
  
    // Update date created
    if ((existing.dateCreated == null && newMessage.dateCreated != null) ||
        (existing.dateCreated != null &&
            newMessage.dateCreated != null &&
            existing.dateCreated!.millisecondsSinceEpoch < newMessage.dateCreated!.millisecondsSinceEpoch)) {
      existing.dateCreated = newMessage.dateCreated;
    }

    // Update date delivered
    if ((existing._dateDelivered.value == null && newMessage._dateDelivered.value != null) ||
        (existing._dateDelivered.value != null &&
            newMessage.dateDelivered != null &&
            existing._dateDelivered.value!.millisecondsSinceEpoch <
                newMessage._dateDelivered.value!.millisecondsSinceEpoch)) {
      existing._dateDelivered.value = newMessage.dateDelivered;
    }

    // Update is delivered
    if (existing._isDelivered.value != newMessage._isDelivered.value) {
      existing._isDelivered.value = newMessage._isDelivered.value;
    }

    // Update date read
    if ((existing._dateRead.value == null && newMessage._dateRead.value != null) ||
        (existing._dateRead.value != null &&
            newMessage._dateRead.value != null &&
            existing._dateRead.value!.millisecondsSinceEpoch < newMessage._dateRead.value!.millisecondsSinceEpoch)) {
      existing._dateRead.value = newMessage.dateRead;
    }

    // Update date played
    if ((existing.datePlayed == null && newMessage.datePlayed != null) ||
        (existing.datePlayed != null &&
            newMessage.datePlayed != null &&
            existing.datePlayed!.millisecondsSinceEpoch < newMessage.datePlayed!.millisecondsSinceEpoch)) {
      existing.datePlayed = newMessage.datePlayed;
    }

    // Update date deleted
    if ((existing.dateDeleted == null && newMessage.dateDeleted != null) ||
        (existing.dateDeleted != null &&
            newMessage.dateDeleted != null &&
            existing.dateDeleted!.millisecondsSinceEpoch < newMessage.dateDeleted!.millisecondsSinceEpoch)) {
      existing.dateDeleted = newMessage.dateDeleted;
    }

    // Update date edited (and attr body & message summary info)
    if ((existing.dateEdited == null && newMessage.dateEdited != null) ||
        (existing.dateEdited != null &&
            newMessage.dateEdited != null &&
            existing.dateEdited!.millisecondsSinceEpoch < newMessage.dateEdited!.millisecondsSinceEpoch)) {
      existing.dateEdited = newMessage.dateEdited;
      if (!isNullOrEmpty(newMessage.attributedBody)) {
        existing.attributedBody = newMessage.attributedBody;
      }
      if (!isNullOrEmpty(newMessage.messageSummaryInfo)) {
        existing.messageSummaryInfo = newMessage.messageSummaryInfo;
      }
    }

    // Update error
    if (existing._error.value != newMessage._error.value) {
      existing._error.value = newMessage._error.value;
    }

    // Update has Dd results
    if ((existing.hasDdResults == null && newMessage.hasDdResults != null) ||
        (!existing.hasDdResults! && newMessage.hasDdResults!)) {
      existing.hasDdResults = newMessage.hasDdResults;
    }

    // Update metadata
    existing.metadata = mergeTopLevelDicts(existing.metadata, newMessage.metadata);

    // Update original ROWID
    if (existing.originalROWID == null && newMessage.originalROWID != null) {
      existing.originalROWID = newMessage.originalROWID;
    }

    // Update attachments flag
    if (!existing.hasAttachments && newMessage.hasAttachments) {
      existing.hasAttachments = newMessage.hasAttachments;
    }

    // Update has reactions flag
    if (!existing.hasReactions && newMessage.hasReactions) {
      existing.hasReactions = newMessage.hasReactions;
    }

    // Update chat
    if (!existing.chat.hasValue && newMessage.chat.hasValue) {
      existing.chat.target = newMessage.chat.target;
    }

    // Update handle
    if (existing.handle?.id == null && newMessage.handle?.id != null) {
      existing.handle = newMessage.handle;
    }

    // Update attachments
    if (existing.dbAttachments.isEmpty && newMessage.dbAttachments.isNotEmpty) {
      existing.dbAttachments.addAll(newMessage.dbAttachments);
    }

    if (existing.payloadData == null && newMessage.payloadData != null) {
      existing.payloadData = newMessage.payloadData;
    }

    if (!existing.wasDeliveredQuietly && newMessage.wasDeliveredQuietly) {
      existing.wasDeliveredQuietly = newMessage.wasDeliveredQuietly;
    }

    if (!existing.didNotifyRecipient && newMessage.didNotifyRecipient) {
      existing.didNotifyRecipient = newMessage.didNotifyRecipient;
    }

    existing.isBookmarked = newMessage.isBookmarked;

    existing.hasBeenForwarded = newMessage.hasBeenForwarded;
    newMessage.stagingGuid = existing.stagingGuid;
    newMessage.verificationFailed = existing.verificationFailed;
    newMessage.amkSessionId = existing.amkSessionId;
    newMessage.dateScheduled = existing.dateScheduled;

    return existing;
  }

  String getLastUpdate() {
    if (dateEdited != null) {
      return "Edited at $dateEdited";
    } else if (datePlayed != null) {
      return "Played at $datePlayed";
    } else if (dateRead != null) {
      return "Read at $dateRead";
    } else if (dateDelivered != null) {
      return "Delivered at $dateDelivered";
    } else if (isDelivered) {
      return "Delivered";
    } else {
      return "Sent at $dateCreated";
    }
  }

  bool isNewerThan(Message other) {
    // If the other message has an error, we want to show that.
    if (error == 0 && other.error != 0) return false;

    // Check null dates in order of what should be filled in first -> last
    if (dateCreated == null && other.dateCreated != null) return false;
    if (dateCreated != null && other.dateCreated == null) return true;
    if (!isDelivered && other.isDelivered) return false;
    if (isDelivered && !other.isDelivered) return true;
    if (dateDelivered == null && other.dateDelivered != null) return false;
    if (dateDelivered != null && other.dateDelivered == null) return true;
    if (dateRead == null && other.dateRead != null) return false;
    if (dateRead != null && other.dateRead == null) return true;
    if (datePlayed == null && other.datePlayed != null) return false;
    if (datePlayed != null && other.datePlayed == null) return true;
    if (dateEdited == null && other.dateEdited != null) return false;
    if (dateEdited != null && other.dateEdited == null) return true;

    // Once we verify that all aren't null, we can start comparing dates.
    // Compare the dates in the opposite order of what should be filled in last -> first
    if (dateEdited != null && other.dateEdited != null) {
      return dateEdited!.millisecondsSinceEpoch > other.dateEdited!.millisecondsSinceEpoch;
    } else if (datePlayed != null && other.datePlayed != null) {
      return datePlayed!.millisecondsSinceEpoch > other.datePlayed!.millisecondsSinceEpoch;
    } else if (dateRead != null && other.dateRead != null) {
      return dateRead!.millisecondsSinceEpoch > other.dateRead!.millisecondsSinceEpoch;
    } else if (dateDelivered != null && other.dateDelivered != null) {
      return dateDelivered!.millisecondsSinceEpoch > other.dateDelivered!.millisecondsSinceEpoch;
    } else if (dateCreated != null && other.dateCreated != null) {
      return dateCreated!.millisecondsSinceEpoch > other.dateCreated!.millisecondsSinceEpoch;
    }

    return false;
  }

  Map<String, dynamic> toMap({bool includeObjects = false}) {
    final map = {
      "ROWID": id,
      "originalROWID": originalROWID,
      "guid": guid,
      "handleId": handleId,
      "otherHandle": otherHandle,
      "text": sanitizeString(text),
      "subject": subject,
      "country": country,
      "_error": _error.value,
      "dateCreated": dateCreated?.millisecondsSinceEpoch,
      "dateRead": _dateRead.value?.millisecondsSinceEpoch,
      "dateDelivered":  _dateDelivered.value?.millisecondsSinceEpoch,
      "isDelivered": _isDelivered.value,
      "isFromMe": isFromMe!,
      "hasDdResults": hasDdResults!,
      "datePlayed": datePlayed?.millisecondsSinceEpoch,
      "itemType": itemType,
      "groupTitle": groupTitle,
      "groupActionType": groupActionType,
      "balloonBundleId": balloonBundleId,
      "associatedMessageGuid": associatedMessageGuid,
      "associatedMessagePart": associatedMessagePart,
      "associatedMessageType": associatedMessageType,
      "expressiveSendStyleId": expressiveSendStyleId,
      "handle": handle?.toMap(includeObjects: true),
      "hasAttachments": hasAttachments,
      "hasReactions": hasReactions,
      "dateDeleted": dateDeleted?.millisecondsSinceEpoch,
      "metadata": jsonEncode(metadata),
      "threadOriginatorGuid": threadOriginatorGuid,
      "threadOriginatorPart": threadOriginatorPart,
      "hasApplePayloadData": hasApplePayloadData,
      "dateEdited": dateEdited?.millisecondsSinceEpoch,
      "wasDeliveredQuietly": wasDeliveredQuietly,
      "didNotifyRecipient": didNotifyRecipient,
      "isBookmarked": isBookmarked,
      "hasBeenForwarded": hasBeenForwarded,
      "stagingGuid": stagingGuid,
      "verificationFailed": verificationFailed,
      "amkSessionId": amkSessionId,
      "sendingServiceId": sendingServiceId,
      "associatedMessageEmoji": associatedMessageEmoji,
      "dateScheduled": dateScheduled?.millisecondsSinceEpoch,
      "ckRecordId": ckRecordId
    };
    if (includeObjects) {
      map['attachments'] = (attachments).map((e) => e!.toMap()).toList();
      map['handle'] = handle?.toMap();
      map['attributedBody'] = attributedBody.map((e) => e.toMap()).toList();
      map['messageSummaryInfo'] = messageSummaryInfo.map((e) => e.toJson()).toList();
      map['payloadData'] = payloadData?.toJson();
    }
    return map;
  }
}
