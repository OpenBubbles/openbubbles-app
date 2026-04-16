import 'dart:async';
import 'dart:math';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms/audio_waveforms.dart' as audio;
import 'package:bluebubbles/app/components/avatars/contact_avatar_group_widget.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/message_holder.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/typing/typing_indicator.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/app/wrappers/scrollbar_wrapper.dart';
import 'package:bluebubbles/app/components/avatars/contact_avatar_widget.dart';
import 'package:bluebubbles/app/wrappers/theme_switcher.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:collection/collection.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_ml_kit/google_ml_kit.dart' hide Message;
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;

class MessagesView extends StatefulWidget {
  final MessagesService? customService;
  final ConversationViewController controller;

  MessagesView({
    super.key,
    this.customService,
    required this.controller,
  });

  @override
  MessagesViewState createState() => MessagesViewState();
}

class MessagesViewState extends OptimizedState<MessagesView> {
  bool initialized = false;
  bool fetching = false;
  late bool noMoreMessages = widget.customService != null;
  List<Message> _messages = <Message>[];

  RxList<Widget> smartReplies = <Widget>[].obs;
  RxMap<String, Widget> internalSmartReplies = <String, Widget>{}.obs;

  late final messageService = widget.customService ?? ms(chat.guid)
    ..init(chat, handleNewMessage, handleUpdatedMessage, handleDeletedMessage, jumpToMessage);
  final smartReply = GoogleMlKit.nlp.smartReply();
  final listKey = GlobalKey<SliverAnimatedListState>();
  final RxBool dragging = false.obs;
  final RxInt numFiles = 0.obs;
  final RxBool latestMessageDeliveredState = false.obs;
  final RxBool jumpingToOldestUnread = false.obs;
  final Map<String, FocusNode> messageFocusNodes = {};

  ConversationViewController get controller => widget.controller;

  AutoScrollController get scrollController => controller.scrollController;

  bool get showSmartReplies => ss.settings.smartReply.value && !kIsWeb && !kIsDesktop;

  Chat get chat => controller.chat;

  FocusNode _messageFocusNode(Message message) => messageFocusNodes.putIfAbsent(message.guid!, () => FocusNode());

  void _syncBottomMessageFocusNode() {
    controller.bottomMessageFocusNode = _messages.isEmpty ? null : _messageFocusNode(_messages.first);
  }

  void _focusMessageAt(int index) {
    if (index < 0) {
      controller.lastFocusedNode.requestFocus();
      return;
    }
    if (index >= _messages.length) {
      if (!noMoreMessages && !fetching) {
        unawaited(loadNextChunk().then((_) {
          if (mounted && index < _messages.length) {
            _focusMessageAt(index);
          }
        }));
      }
      return;
    }
    _messageFocusNode(_messages[index]).requestFocus();
    unawaited(scrollController.scrollToIndex(index, preferPosition: AutoScrollPosition.middle));
  }

  Future<bool> _toggleAudioMessage(Message message) async {
    final attachment = message.attachments.firstWhereOrNull((e) =>
        e != null && (e.mimeStart == "audio" || e.uti == "com.apple.coreaudio-format"));
    if (attachment == null || attachment.guid == null) return false;

    final mobilePlayer = controller.audioPlayers[attachment.guid];
    if (mobilePlayer != null) {
      if (mobilePlayer.playerState == audio.PlayerState.playing) {
        await mobilePlayer.pausePlayer();
      } else {
        mobilePlayer.setFinishMode(finishMode: FinishMode.pause);
        await mobilePlayer.startPlayer();
      }
      return true;
    }

    final desktopPlayer = controller.audioPlayersDesktop[attachment.guid];
    if (desktopPlayer != null) {
      if (desktopPlayer.state.playing) {
        await desktopPlayer.pause();
      } else {
        await desktopPlayer.play();
      }
      return true;
    }

    return false;
  }

  bool _canToggleAudioMessage(Message message) {
    final attachment = message.attachments.firstWhereOrNull((e) =>
        e != null && (e.mimeStart == "audio" || e.uti == "com.apple.coreaudio-format"));
    if (attachment?.guid == null) return false;
    return controller.audioPlayers.containsKey(attachment!.guid) || controller.audioPlayersDesktop.containsKey(attachment.guid);
  }

  @override
  void initState() {
    super.initState();

    eventDispatcher.stream.listen((e) async {
      if (e.item1 == "refresh-messagebloc" && e.item2 == chat.guid) {
        // Clear state items
        noMoreMessages = false;
        _messages = [];
        // Reload the state after refreshing
        messageService.reload();
        messageService.init(chat, handleNewMessage, handleUpdatedMessage, handleDeletedMessage, jumpToMessage);
        setState(() {});
      } else if (e.item1 == "add-custom-smartreply") {
        if (e.item2 != null && internalSmartReplies['attach-recent'] == null) {
          internalSmartReplies['attach-recent'] = _buildReply("Attach recent photo", onTap: () async {
            controller.pickedAttachments.add(e.item2);
            internalSmartReplies.clear();
          });
        }
      }
    });

    updateObx(() async {
      if (chat.isIMessage && !chat.isGroup) {
        getFocusState();
      }
      final searchMessage = (messageService.method == null) ? null : messageService.struct.messages.firstOrNull;
      if (messageService.method != null) {
        await messageService.loadSearchChunk(
            messageService.struct.messages.first, messageService.method == "local" ? SearchMethod.local : SearchMethod.network);
      } else if (messageService.struct.isEmpty) {
        await messageService.loadChunk(0, controller);
      }
      _messages = messageService.struct.messages;
      _messages.sort(Message.sort);
      setState(() {});
      _messages.forEachIndexed((i, m) {
        final c = mwc(m);
        c.cvController = controller;
        listKey.currentState!.insertItem(i, duration: const Duration(milliseconds: 0));
      });
      _syncBottomMessageFocusNode();
      // scroll to message if needed
      if (searchMessage != null) {
        final index = _messages.indexWhere((element) => element.guid == searchMessage.guid);
        await scrollController.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
        scrollController.highlight(index, highlightDuration: const Duration(milliseconds: 500));
      } else if (!(_messages.firstOrNull?.isFromMe ?? true)) {
        updateReplies();
      }
      initialized = true;
      if (ss.settings.scrollToLastUnread.value && chat.lastReadMessageGuid != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (getActiveMwc(chat.lastReadMessageGuid!)?.built ?? false) return;
          internalSmartReplies['scroll-last-read'] = _buildReply("Jump to oldest unread", onTap: () async {
            if (jumpingToOldestUnread.value) return;
            jumpingToOldestUnread.value = true;
            await jumpToMessage(chat.lastReadMessageGuid!);
            internalSmartReplies.remove('scroll-last-read');
            jumpingToOldestUnread.value = false;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    if (!kIsWeb && !kIsDesktop) smartReply.close();
    chat.lastReadMessageGuid = _messages.first.guid;
    chat.save(updateLastReadMessageGuid: true);
    messageService.close(force: widget.customService != null);
    if (controller.bottomMessageFocusNode != null && messageFocusNodes.containsValue(controller.bottomMessageFocusNode)) {
      controller.bottomMessageFocusNode = null;
    }
    for (FocusNode node in messageFocusNodes.values) {
      node.dispose();
    }
    for (Message m in _messages) {
      getActiveMwc(m.guid!)?.close();
    }
    super.dispose();
  }

  void getFocusState() {
    if (!backend.supportsFocusStates()) return;
    final recipient = chat.participants.firstOrNull;
    if (recipient != null) {
      http.handleFocusState(recipient.address).then((response) {
        final status = response.data['data']['status'];
        controller.recipientNotifsSilenced.value = status != "none";
      }).catchError((error, stack) async {
        Logger.error('Failed to get focus state!', error: error, trace: stack);
      });
    }
  }

  Future<void> jumpToMessage(String guid) async {
    // check if the message is already loaded
    int index = _messages.indexWhere((element) => element.guid == guid);
    if (index != -1) {
      await scrollController.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
      scrollController.highlight(index, highlightDuration: const Duration(milliseconds: 500));
      return;
    }
    // otherwise fetch until it is loaded
    final message = Message.findOne(guid: guid);
    final query = (Database.messages.query(Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull()))
          ..link(Message_.chat, Chat_.id.equals(chat.id!))
          ..order(Message_.dateCreated, flags: Order.descending))
        .build();
    final ids = await query.findIdsAsync();
    final pos = ids.indexOf(message!.id!);
    await loadNextChunk(limit: pos + 10);
    index = _messages.indexWhere((element) => element.guid == guid);
    if (index != -1) {
      await scrollController.scrollToIndex(index, preferPosition: AutoScrollPosition.middle);
      scrollController.highlight(index, highlightDuration: const Duration(milliseconds: 500));
    } else {
      showSnackbar("Error", "Failed to find message!");
    }
  }

  void updateReplies({bool updateConversation = true}) async {
    if (!showSmartReplies || isNullOrEmpty(_messages) || kIsWeb || kIsDesktop || !mounted || !ls.isAlive) return;

    if (updateConversation) {
      _messages.reversed.where((e) => !isNullOrEmpty(e.fullText) && e.dateCreated != null).skip(max(_messages.length - 5, 0)).forEach((message) {
        _addMessageToSmartReply(message);
      });
    }
    Logger.info("Getting smart replies...");
    SmartReplySuggestionResult results = await smartReply.suggestReplies();

    if (results.status == SmartReplySuggestionResultStatus.success) {
      Logger.info("Smart Replies found: ${results.suggestions.length}");
      smartReplies.value = results.suggestions.map((e) => _buildReply(e)).toList();
      Logger.debug(smartReplies.toString());
    } else {
      smartReplies.clear();
    }
  }

  void _addMessageToSmartReply(Message message) {
    if (message.isFromMe ?? false) {
      smartReply.addMessageToConversationFromLocalUser(message.fullText, message.dateCreated!.millisecondsSinceEpoch);
    } else {
      smartReply.addMessageToConversationFromRemoteUser(
          message.fullText, message.dateCreated!.millisecondsSinceEpoch, message.handle?.address ?? "participant");
    }
  }

  Future<void> loadNextChunk({int limit = 25}) async {
    if (noMoreMessages || fetching) return;
    fetching = true;

    // Start loading the next chunk of messages
    noMoreMessages = !(await messageService.loadChunk(_messages.length, controller, limit: limit).catchError((e, stack) {
      Logger.error("Failed to fetch message chunk!", error: e, trace: stack);
      return true;
    }));

    if (noMoreMessages) return setState(() {});

    final oldLength = _messages.length;
    _messages = messageService.struct.messages;
    _messages.sort(Message.sort);
    fetching = false;
    _messages.sublist(max(oldLength - 1, 0)).forEachIndexed((i, m) {
      if (!mounted) return;
      final c = mwc(m);
      c.cvController = controller;
      listKey.currentState!.insertItem(i, duration: const Duration(milliseconds: 0));
    });
    _syncBottomMessageFocusNode();
    // should only happen when a reaction is the most recent message
    if (oldLength == 0) {
      setState(() {});
    }
  }

  void handleNewMessage(Message message) async {
    _messages.add(message);
    _messages.sort(Message.sort);
    final insertIndex = _messages.indexOf(message);
    _syncBottomMessageFocusNode();

    if (listKey.currentState != null) {
      listKey.currentState!.insertItem(
        insertIndex,
        duration: const Duration(milliseconds: 500),
      );
    }

    if (insertIndex == 0 && showSmartReplies) {
      _addMessageToSmartReply(message);
      if (message.isFromMe!) {
        smartReplies.clear();
      } else {
        updateReplies(updateConversation: false);
      }
    }

    if (insertIndex == 0 && !message.isFromMe! && ss.settings.receiveSoundPath.value != null) {
      if (kIsDesktop && (cm.getChatController(chat.guid)?.isActive ?? false)) {
        Player player = Player();
        player.stream.completed
            .firstWhere((completed) => completed)
            .then((_) async => Future.delayed(const Duration(milliseconds: 500), () async => await player.dispose()));
        await player.setVolume(ss.settings.soundVolume.value.toDouble());
        await player.open(Media(ss.settings.receiveSoundPath.value!));
      } else if (cm.isChatActive(chat.guid)) {
        PlayerController controller = PlayerController();
        await controller
            .preparePlayer(path: ss.settings.receiveSoundPath.value!, volume: ss.settings.soundVolume.value / 100)
            .then((_) => controller.startPlayer());
      }
    }
  }

  void handleUpdatedMessage(Message message, {String? oldGuid}) {
    final index = _messages.indexWhere((e) => e.guid == (oldGuid ?? message.guid));
    if (index != -1) {
      if (oldGuid != null && oldGuid != message.guid) {
        final node = messageFocusNodes.remove(oldGuid);
        if (node != null) {
          messageFocusNodes[message.guid!] = node;
        }
      }
      _messages[index] = message;
      _messages.sort(Message.sort);
      _syncBottomMessageFocusNode();
    }
    if (message.wasDeliveredQuietly != latestMessageDeliveredState.value) {
      latestMessageDeliveredState.value = message.wasDeliveredQuietly;
    }
  }

  void handleDeletedMessage(Message message) {
    final index = _messages.indexWhere((e) => e.guid == message.guid);
    if (index != -1) {
      _messages.removeAt(index);
      messageFocusNodes.remove(message.guid)?.dispose();
      _syncBottomMessageFocusNode();
      listKey.currentState!.removeItem(index, (context, animation) => const SizedBox.shrink());
    }
  }

  Widget _buildReply(String text, {Function()? onTap}) => Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            style: BorderStyle.solid,
            color: context.theme.colorScheme.properSurface,
          ),
          borderRadius: BorderRadius.circular(19),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onTap ??
              () {
                outq.queue(OutgoingItem(
                  type: QueueType.sendMessage,
                  chat: controller.chat,
                  message: Message(
                    text: text,
                    dateCreated: DateTime.now(),
                    hasAttachments: false,
                    isFromMe: true,
                    handleId: 0,
                  ),
                ));
              },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 1.5, left: 13.0, right: 13.0),
              child: Obx(() => RichText(
                    text: TextSpan(
                      children: MessageHelper.buildEmojiText(
                        jumpingToOldestUnread.value && text == "Jump to oldest unread" ? "Jumping to oldest unread..." : text,
                        context.theme.extension<BubbleText>()!.bubbleText,
                      ),
                    ),
                  )),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const moonIcon = CupertinoIcons.moon_fill;
    return DropRegion(
      hitTestBehavior: HitTestBehavior.translucent,
      formats: Formats.standardFormats,
      onDropOver: (DropOverEvent event) {
        if (!event.session.allowedOperations.contains(DropOperation.copy)) {
          dragging.value = false;
          return DropOperation.forbidden;
        }
        numFiles.value = event.session.items.where((item) => Formats.standardFormats.whereType<FileFormat>().any((f) => item.canProvide(f))).length;
        if (numFiles.value > 0) {
          dragging.value = true;
          return DropOperation.copy;
        }

        dragging.value = false;
        return DropOperation.forbidden;
      },
      onDropLeave: (_) {
        dragging.value = false;
      },
      onPerformDrop: (PerformDropEvent event) async {
        for (DropItem item in event.session.items) {
          final reader = item.dataReader!;
          FileFormat? format = reader.getFormats(Formats.standardFormats).whereType<FileFormat>().firstOrNull;

          if (format == null) return;

          reader.getFile(format, (file) async {
            Uint8List bytes = await file.readAll();
            controller.pickedAttachments.add(PlatformFile(
              path: file.fileName!,
              name: file.fileName!,
              size: file.fileSize!,
              bytes: bytes,
            ));
          });
        }
        dragging.value = false;
      },
      child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onHorizontalDragUpdate: (details) {
            if (ss.settings.skin.value != Skins.Samsung && !kIsWeb && !kIsDesktop) {
              controller.timestampOffset.value += details.delta.dx * 0.3;
            }
          },
          onHorizontalDragEnd: (details) {
            if (ss.settings.skin.value != Skins.Samsung) {
              controller.timestampOffset.value = 0;
            }
          },
          onHorizontalDragCancel: () {
            if (ss.settings.skin.value != Skins.Samsung) {
              controller.timestampOffset.value = 0;
            }
          },
          child: Stack(
            children: [
              Obx(
                () => AnimatedOpacity(
                  opacity: _messages.isEmpty && widget.customService == null ? 0 : (dragging.value ? 0.3 : 1),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeIn,
                  child: DeferredPointerHandler(
                    child: ScrollbarWrapper(
                      reverse: true,
                      controller: scrollController,
                      showScrollbar: true,
                      child: CustomScrollView(
                        controller: scrollController,
                        reverse: true,
                        physics: ThemeSwitcher.getScrollPhysics(),
                        slivers: <Widget>[
                          if (showSmartReplies || internalSmartReplies.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Obx(() => AnimatedSize(
                                  duration: const Duration(milliseconds: 400),
                                  child: smartReplies.isNotEmpty || internalSmartReplies.isNotEmpty
                                      ? Padding(
                                          padding: EdgeInsets.only(top: iOS ? 8.0 : 0.0, right: 5),
                                          child: SizedBox(
                                            height: context.theme.extension<BubbleText>()!.bubbleText.fontSize! + 35,
                                            child: ListView(
                                              scrollDirection: Axis.horizontal,
                                              reverse: true,
                                              children: List<Widget>.from(smartReplies)..addAll(internalSmartReplies.values),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink())),
                            ),
                          if (_messages.isEmpty && widget.customService != null)
                            const SliverToBoxAdapter(
                              child: Loader(text: "Loading surrounding message context..."),
                            ),
                          SliverAnimatedList(
                              initialItemCount: _messages.length + 1,
                              key: listKey,
                              findChildIndexCallback: (key) => findChildIndexByKey(_messages, key, (item) => item.guid),
                              itemBuilder: (BuildContext context, int index, Animation<double> animation) {
                                // paginate
                                if (index >= _messages.length) {
                                  if (!noMoreMessages && initialized && index == _messages.length) {
                                    if (!fetching) {
                                      loadNextChunk();
                                    }
                                    return const Loader();
                                  }

                                  return const SizedBox.shrink();
                                }

                                Message? olderMessage;
                                Message? newerMessage;
                                if (index + 1 < _messages.length) {
                                  olderMessage = _messages[index + 1];
                                }
                                if (index - 1 >= 0) {
                                  newerMessage = _messages[index - 1];
                                }

                                final message = _messages[index];
                                final messageFocusNode = _messageFocusNode(message);
                                if (index == 0) {
                                  controller.bottomMessageFocusNode = messageFocusNode;
                                }

                                final messageWidget = Padding(
                                  padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                                  child: Focus(
                                    focusNode: messageFocusNode,
                                    onKeyEvent: (node, ev) {
                                      if (ev is! KeyDownEvent) return KeyEventResult.ignored;
                                      if (ev.logicalKey == LogicalKeyboardKey.arrowUp) {
                                        _focusMessageAt(index + 1);
                                        return KeyEventResult.handled;
                                      }
                                      if (ev.logicalKey == LogicalKeyboardKey.arrowDown) {
                                        _focusMessageAt(index - 1);
                                        return KeyEventResult.handled;
                                      }
                                      if ((ev.logicalKey == LogicalKeyboardKey.enter ||
                                              ev.logicalKey == LogicalKeyboardKey.select ||
                                              ev.logicalKey == LogicalKeyboardKey.space) &&
                                          !HardwareKeyboard.instance.isAltPressed &&
                                          !HardwareKeyboard.instance.isControlPressed &&
                                          !HardwareKeyboard.instance.isMetaPressed &&
                                          _canToggleAudioMessage(message)) {
                                        unawaited(_toggleAudioMessage(message));
                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: Builder(
                                      builder: (context) => Container(
                                        color: Focus.of(context).hasFocus ? Colors.grey.withOpacity(0.2) : Colors.transparent,
                                        child: MessageHolder(
                                          cvController: controller,
                                          message: message,
                                          oldMessageGuid: olderMessage?.guid,
                                          newMessageGuid: newerMessage?.guid,
                                        ),
                                      ),
                                    ),
                                  ),
                                );

                                Widget toReturn;

                                if (index == 0 || newerMessage?.dateScheduled != null) {
                                  toReturn = SizeTransition(
                                    axis: Axis.vertical,
                                    sizeFactor: animation.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut))),
                                    child: SlideTransition(
                                        position: animation.drive(
                                          Tween(
                                            begin: const Offset(0.0, 1),
                                            end: const Offset(0.0, 0.0),
                                          ).chain(
                                            CurveTween(
                                              curve: Curves.easeInOut,
                                            ),
                                          ),
                                        ),
                                        child: AnimatedBuilder(
                                          animation: animation,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity: message.guid!.contains("temp") &&
                                                      (!isNullOrEmpty(message.text) || !isNullOrEmpty(message.subject)) &&
                                                      !animation.isCompleted
                                                  ? 0
                                                  : 1,
                                              child: child,
                                            );
                                          },
                                          child: messageWidget,
                                        )),
                                  );
                                } else {
                                  toReturn = SizedBox(
                                    key: ValueKey(_messages[index].guid!),
                                    child: messageWidget,
                                  );
                                }

                                // we are the last non-scheduled message
                                if (message.dateScheduled == null && (newerMessage?.dateScheduled != null || index == 0)) {
                                  toReturn = Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      toReturn,
                                      if (!chat.isGroup && chat.isIMessage)
                                        Align(child:AnimatedSize(
                                          key: controller.focusInfoKey,
                                          duration: const Duration(milliseconds: 250),
                                          child: Obx(() => controller.recipientNotifsSilenced.value
                                              ? Padding(
                                                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                                                  child: Obx(() {
                                                    latestMessageDeliveredState.value;
                                                    var showNotifyAnyways = _messages.firstOrNull?.isFromMe == true &&
                                                        _messages.firstOrNull?.dateRead == null &&
                                                        _messages.firstOrNull?.wasDeliveredQuietly == true &&
                                                        _messages.firstOrNull?.didNotifyRecipient == false;
                                                    return Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            String.fromCharCode(moonIcon.codePoint),
                                                            style: TextStyle(
                                                              fontFamily: moonIcon.fontFamily,
                                                              package: moonIcon.fontPackage,
                                                              fontSize: context.theme.textTheme.bodyLarge!.fontSize,
                                                              color: showNotifyAnyways ? context.theme.colorScheme.outline : Colors.deepPurple,
                                                            ),
                                                          ),
                                                          Text(
                                                            " ${chat.title ?? "Recipient"} has notifications silenced",
                                                            style:
                                                                context.theme.textTheme.bodyLarge!.copyWith(color: showNotifyAnyways ? context.theme.colorScheme.outline : Colors.deepPurple),
                                                          ),
                                                        ],
                                                        ),
                                                      showNotifyAnyways ? TextButton(
                                                        child: Text("Notify Anyway",
                                                            style: context.theme.textTheme.labelLarge!
                                                                .copyWith(color: Colors.deepPurple)),
                                                        style: TextButton.styleFrom(
                                                          padding: EdgeInsets.zero,
                                                          minimumSize: Size(50, 30),
                                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                          alignment: Alignment.centerLeft),
                                                        onPressed: () async {
                                                          var msg = await api.newMsg(
                                                            conversation: await chat.getConversationData(),
                                                            sender: await chat.ensureHandle(),
                                                            message: const api.Message.notifyAnyways(),
                                                          );
                                                          msg.id = _messages.first.guid!;
                                                          try {
                                                            await (backend as RustPushBackend).sendMsg(msg);
                                                          } catch (e) {
                                                            Logger.error(e);
                                                            if (!chat.isRpSms) {
                                                              rethrow; // APN errors are fatal for non-SMS messages
                                                            }
                                                          }
                                                          _messages.first.wasDeliveredQuietly = false;
                                                          _messages.first.save();
                                                          eventDispatcher.emit("message-updated-${_messages.first.guid}");
                                                          latestMessageDeliveredState.value = true;
                                                          latestMessageDeliveredState.value = false;
                                                          chat.dateNotifiedAnyways = DateTime.now();
                                                          chat.save(updateDateNotifiedAnyways: true);
                                                        },
                                                      ) : const SizedBox.shrink()
                                                    ],
                                                  );
                                                  })
                                                )
                                              : ConstrainedBox(
                                                constraints: const BoxConstraints(
                                                  minWidth: double.infinity, // Fix the width
                                                  maxWidth: double.infinity,
                                                ),
                                                child: const SizedBox.shrink(),
                                              )),
                                        ),
                                        alignment: Alignment.center,
                                        ),
                                        if (!chat.isGroup && chat.isIMessage)
                                        Align(child:AnimatedSize(
                                          duration: const Duration(milliseconds: 250),
                                          child: Obx(() => controller.reportJunkAvailable.value
                                              ? Padding(
                                                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                                                  child: GestureDetector(
                                                    child: RichText(
                                                      textAlign: TextAlign.center,
                                                      text: TextSpan(
                                                        style: context.theme.textTheme.labelMedium!.copyWith(color: context.theme.colorScheme.outline, fontWeight: FontWeight.normal),
                                                        children: [
                                                          TextSpan(
                                                            text: "This sender is not in your contacts\n",
                                                            style: context.theme.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600, color: context.theme.colorScheme.outline, height: 2.5),
                                                          ),
                                                          TextSpan(
                                                            text: "Report Junk",
                                                            style: context.theme.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600, color: context.theme.primaryColor),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    onTap: () async {
                                                      showDialog(
                                                        context: Get.context!,
                                                        builder: (BuildContext context) {
                                                          return AlertDialog(
                                                            title: Text(
                                                              "Report junk?",
                                                              style: context.theme.textTheme.titleLarge,
                                                            ),
                                                            backgroundColor: context.theme.colorScheme.properSurface,
                                                            content: Text("You can report this message to Apple.", style: context.theme.textTheme.bodyLarge),
                                                            actions: <Widget>[
                                                              TextButton(
                                                                child: Text("Cancel",
                                                                    style: context.theme.textTheme.bodyLarge!
                                                                        .copyWith(color: context.theme.colorScheme.primary)),
                                                                onPressed: () {
                                                                  Navigator.of(context).pop();
                                                                },
                                                              ),
                                                              TextButton(
                                                                child: Text("Delete and Report",
                                                                    style: context.theme.textTheme.bodyLarge!
                                                                        .copyWith(color: context.theme.colorScheme.primary)),
                                                                onPressed: () async {
                                                                  Navigator.of(context).pop();
                                                                  Navigator.of(context).pop();
                                                                  try {
                                                                    await pushService.markAsSpam(chat);
                                                                  } catch (e, s) {
                                                                    showSnackbar("Failed to mark as spam!", "$e");
                                                                    Logger.error("Failed to mark as spam", error: e, trace: s);
                                                                    rethrow;
                                                                  }
                                                                },
                                                              ),
                                                            ],
                                                          );
                                                        });
                                                    },
                                                  )
                                                )
                                              : ConstrainedBox(
                                                constraints: const BoxConstraints(
                                                  minWidth: double.infinity, // Fix the width
                                                  maxWidth: double.infinity,
                                                ),
                                                child: const SizedBox.shrink(),
                                              )),
                                        ),
                                        alignment: Alignment.center,
                                        ),
                                      Obx(() => Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                if (controller.showTypingIndicatorFor.isNotEmpty && (chat.isGroup || ss.settings.alwaysShowAvatars.value) && iOS)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 10.0),
                                                    child: ContactAvatarGroupWidget(
                                                      participants: [...controller.showTypingIndicatorFor],
                                                      size: 30,
                                                      editable: false,
                                                    ),
                                                  ),
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 5),
                                                  child: TypingIndicator(
                                                    controller: controller,
                                                  ),
                                                ),
                                              ],
                                            ))
                                    ],
                                  );
                                }
                                return AutoScrollTag(
                                    key: ValueKey("${message.guid!}-scrolling"),
                                    index: index,
                                    controller: scrollController,
                                    highlightColor: context.theme.colorScheme.surface.withOpacity(0.7),
                                    child: toReturn);
                              }),
                          const SliverPadding(
                            padding: EdgeInsets.all(70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Obx(
                () => AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  color: context.theme.colorScheme.surface.withOpacity(dragging.value ? 0.4 : 0),
                  child: dragging.value
                      ? Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(iOS ? CupertinoIcons.paperclip : Icons.attach_file, color: context.theme.colorScheme.primary, size: 50),
                              Text("Attach ${numFiles.value} File${numFiles.value > 1 ? 's' : ''}",
                                  style: context.theme.textTheme.headlineLarge!.copyWith(color: context.theme.colorScheme.primary)),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          )),
    );
  }
}

class Loader extends StatelessWidget {
  const Loader({this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            text ?? "Loading more messages...",
            style: context.theme.textTheme.labelLarge!.copyWith(color: context.theme.colorScheme.outline),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ss.settings.skin.value == Skins.iOS
              ? Theme(
                  data: ThemeData(
                    cupertinoOverrideTheme: const CupertinoThemeData(brightness: Brightness.dark),
                  ),
                  child: const CupertinoActivityIndicator(),
                )
              : const SizedBox(height: 20, width: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      ],
    );
  }
}
