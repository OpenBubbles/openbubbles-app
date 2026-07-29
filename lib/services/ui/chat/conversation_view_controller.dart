import 'dart:async';
import 'dart:isolate';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:bluebubbles/app/components/custom_text_editing_controllers.dart';
import 'package:bluebubbles/app/layouts/settings/pages/profile/posterkit.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/memory/bounded_byte_cache.dart';
import 'package:bluebubbles/helpers/memory/bounded_lru_map.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:emojis/emoji.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:google_ml_kit/google_ml_kit.dart' hide Message;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:tuple/tuple.dart';
import 'package:universal_io/io.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'dart:ui' as ui;

ConversationViewController cvc(Chat chat, {String? tag}) =>
    Get.isRegistered<ConversationViewController>(tag: tag ?? chat.guid)
        ? Get.find<ConversationViewController>(tag: tag ?? chat.guid)
        : Get.put(ConversationViewController(chat, tag_: tag),
            tag: tag ?? chat.guid);

class ConversationViewController extends StatefulController
    with GetSingleTickerProviderStateMixin {
  final Chat chat;
  late final String tag;
  bool fromChatCreator = false;
  bool addedRecentPhotoReply = false;
  final AutoScrollController scrollController = AutoScrollController();

  ConversationViewController(this.chat, {String? tag_}) {
    tag = tag_ ?? chat.guid;
    recipientNotifsSilenced.value = chat.notifsSilenced;
    reportJunkAvailable.value = !(chat.senderIsKnown ?? true);
  }

  // caching items
  static const int attachmentCacheMaximumBytes = 32 * 1024 * 1024;
  static const int attachmentCacheMaximumEntries = 48;
  final BoundedByteCache imageData = BoundedByteCache(
    maximumSizeBytes: attachmentCacheMaximumBytes,
    maximumEntries: attachmentCacheMaximumEntries,
  );
  final List<_PendingImageLoad> _imageCacheQueue = [];
  final Map<String, Future<Uint8List>> _pendingImageLoads = {};
  _PendingImageLoad? _activeImageLoad;
  final BoundedLruMap<String, Map<String, (Uint8List, StickerData?)>>
      stickerData = BoundedLruMap(
    maximumEntries: 64,
    maximumWeight: 16 * 1024 * 1024,
    weightOf: (stickers) => stickers.values.fold(
      0,
      (total, sticker) => total + sticker.$1.lengthInBytes,
    ),
  );
  final BoundedLruMap<String, Metadata> legacyUrlPreviews =
      BoundedLruMap(maximumEntries: 64);
  final Map<String, VideoController> videoPlayers = {};
  final Map<String, PlayerController> audioPlayers = {};
  final Map<String, Player> audioPlayersDesktop = {};
  final BoundedLruMap<String, List<EntityAnnotation>> mlKitParsedText =
      BoundedLruMap(maximumEntries: 256);

  // message view items
  final RxList<Handle> showTypingIndicatorFor = <Handle>[].obs;
  final RxBool showScrollDown = false.obs;
  final RxDouble timestampOffset = 0.0.obs;
  final RxBool inSelectMode = false.obs;
  final RxList<Message> selected = <Message>[].obs;
  final RxList<Tuple3<Message, MessagePart, MentionTextEditingController>>
      editing =
      <Tuple3<Message, MessagePart, MentionTextEditingController>>[].obs;
  final GlobalKey focusInfoKey = GlobalKey();
  final RxBool recipientNotifsSilenced = false.obs;
  bool showingOverlays = false;
  bool _subjectWasLastFocused =
      false; // If this is false, then message field was last focused (default)
  final Map<String, (StreamSubscription<dynamic>, Uint8List?)>
      typingIndicatorData = {};

  FocusNode get lastFocusedNode =>
      _subjectWasLastFocused ? subjectFocusNode : focusNode;
  SpellCheckTextEditingController get lastFocusedTextController =>
      _subjectWasLastFocused ? subjectTextController : textController;

  // text field items
  bool showAttachmentPicker = false;
  RxBool showEmojiPicker = false.obs;
  final GlobalKey textFieldKey = GlobalKey();
  final RxList<PlatformFile> pickedAttachments = <PlatformFile>[].obs;
  final focusNode = FocusNode();
  final subjectFocusNode = FocusNode();
  final headerBackFocusNode = FocusNode();
  FocusNode? bottomMessageFocusNode;
  late final textController = MentionTextEditingController(
      focusNode: focusNode, supportsFormatting: chat.isIMessage);
  late final subjectTextController =
      SpellCheckTextEditingController(focusNode: subjectFocusNode);
  final Rx<(PlatformFile?, PayloadData)?> pickedApp =
      Rx<(PlatformFile?, PayloadData)?>(null);
  final RxBool showRecording = false.obs;
  final RxList<Emoji> emojiMatches = <Emoji>[].obs;
  final RxInt emojiSelectedIndex = 0.obs;
  final RxList<Mentionable> mentionMatches = <Mentionable>[].obs;
  final RxInt mentionSelectedIndex = 0.obs;
  final ScrollController emojiScrollController = ScrollController();
  final Rxn<DateTime> scheduledDate = Rxn<DateTime>(null);
  final Rxn<Tuple2<Message, int>> _replyToMessage =
      Rxn<Tuple2<Message, int>>(null);
  Tuple2<Message, int>? get replyToMessage => _replyToMessage.value;
  set replyToMessage(Tuple2<Message, int>? m) {
    _replyToMessage.value = m;
    if (m != null) {
      lastFocusedNode.requestFocus();
    }
  }

  late final mentionables = chat.participants
      .map((e) => Mentionable(
            handle: e,
          ))
      .toList();

  final Rxn<Contact> suggestedContact = Rxn<Contact>(null);
  final RxBool suggestShare = false.obs;
  bool keyboardOpen = false;
  double _keyboardOffset = 0;
  Timer? _scrollDownDebounce;
  StreamSubscription<bool>? keyboardVisibilitySubscription;
  Future<void> Function(
      Tuple7<List<PlatformFile>, AttributedBody, String, String?, int?, String?,
          PayloadData?>,
      bool,
      DateTime?)? sendFunc;
  bool isProcessingImage = false;

  final Rxn<api.SimplifiedTranscriptPoster> backgroundPoster =
      Rxn<api.SimplifiedTranscriptPoster>(null);
  Map<String, ui.Image> images = {};

  final RxBool reportJunkAvailable = false.obs;
  Timer? _debounceTyping;
  bool _isClosed = false;
  int _posterGeneration = 0;

  void clearTypingState() {
    _debounceTyping = null;
  }

  void triggerTypingIndicator() {
    // don't send a bunch of duplicate events for every typing change
    if (!ss.settings.enablePrivateAPI.value ||
        !(chat.autoSendTypingIndicators ??
            ss.settings.privateSendTypingIndicators.value)) return;
    _debounceTyping?.cancel();
    if (_debounceTyping == null) {
      var a = pickedApp.value?.$2.appData?.firstOrNull;
      // only other app is Polls atm. Built-in apps have a circle icon which does not work with typing indicators.
      backend.startedTyping(chat, a?.appId != null ? a : null);
    }
    _debounceTyping = Timer(const Duration(seconds: 5), () {
      backend.stoppedTyping(chat);
      _debounceTyping = null;
    });
  }

  void updateContactInfo() {
    if (chat.participants.length == 1) {
      Contact? sharedContact;
      if ((chat.participants.first.contact?.isShared ?? false)) {
        sharedContact = chat.participants.firstOrNull!.contact!;
      } else {
        sharedContact = Contact.findOne(
            address: chat.participants.firstOrNull!.address, wantShared: true);
      }
      if (sharedContact != null && !sharedContact.isDismissed) {
        suggestedContact.value = sharedContact;
      }

      // (not in our contacts or contact sharing disabled) and not shared
      suggestShare.value =
          ((chat.participants.first.contact?.isShared ?? true) ||
                  !ss.settings.shareContactAutomatically.value) &&
              !ss.settings.sharedContacts
                  .contains(chat.participants.first.address) &&
              !ss.settings.dismissedContacts
                  .contains(chat.participants.first.address) &&
              ss.settings.nameAndPhotoSharing.value &&
              chat.isIMessage;
    }
  }

  StreamSubscription<int>? shareSubscription;

  @override
  void onInit() {
    super.onInit();

    shareSubscription =
        ss.settings.shareVersion.listen((s) => updateContactInfo());

    updateContactInfo();

    textController.mentionables = mentionables;
    keyboardVisibilitySubscription =
        KeyboardVisibilityController().onChange.listen((bool visible) async {
      keyboardOpen = visible;
      if (scrollController.hasClients) {
        _keyboardOffset = scrollController.offset;
      }
    });

    scrollController.addListener(() {
      if (!scrollController.hasClients) return;
      if (keyboardOpen &&
          ss.settings.hideKeyboardOnScroll.value &&
          scrollController.offset > _keyboardOffset + 100) {
        focusNode.unfocus();
        subjectFocusNode.unfocus();
      }

      if (showScrollDown.value && scrollController.offset >= 500) return;
      if (!showScrollDown.value && scrollController.offset < 500) return;

      if (scrollController.offset >= 500 && !showScrollDown.value) {
        showScrollDown.value = true;
        if (_scrollDownDebounce?.isActive ?? false) {
          _scrollDownDebounce?.cancel();
        }
        _scrollDownDebounce = Timer(const Duration(seconds: 3), () {
          showScrollDown.value = false;
        });
      } else if (showScrollDown.value) {
        showScrollDown.value = false;
      }
    });

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        _subjectWasLastFocused = false;
      }
    });

    subjectFocusNode.addListener(() {
      if (subjectFocusNode.hasFocus) {
        _subjectWasLastFocused = true;
      }
    });
  }

  void updatePoster() async {
    final generation = ++_posterGeneration;
    if (chat.transcriptPosterPath == null) {
      _disposePosterImages();
      backgroundPoster.value = null;
      return;
    }
    var data = await File("${chat.transcriptPosterPath}.jpg").readAsBytes();
    var poster = await api.fromTranscriptPosterSave(poster: data);
    if (_isClosed || generation != _posterGeneration) return;
    final loadedImages =
        await loadPosterImages(chat.transcriptPosterPath!, poster.poster);
    if (_isClosed || generation != _posterGeneration) {
      for (final image in loadedImages.values) {
        image.dispose();
      }
      return;
    }
    _disposePosterImages();
    images = loadedImages;
    backgroundPoster.value = poster;
  }

  void _disposePosterImages() {
    for (final image in images.values) {
      image.dispose();
    }
    images = {};
  }

  void pauseMediaPlayers() {
    for (final controller in videoPlayers.values) {
      unawaited(controller.player.pause());
    }
    for (final controller in audioPlayers.values) {
      unawaited(controller.pausePlayer());
    }
    for (final controller in audioPlayersDesktop.values) {
      unawaited(controller.pause());
    }
  }

  @override
  void onClose() {
    _isClosed = true;
    _posterGeneration++;
    final activeLoad = _activeImageLoad;
    if (activeLoad != null && !activeLoad.completer.isCompleted) {
      activeLoad.completer.complete(Uint8List(0));
    }
    for (final queued in _imageCacheQueue) {
      if (!queued.completer.isCompleted) {
        queued.completer.complete(Uint8List(0));
      }
    }
    _imageCacheQueue.clear();
    _pendingImageLoads.clear();
    pauseMediaPlayers();
    videoPlayers.clear();
    audioPlayers.clear();
    audioPlayersDesktop.clear();
    imageData.clear();
    stickerData.clear();
    legacyUrlPreviews.clear();
    mlKitParsedText.clear();
    _disposePosterImages();
    _scrollDownDebounce?.cancel();
    _debounceTyping?.cancel();
    for (final typingState in typingIndicatorData.values) {
      unawaited(typingState.$1.cancel());
    }
    typingIndicatorData.clear();
    scrollController.dispose();
    emojiScrollController.dispose();
    headerBackFocusNode.dispose();
    shareSubscription?.cancel();
    keyboardVisibilitySubscription?.cancel();
    super.onClose();
  }

  void dismissKeyboard() {
    focusNode.unfocus();
    subjectFocusNode.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  Future<void> scrollToBottom() async {
    if (scrollController.positions.isNotEmpty &&
        scrollController.positions.first.extentBefore > 0) {
      await scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    }

    if (ss.settings.openKeyboardOnSTB.value) {
      focusNode.requestFocus();
    }
  }

  Future<void> scrollToTime(DateTime time) async {
    var messages = ms(chat.guid).struct.messages;
    messages.sort(Message.sort);
    if (scrollController.positions.isNotEmpty) {
      var test = messages.indexWhere(
          (element) => element.chatViewDate?.isBefore(time) ?? false);
      await scrollController.scrollToIndex(test,
          preferPosition: AutoScrollPosition.begin);
    }

    if (ss.settings.openKeyboardOnSTB.value) {
      focusNode.requestFocus();
    }
  }

  Future<void> send(
      List<PlatformFile> attachments,
      AttributedBody text,
      String subject,
      String? replyGuid,
      int? replyPart,
      String? effectId,
      PayloadData? payload,
      bool isAudioMessage,
      DateTime? scheduledDate) async {
    sendFunc?.call(
        Tuple7(attachments, text, subject, replyGuid, replyPart, effectId,
            payload),
        isAudioMessage,
        scheduledDate);
  }

  Future<Uint8List> queueImage(Attachment attachment, PlatformFile file) {
    final guid = attachment.guid;
    if (guid == null) return Future.value(Uint8List(0));
    final cached = imageData[guid];
    if (cached != null) return Future.value(cached);
    final pending = _pendingImageLoads[guid];
    if (pending != null) return pending;

    if (_isClosed) {
      return Future.value(Uint8List(0));
    }

    final completer = Completer<Uint8List>();
    final load = _PendingImageLoad(attachment, file, completer);
    _imageCacheQueue.add(load);
    _pendingImageLoads[guid] = completer.future;
    completer.future.then((_) {
      if (identical(_pendingImageLoads[guid], completer.future)) {
        _pendingImageLoads.remove(guid);
      }
    });
    if (!isProcessingImage) _processNextImage();
    return completer.future;
  }

  Future<void> _processNextImage() async {
    isProcessingImage = true;
    try {
      while (!_isClosed && _imageCacheQueue.isNotEmpty) {
        final queued = _imageCacheQueue.removeAt(0);
        _activeImageLoad = queued;
        final attachment = queued.attachment;
        final file = queued.file;
        Uint8List? tmpData;
        try {
          // If it's an image, compress the image when loading it.
          if (kIsWeb || file.path == null) {
            if (attachment.mimeType?.contains("image/tif") ?? false) {
              final receivePort = ReceivePort();
              await Isolate.spawn(unsupportedToPngIsolate,
                  IsolateData(file, receivePort.sendPort));
              tmpData = await receivePort.first as Uint8List?;
            } else {
              tmpData = file.bytes;
            }
          } else if (attachment.canCompress) {
            tmpData = await as.loadAndGetProperties(
              attachment,
              actualPath: file.path!,
            );
          } else {
            tmpData = await File(file.path!).readAsBytes();
          }
        } catch (error, stackTrace) {
          Logger.warn(
            "Failed to prepare attachment preview",
            error: error,
            trace: stackTrace,
          );
        }

        if (_isClosed || tmpData == null) {
          if (!queued.completer.isCompleted) {
            queued.completer.complete(Uint8List(0));
          }
          continue;
        }

        imageData[attachment.guid!] = tmpData;
        if (!queued.completer.isCompleted) {
          queued.completer.complete(tmpData);
        }
      }
    } finally {
      _activeImageLoad = null;
      isProcessingImage = false;
    }
  }

  bool isSelected(String guid) {
    return selected.firstWhereOrNull((e) => e.guid == guid) != null;
  }

  bool isEditing(String guid, int part) {
    return editing.firstWhereOrNull(
            (e) => e.item1.guid == guid && e.item2.part == part) !=
        null;
  }

  void close() {
    eventDispatcher.emit("update-highlight", null);
    cm.setAllInactiveSync();
    Get.delete<ConversationViewController>(tag: tag);
  }

  Future<void> saveReplyToMessageState() async {
    if (replyToMessage != null) {
      await ss.prefs.setString(
          'replyToMessage_${chat.guid}', replyToMessage!.item1.guid!);
      await ss.prefs
          .setInt('replyToMessagePart_${chat.guid}', replyToMessage!.item2);
    } else {
      await ss.prefs.remove('replyToMessage_${chat.guid}');
      await ss.prefs.remove('replyToMessagePart_${chat.guid}');
    }
  }

  Future<void> loadReplyToMessageState() async {
    final replyToMessageGuid =
        ss.prefs.getString('replyToMessage_${chat.guid}');
    final replyToMessagePart =
        ss.prefs.getInt('replyToMessagePart_${chat.guid}');
    if (replyToMessageGuid != null && replyToMessagePart != null) {
      final message = Message.findOne(guid: replyToMessageGuid);
      if (message != null) {
        replyToMessage = Tuple2(message, replyToMessagePart);
      }
    }
  }
}

class _PendingImageLoad {
  const _PendingImageLoad(this.attachment, this.file, this.completer);

  final Attachment attachment;
  final PlatformFile file;
  final Completer<Uint8List> completer;
}
