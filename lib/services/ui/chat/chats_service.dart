import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:bluebubbles/app/layouts/chat_creator/chat_creator.dart';
import 'package:bluebubbles/helpers/backend/startup_tasks.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:tuple/tuple.dart';
import 'package:universal_io/io.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;

ChatsService chats = Get.isRegistered<ChatsService>() ? Get.find<ChatsService>() : Get.put(ChatsService());

class ChatsService extends GetxService {
  static const batchSize = 15;
  int currentCount = 0;
  late final StreamSubscription countSub;

  final RxBool hasChats = false.obs;
  Completer<void> loadedAllChats = Completer();
  final RxBool loadedChatBatch = false.obs;
  final RxList<Chat> chats = <Chat>[].obs;

  bool restoring = false;

  final List<Handle> webCachedHandles = [];

  @override
  void onInit() {
    super.onInit();
    if (!kIsWeb) {
      // watch for new chats
      (() async {
        final countQuery = (Database.chats.query(Chat_.dateDeleted.isNull().and(Chat_.telephonyId.isNull()).and(Chat_.isRoutingStub.equals(false).or(Chat_.isRoutingStub.isNull())))..order(Chat_.id, flags: Order.descending))
            .watch(triggerImmediately: true);
        countSub = countQuery.listen((event) async {
          if (!ss.settings.finishedSetup.value) return;
          final newCount = event.count();
          if (newCount > currentCount && currentCount != 0) {
            final chat = event.findFirst()!;
            if (chat.latestMessage.dateCreated!.millisecondsSinceEpoch == 0) {
              // wait for the chat.addMessage to go through
              await Future.delayed(const Duration(milliseconds: 500));
              // refresh the latest message
              chat.dbLatestMessage;
            }
            await addChat(chat);
          }
          currentCount = newCount;
        });
      })();
    } else {
      countSub = WebListeners.newChat.listen((chat) async {
        if (!ss.settings.finishedSetup.value) return;
        await addChat(chat);
      });
    }
  }

  RxList<Handle> suggestedHandles = <Handle>[].obs;

  Future<void> loadChatSuggestions() async {
    if (!Platform.isAndroid) return;
    if (chats.isNotEmpty) return;
    List<String> recents = List<String>.from(await mcs.invokeMethod("recent-contacts"));
    await pushService.initFuture;
    List<String> suggestedHandles = [];
    while (recents.isNotEmpty && suggestedHandles.length < 3) {
      var wantedCount = min(3 - suggestedHandles.length, recents.length);
      List<String> queryList = recents.sublist(0, wantedCount);
      recents = recents.sublist(wantedCount);
      List<String> formattedList = [];
      for (var item in queryList) {
        formattedList.add(await RustPushBBUtils.formatAndAddPrefix(item));
      }
      var handle = await (backend as RustPushBackend).getDefaultHandle();
      suggestedHandles.addAll(await pushService.doValidateTargets(formattedList, handle));
    }
    List<Handle> results = suggestedHandles.map((s) => RustPushBBUtils.rustHandleToBB(s)).toList();
    this.suggestedHandles.value = results;
    Logger.info("response $suggestedHandles");
  }

  Future<void> init({bool force = false}) async {
    if (!force && !ss.settings.finishedSetup.value) return;
    Logger.info("Fetching chats... ${StackTrace.current}", tag: "ChatBloc");
    currentCount = Chat.count() ?? (await backend.getRemoteService()?.chatCount().catchError((err) {
      Logger.info("Error when fetching chat count!", tag: "ChatBloc");
      return Response(requestOptions: RequestOptions(path: ''));
    }))?.data['data']['total'] ?? 0;
    loadedAllChats = Completer();
    if (currentCount != 0) {
      hasChats.value = true;
    } else {
      loadedChatBatch.value = true;
      loadChatSuggestions();
      return;
    }

    final newChats = <Chat>[];
    final batches = (currentCount < batchSize) ? batchSize : (currentCount / batchSize).ceil();

    for (int i = 0; i < batches; i++) {
      List<Chat> temp;
      if (kIsWeb) {
        temp = await cm.getChats(withLastMessage: true, limit: batchSize, offset: i * batchSize);
      } else {
        temp = await Chat.getChats(limit: batchSize, offset: i * batchSize);
      }

      if (kIsWeb) {
        webCachedHandles.addAll(temp.map((e) => e.participants).flattened.toList());
        final ids = webCachedHandles.map((e) => e.address).toSet();
        webCachedHandles.retainWhere((element) => ids.remove(element.address));
      }

      for (Chat c in temp) {
        cm.createChatController(c, active: cm.activeChat?.chat.guid == c.guid);
      }
      newChats.addAll(temp);
      newChats.sort(Chat.sort);
      chats.value = newChats;
      loadedChatBatch.value = true;
    }
    loadChatSuggestions();
    loadedAllChats.complete();
    Logger.info("Finished fetching chats (${chats.length}).", tag: "ChatBloc");
    // update share targets
    if (Platform.isAndroid) {
      StartupTasks.waitForUI().then((_) async {
        for (Chat c in chats.where((e) => !isNullOrEmpty(e.title)).take(4)) {
          await mcs.invokeMethod("push-share-targets", {
            "title": c.title,
            "guid": c.guid,
            "icon": await avatarAsBytes(chat: c, quality: 256),
          });
        }
      });
    }

    if (kIsDesktop && Platform.isWindows) {
      /* ----- IMESSAGE:// HANDLER ----- */
      final _appLinks = AppLinks();
      _appLinks.stringLinkStream.listen((String string) async {
        if (!string.startsWith("imessage://")) return;
        final uri = Uri.tryParse(string
            .replaceFirst("imessage://", "imessage:")
            .replaceFirst("&body=", "?body=")
            .replaceFirst(RegExp(r'/$'), ''));
        if (uri == null) return;

        final address = uri.path;
        final handle = Handle.findOne(addressAndService: Tuple2(address, "iMessage"));
        ns.closeSettings(Get.context!);
        await ns.pushAndRemoveUntil(
          Get.context!,
          ChatCreator(
            initialSelected: [SelectedContact(displayName: handle?.displayName ?? address, address: address)],
            initialText: uri.queryParameters['body'],
          ),
          (route) => route.isFirst,
        );
      });
    }

    // prune older chats and messages
    var c = Database.chats.query(Chat_.dateDeleted.lessThanDate(DateTime.now().subtract(const Duration(days: 30)))).build().find();
    for (var chat in c) {
      Chat.deleteChat(chat);
    }
    var messages = Database.messages.query(Message_.dateDeleted.lessThanDate(DateTime.now().subtract(const Duration(days: 30)))).build().find();
    for (var message in messages) {
      Message.delete(message.guid!);
    }
  }

  @override
  void onClose() {
    countSub.cancel();
    super.onClose();
  }

  void sort() {
    final ids = chats.map((e) => e.guid).toSet();
    chats.retainWhere((element) => ids.remove(element.guid));
    chats.sort(Chat.sort);
  }

  Future<void> updateShareTarget(Chat c) async {
    if (!Platform.isAndroid) return;
    try {
      final title = c.properTitle;
      if (isNullOrEmpty(title)) return;
      final icon = await avatarAsBytes(chat: c, quality: 256);
      await mcs.invokeMethod("push-share-targets", {
        "title": title,
        "guid": c.guid,
        "icon": icon,
      });
    } catch (ex) {
      // ignore
    }
  }

  bool updateChat(Chat updated, {bool shouldSort = false, bool override = false}) {
    final index = chats.indexWhere((e) => updated.guid == e.guid);
    if (index != -1) {
      // delete
      if (updated.isRoutingStub) {
        chats.removeAt(index);
        return true;
      }
      final toUpdate = chats[index];
      // this is so the list doesn't re-render
      // ignore: invalid_use_of_protected_member
      chats.value[index] = override ? updated : updated.merge(toUpdate);
      if (shouldSort) sort();
      if (updated.getTitle() != toUpdate.getTitle() || updated.customAvatarPath != toUpdate.customAvatarPath) {
        updateShareTarget(updated);
      }
    }

    return index != -1;
  }

  Future<void> addChat(Chat toAdd) async {
    if (toAdd.isRoutingStub) return;
    chats.add(toAdd);
    cm.createChatController(toAdd);
    sort();
    updateShareTarget(toAdd);
  }

  void removeChat(Chat toRemove) {
    final index = chats.indexWhere((e) => toRemove.guid == e.guid);
    chats.removeAt(index);
  }

  void markAllAsRead() {
    final _chats = Database.chats.query(Chat_.hasUnreadMessage.equals(true)).build().find();
    for (Chat c in _chats) {
      c.hasUnreadMessage = false;
      mcs.invokeMethod(
        "delete-notification",
        {
          "notification_id": c.id,
          "tag": NotificationsService.NEW_MESSAGE_TAG
        }
      );
      backend.markRead(c, ss.settings.enablePrivateAPI.value && ss.settings.privateMarkChatAsRead.value);
    }
    Database.chats.putMany(_chats);
  }

  void updateChatPinIndex(int oldIndex, int newIndex) {
    final items = chats.bigPinHelper(true);
    final item = items[oldIndex];

    // Remove the item at the old index, and re-add it at the newIndex
    // We dynamically subtract 1 from the new index depending on if the newIndex is > the oldIndex
    items.removeAt(oldIndex);
    items.insert(newIndex + (oldIndex < newIndex ? -1 : 0), item);

    // Move the pinIndex for each of the chats, and save the pinIndex in the DB
    items.forEachIndexed((i, e) {
      e.pinIndex = i;
      e.save(updatePinIndex: true);
    });
    chats.sort(Chat.sort);
  }

  void removePinIndices() {
    chats.bigPinHelper(true).where((e) => e.pinIndex != null).forEach((element) {
      element.pinIndex = null;
      element.save(updatePinIndex: true);
    });
    chats.sort(Chat.sort);
  }
}
