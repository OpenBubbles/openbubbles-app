import 'dart:async';

import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/group_participant_helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:dio/dio.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:get/get.dart' hide Response;
import 'package:tuple/tuple.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;

ChatManager cm = Get.isRegistered<ChatManager>() ? Get.find<ChatManager>() : Get.put(ChatManager());

class ChatManager extends GetxService {
  ChatLifecycleManager? activeChat;
  api.ChannelInterestToken? provider;
  final Map<String, ChatLifecycleManager> _chatControllers = {};

  /// Same as setAllInactive but but removes lastOpenedChat from prefs on next frame
  void setAllInactiveSync({save = true, bool clearActive = true}) {
    Logger.debug('Setting chats to inactive (save: $save, clearActive: $clearActive)');

    String? skip;
    if (clearActive) {
      activeChat?.controller = null;
      activeChat = null;
      provider?.dispose();
      provider = null;
    } else {
      skip = activeChat?.chat.guid;
    }

    _chatControllers.forEach((key, value) {
      if (key == skip) return;
      value.isActive = false;
      value.isAlive = false;
    });

    if (save) {
      eventDispatcher.emit("update-highlight", null);
      Future(() async => await ss.prefs.remove('lastOpenedChat'));
    }
  }

  Future<void> setAllInactive() async {
    Logger.debug('Setting all chats to inactive');
    await ss.prefs.remove('lastOpenedChat');
    setAllInactiveSync(save: false);
  }

  Future<void> setActiveChat(Chat chat, {clearNotifications = true}) async {
    await ss.prefs.setString('lastOpenedChat', chat.guid);
    setActiveChatSync(chat, clearNotifications: clearNotifications, save: false);
  }

  /// Same as setActiveChat but saves lastOpenedChat to prefs on next frame
  void setActiveChatSync(Chat chat, {clearNotifications = true, save = true}) {
    eventDispatcher.emit("update-highlight", chat.guid);
    Logger.debug('Setting active chat to ${chat.guid} (${chat.displayName})');

    (() async {
      if (!chat.isIMessage) return;
      var statuskit = pushService.state?.icloudServices?.statuskitClient;
      if (statuskit == null) return;
      Logger.info("ensuring keys");
      var participants = (await chat.getConversationData()).participants;
      var targets = await pushService.doValidateTargets(participants, await chat.ensureHandle());
      Logger.info("finished ensuring keys ${targets.length}/${participants.length}");
      if (chat.participants.length == 1) {
        participants.remove(await chat.ensureHandle());
        Logger.info("showing interest in handle ${participants[0]}");
        provider?.dispose();
        provider = await api.requestHandles(status: statuskit, to: [participants[0]]);
        Logger.info("showed interest in handles");
        chat.fixZenModeShared();
      }
    })();

    createChatController(chat, active: true);
    if (clearNotifications) {
      chat.toggleHasUnread(false, force: true);
    }
    if (save) {
      Future(() async => await ss.prefs.setString('lastOpenedChat', chat.guid));
    }
  }

  void setActiveToDead() {
    Logger.debug('Setting active chat to dead: ${activeChat?.chat.guid}');
    activeChat?.isAlive = false;
  }

  void setActiveToAlive() {
    Logger.info('Setting active chat to alive: ${activeChat?.chat.guid}');
    eventDispatcher.emit("update-highlight", activeChat?.chat.guid);
    activeChat?.isAlive = true;
  }

  bool isChatActive(String guid) => (getChatController(guid)?.isActive ?? false) && (getChatController(guid)?.isAlive ?? false);

  ChatLifecycleManager createChatController(Chat chat, {active = false}) {
    // If a chat is passed, get the chat and set it be active and make sure it's stored
    ChatLifecycleManager controller = getChatController(chat.guid) ?? ChatLifecycleManager(chat);
    _chatControllers[chat.guid] = controller;

    // If we are setting a new active chat, we need to clear the active statuses on
    // all of the other chat controllers
    if (active) {
      activeChat = controller;
    }

    controller.isActive = active;
    controller.isAlive = active;

    if (active) {
      // Don't clear active cuz we just set the active Chat.
      // We set it first to avoid any race conditions.
      setAllInactiveSync(save: false, clearActive: false);
    }

    return controller;
  }

  ChatLifecycleManager? getChatController(String guid) {
    if (!_chatControllers.containsKey(guid)) return null;
    return _chatControllers[guid];
  }

  /// Fetch chat information from the server
  Future<Chat?> fetchChat(String chatGuid, {withParticipants = true, withLastMessage = false}) async {
    Logger.info("Fetching full chat metadata from server. ${StackTrace.current}", tag: "Fetch-Chat");

    var remote = backend.getRemoteService();
    if (remote == null) {
      return Chat.findOne(guid: chatGuid);
    }

    final withQuery = <String>[];
    if (withParticipants) withQuery.add("participants");
    if (withLastMessage) withQuery.add("lastmessage");

    final response = await remote.singleChat(chatGuid, withQuery: withQuery.join(",")).catchError((err, stack) {
      if (err is! Response) {
        Logger.error("Failed to fetch chat metadata!", error: err, trace: stack, tag: "Fetch-Chat");
        return err;
      }
      return Response(requestOptions: RequestOptions(path: ''));
    });

    if (response.statusCode == 200 && response.data["data"] != null) {
      Map<String, dynamic> chatData = response.data["data"];

      Logger.info("Got updated chat metadata from server. Saving.", tag: "Fetch-Chat");
      Chat updatedChat = Chat.fromMap(chatData);
      Chat? chat = Chat.findOne(guid: chatGuid);
      if (chat == null) {
        updatedChat.save();
        chat = Chat.findOne(guid: chatGuid)!;
      } else {
        // Reconcile by address and service, not just list length. A group can
        // replace one participant without changing its size, and multiple
        // additions must all be reflected in the local relation.
        // An incomplete server response must not erase a known participant
        // list. A valid empty group is not useful for this client, so retain
        // the local list when the response contains no participants.
        if (updatedChat.participants.isNotEmpty || chat.participants.isEmpty) {
          final handles = reconcileGroupParticipants(
            chat.participants,
            updatedChat.participants,
          );
          if (handles.isNotEmpty) Handle.bulkSave(handles);
          chat.handles.clear();
          chat.handles.addAll(handles);
          chat.handles.applyToDb();
          chat.getParticipants();
        }
      }
      if (!chat.lockChatName) {
        chat.displayName = updatedChat.displayName;
      }
      chat = chat.save(updateDisplayName: !chat.lockChatName);
      return chat;
    }

    return null;
  }

  Future<List<Chat>> getChats({bool withParticipants = false, bool withLastMessage = false, int offset = 0, int limit = 100,}) async {
    final withQuery = <String>[];
    if (withParticipants) withQuery.add("participants");
    if (withLastMessage) withQuery.add("lastmessage");

    final response = await http.chats(withQuery: withQuery, offset: offset, limit: limit, sort: withLastMessage ? "lastmessage" : null).catchError((err, stack) {
      if (err is! Response) {
        Logger.error("Failed to fetch chat metadata!", error: err, trace: stack, tag: "Fetch-Chat");
        return err;
      }
      return Response(requestOptions: RequestOptions(path: ''));
    });

    // parse chats from the response
    final chats = <Chat>[];
    for (var item in response.data["data"]) {
      try {
        var chat = Chat.fromMap(item);
        chats.add(chat);
      } catch (ex) {
        chats.add(Chat(guid: "ERROR", displayName: item.toString()));
      }
    }

    return chats;
  }

  Future<List<dynamic>> getMessages(String guid, {bool withAttachment = true, bool withHandle = true, int offset = 0, int limit = 25, String sort = "DESC", int? after, int? before}) async {
    Completer<List<dynamic>> completer = Completer();
    final withQuery = <String>["message.attributedBody", "message.messageSummaryInfo", "message.payloadData"];
    if (withAttachment) withQuery.add("attachment");
    if (withHandle) withQuery.add("handle");

    backend.getRemoteService()?.chatMessages(guid, withQuery: withQuery.join(","), offset: offset, limit: limit, sort: sort, after: after, before: before).then((response) {
      if (!completer.isCompleted) completer.complete(response.data["data"]);
    }).catchError((err) {
      late final dynamic error;
      if (err is Response) {
        error = err.data["error"]["message"];
      } else {
        error = err.toString();
      }
      if (!completer.isCompleted) completer.completeError(error);
    }) ?? completer.complete([]);

    return completer.future;
  }
}
