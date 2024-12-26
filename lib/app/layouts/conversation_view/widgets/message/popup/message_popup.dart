import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:bluebubbles/app/components/custom_text_editing_controllers.dart';
import 'package:bluebubbles/app/layouts/chat_creator/chat_creator.dart';
import 'package:bluebubbles/app/layouts/conversation_details/dialogs/timeframe_picker.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/attachment/attachment_holder.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/interactive/embedded_media.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/popup/details_menu_action.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/popup/reaction_picker_clipper.dart';
import 'package:bluebubbles/app/components/avatars/contact_avatar_widget.dart';
import 'package:bluebubbles/app/components/custom/custom_cupertino_alert_dialog.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/reaction/reaction_clipper.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_pin_clipper.dart';
import 'package:bluebubbles/app/wrappers/theme_switcher.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/layouts/conversation_view/pages/conversation_view.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/reply/reply_thread_popup.dart';
import 'package:bluebubbles/app/wrappers/titlebar_wrapper.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/utils/share.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide BackButton;
import 'package:bluebubbles/database/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:intl/intl.dart';
import 'package:path/path.dart' hide context;
import 'package:permission_handler/permission_handler.dart';
import 'package:sprung/sprung.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:universal_io/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MessagePopup extends StatefulWidget {
  final Offset childPosition;
  final Size size;
  final Widget child;
  final MessagePart part;
  final MessageWidgetController controller;
  final ConversationViewController cvController;
  final Tuple3<bool, bool, bool> serverDetails;
  final Function([String? type, String? emoji, int? part]) sendTapback;
  final BuildContext? Function() widthContext;

  const MessagePopup({
    super.key,
    required this.childPosition,
    required this.size,
    required this.child,
    required this.part,
    required this.controller,
    required this.cvController,
    required this.serverDetails,
    required this.sendTapback,
    required this.widthContext,
  });

  @override
  State<StatefulWidget> createState() => _MessagePopupState();
}

class _MessagePopupState extends OptimizedState<MessagePopup> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    animationBehavior: AnimationBehavior.preserve,
  );
  final double itemHeight = kIsDesktop || kIsWeb ? 56 : 48;

  List<Message> reactions = [];
  late double messageOffset = Get.height - widget.childPosition.dy - widget.size.height;
  late double materialOffset = widget.childPosition.dy +
      EdgeInsets.fromViewPadding(
        View.of(context).viewInsets,
        View.of(context).devicePixelRatio,
      ).bottom;
  late int numberToShow = 5;
  late Chat? dmChat = chats.chats
      .firstWhereOrNull((chat) => !chat.isGroup && chat.participants.firstWhereOrNull((handle) => handle.address == message.handle?.address) != null);
  String? selfReaction;
  String? currentlySelectedReaction = "init";

  ConversationViewController get cvController => widget.cvController;

  MessagesService get service => ms(chat.guid);

  Chat get chat => widget.cvController.chat;

  MessagePart get part => widget.part;

  Message get message => widget.controller.message;

  bool get isSent => !message.guid!.startsWith('temp') && !message.guid!.startsWith('error');

  bool get showDownload =>
      (isSent && part.attachments.isNotEmpty && part.attachments.where((element) => as.getContent(element) is PlatformFile).isNotEmpty) ||
      isEmbeddedMedia;

  late bool isEmbeddedMedia = (message.balloonBundleId == "com.apple.Handwriting.HandwritingProvider" ||
          message.balloonBundleId == "com.apple.DigitalTouchBalloonProvider") &&
      File(message.interactiveMediaPath!).existsSync();

  bool get minSierra => widget.serverDetails.item1;

  bool get minBigSur => widget.serverDetails.item2;

  bool get supportsOriginalDownload => widget.serverDetails.item3;

  BuildContext get widthContext => widget.widthContext.call() ?? context;

  List<String> reactOptions = ReactionTypes.toList();
  @override
  void initState() {
    super.initState();
    controller.forward();
    if (iOS) {
      final remainingHeight = max(Get.height - Get.statusBarHeight - 135 - widget.size.height, itemHeight);
      numberToShow = min(remainingHeight ~/ itemHeight, 5);
    } else {
      // Potentially make this dynamic in the future
      numberToShow = 5;
    }

    updateObx(() {
      currentlySelectedReaction = null;
      reactions = getUniqueReactionMessages(message.associatedMessages
          .where((e) => ReactionTypes.toList().contains(e.associatedMessageType?.replaceAll("-", "")) && (e.associatedMessagePart ?? 0) == part.part)
          .toList());
      final reaction = reactions.firstWhereOrNull((e) => e.isFromMe!);
      final myReact = reaction?.associatedMessageType;
      if (!(myReact?.contains("-") ?? true)) {
        selfReaction = myReact == "emoji" ? reaction!.associatedMessageEmoji : myReact;
        currentlySelectedReaction = selfReaction;
      }

      (() async {
      var reactions = await getReactionList();
        setState(() {
          reactOptions = reactions;
          if (reactions.length == 6) {
            emojiMode = 0;
            emojiPickerSize = iOS ? 280 : 286;
          } else if (reactions.length == 7) {
            emojiMode = 1;
            emojiPickerSize = iOS ? 325 : 331;
          } else {
            emojiMode = 2;
            emojiPickerSize = iOS ? 350 : 356;
          }
        });
      })();

      for (Message m in reactions) {
        if (m.isFromMe!) {
          m.handle = null;
        } else {
          m.handle ??= m.getHandle();
        }
      }
      setState(() {
        if (iOS) messageOffset = itemHeight * numberToShow + 40;
      });
    });
  }

  Map<String, Emoji> emojiMap = {};

  Future<List<String>> getReactionList() async {
    final recentEmojis = await EmojiPickerUtils().getRecentEmojis();

    var reactions = ReactionTypes.toList().where((i) => ReactionTypes.reactionToEmoji.containsKey(i)).toList();

    if (currentlySelectedReaction != "init" && currentlySelectedReaction != null && !reactions.contains(currentlySelectedReaction)) {
      reactions.add(currentlySelectedReaction!); // add current reaction
    }

    for (var emoji in recentEmojis.take(10)) {
      if (reactions.contains(emoji.emoji.emoji)) continue;
      reactions.add(emoji.emoji.emoji);
      emojiMap[emoji.emoji.emoji] = emoji.emoji;
    }

    var emojis = ["❤️", "😍", "😒", "👌", "☺️", "😊", "😘", "😭", "😩", "💕"];
    while (reactions.length < 16 && emojis.isNotEmpty) {
      var emoji = emojis.removeAt(0);
      if (reactions.contains(emoji)) continue;
      reactions.add(emoji);
    }

    
    
    return reactions;
  }

  void reactEmoji(String emoji) {
    HapticFeedback.lightImpact();
    widget.sendTapback(selfReaction == emoji ? "-${ReactionTypes.EMOJI}" : ReactionTypes.EMOJI, emoji, part.part);
    popDetails();
  }

  static const double iosSize = 50;

  int emojiMode = 1;
  int emojiPickerSize = 325;

  void popDetails({bool returnVal = true}) {
    bool dialogOpen = Get.isDialogOpen ?? false;
    if (dialogOpen) {
      if (kIsWeb) {
        Get.back();
      } else {
        Navigator.of(context).pop();
      }
    }
    Navigator.of(context).pop(returnVal);
  }

  @override
  Widget build(BuildContext context) {
    double narrowWidth = message.isFromMe! || !ss.settings.alwaysShowAvatars.value ? 330 : 360;
    bool narrowScreen = ns.width(widthContext) < narrowWidth;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: ss.settings.immersiveMode.value ? Colors.transparent : context.theme.colorScheme.background, // navigation bar color
        systemNavigationBarIconBrightness: context.theme.colorScheme.brightness.opposite,
        statusBarColor: Colors.transparent, // status bar color
        statusBarIconBrightness: context.theme.colorScheme.brightness.opposite,
      ),
      child: Theme(
        data: context.theme.copyWith(
          // in case some components still use legacy theming
          primaryColor: context.theme.colorScheme.bubble(context, chat.isIMessage),
          colorScheme: context.theme.colorScheme.copyWith(
            primary: context.theme.colorScheme.bubble(context, chat.isIMessage),
            onPrimary: context.theme.colorScheme.onBubble(context, chat.isIMessage),
            surface:
                ss.settings.monetTheming.value == Monet.full ? null : (context.theme.extensions[BubbleColors] as BubbleColors?)?.receivedBubbleColor,
            onSurface: ss.settings.monetTheming.value == Monet.full
                ? null
                : (context.theme.extensions[BubbleColors] as BubbleColors?)?.onReceivedBubbleColor,
          ),
        ),
        child: TitleBarWrapper(
            child: Scaffold(
                extendBodyBehindAppBar: true,
                backgroundColor: kIsDesktop && iOS && ss.settings.windowEffect.value != WindowEffect.disabled
                    ? context.theme.colorScheme.properSurface.withOpacity(0.6)
                    : Colors.transparent,
                appBar: iOS
                    ? null
                    : AppBar(
                        backgroundColor: context.theme.colorScheme.background.oppositeLightenOrDarken(5),
                        systemOverlayStyle:
                            context.theme.colorScheme.brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
                        automaticallyImplyLeading: false,
                        leadingWidth: 40,
                        toolbarHeight: kIsDesktop ? 80 : null,
                        leading: Padding(
                          padding: EdgeInsets.only(top: kIsDesktop ? 20 : 0, left: 10.0),
                          child: BackButton(
                            color: context.theme.colorScheme.onBackground,
                            onPressed: () {
                              popDetails();
                              return true;
                            },
                          ),
                        ),
                        actions: buildMaterialDetailsMenu(context),
                ),
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: popDetails,
                      child: iOS
                          ? (ss.settings.highPerfMode.value
                              ? Container(color: context.theme.colorScheme.background.withOpacity(0.8))
                              : BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: kIsDesktop && ss.settings.windowEffect.value != WindowEffect.disabled ? 10 : 30,
                                      sigmaY: kIsDesktop && ss.settings.windowEffect.value != WindowEffect.disabled ? 10 : 30),
                                  child: Container(
                                    color: context.theme.colorScheme.properSurface.withOpacity(0.3),
                                  ),
                                ))
                          : null,
                    ),
                    if (iOS)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        left: widget.childPosition.dx,
                        bottom: messageOffset,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.8, end: 1),
                          curve: Curves.easeOutBack,
                          duration: const Duration(milliseconds: 500),
                          child: ConstrainedBox(constraints: BoxConstraints(maxWidth: widget.size.width), child: widget.child),
                          builder: (context, size, child) {
                            return Transform.scale(
                              scale: size.clamp(1, double.infinity),
                              child: child,
                              alignment: message.isFromMe! ? Alignment.centerRight : Alignment.centerLeft,
                            );
                          },
                        ),
                      ),
                    if (iOS)
                      Positioned(
                        top: 40,
                        left: 15,
                        right: 15,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 500),
                          curve: Sprung.underDamped,
                          alignment: Alignment.center,
                          child: reactions.isNotEmpty ? ReactionDetails(reactions: reactions) : const SizedBox.shrink(),
                        ),
                      ),
                    if (ss.settings.enablePrivateAPI.value && isSent && minSierra && chat.isIMessage && message.dateScheduled == null)
                      Positioned(
                        bottom: (iOS ? itemHeight * numberToShow + 35 + widget.size.height : context.height - materialOffset)
                            .clamp(0, context.height - (narrowScreen ? 200 : 125)),
                        right: message.isFromMe! ? max(15, widget.size.width - emojiPickerSize + 65) : null,
                        left: !message.isFromMe! ? max(widget.childPosition.dx + 10, widget.childPosition.dx + widget.size.width - emojiPickerSize + 65) : null,
                        child: AnimatedSize(
                          curve: Curves.easeInOut,
                          alignment: message.isFromMe! ? Alignment.centerRight : Alignment.centerLeft,
                          duration: const Duration(milliseconds: 250),
                          child: currentlySelectedReaction == "init"
                              ? const SizedBox(height: 80)
                              : ClipShadowPath(
                                  shadow: iOS
                                      ? BoxShadow(
                                          color: context.theme.colorScheme.properSurface.withAlpha(iOS ? 150 : 255).lightenOrDarken(iOS ? 0 : 10))
                                      : BoxShadow(
                                          color: context.theme.colorScheme.shadow,
                                          blurRadius: 2,
                                        ),
                                  clipper: ReactionPickerClipper(
                                    messageSize: widget.size,
                                    isFromMe: message.isFromMe!,
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                    child: Container(
                                      padding: const EdgeInsets.all(5).add(const EdgeInsets.only(bottom: 15)),
                                      color: context.theme.colorScheme.properSurface.lightenOrDarken(iOS ? 0 : 10),
                                      width: emojiPickerSize.toDouble(),
                                      child: ShaderMask(
                                        shaderCallback: (Rect rect) {
                                          return LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [Colors.transparent, emojiMode == 2 ? Colors.purple : Colors.transparent],
                                              stops: [0.9, 1.0], // 10% purple, 80% transparent, 10% purple
                                            ).createShader(rect);
                                        },
                                        blendMode: BlendMode.dstOut,
                                        child: 
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            padding: emojiMode == 2 ? const EdgeInsets.only(right: 25) : EdgeInsets.zero,
                                            child: Row(
                                            children: reactOptions
                                                .map((e) {
                                              return Padding(
                                                padding: iOS ? const EdgeInsets.all(5.0) : const EdgeInsets.symmetric(horizontal: 5),
                                                child: Material(
                                                  color: currentlySelectedReaction == e ? context.theme.colorScheme.primary : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: SizedBox(
                                                    width: iOS ? 35 : null,
                                                    height: iOS ? 35 : null,
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(20),
                                                      onTap: () {
                                                        if (currentlySelectedReaction == e) {
                                                          currentlySelectedReaction = null;
                                                        } else {
                                                          currentlySelectedReaction = e;
                                                        }
                                                        setState(() {});
                                                        if (ReactionTypes.toList().contains(e)) {
                                                          HapticFeedback.lightImpact();
                                                          widget.sendTapback(selfReaction == e ? "-$e" : e, null, part.part);
                                                          popDetails();
                                                        } else {
                                                          if (selfReaction != e) {
                                                            (() async {
                                                              // Add an emoji to recently used list or increase its counter
                                                              Emoji? emoji = emojiMap[e];
                                                              if (emoji == null) {
                                                                outerLoop:
                                                                for (var category in defaultEmojiSet) {
                                                                  for (var myEmoji in category.emoji) {
                                                                    if (myEmoji.emoji == e) {
                                                                      emojiMap[e] = myEmoji;
                                                                      emoji = myEmoji;
                                                                      break outerLoop;
                                                                    }
                                                                  }
                                                                }
                                                              }
                                                              if (emoji != null) await EmojiPickerUtils().addEmojiToRecentlyUsed(key: GlobalKey(), emoji: emoji);
                                                            })();
                                                          }
                                                          reactEmoji(e);
                                                        }
                                                      },
                                                      child: Padding(
                                                        padding: EdgeInsets.symmetric(horizontal: 6.5, vertical: iOS ? 4.5 : 6.5).add(EdgeInsets.only(right: e == "emphasize" ? 2.5 : 0)),
                                                        child: Center(
                                                          child: Builder(builder: (context) {
                                                            final text = Text(
                                                              ReactionTypes.reactionToEmoji[e] ?? e ?? "X",
                                                              style: const TextStyle(fontSize: 18, fontFamily: 'Apple Color Emoji'),
                                                              textAlign: TextAlign.center,
                                                            );
                                                            // rotate thumbs down to match iOS
                                                            if (e == "dislike") {
                                                              return Transform(
                                                                transform: Matrix4.identity()..rotateY(pi),
                                                                alignment: FractionalOffset.center,
                                                                child: text,
                                                              );
                                                            }
                                                            return text;
                                                          }),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                      ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    if (ss.settings.enablePrivateAPI.value && isSent && minSierra && chat.isIMessage && message.dateScheduled == null)
                      Positioned(
                        bottom: (iOS ? itemHeight * numberToShow + 5 + widget.size.height : context.height - materialOffset)
                            .clamp(0, context.height - (narrowScreen ? 200 : 125)),
                        right: message.isFromMe! ? widget.size.width + 10 + (iOS ? 0 : 60) : null,
                        left: !message.isFromMe! ? widget.childPosition.dx + widget.size.width + 10 + (iOS ? 0 : 60) : null,
                        child: AnimatedSize(
                          curve: Curves.easeInOut,
                          alignment: message.isFromMe! ? Alignment.centerRight : Alignment.centerLeft,
                          duration: const Duration(milliseconds: 100),
                          
                          child: currentlySelectedReaction == "init"
                              ? const SizedBox(height: 80)
                              : ClipPath(
                          clipper: ReactionClipper(isFromMe: message.isFromMe!),
                          child: Material(
                            color: context.theme.colorScheme.properSurface,
                            child: Container(
                              width: iosSize,
                              height: iosSize,
                              alignment: message.isFromMe! ? Alignment.topRight : Alignment.topLeft,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {


                                  Widget content = Container(
                                    width: 512,
                                    child: Theme(
                                    data: context.theme.copyWith(canvasColor: Colors.transparent),
                                    child: EmojiPicker(
                                      scrollController: ScrollController(),
                                      config: Config(
                                        height: 512,
                                        checkPlatformCompatibility: true,
                                        emojiViewConfig: EmojiViewConfig(
                                          emojiSizeMax: 28,
                                          backgroundColor: Colors.transparent,
                                          columns: min(ns.width(context), 512) ~/ 56,
                                          noRecents: Text("No Recents", style: context.textTheme.headlineMedium!.copyWith(color: context.theme.colorScheme.outline))
                                        ),
                                        swapCategoryAndBottomBar: true,
                                        skinToneConfig: const SkinToneConfig(enabled: false),
                                        categoryViewConfig: const CategoryViewConfig(
                                          backgroundColor: Colors.transparent,
                                          dividerColor: Colors.transparent,
                                        ),
                                        bottomActionBarConfig: BottomActionBarConfig(
                                          customBottomActionBar: (Config config, EmojiViewState state, VoidCallback showSearchView) {
                                            return Container(
                                              margin: const EdgeInsets.only(top: 10),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Material(
                                                      child: InkWell(
                                                        onTap: showSearchView,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(12),
                                                          child: Row(children: [
                                                            Icon(
                                                              iOS ? cupertino.CupertinoIcons.search : Icons.search,
                                                              color: context.theme.colorScheme.outline,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                "Search...",
                                                                style: context.theme.textTheme.bodyLarge!.copyWith(
                                                                  color: context.theme.colorScheme.outline,
                                                                ),
                                                              ),
                                                            ),
                                                          ]),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.all(12),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        iOS ? cupertino.CupertinoIcons.xmark : Icons.close,
                                                        color: context.theme.colorScheme.outline,
                                                      ),
                                                      onPressed: () {
                                                        Get.back();
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        searchViewConfig: SearchViewConfig(
                                          backgroundColor: Colors.transparent,
                                          buttonIconColor: context.theme.colorScheme.outline,
                                        ),
                                      ),
                                      onEmojiSelected: (cat, emoji) {
                                        Get.back();
                                        reactEmoji(emoji.emoji);
                                      },
                                    ),
                                    )
                                  );
                                  Get.dialog(
                                      AlertDialog(
                                              backgroundColor: context.theme.colorScheme.properSurface,
                                              content: content,
                                            ),
                                      name: 'Popup Menu');
                                },
                                child: const SizedBox(
                                  width: iosSize*0.8,
                                  height: iosSize*0.8,
                                  child: Center(
                                    child: Icon(cupertino.CupertinoIcons.smiley, size: 20),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ),
                        ),
                      ),
                    if (iOS)
                      Positioned(
                        right: message.isFromMe! ? max(15, widget.size.width - maxMenuWidth) : null,
                        left: !message.isFromMe! ? max(widget.childPosition.dx + 10, widget.childPosition.dx + widget.size.width - maxMenuWidth) : null,
                        bottom: 30,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.8, end: 1),
                          curve: Curves.easeOutBack,
                          duration: const Duration(milliseconds: 400),
                          child: FadeTransition(
                            opacity: CurvedAnimation(
                              parent: controller,
                              curve: const Interval(0.0, .9, curve: Curves.ease),
                              reverseCurve: Curves.easeInCubic,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                buildDetailsMenu(context),
                              ],
                            ),
                          ),
                          builder: (context, size, child) {
                            return Transform.scale(
                              scale: size,
                              child: child,
                            );
                          },
                        ),
                      ),
                    if (!iOS && ss.settings.enablePrivateAPI.value && minBigSur && chat.isIMessage && isSent)
                      Positioned(
                        left: !message.isFromMe!
                            ? widget.childPosition.dx + widget.size.width + (reactions.isNotEmpty ? 20 : 5)
                            : widget.childPosition.dx - 55,
                        top: materialOffset,
                        child: Material(
                          color: context.theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 35,
                            height: 35,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: reply,
                              child: const Center(child: Icon(Icons.reply, size: 20)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ))),
      ),
    );
  }

  void reply() {
    popDetails();
    cvController.replyToMessage = Tuple2(message, part.part);
  }

  Future<void> download() async {
    try {
      dynamic content;
      if (isEmbeddedMedia) {
        content = PlatformFile(
          name: basename(message.interactiveMediaPath!),
          path: message.interactiveMediaPath,
          size: 0,
        );
      } else {
        content = as.getContent(part.attachments.first);
      }
      if (content is PlatformFile) {
        popDetails();
        await as.saveToDisk(content, isDocument: part.attachments.first.mimeStart != "image" && part.attachments.first.mimeStart != "video");
      }
    } catch (ex, trace) {
      Logger.error("Error downloading attachment: ${ex.toString()}", error: ex, trace: trace);
      showSnackbar("Save Error", ex.toString());
    }
  }

  void openLink() {
    String? url = part.url;
    mcs.invokeMethod("open-browser", {"link": url ?? part.text});
    popDetails();
  }

  Future<void> openAttachmentWeb() async {
    await launchUrlString("${part.attachments.first.webUrl!}?guid=${ss.settings.guidAuthKey}");
    popDetails();
  }

  void copyText() {
    Clipboard.setData(ClipboardData(text: part.fullText));
    popDetails();
    if (!Platform.isAndroid || (fs.androidInfo?.version.sdkInt ?? 0) < 33) {
      showSnackbar("Copied", "Copied to clipboard!");
    }
  }

  void copySelection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.colorScheme.properSurface,
        title: Text("Copy Selection", style: context.theme.textTheme.titleLarge),
        content: SelectableText(part.fullText, style: context.theme.extension<BubbleText>()!.bubbleText),
      ),
    );
  }

  Future<void> downloadOriginal() async {
    final RxBool downloadingAttachments = true.obs;
    final RxnDouble progress = RxnDouble();
    final Rxn<Attachment> attachmentObs = Rxn<Attachment>();
    final toDownload = part.attachments.where((element) =>
        (element.uti?.contains("heic") ?? false) ||
        (element.uti?.contains("heif") ?? false) ||
        (element.uti?.contains("quicktime") ?? false) ||
        (element.uti?.contains("coreaudio") ?? false) ||
        (element.uti?.contains("tiff") ?? false));
    final length = toDownload.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.colorScheme.properSurface,
        title: Text("Downloading attachment${length > 1 ? "s" : ""}...", style: context.theme.textTheme.titleLarge),
        content: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: <Widget>[
          Obx(
            () => Text(
                '${progress.value != null && attachmentObs.value != null ? (progress.value! * attachmentObs.value!.totalBytes!).getFriendlySize() : ""} / ${(attachmentObs.value!.totalBytes!.toDouble()).getFriendlySize()} (${((progress.value ?? 0) * 100).floor()}%)',
                style: context.theme.textTheme.bodyLarge),
          ),
          const SizedBox(height: 10.0),
          Obx(
            () => ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                backgroundColor: context.theme.colorScheme.outline,
                valueColor: AlwaysStoppedAnimation<Color>(Get.context!.theme.colorScheme.primary),
                value: progress.value,
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(
            height: 15.0,
          ),
          Obx(() => Text(
                progress.value == 1
                    ? "Download Complete!"
                    : "You can close this dialog. The attachment(s) will continue to download in the background.",
                maxLines: 2,
                textAlign: TextAlign.center,
                style: context.theme.textTheme.bodyLarge,
              )),
        ]),
        actions: [
          Obx(
            () => downloadingAttachments.value
                ? Container(height: 0, width: 0)
                : TextButton(
                    child: Text("Close", style: context.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)),
                    onPressed: () async {
                      Get.closeAllSnackbars();
                      Navigator.of(context).pop();
                      popDetails();
                    },
                  ),
          ),
        ],
      ),
    );
    try {
      for (Attachment? element in toDownload) {
        attachmentObs.value = element;
        final file = await backend.downloadAttachment(element!,
            original: true, onReceiveProgress: (count, total) => progress.value = kIsWeb ? (count / total) : (count / element.totalBytes!));
        await as.saveToDisk(file, isDocument: element.mimeStart != "image" && element.mimeStart != "video");
      }
      progress.value = 1;
      downloadingAttachments.value = false;
    } catch (ex, trace) {
      Logger.error("Failed to download original attachment!", error: ex, trace: trace);
      showSnackbar("Download Error", ex.toString());
    }
  }

  Future<void> downloadLivePhoto() async {
    final RxBool downloadingAttachments = true.obs;
    final RxnInt progress = RxnInt();
    final Rxn<Attachment> attachmentObs = Rxn<Attachment>();
    final toDownload = part.attachments.where((element) => element.hasLivePhoto);
    final length = toDownload.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.colorScheme.properSurface,
        title: Text("Downloading live photo${length > 1 ? "s" : ""}...", style: context.theme.textTheme.titleLarge),
        content: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: <Widget>[
          Obx(
            () => Text(
              progress.value?.toDouble().getFriendlySize() ?? "",
              style: context.theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 10.0),
          Obx(
            () => ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                backgroundColor: context.theme.colorScheme.outline,
                valueColor: AlwaysStoppedAnimation<Color>(Get.context!.theme.colorScheme.primary),
                value: downloadingAttachments.value ? null : 1,
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(
            height: 15.0,
          ),
          Obx(() => Text(
                !downloadingAttachments.value
                    ? "Download Complete!"
                    : "You can close this dialog. The live photo(s) will continue to download in the background.",
                maxLines: 2,
                textAlign: TextAlign.center,
                style: context.theme.textTheme.bodyLarge,
              )),
        ]),
        actions: [
          Obx(
            () => downloadingAttachments.value
                ? Container(height: 0, width: 0)
                : TextButton(
                    child: Text("Close", style: context.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)),
                    onPressed: () async {
                      Get.closeAllSnackbars();
                      Navigator.of(context).pop();
                      popDetails();
                    },
                  ),
          ),
        ],
      ),
    );
    try {
      for (Attachment? element in toDownload) {
        attachmentObs.value = element;
        final nameSplit = element!.transferName!.split(".");
        await backend.downloadLivePhoto(element, "${nameSplit.take(nameSplit.length - 1).join(".")}.mov",
            onReceiveProgress: (count, total) => progress.value = count);
      }
      downloadingAttachments.value = false;
    } catch (ex, trace) {
      Logger.error("Failed to download live photo!", error: ex, trace: trace);
      showSnackbar("Download Error", ex.toString());
    }
  }

  void openDm() {
    popDetails();
    Navigator.pushReplacement(
      context,
      cupertino.CupertinoPageRoute(
        builder: (BuildContext context) {
          return ConversationView(
            chat: dmChat!,
          );
        },
      ),
    );
  }

  void createContact() async {
    popDetails();
    await mcs
        .invokeMethod("open-contact-form", {'address': message.handle!.address, 'address_type': message.handle!.address.isEmail ? 'email' : 'phone'});
  }

  void showThread() {
    popDetails();
    if (message.threadOriginatorGuid != null) {
      final mwc = getActiveMwc(message.threadOriginatorGuid!);
      if (mwc == null) return showSnackbar("Error", "Failed to find thread!");
      showReplyThread(context, mwc.message, mwc.parts[message.normalizedThreadPart], service, cvController);
    } else {
      showReplyThread(context, message, part, service, cvController);
    }
  }

  void newConvo() {
    Handle? handle = message.handle;
    if (handle == null) return;
    popDetails();
    ns.pushAndRemoveUntil(
      context,
      ChatCreator(initialSelected: [SelectedContact(displayName: handle.displayName, address: handle.address)]),
      (route) => route.isFirst,
    );
  }

  void forward() async {
    popDetails();
    List<PlatformFile> attachments = [];
    final _attachments = message.attachments
        .where((e) => as.getContent(e!, autoDownload: false) is PlatformFile)
        .map((e) => as.getContent(e!, autoDownload: false) as PlatformFile);
    for (PlatformFile a in _attachments) {
      Uint8List? bytes = a.bytes;
      bytes ??= await File(a.path!).readAsBytes();
      attachments.add(PlatformFile(
        name: a.name,
        path: a.path,
        size: bytes.length,
        bytes: bytes,
      ));
    }
    if (attachments.isNotEmpty || !isNullOrEmpty(message.text)) {
      ns.pushAndRemoveUntil(
        context,
        ChatCreator(
          initialText: message.text,
          initialAttachments: attachments,
        ),
        (route) => route.isFirst,
      );
    }
  }

  void redownload() {
    if (isEmbeddedMedia) {
      popDetails();
      getActiveMwc(message.guid!)?.updateWidgets<EmbeddedMedia>(null);
    } else {
      for (Attachment? element in part.attachments) {
        widget.cvController.imageData.remove(element!.guid!);
        as.redownloadAttachment(element);
      }
      popDetails();
      getActiveMwc(message.guid!)?.updateWidgets<AttachmentHolder>(null);
    }
  }

  void share() {
    if (part.attachments.isNotEmpty && !message.isLegacyUrlPreview && !kIsWeb && !kIsDesktop) {
      for (Attachment? element in part.attachments) {
        Share.file(
          "${element!.mimeType!.split("/")[0].capitalizeFirst} shared from OpenBubbles: ${element.transferName}",
          element.path,
        );
      }
    } else if (part.text!.isNotEmpty) {
      Share.text(
        "Text shared from OpenBubbles",
        part.text!,
      );
    }
    popDetails();
  }

  Future<void> reportIssue() async {
    final TextEditingController participantController = TextEditingController();
    Uint8List? attachment;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          actions: [
            TextButton(
              child: Text("Cancel", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
              onPressed: () => Get.back(),
            ),
            TextButton(
              child: Text("Screenshot", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
              onPressed: () async {
                final res = await picker.FilePicker.platform.pickFiles(withData: true, type: picker.FileType.custom, allowedExtensions: ['png', 'jpg', 'jpeg']);
                if (res == null || res.count == 0) return;
                attachment = await File(res.files[0].path!).readAsBytes();
                showSnackbar("Notice", "Screenshot added");
              },
            ),
            TextButton(
              child: Text("OK", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
              onPressed: () async {
                if (participantController.text == "") return;

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: context.theme.colorScheme.properSurface,
                      title: Text(
                        "Uploading log...",
                        style: context.theme.textTheme.titleLarge,
                      ),
                      content: Container(
                        height: 70,
                        child: Center(
                          child: CircularProgressIndicator(
                            backgroundColor: context.theme.colorScheme.properSurface,
                            valueColor: AlwaysStoppedAnimation<Color>(context.theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    );
                  }
                );
                
                // 
                var file = Directory(Platform.isAndroid ? "${fs.appDocDir.path}/../files/logs" : "${fs.appDocDir.path}/logs");
                final List<FileSystemEntity> entities = await file.list().toList();
                var current = entities.indexWhere((element) => element.path.endsWith("CURRENT.log"));
                var item = entities.removeAt(current);
                var end = await File(item.path).readAsBytes();
                var b = BytesBuilder();
                if (entities.isNotEmpty) {
                  var next = await File(entities.first.path).readAsBytes();
                  b.add(next);
                }
                b.add(end);
                var total = b.toBytes();

                var encoder = const JsonEncoder.withIndent("     ");
                var messageMeta = encoder.convert(message.toMap(includeObjects: true));
                var chatMeta = encoder.convert(chat.toMap());

                // stop stupid automatic cralwers from spamming the webhook
                var url = dotenv.get('REPORT_ISSUE_WEBHOOK');

                try {
                  final response = await http.dio.post(
                      url,
                      data: FormData.fromMap({
                        "content": "Handle: ${(await api.getHandles(state: pushService.state)).first} \nDesc: ${participantController.text}",
                        "username": ss.settings.userName.value,
                        "files[0]": MultipartFile.fromBytes(total, filename: "rustpush-logs.log"),
                        "files[1]": MultipartFile.fromString(messageMeta, filename: "message.json"),
                        "files[2]": MultipartFile.fromString(chatMeta, filename: "chat.json"),
                        if (attachment != null)
                        "files[3]": MultipartFile.fromBytes(attachment!, filename: "screenshot.png")
                      }),
                  );

                  if (response.statusCode == 200) {
                    Get.back();
                    Get.back();
                    showSnackbar("Notice", "Logs sent! Thank you!");
                  } else {
                    Get.back();
                    Logger.error(response.toString());
                    showSnackbar("Error", "There was an issue sending logs");
                  }
                } catch(e, s) {
                  Get.back();
                  Logger.error("failed", error: e, trace: s);
                  showSnackbar("Error", "There was an issue sending logs $e");
                }
              },
            ),
          ],
          content: Column(children: [
            const Text("Logs will be sent to developer for review. Logs contain personal identifiers and 48 hours of message and chat history. Do not submit logs containing sensitive chats or messages. Your logs will be shared with Discord for storage subject to their Privacy Policy. We may contact you on iMessage for further information."),
            const SizedBox(height: 16,),
            TextField(
              controller: participantController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
            )
          ],
          mainAxisSize: MainAxisSize.min,),
          title: Text("Report issue", style: context.theme.textTheme.titleLarge),
          backgroundColor: context.theme.colorScheme.properSurface,
        );
      }
    );
  }

  Future<void> remindLater() async {
    if (Platform.isAndroid) {
      bool denied = await Permission.scheduleExactAlarm.isDenied;
      ;
      bool permanentlyDenied = await Permission.scheduleExactAlarm.isPermanentlyDenied;
      if (denied && !permanentlyDenied) {
        await Permission.scheduleExactAlarm.request();
      } else if (permanentlyDenied) {
        showSnackbar("Error", "You must enable the manage alarm permission to use this feature");
        return;
      }
    }

    final finalDate = await showTimeframePicker("Select Reminder Time", context,
        presetsAhead: true, additionalTimeframes: {"3 Hours": 3, "6 Hours": 6}, useTodayYesterday: true);
    if (finalDate != null) {
      if (!finalDate.isAfter(DateTime.now().toLocal())) {
        showSnackbar("Error", "Select a date in the future");
        return;
      }
      await notif.createReminder(chat, message, finalDate);
      popDetails();
      showSnackbar("Notice", "Scheduled reminder for ${buildDate(finalDate)}");
    }
  }

  void unsend() async {
    popDetails();
    final updatedMessage = await backend.unsend(message, part);
    if (updatedMessage == null) {
      return;
    }
    ah.handleUpdatedMessage(chat, updatedMessage, null);
  }

  void edit() {
    popDetails();
    final FocusNode? node = kIsDesktop || kIsWeb ? FocusNode() : null;

    var controller = MentionTextEditingController(text: "", focusNode: node);
    controller.importMessagePart(part);

    cvController.editing.add(Tuple3(message, part, controller));
  }

  void delete() {
    service.removeMessage(message);
    Message.softDelete(message.guid!);
    popDetails();
  }

  void selectMultiple() {
    cvController.inSelectMode.toggle();
    if (iOS) {
      cvController.selected.add(message);
    }
    popDetails(returnVal: false);
  }

  void toggleBookmark() {
    message.isBookmarked = !message.isBookmarked;
    message.save(updateIsBookmarked: true);
    popDetails();
  }

  void messageInfo() {
    const encoder = JsonEncoder.withIndent("     ");
    Map map = message.toMap(includeObjects: true);
    if (map["dateCreated"] is int) {
      map["dateCreated"] = DateFormat("MMMM d, yyyy h:mm:ss a").format(DateTime.fromMillisecondsSinceEpoch(map["dateCreated"]));
    }
    if (map["dateDelivered"] is int) {
      map["dateDelivered"] = DateFormat("MMMM d, yyyy h:mm:ss a").format(DateTime.fromMillisecondsSinceEpoch(map["dateDelivered"]));
    }
    if (map["dateRead"] is int) {
      map["dateRead"] = DateFormat("MMMM d, yyyy h:mm:ss a").format(DateTime.fromMillisecondsSinceEpoch(map["dateRead"]));
    }
    if (map["dateEdited"] is int) {
      map["dateEdited"] = DateFormat("MMMM d, yyyy h:mm:ss a").format(DateTime.fromMillisecondsSinceEpoch(map["dateEdited"]));
    }
    String str = encoder.convert(map);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Message Info",
          style: context.theme.textTheme.titleLarge,
        ),
        backgroundColor: context.theme.colorScheme.properSurface,
        content: SizedBox(
          width: ns.width(widthContext) * 3 / 5,
          height: context.height * 1 / 4,
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(color: context.theme.colorScheme.background, borderRadius: const BorderRadius.all(Radius.circular(10))),
            child: SingleChildScrollView(
              child: SelectableText(
                str,
                style: context.theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text("Close", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  get _allActions {
    final canEdit = (message.dateCreated?.toUtc().isWithin(DateTime.now().toUtc(), minutes: 15) ?? false) 
        || (message.dateCreated?.toUtc().isAfter(DateTime.now().toUtc()) ?? false);
    return [
        if (ss.settings.enablePrivateAPI.value && minBigSur && chat.isIMessage && isSent)
          DetailsMenuActionWidget(
            onTap: reply,
            action: DetailsMenuAction.Reply,
          ),
        if (showDownload)
          DetailsMenuActionWidget(
            onTap: download,
            action: DetailsMenuAction.Save,
          ),
        if ((part.text?.hasUrl ?? false) && !kIsWeb && !kIsDesktop && !ls.isBubble)
          DetailsMenuActionWidget(
            onTap: openLink,
            action: DetailsMenuAction.OpenInBrowser,
          ),
        if (showDownload && kIsWeb && part.attachments.firstOrNull?.webUrl != null)
          DetailsMenuActionWidget(
            onTap: openAttachmentWeb,
            action: DetailsMenuAction.OpenInNewTab,
          ),
        if (!isNullOrEmptyString(part.fullText))
          DetailsMenuActionWidget(
            onTap: copyText,
            action: DetailsMenuAction.CopyText,
          ),
        if (showDownload &&
            supportsOriginalDownload &&
            part.attachments
                .where((element) =>
                    (element.uti?.contains("heic") ?? false) ||
                    (element.uti?.contains("heif") ?? false) ||
                    (element.uti?.contains("quicktime") ?? false) ||
                    (element.uti?.contains("coreaudio") ?? false) ||
                    (element.uti?.contains("tiff") ?? false))
                .isNotEmpty)
          DetailsMenuActionWidget(
            onTap: downloadOriginal,
            action: DetailsMenuAction.SaveOriginal,
          ),
        if (showDownload && part.attachments.where((e) => e.hasLivePhoto).isNotEmpty)
          DetailsMenuActionWidget(
            onTap: downloadLivePhoto,
            action: DetailsMenuAction.SaveLivePhoto,
          ),
        if (chat.isGroup && !message.isFromMe! && dmChat != null && !ls.isBubble)
          DetailsMenuActionWidget(
            onTap: openDm,
            action: DetailsMenuAction.OpenDirectMessage,
          ),
        if (message.threadOriginatorGuid != null || service.struct.threads(message.guid!, part.part, returnOriginator: false).isNotEmpty)
          DetailsMenuActionWidget(
            onTap: showThread,
            action: DetailsMenuAction.ViewThread,
          ),
        if ((part.attachments.isNotEmpty && !kIsWeb && !kIsDesktop) || (!kIsWeb && !kIsDesktop && !isNullOrEmpty(part.text)))
          DetailsMenuActionWidget(
            onTap: share,
            action: DetailsMenuAction.Share,
          ),
        if (showDownload)
          DetailsMenuActionWidget(
            onTap: redownload,
            action: DetailsMenuAction.ReDownloadFromServer,
          ),
        if (!kIsWeb && !kIsDesktop)
          DetailsMenuActionWidget(
            onTap: remindLater,
            action: DetailsMenuAction.RemindLater,
          ),
        if (!kIsWeb && !kIsDesktop)
          DetailsMenuActionWidget(
            onTap: reportIssue,
            action: DetailsMenuAction.ReportIssue,
          ),
        if (!kIsWeb && !kIsDesktop && !message.isFromMe! && message.handle != null && message.handle!.contact == null)
          DetailsMenuActionWidget(
            onTap: createContact,
            action: DetailsMenuAction.CreateContact,
          ),
        if (backend.canEditUnsend() && message.isFromMe! && !message.guid!.startsWith("temp") && message.dateScheduled == null)
          DetailsMenuActionWidget(
            onTap: unsend,
            action: DetailsMenuAction.UndoSend,
          ),
        if (backend.canEditUnsend() && 
            message.isFromMe! &&
            !message.guid!.startsWith("temp") &&
            (part.text?.isNotEmpty ?? false))
          DetailsMenuActionWidget(
            onTap: edit,
            customTitle: canEdit ? 'Edit' : 'Edit (too old)',
            shouldDisableBtn: !canEdit,
            action: DetailsMenuAction.Edit,
          ),
        if (!ls.isBubble && !message.isInteractive)
          DetailsMenuActionWidget(
            onTap: forward,
            action: DetailsMenuAction.Forward,
          ),
        if (chat.isGroup && !message.isFromMe! && dmChat == null && !ls.isBubble)
          DetailsMenuActionWidget(
            onTap: newConvo,
            action: DetailsMenuAction.StartConversation,
          ),
        if (!isNullOrEmptyString(part.fullText) && (kIsDesktop || kIsWeb))
          DetailsMenuActionWidget(
            onTap: copySelection,
            action: DetailsMenuAction.CopySelection,
          ),
        DetailsMenuActionWidget(
          onTap: delete,
          action: DetailsMenuAction.Delete,
        ),
        DetailsMenuActionWidget(
          onTap: toggleBookmark,
          action: DetailsMenuAction.Bookmark,
          customTitle: message.isBookmarked ? "Remove Bookmark" : "Add Bookmark",
        ),
        DetailsMenuActionWidget(
          onTap: selectMultiple,
          action: DetailsMenuAction.SelectMultiple,
        ),
        DetailsMenuActionWidget(
          onTap: messageInfo,
          action: DetailsMenuAction.MessageInfo,
        ),
      ].sorted((a, b) => ss.settings.detailsMenuActions.indexOf(a.action).compareTo(ss.settings.detailsMenuActions.indexOf(b.action)));
  }

  double maxMenuWidth = 300;

  Widget buildDetailsMenu(BuildContext context) {

    List<DetailsMenuActionWidget> allActions = _allActions;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: context.theme.colorScheme.properSurface.withAlpha(150),
          width: maxMenuWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: allActions.cast<CustomDetailsMenuActionWidget>().sublist(0, numberToShow - 1)
              ..add(
                CustomDetailsMenuActionWidget(
                  onTap: () async {
                    Widget content = Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: allActions.sublist(numberToShow - 1),
                    );
                    Get.dialog(
                        ss.settings.skin.value == Skins.iOS
                            ? CupertinoAlertDialog(
                                backgroundColor: context.theme.colorScheme.properSurface,
                                content: content,
                              )
                            : AlertDialog(
                                backgroundColor: context.theme.colorScheme.properSurface,
                                content: content,
                              ),
                        name: 'Popup Menu');
                  },
                  title: 'More...',
                  iosIcon: cupertino.CupertinoIcons.ellipsis,
                  nonIosIcon: Icons.more_vert,
                ),
              ),
          ),
        ),
      ),
    );
  }

  List<Widget> buildMaterialDetailsMenu(BuildContext context) {
    List<DetailsMenuActionWidget> allActions = _allActions;

    return [
      ...allActions.slice(0, numberToShow - 1).map((action) {
        bool isDisabled = false;
        if (action.action == DetailsMenuAction.Edit) {
          isDisabled = !((message.dateCreated?.toUtc().isWithin(DateTime.now().toUtc(), minutes: 15) ?? false));
        }
  
        Color color = isDisabled ? context.theme.colorScheme.properOnSurface.withOpacity(0.5) : context.theme.colorScheme.properOnSurface;
        return Padding(
          padding: EdgeInsets.only(top: kIsDesktop ? 20 : 0),
          child: IconButton(
            icon: Icon(action.nonIosIcon, color: color),
            onPressed: isDisabled ? null : action.onTap,
            tooltip: action.title,
          )
        );
      }),
      Padding(
        padding: EdgeInsets.only(top: kIsDesktop ? 20 : 0),
        child: PopupMenuButton<int>(
          color: context.theme.colorScheme.properSurface,
          shape: ss.settings.skin.value != Skins.Material ? const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ) : null,
          onSelected: (int value) {
            allActions[value + numberToShow - 1].onTap?.call();
          },
          itemBuilder: (context) {
            return allActions.slice(numberToShow - 1).mapIndexed((index, action) {
              return PopupMenuItem(
                value: index,
                child: Text(
                  action.title,
                  style: context.textTheme.bodyLarge!.apply(color: context.theme.colorScheme.properOnSurface),
                ),
              );
            }).toList();
          }
        )
      )
    ];
  }
}

class ReactionDetails extends StatelessWidget {
  const ReactionDetails({
    super.key,
    required this.reactions,
  });

  final List<Message> reactions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          alignment: Alignment.center,
          height: 120,
          color: context.theme.colorScheme.properSurface.withAlpha(ss.settings.skin.value == Skins.iOS ? 150 : 255),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: ThemeSwitcher.getScrollPhysics(),
              scrollDirection: Axis.horizontal,
              findChildIndexCallback: (key) => findChildIndexByKey(reactions, key, (item) => item.guid),
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final message = reactions[index];
                return Column(
                  key: ValueKey(message.guid!),
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
                      child: ContactAvatarWidget(
                        handle: message.handle,
                        borderThickness: 0.1,
                        editable: false,
                        fontSize: 22,
                      ),
                    ),
                    if (!ss.settings.hideNamesForReactions.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          message.isFromMe! ? ss.settings.userName.value : (message.handle?.displayName ?? "Unknown"),
                          style: context.theme.textTheme.bodySmall!.copyWith(color: context.theme.colorScheme.properOnSurface),
                        ),
                      ),
                    if (ss.settings.hideNamesForReactions.value)
                      const SizedBox(
                        height: 8,
                      ),
                    Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: message.isFromMe! ? context.theme.colorScheme.primary : context.theme.colorScheme.properSurface,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 1.0,
                            color: context.theme.colorScheme.outline,
                          )
                        ],
                      ),
                      child: Center(
                        child: Builder(builder: (context) {
                          if (message.associatedMessageType == ReactionTypes.STICKERBACK) {
                            var image = cvc(message.chat.target!).stickerData[message.guid]?[message.attachments[0]?.guid]?.$1;
                            return image != null ? Padding(
                              padding: const EdgeInsets.all(5),
                              child: Image.memory(
                                image,
                                gaplessPlayback: true,
                                cacheHeight: 200,
                                filterQuality: FilterQuality.none,
                              ),
                            ) : const SizedBox.shrink();
                          }
                          final text = Text(
                            ReactionTypes.reactionToEmoji[message.associatedMessageType] ?? message.associatedMessageEmoji ?? "X",
                            style: const TextStyle(fontSize: 18, fontFamily: 'Apple Color Emoji'),
                            textAlign: TextAlign.center,
                          );
                          // rotate thumbs down to match iOS
                          if (message.associatedMessageType == "dislike") {
                            return Transform(
                              transform: Matrix4.identity()..rotateY(pi),
                              alignment: FractionalOffset.center,
                              child: text,
                            );
                          }
                          return text;
                        }),
                      ),
                    )
                  ],
                );
              },
              itemCount: reactions.length,
            ),
          ),
        ),
      ),
    );
  }
}
