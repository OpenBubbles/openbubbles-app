import 'dart:async';
import 'dart:convert';

import 'package:async_task/async_task.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:mime_type/mime_type.dart';
// (needed when generating objectbox model code)
// ignore: unnecessary_import
import 'package:objectbox/objectbox.dart';
import 'package:supercharged/supercharged.dart';
import 'package:tuple/tuple.dart';
import 'package:universal_io/io.dart';

/// Async method to get attachments from objectbox
class GetChatAttachments extends AsyncTask<List<dynamic>, List<Attachment>> {
  final List<dynamic> stuff;

  GetChatAttachments(this.stuff);

  @override
  AsyncTask<List<dynamic>, List<Attachment>> instantiate(List<dynamic> parameters,
      [Map<String, SharedData>? sharedData]) {
    return GetChatAttachments(parameters);
  }

  @override
  List<dynamic> parameters() {
    return stuff;
  }

  @override
  FutureOr<List<Attachment>> run() {
    int chatId = stuff[0];
    bool includeDeleted = stuff[1];
    return Database.runInTransaction(TxMode.read, () {
      final query = (Database.messages.query(
              includeDeleted
                  ? Message_.dateCreated.notNull().and(
                      Message_.dateDeleted.isNull().or(Message_.dateDeleted.notNull()))
                  : Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull()))
            ..link(Message_.chat, Chat_.id.equals(chatId))
            ..order(Message_.dateCreated, flags: Order.descending))
          .build();
      final messages = query.find();
      query.close();

      final actualAttachments = <Attachment>[];

      for (Message m in messages) {
        m.attachments = List<Attachment>.from(
            m.dbAttachments.where((element) => element.mimeType != null));
        actualAttachments.addAll((m.attachments).map((e) => e!));
      }

      if (actualAttachments.isNotEmpty) {
        final guids = actualAttachments.map((e) => e.guid).toSet();
        actualAttachments.retainWhere((element) => guids.remove(element.guid));
      }
      return actualAttachments;
    });
  }
}

/// Async method to get messages from objectbox
class GetMessages extends AsyncTask<List<dynamic>, List<Message>> {
  final List<dynamic> stuff;

  GetMessages(this.stuff);

  @override
  AsyncTask<List<dynamic>, List<Message>> instantiate(
      List<dynamic> parameters, [Map<String, SharedData>? sharedData]) {
    return GetMessages(parameters);
  }

  @override
  List<dynamic> parameters() {
    return stuff;
  }

  @override
  FutureOr<List<Message>> run() {
    int chatId = stuff[0];
    int offset = stuff[1];
    int limit = stuff[2];
    bool includeDeleted = stuff[3];
    int? searchAround = stuff[4];
    return Database.runInTransaction(TxMode.read, () {
      final messages = <Message>[];
      if (searchAround == null) {
        final query = (Database.messages.query(
                includeDeleted
                    ? Message_.dateCreated
                        .notNull()
                        .and(Message_.dateDeleted.isNull().or(Message_.dateDeleted.notNull()))
                    : Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull()))
              ..link(Message_.chat, Chat_.id.equals(chatId))
              ..order(Message_.dateCreated, flags: Order.descending))
            .build();
        query
          ..limit = limit
          ..offset = offset;
        messages.addAll(query.find());
        query.close();
      } else {
        final beforeQuery = (Database.messages.query(
                Message_.dateCreated.lessThan(searchAround).and(includeDeleted
                    ? Message_.dateCreated.notNull().and(
                        Message_.dateDeleted.isNull().or(Message_.dateDeleted.notNull()))
                    : Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull())))
              ..link(Message_.chat, Chat_.id.equals(chatId))
              ..order(Message_.dateCreated, flags: Order.descending))
            .build();
        beforeQuery.limit = limit;
        final before = beforeQuery.find();
        beforeQuery.close();
        final afterQuery = (Database.messages.query(
                Message_.dateCreated.greaterThan(searchAround).and(includeDeleted
                    ? Message_.dateCreated.notNull().and(
                        Message_.dateDeleted.isNull().or(Message_.dateDeleted.notNull()))
                    : Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull())))
              ..link(Message_.chat, Chat_.id.equals(chatId))
              ..order(Message_.dateCreated))
            .build();
        afterQuery.limit = limit;
        final after = afterQuery.find();
        afterQuery.close();
        messages..addAll(before)..addAll(after);
      }

      final chat = Database.chats.get(chatId);
      for (int i = 0; i < messages.length; i++) {
        Message message = messages[i];
        if (chat!.participants.isNotEmpty &&
            !message.isFromMe! &&
            message.handleId != null &&
            message.handleId != 0) {
          Handle? handle = chat.participants.firstWhereOrNull(
                  (e) => e.originalROWID == message.handleId) ??
              message.getHandle();
          if (handle == null && message.originalROWID != null) {
            messages.remove(message);
            i--;
          } else {
            message.handle = handle;
          }
        }
      }
      final messageGuids = messages.map((e) => e.guid!).toList();
      final associatedMessagesQuery =
          (Database.messages.query(Message_.associatedMessageGuid.oneOf(messageGuids))
                ..order(Message_.originalROWID))
              .build();
      List<Message> associatedMessages = associatedMessagesQuery.find();
      associatedMessagesQuery.close();
      associatedMessages = MessageHelper.normalizedAssociatedMessages(associatedMessages);
      for (Message m in associatedMessages) {
        if (m.associatedMessageType != "sticker") continue;
        m.attachments = List<Attachment>.from(m.dbAttachments);
      }
      for (Message m in messages) {
        m.attachments = List<Attachment>.from(m.dbAttachments);
        m.associatedMessages =
            associatedMessages.where((e) => e.associatedMessageGuid == m.guid).toList();
      }
      return messages;
    });
  }
}

/// Async method to add messages to objectbox
class AddMessages extends AsyncTask<List<dynamic>, List<Message>> {
  final List<dynamic> stuff;

  AddMessages(this.stuff);

  @override
  AsyncTask<List<dynamic>, List<Message>> instantiate(
      List<dynamic> parameters, [Map<String, SharedData>? sharedData]) {
    return AddMessages(parameters);
  }

  @override
  List<dynamic> parameters() {
    return stuff;
  }

  @override
  FutureOr<List<Message>> run() {
    List<Message> messages =
        stuff[0].map((e) => Message.fromMap(e)).toList().cast<Message>();

    final newMessages = Database.runInTransaction(TxMode.write, () {
      List<Message> newMessages = Message.bulkSave(messages);
      Attachment.bulkSave(Map.fromIterables(
          newMessages, newMessages.map((e) => (e.attachments).map((e) => e!).toList())));
      return newMessages;
    });

    return Database.runInTransaction(TxMode.read, () {
      final messageGuids = newMessages.map((e) => e.guid!).toList();

      final associatedMessagesQuery =
          (Database.messages.query(Message_.associatedMessageGuid.oneOf(messageGuids))
                ..order(Message_.originalROWID))
              .build();
      List<Message> associatedMessages = associatedMessagesQuery.find();
      associatedMessagesQuery.close();
      associatedMessages = MessageHelper.normalizedAssociatedMessages(associatedMessages);

      for (Message m in associatedMessages) {
        if (m.associatedMessageType != "sticker") continue;
        m.attachments = List<Attachment>.from(m.dbAttachments);
      }
      for (Message m in newMessages) {
        m.attachments = List<Attachment>.from(m.dbAttachments);
        m.associatedMessages =
            associatedMessages.where((e) => e.associatedMessageGuid == m.guid).toList();
      }
      return newMessages;
    });
  }
}

/// Async method to get chats from objectbox
class GetChats extends AsyncTask<List<dynamic>, List<Chat>> {
  final List<dynamic> stuff;

  GetChats(this.stuff);

  @override
  AsyncTask<List<dynamic>, List<Chat>> instantiate(
      List<dynamic> parameters, [Map<String, SharedData>? sharedData]) {
    return GetChats(parameters);
  }

  @override
  List<dynamic> parameters() {
    return stuff;
  }

  @override
  FutureOr<List<Chat>> run() {
    return Database.runInTransaction(TxMode.write, () {
      late final QueryBuilder<Chat> queryBuilder;

      if (stuff.length >= 3 && stuff[2] != null && stuff[2] is List) {
        queryBuilder = Database.chats.query(Chat_.id.oneOf(stuff[2] as List<int>));
      } else {
        queryBuilder = Database.chats.query(Chat_.dateDeleted.isNull());
      }

      Query<Chat> query = (queryBuilder
            ..order(Chat_.isPinned, flags: Order.descending)
            ..order(Chat_.dbOnlyLatestMessageDate, flags: Order.descending))
          .build()
        ..limit = stuff[0]
        ..offset = stuff[1];

      final chatsList = query.find();
      query.close();

      for (Chat c in chatsList) {
        c._participants = List<Handle>.from(c.handles);
        c._deduplicateParticipants();
        c.title = c.getTitle();
      }
      return chatsList;
    });
  }
}

@Entity()
class Chat {
  int? id;

  @Index(type: IndexType.value)
  @Unique()
  String guid;

  String? chatIdentifier;
  bool? isArchived;
  String? muteType;
  String? muteArgs;
  bool? isPinned;
  bool? hasUnreadMessage;
  // Added property to track if the chat is whitelisted (i.e. no longer unknown)
  bool isWhitelisted;
  String? title;
  String? apnTitle;
  String get properTitle {
    if (ss.settings.redactedMode.value && ss.settings.hideContactInfo.value) {
      return getTitle();
    }
    title ??= getTitle();
    return title!;
  }
  String? displayName;
  List<Handle> _participants = [];
  List<Handle> get participants {
    if (_participants.isEmpty) {
      getParticipants();
    }
    return _participants;
  }
  bool? autoSendReadReceipts;
  bool? autoSendTypingIndicators;
  String? textFieldText;
  String? textFieldAnnotations;
  List<String> textFieldAttachments = [];
  Message? _latestMessage;
  Message get latestMessage {
    if (_latestMessage != null) return _latestMessage!;
    _latestMessage = Chat.getMessages(this, limit: 1, getDetails: true).firstOrNull ??
        Message(
          dateCreated: DateTime.fromMillisecondsSinceEpoch(0),
          guid: guid,
        );
    return _latestMessage!;
  }
  Message get dbLatestMessage {
    _latestMessage = Chat.getMessages(this, limit: 1, getDetails: true).firstOrNull ??
        Message(
          dateCreated: DateTime.fromMillisecondsSinceEpoch(0),
          guid: guid,
        );
    return _latestMessage!;
  }
  set latestMessage(Message m) => _latestMessage = m;
  @Property(uid: 526293286661780207)
  DateTime? dbOnlyLatestMessageDate;
  DateTime? dateDeleted;
  int? style;
  bool lockChatName;
  bool lockChatIcon;
  String? lastReadMessageGuid;
  int? groupVersion;

  Message get sendLastMessage {
    var messages = Chat.getMessages(this, limit: 10, getDetails: true);
    return messages.firstWhereOrNull((msg) =>
            msg.stagingGuid != null ||
            (msg.guid != null &&
                !msg.guid!.contains("temp") &&
                !msg.guid!.contains("error"))) ??
        Message(
          dateCreated: DateTime.fromMillisecondsSinceEpoch(0),
          guid: guid,
        );
  }

  final RxnString _customAvatarPath = RxnString();
  String? get customAvatarPath => _customAvatarPath.value;
  set customAvatarPath(String? s) => _customAvatarPath.value = s;

  final RxnInt _pinIndex = RxnInt();
  int? get pinIndex => _pinIndex.value;
  set pinIndex(int? i) => _pinIndex.value = i;

  @Transient()
  RxDouble sendProgress = 0.0.obs;

  void handlesChanged() {
    var cachedChat = cvc(this).chat;
    cachedChat.handles = handles;
    cachedChat._participants = [];
  }

  List<String> guidRefs = [];
  var handles = ToMany<Handle>();

  String? usingHandle;
  bool isRpSms;
  int? telephonyId;

  @Backlink('chat')
  final messages = ToMany<Message>();

  Chat({
    this.id,
    required this.guid,
    this.chatIdentifier,
    this.isArchived = false,
    this.isPinned = false,
    this.muteType,
    this.muteArgs,
    this.hasUnreadMessage = false,
    this.isWhitelisted = false,
    this.displayName,
    String? customAvatar,
    int? pinnedIndex,
    List<Handle>? participants,
    Message? latestMessage,
    this.autoSendReadReceipts,
    this.autoSendTypingIndicators,
    this.textFieldText,
    this.textFieldAnnotations,
    this.textFieldAttachments = const [],
    this.dateDeleted,
    this.style,
    this.lockChatName = false,
    this.lockChatIcon = false,
    this.lastReadMessageGuid,
    this.usingHandle,
    this.isRpSms = false,
    this.telephonyId,
    List<String>? guidRefs,
  }) : isWhitelisted = false,
       guidRefs = guidRefs ?? [guid] {
    customAvatarPath = customAvatar;
    pinIndex = pinnedIndex;
    if (textFieldAttachments.isEmpty) textFieldAttachments = [];
    _participants = participants ?? [];
    _latestMessage = latestMessage;
  }

  factory Chat.fromMap(Map<String, dynamic> json) {
    final message = json['lastMessage'] != null
        ? Message.fromMap(json['lastMessage']!.cast<String, Object>())
        : null;
    return Chat(
      id: json["ROWID"] ?? json["id"],
      guid: json["guid"],
      chatIdentifier: json["chatIdentifier"],
      isArchived: json['isArchived'] ?? false,
      muteType: json["muteType"],
      muteArgs: json["muteArgs"],
      isPinned: json["isPinned"] ?? false,
      hasUnreadMessage: json["hasUnreadMessage"] ?? false,
      isWhitelisted: json["isWhitelisted"] ?? false,
      latestMessage: message,
      displayName: json["displayName"],
      customAvatar: json['_customAvatarPath'],
      pinnedIndex: json['_pinIndex'],
      participants: (json['participants'] as List? ?? [])
          .map((e) => Handle.fromMap(e!.cast<String, Object>()))
          .toList(),
      autoSendReadReceipts: json["autoSendReadReceipts"],
      autoSendTypingIndicators: json["autoSendTypingIndicators"],
      dateDeleted: parseDate(json["dateDeleted"]),
      style: json["style"],
      lockChatName: json["lockChatName"] ?? false,
      lockChatIcon: json["lockChatIcon"] ?? false,
      lastReadMessageGuid: json["lastReadMessageGuid"],
      usingHandle: json["usingHandle"],
      isRpSms: json["isRpSms"] ?? false,
      guidRefs: json["guidRefs"]?.cast<String>() ?? [],
      telephonyId: json["telephonyId"],
    );
  }

  Future<String> ensureHandle() async {
    if (usingHandle == null) {
      usingHandle = await (backend as RustPushBackend).getDefaultHandle();
      save(updateUsingHandle: true);
    }
    return usingHandle!;
  }

  void removeProfilePhoto() {
    try {
      File file = File(customAvatarPath!);
      file.delete();
    } catch (_) {}
    customAvatarPath = null;
  }

  Chat save({
    bool updateMuteType = false,
    bool updateMuteArgs = false,
    bool updateIsPinned = false,
    bool updatePinIndex = false,
    bool updateIsArchived = false,
    bool updateHasUnreadMessage = false,
    bool updateAutoSendReadReceipts = false,
    bool updateAutoSendTypingIndicators = false,
    bool updateCustomAvatarPath = false,
    bool updateTextFieldText = false,
    bool updateTextFieldAnnotations = false,
    bool updateTextFieldAttachments = false,
    bool updateDisplayName = false,
    bool updateDateDeleted = false,
    bool updateLockChatName = false,
    bool updateLockChatIcon = false,
    bool updateLastReadMessageGuid = false,
    bool updateGroupVersion = false,
    bool updateUsingHandle = false,
    bool updateIsSms = false,
    bool updateAPNTitle = false,
    bool updateGuidRefs = false,
    bool updateTelephonyId = false,
  }) {
    if (kIsWeb) return this;
    Database.runInTransaction(TxMode.write, () {
      Chat? existing = Chat.findOne(guid: guid);
      id = existing?.id ?? id;
      if (!updateMuteType) {
        muteType = existing?.muteType ?? muteType;
      }
      if (!updateMuteArgs) {
        muteArgs = existing?.muteArgs ?? muteArgs;
      }
      if (!updateIsPinned) {
        isPinned = existing?.isPinned ?? isPinned;
      }
      if (!updatePinIndex) {
        pinIndex = existing?.pinIndex ?? pinIndex;
      }
      if (!updateIsArchived) {
        isArchived = existing?.isArchived ?? isArchived;
      }
      if (!updateHasUnreadMessage) {
        hasUnreadMessage = existing?.hasUnreadMessage ?? hasUnreadMessage;
      }
      if (!updateAutoSendReadReceipts) {
        autoSendReadReceipts = existing?.autoSendReadReceipts;
      }
      if (!updateAutoSendTypingIndicators) {
        autoSendTypingIndicators = existing?.autoSendTypingIndicators;
      }
      if (!updateCustomAvatarPath) {
        customAvatarPath = existing?.customAvatarPath ?? customAvatarPath;
      }
      if (!updateTextFieldText) {
        textFieldText = existing?.textFieldText ?? textFieldText;
      }
      if (!updateTextFieldAnnotations) {
        textFieldAnnotations = existing?.textFieldAnnotations ?? textFieldAnnotations;
      }
      if (!updateAPNTitle) {
        apnTitle = existing?.apnTitle ?? apnTitle;
      }
      if (!updateTextFieldAttachments) {
        textFieldAttachments = existing?.textFieldAttachments ?? textFieldAttachments;
      }
      if (!updateDisplayName) {
        displayName = existing?.displayName ?? displayName;
      }
      if (!updateDateDeleted) {
        dateDeleted = existing?.dateDeleted;
      }
      if (!updateLockChatName) {
        lockChatName = existing?.lockChatName ?? false;
      }
      if (!updateLockChatIcon) {
        lockChatIcon = existing?.lockChatIcon ?? false;
      }
      if (!updateLastReadMessageGuid) {
        lastReadMessageGuid = existing?.lastReadMessageGuid ?? lastReadMessageGuid;
      }
      if (!updateGroupVersion) {
        groupVersion = existing?.groupVersion ?? groupVersion;
      }
      if (!updateUsingHandle) {
        usingHandle = existing?.usingHandle ?? usingHandle;
      }
      if (!updateIsSms) {
        isRpSms = existing?.isRpSms ?? isRpSms;
      }
      if (!updateGuidRefs) {
        guidRefs = existing?.guidRefs ?? guidRefs;
      }
      if (!updateTelephonyId) {
        telephonyId = existing?.telephonyId ?? telephonyId;
      }

      for (int i = 0; i < participants.length; i++) {
        participants[i] = participants[i].save();
        _deduplicateParticipants();
      }
      dbOnlyLatestMessageDate = dbLatestMessage.dateCreated!;
      try {
        id = Database.chats.put(this);
        if (existing == null && participants.isNotEmpty) {
          final toSave = Database.chats.get(id!);
          toSave!.handles.clear();
          toSave.handles.addAll(participants);
          toSave.handles.applyToDb();
        } else if (existing == null && participants.isEmpty) {
          cm.fetchChat(guid);
        }
      } on UniqueViolationException catch (_) {}
    });
    return this;
  }

  static Future<Chat> getChatForTel(int tid, List<String> participants) async {
    final query3 = Database.chats.query(Chat_.telephonyId.equals(tid).and(Chat_.dateDeleted.isNull())).build();
    final result4 = query3.findFirst();
    query3.close();
    if (result4 != null) return result4;

    final query = (Database.chats.query(Chat_.dateDeleted.isNull().and(Chat_.isRpSms.equals(true)))
          ..linkMany(Chat_.handles, Handle_.address.oneOf(participants)))
        .build();
    final results = query.find();
    query.close();

    var result = results.firstWhereOrNull((element) {
      var participantsCopy = [...participants];
      for (var handle in element.handles) {
        var included = participantsCopy.contains(handle.address);
        if (!included) {
          return false;
        }
        participantsCopy.remove(handle.address);
      }
      return participantsCopy.isEmpty;
    });
    if (result == null) {
      result = await backend.createChat(participants, null, "SMS");
      chats.updateChat(result);
    }
    result.telephonyId = tid;
    result.save(updateTelephonyId: true);
    return result;
  }

  Future<void> deliverSMS(String sender, List<Map<String, dynamic>> parts) async {
    if (!ss.settings.isSmsRouter.value) {
      return;
    }
    if (sender.isEmail) return;
    var handle = Handle.findOne(addressAndService: Tuple2(sender, "iMessage"));
    if (handle == null) {
      handle = Handle(address: sender);
      handle.save();
    }
    if (handle.originalROWID == null) {
      handle.originalROWID = handle.id!;
      handle.save();
    }
    for (var part in parts) {
      var partContent = part["body"] is Uint8List
          ? part["body"] as Uint8List
          : Uint8List.fromList(part["body"].cast<int>().toList());
      if (part["contentType"] == "text/plain") {
        var bodyString = utf8.decode(partContent);
        if (bodyString.trim() == "") continue;
        final _message = Message(
          text: bodyString,
          threadOriginatorPart: "0:0:0",
          dateCreated: DateTime.now(),
          hasAttachments: false,
          isFromMe: false,
          guid: part["id"] as String,
          handleId: 0,
          handle: handle,
          hasDdResults: true,
          attributedBody: [
            AttributedBody(
                string: bodyString,
                runs: [
                  Run(
                    range: [0, bodyString.length],
                    attributes: Attributes(messagePart: 0),
                  )
                ])
          ],
        );
        try {
          inq.queue(IncomingItem(
              chat: this,
              message: await backend.sendMessage(this, _message),
              type: QueueType.newMessage));
        } catch (e) {
          Logger.debug("Failed to forward sms! $e");
          inq.queue(IncomingItem(
              chat: this, message: _message, type: QueueType.newMessage));
        }
        if (!ls.isAlive) {
          await MessageHelper.handleNotification(_message, this, findExisting: false);
        }
      } else {
        var myUuid = "${part["id"]}_0";
        String data = await rootBundle.loadString("assets/rustpush/uti-map.json");
        final utiMap = jsonDecode(data);

        final _message = Message(
          text: " ",
          threadOriginatorPart: "0:0:0",
          dateCreated: DateTime.now(),
          hasAttachments: true,
          isFromMe: false,
          guid: part["id"] as String,
          handleId: 0,
          handle: handle,
          hasDdResults: true,
          attributedBody: [
            AttributedBody(
                string: " ",
                runs: [
                  Run(
                    range: [0, 1],
                    attributes: Attributes(
                        attachmentGuid: myUuid, messagePart: 0),
                  )
                ])
          ],
          attachments: [
            Attachment(
              guid: myUuid,
              uti: utiMap[part["contentType"] as String] ?? "public.data",
              mimeType: part["contentType"] as String,
              isOutgoing: false,
              bytes: partContent,
              totalBytes: partContent.length,
              transferName:
                  "${part["id"]}.${extensionFromMime(part["contentType"] as String) ?? "bin"}",
            )
          ],
        );
        await _message.attachments.first!.writeToDisk();
        try {
          var forwarded = await (backend as RustPushBackend)
              .forwardMMSAttachment(this, _message, _message.attachments.first!);
          inq.queue(IncomingItem(
              chat: this,
              message: forwarded,
              type: QueueType.newMessage));
        } catch (e) {
          Logger.debug("Failed to forward mms! $e");
          inq.queue(IncomingItem(
              chat: this, message: _message, type: QueueType.newMessage));
        }

        if (!ls.isAlive) {
          await MessageHelper.handleNotification(_message, this, findExisting: false);
        }
      }
    }
  }

  Future<api.ConversationData> getConversationData() async {
    var handles = participants.map((e) {
      if (e.address.isEmail) {
        return "mailto:${e.address}";
      } else {
        return "tel:${e.address}";
      }
    }).toList();
    handles.add(await ensureHandle());
    return api.ConversationData(
        participants: handles,
        cvName: apnTitle,
        senderGuid: guid,
        afterGuid: sendLastMessage.stagingGuid ?? sendLastMessage.guid);
  }

  Chat changeName(String? name) {
    if (kIsWeb) {
      displayName = name;
      return this;
    }
    displayName = name;
    save(updateDisplayName: true);
    return this;
  }

  String getTitle() {
    if (isNullOrEmpty(displayName)) {
      title = getChatCreatorSubtitle();
    } else {
      title = displayName;
    }
    return title!;
  }

  String getChatCreatorSubtitle() {
    List<String> titles = participants
        .map((e) => e.displayName.trim().split(
            isGroup && e.contact != null ? " " : String.fromCharCode(65532)).first)
        .toList();
    if (titles.isEmpty) {
      if (chatIdentifier != null) {
        if (chatIdentifier!.startsWith("urn:biz")) {
          return "Business Chat";
        }
        return chatIdentifier!;
      } else {
        return "Unnamed chat";
      }
    } else if (titles.length == 1) {
      return titles[0];
    } else if (titles.length <= 4) {
      final _title = titles.join(", ");
      int pos = _title.lastIndexOf(", ");
      if (pos != -1) {
        return "${_title.substring(0, pos)} & ${_title.substring(pos + 2)}";
      } else {
        return _title;
      }
    } else {
      final _title = titles.take(3).join(", ");
      return "$_title & ${titles.length - 3} others";
    }
  }

  /// Modified shouldMuteNotification: if the chat is an unknown sender but has been whitelisted (i.e. you've sent a message), then notifications will be allowed.
  bool shouldMuteNotification(Message? message) {
    if (ss.settings.filterUnknownSenders.value &&
        participants.length == 1 &&
        participants.first.contact == null &&
        !isWhitelisted) {
      return true;
    }

    if (ss.settings.globalTextDetection.value.isNotEmpty) {
      List<String> text = ss.settings.globalTextDetection.value.split(",");
      for (String s in text) {
        if (message?.text?.toLowerCase().contains(s.toLowerCase()) ?? false) {
          return false;
        }
      }
      return true;
    }

    if (muteType == "mute") {
      return true;
    }

    if (muteType == "mute_individuals") {
      List<String> individuals = muteArgs!.split(",");
      return individuals.contains(message?.handle?.address ?? "");
    }

    if (muteType == "temporary_mute") {
      DateTime time = DateTime.parse(muteArgs!);
      bool shouldMute = DateTime.now().toLocal().difference(time).inSeconds.isNegative;
      if (!shouldMute) {
        toggleMute(false);
      }
      return shouldMute;
    }

    if (muteType == "text_detection") {
      List<String> text = muteArgs!.split(",");
      for (String s in text) {
        if (message?.text?.toLowerCase().contains(s.toLowerCase()) ?? false) {
          return false;
        }
      }
      return true;
    }

    return !ss.settings.notifyReactions.value &&
        ReactionTypes.toList().contains(message?.associatedMessageType ?? "");
  }

  static void deleteChat(Chat chat) async {
    if (kIsWeb) return;
    if (cm.activeChat?.chat.guid == chat.guid) {
      ns.closeAllConversationView(Get.context!);
      await cm.setAllInactive();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    List<Message> messages = Chat.getMessages(chat);
    List<Attachment> attachments = await chat.getAttachmentsAsync();
    for (Attachment attachment in attachments) {
      try {
        File(attachment.getFile().path!).deleteSync();
      } catch (e) {
        Logger.debug("Failed to rm attachment $e");
      }
    }
    Database.runInTransaction(TxMode.write, () {
      Database.chats.remove(chat.id!);
      Database.messages.removeMany(messages.map((e) => e.id!).toList());
      Database.attachments.removeMany(attachments.map((e) => e.id!).toList());
    });
  }

  static void softDelete(Chat chat, {bool markDeleted = true}) async {
    if (kIsWeb) return;
    if (cm.activeChat?.chat.guid == chat.guid) {
      ns.closeAllConversationView(Get.context!);
      await cm.setAllInactive();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    Database.runInTransaction(TxMode.write, () {
      chat.dateDeleted = DateTime.now().toUtc();
      chat.hasUnreadMessage = false;
      chat.save(updateDateDeleted: true, updateHasUnreadMessage: true);
      chat.clearTranscript();
    });
    if (markDeleted) {
      await backend.moveToRecycleBin(chat, null);
    }
  }

  static void unDelete(Chat chat) async {
    if (kIsWeb) return;
    Database.runInTransaction(TxMode.write, () {
      chat.dateDeleted = null;
      chat.save(updateDateDeleted: true);
    });
  }

  Chat toggleHasUnread(bool hasUnread,
      {bool force = false,
      bool newOnMessage = false,
      bool clearLocalNotifications = true,
      bool privateMark = true}) {
    if (kIsDesktop && !hasUnread) {
      notif.clearDesktopNotificationsForChat(guid);
    }

    if (hasUnreadMessage == hasUnread && !force) return this;
    var changed = false;
    if (!cm.isChatActive(guid) || !hasUnread || force) {
      changed = Chat.findOne(guid: guid)!.hasUnreadMessage! != hasUnread || newOnMessage;
      hasUnreadMessage = hasUnread;
      save(updateHasUnreadMessage: true);
    }
    if (cm.isChatActive(guid) && hasUnread && !force) {
      hasUnread = false;
      clearLocalNotifications = false;
    }

    try {
      if (clearLocalNotifications && !hasUnread && !ls.isBubble) {
        mcs.invokeMethod("delete-notification", {
          "notification_id": id,
          "tag": NotificationsService.NEW_MESSAGE_TAG
        });
      }
      if (privateMark && changed) {
        if (!hasUnread) {
          backend.markRead(this, ss.settings.enablePrivateAPI.value && (autoSendReadReceipts ?? ss.settings.privateMarkChatAsRead.value));
        } else if (hasUnread) {
          backend.markUnread(this);
        }
      }
    } catch (_) {}

    return this;
  }

  Future<Chat> addMessage(Message message,
      {bool changeUnreadStatus = true,
      bool checkForMessageText = true,
      bool clearNotificationsIfFromMe = true}) async {
    if (message.fullText.replaceAll("\n", " ").hasUrl &&
        !MetadataHelper.mapIsNotEmpty(message.metadata) &&
        !message.hasApplePayloadData) {
      MetadataHelper.fetchMetadata(message).then((Metadata? meta) async {
        if (!MetadataHelper.isNotEmpty(meta)) return;
        message.metadata = meta!.toJson();
      });
    }

    Message? latest = latestMessage;
    Message? newMessage;

    try {
      newMessage = message.save(chat: this);
    } catch (ex, stacktrace) {
      newMessage = Message.findOne(guid: message.guid);
      if (newMessage == null) {
        Logger.error("Failed to add message (GUID: ${message.guid}) to chat (GUID: $guid)",
            error: ex, trace: stacktrace);
      }
    }
    for (Attachment? attachment in message.attachments) {
      attachment!.save(newMessage);
    }
    bool isNewer = false;

    if ((newMessage?.id != null || kIsWeb) && checkForMessageText) {
      isNewer = message.dateCreated!.isAfter(latest.dateCreated!) ||
          (message.guid != latest.guid && message.dateCreated == latest.dateCreated);
      if (isNewer) {
        _latestMessage = message;
        if (dateDeleted != null) {
          dateDeleted = null;
          save(updateDateDeleted: true);
          await chats.addChat(this);
        }
        if (isArchived! &&
            !_latestMessage!.isFromMe! &&
            ss.settings.unarchiveOnNewMessage.value) {
          toggleArchived(false);
        }
      }
    }

    save();

    if (checkForMessageText && changeUnreadStatus && isNewer) {
      if (message.isFromMe! || cm.isChatActive(guid)) {
        toggleHasUnread(
          false,
          clearLocalNotifications: clearNotificationsIfFromMe,
          force: cm.isChatActive(guid),
          privateMark: cm.isChatActive(guid),
          newOnMessage: !message.isFromMe!,
        );
      } else if (!cm.isChatActive(guid)) {
        toggleHasUnread(true, privateMark: false);
      }
    }

    if (message.isParticipantEvent && checkForMessageText) {
      serverSyncParticipants();
    }

    return this;
  }

  void serverSyncParticipants() async {
    final chat = await cm.fetchChat(guid);
    if (chat != null) {
      chat.save();
    }
  }

  static int? count() {
    return Database.chats.count();
  }

  Future<List<Attachment>> getAttachmentsAsync({bool fetchDeleted = false}) async {
    if (kIsWeb || id == null) return [];
    final task = GetChatAttachments([id!, fetchDeleted]);
    return (await createAsyncTask<List<Attachment>>(task)) ?? [];
  }

  static List<Message> getMessages(Chat chat,
      {int offset = 0, int limit = 25, bool includeDeleted = false, bool getDetails = false}) {
    if (kIsWeb || chat.id == null) return [];
    return Database.runInTransaction(TxMode.read, () {
      final query = (Database.messages.query(
              includeDeleted
                  ? Message_.dateCreated
                      .notNull()
                      .and(Message_.dateDeleted.isNull().or(Message_.dateDeleted.notNull()))
                  : Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull()))
            ..link(Message_.chat, Chat_.id.equals(chat.id!))
            ..order(Message_.dateCreated, flags: Order.descending))
          .build();
      query
        ..limit = limit
        ..offset = offset;
      final messages = query.find();
      query.close();
      for (int i = 0; i < messages.length; i++) {
        Message message = messages[i];
        if (chat.participants.isNotEmpty &&
            !message.isFromMe! &&
            message.handleId != null &&
            message.handleId != 0) {
          Handle? handle = chat.participants.firstWhereOrNull((e) => e.originalROWID == message.handleId) ??
              message.getHandle();
          if (handle == null) {
            messages.remove(message);
            i--;
          } else {
            message.handle = handle;
          }
        }
      }
      if (getDetails) {
        final messageGuids = messages.map((e) => e.guid!).toList();
        final associatedMessagesQuery = (Database.messages.query(
              Message_.associatedMessageGuid.oneOf(messageGuids))
            ..order(Message_.originalROWID))
            .build();
        List<Message> associatedMessages = associatedMessagesQuery.find();
        associatedMessagesQuery.close();
        associatedMessages = MessageHelper.normalizedAssociatedMessages(associatedMessages);
        for (Message m in messages) {
          m.attachments = List<Attachment>.from(m.dbAttachments);
          m.associatedMessages =
              associatedMessages.where((e) => e.associatedMessageGuid == m.guid).toList();
        }
      }
      return messages;
    });
  }

  static Future<List<Message>> getMessagesAsync(Chat chat,
      {int offset = 0, int limit = 25, bool includeDeleted = false, int? searchAround}) async {
    if (kIsWeb || chat.id == null) return [];
    final task = GetMessages([chat.id, offset, limit, includeDeleted, searchAround]);
    return (await createAsyncTask<List<Message>>(task)) ?? [];
  }

  Chat getParticipants() {
    if (kIsWeb || id == null) return this;
    Database.runInTransaction(TxMode.read, () {
      _participants = List<Handle>.from(handles);
    });
    _deduplicateParticipants();
    return this;
  }

  void webSyncParticipants() {}

  void _deduplicateParticipants() {
    if (_participants.isEmpty) return;
    final ids = _participants.map((e) => e.uniqueAddressAndService).toSet();
    _participants.retainWhere((element) => ids.remove(element.uniqueAddressAndService));
  }

  Chat togglePin(bool isPinned) {
    if (id == null) return this;
    this.isPinned = isPinned;
    _pinIndex.value = null;
    save(updateIsPinned: true, updatePinIndex: true);
    chats.updateChat(this);
    chats.sort();
    return this;
  }

  Chat toggleMute(bool isMuted) {
    if (id == null) return this;
    muteType = isMuted ? "mute" : null;
    muteArgs = null;
    save(updateMuteType: true, updateMuteArgs: true);
    return this;
  }

  Chat toggleArchived(bool isArchived) {
    if (id == null) return this;
    isPinned = false;
    this.isArchived = isArchived;
    save(updateIsPinned: true, updateIsArchived: true);
    chats.updateChat(this);
    chats.sort();
    return this;
  }

  Chat toggleAutoRead(bool? autoSendReadReceipts) {
    if (id == null) return this;
    this.autoSendReadReceipts = autoSendReadReceipts;
    save(updateAutoSendReadReceipts: true);
    backend.markRead(this, autoSendReadReceipts ?? ss.settings.privateMarkChatAsRead.value);
    return this;
  }

  Chat toggleAutoType(bool? autoSendTypingIndicators) {
    if (id == null) return this;
    this.autoSendTypingIndicators = autoSendTypingIndicators;
    save(updateAutoSendTypingIndicators: true);
    if (!(autoSendTypingIndicators ?? ss.settings.privateSendTypingIndicators.value)) {
      backend.stoppedTyping(this);
    }
    return this;
  }

  static Future<Chat?> findOneWeb({String? guid, String? chatIdentifier}) async {
    return null;
  }

  static Future<Chat?> findByRust(api.ConversationData data, String service, {bool soft = false}) async {
    if (data.participants.isEmpty) {
      throw Exception("empty participants!??");
    }

    if (data.senderGuid != null) {
      final direct = Chat.findOne(guid: data.senderGuid);
      if (direct != null) return direct;

      final query = Database.chats.query(Chat_.guidRefs.containsElement(data.senderGuid!)).build();
      final results = query.find();
      query.close();
      if (results.isNotEmpty) {
        return results[0];
      }
    }

    var (mine, dartParticipants) = await RustPushBBUtils.rustParticipantsToBB(data.participants);

    final name = data.cvName;

    var cond = name != null ? Chat_.apnTitle.equals(name) : null;
    final query = (Database.chats.query(cond)
          ..linkMany(Chat_.handles, Handle_.address.oneOf(
              dartParticipants.map((e) => e.address).toList())))
        .build();
    final results = query.find();
    query.close();

    var result = results.firstWhereOrNull((element) {
      var participantsCopy = [...dartParticipants];
      for (var handle in element.handles) {
        var included = participantsCopy.contains(handle);
        if (!included) {
          return false;
        }
        participantsCopy.remove(handle);
      }
      return participantsCopy.isEmpty;
    });
    if (result == null && !soft) {
      result = await backend.createChat(
          dartParticipants.map((e) => e.address).toList(), null, service,
          existingGuid: data.senderGuid);
      result.displayName = data.cvName;
      result.apnTitle = data.cvName;
      if (mine.isNotEmpty) result.usingHandle = mine[0];
      result = result.save();
      chats.updateChat(result);
    }
    return result;
  }

  static Chat? findOne({String? guid, String? chatIdentifier}) {
    if (guid != null) {
      final query = Database.chats.query(Chat_.guid.equals(guid)).build();
      final result = query.findFirst();
      query.close();
      return result;
    } else if (chatIdentifier != null) {
      final query = Database.chats.query(Chat_.chatIdentifier.equals(chatIdentifier)).build();
      final result = query.findFirst();
      query.close();
      return result;
    }
    return null;
  }

  static Future<List<Chat>> getChats({int limit = 15, int offset = 0, List<int> ids = const []}) async {
    if (kIsWeb) throw Exception("Use socket to get chats on Web!");
    final task = GetChats([limit, offset, ids.isEmpty ? null : ids]);
    return (await createAsyncTask<List<Chat>>(task)) ?? [];
  }

  static Future<List<Chat>> syncLatestMessages(List<Chat> chats, bool toggleUnread) async {
    if (kIsWeb) throw Exception("Use socket to sync the last message on Web!");
    final task = SyncLastMessages([chats, toggleUnread]);
    return (await createAsyncTask<List<Chat>>(task)) ?? [];
  }

  static Future<List<Chat>> bulkSyncChats(List<Chat> chats) async {
    if (kIsWeb) throw Exception("Web does not support saving chats!");
    if (chats.isEmpty) return [];
    final task = BulkSyncChats([chats]);
    return (await createAsyncTask<List<Chat>>(task)) ?? [];
  }

  static Future<List<Message>> bulkSyncMessages(Chat chat, List<Message> messages) async {
    if (kIsWeb) throw Exception("Web does not support saving messages!");
    if (messages.isEmpty) return [];
    final task = BulkSyncMessages([chat, messages]);
    return (await createAsyncTask<List<Message>>(task)) ?? [];
  }

  void clearTranscript() {
    if (kIsWeb) return;
    Database.runInTransaction(TxMode.write, () {
      final toDelete = List<Message>.from(messages);
      for (Message element in toDelete) {
        element.dateDeleted = DateTime.now().toUtc();
      }
      Database.messages.putMany(toDelete);
    });
  }

  void restoreTranscript() {
    if (kIsWeb) return;
    Database.runInTransaction(TxMode.write, () {
      final toDelete = List<Message>.from(messages);
      for (Message element in toDelete) {
        element.dateDeleted = null;
      }
      Database.messages.putMany(toDelete);
    });
  }

  bool get isTextForwarding => guid.startsWith("SMS") || isRpSms;
  bool get isSMS => false;
  bool get isIMessage => !isTextForwarding && !isSMS;
  bool get isGroup => participants.length > 1 || style == 43;

  Chat merge(Chat other) {
    id ??= other.id;
    _customAvatarPath.value ??= other._customAvatarPath.value;
    _pinIndex.value ??= other._pinIndex.value;
    autoSendReadReceipts ??= other.autoSendReadReceipts;
    autoSendTypingIndicators ??= other.autoSendTypingIndicators;
    textFieldText ??= other.textFieldText;
    textFieldAnnotations ??= other.textFieldAnnotations;
    if (textFieldAttachments.isEmpty) {
      textFieldAttachments.addAll(other.textFieldAttachments);
    }
    chatIdentifier ??= other.chatIdentifier;
    displayName ??= other.displayName;
    if (handles.isEmpty) {
      handles.addAll(other.handles);
    }
    hasUnreadMessage ??= other.hasUnreadMessage;
    isArchived ??= other.isArchived;
    isPinned ??= other.isPinned;
    _latestMessage ??= other.latestMessage;
    muteArgs ??= other.muteArgs;
    title ??= other.title;
    dateDeleted ??= other.dateDeleted;
    style ??= other.style;
    return this;
  }

  static int sort(Chat? a, Chat? b) {
    if (a!.isPinned! && b!.isPinned! && a.pinIndex != null && b.pinIndex != null) {
      return a.pinIndex!.compareTo(b.pinIndex!);
    }
    if (b!.isPinned! && b.pinIndex != null && (!a.isPinned! || a.pinIndex == null)) return 1;
    if (a.isPinned! && a.pinIndex != null && (!b.isPinned! || b.pinIndex == null)) return -1;
    if (!a.isPinned! && b.isPinned!) return 1;
    if (a.isPinned! && !b.isPinned!) return -1;
    return -(a.latestMessage.dateCreated)!.compareTo(b.latestMessage.dateCreated!);
  }

  String getIconPath(int responseLength) {
    return "${fs.appDocDir.path}/avatars/${guid.characters.where((char) => char.isAlphabetOnly || char.isNumericOnly).join()}/avatar-$responseLength.jpg";
  }

  static Future<void> getIcon(Chat c, {bool force = false}) async {
    if ((!force && c.lockChatIcon) || backend.getRemoteService() == null) return;
    final response = await backend.getRemoteService()!
        .getChatIcon(c.guid)
        .catchError((err, stack) async {
      Logger.error("Failed to get chat icon for chat ${c.getTitle()}",
          error: err, trace: stack);
      return Response(statusCode: 500, requestOptions: RequestOptions(path: ""));
    });
    if (response.statusCode != 200 || isNullOrEmpty(response.data)) {
      if (c.customAvatarPath != null) {
        await File(c.customAvatarPath!).delete(recursive: true);
        c.customAvatarPath = null;
        c.save(updateCustomAvatarPath: true);
      }
    } else {
      Logger.debug("Got chat icon for chat ${c.getTitle()}");
      File file = File(c.getIconPath(response.data.length));
      if (!(await file.exists())) {
        await file.create(recursive: true);
      }
      if (c.customAvatarPath != null) {
        await file.delete();
      }
      await file.writeAsBytes(response.data);
      c.customAvatarPath = file.path;
      c.save(updateCustomAvatarPath: true);
    }
  }

  Map<String, dynamic> toMap() => {
        "ROWID": id,
        "guid": guid,
        "chatIdentifier": chatIdentifier,
        "isArchived": isArchived!,
        "muteType": muteType,
        "muteArgs": muteArgs,
        "isPinned": isPinned!,
        "hasUnreadMessage": hasUnreadMessage!,
        "isWhitelisted": isWhitelisted,
        "displayName": displayName,
        "participants": participants.map((item) => item.toMap()).toList(),
        "customAvatarPath": _customAvatarPath.value,
        "pinIndex": _pinIndex.value,
        "autoSendReadReceipts": autoSendReadReceipts,
        "autoSendTypingIndicators": autoSendTypingIndicators,
        "dateDeleted": dateDeleted?.millisecondsSinceEpoch,
        "style": style,
        "lockChatName": lockChatName,
        "lockChatIcon": lockChatIcon,
        "lastReadMessageGuid": lastReadMessageGuid,
        "isRpSms": isRpSms,
        "guidRefs": guidRefs,
        "telephonyId": telephonyId,
        "textFieldText": textFieldText,
        "textFieldAnnotations": textFieldAnnotations,
      };
}
