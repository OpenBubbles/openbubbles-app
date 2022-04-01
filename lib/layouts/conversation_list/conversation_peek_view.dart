import 'dart:math';
import 'dart:ui';

import 'package:bluebubbles/blocs/chat_bloc.dart';
import 'package:bluebubbles/blocs/message_bloc.dart';
import 'package:bluebubbles/helpers/constants.dart';
import 'package:bluebubbles/helpers/hex_color.dart';
import 'package:bluebubbles/helpers/themes.dart';
import 'package:bluebubbles/helpers/utils.dart';
import 'package:bluebubbles/layouts/titlebar_wrapper.dart';
import 'package:bluebubbles/layouts/widgets/custom_cupertino_alert_dialog.dart';
import 'package:bluebubbles/layouts/widgets/message_widget/message_widget.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bluebubbles/repository/models/models.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

Future<void> peekChat(BuildContext context, Chat c, Offset offset) async {
  HapticFeedback.mediumImpact();
  final position = offset;
  final chat = c;
  final messages = Chat.getMessages(c, getDetails: true).where((e) => e.associatedMessageGuid == null).toList();
  await Navigator.push(
    context,
    PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return ConversationPeekView(position: position, chat: chat, messages: messages);
            },
          ),
        );
      },
      fullscreenDialog: true,
      opaque: false,
    ),
  );
}

class ConversationPeekView extends StatefulWidget {
  final Offset position;
  final Chat chat;
  final List<Message> messages;

  const ConversationPeekView({Key? key, required this.position, required this.chat, required this.messages}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ConversationPeekViewState();

}

class _ConversationPeekViewState extends State<ConversationPeekView> with SingleTickerProviderStateMixin {
  double targetValue = 1;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    controller.forward();
  }

  void popPeekView() {
    bool dialogOpen = Get.isDialogOpen ?? false;
    if (dialogOpen) {
      if (kIsWeb) {
        Get.back();
      } else {
        Navigator.of(context).pop();
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: SettingsManager().settings.immersiveMode.value
            ? Colors.transparent
            : Theme.of(context).backgroundColor, // navigation bar color
        systemNavigationBarIconBrightness:
        Theme.of(context).backgroundColor.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light,
        statusBarColor: Colors.transparent, // status bar color
        statusBarIconBrightness: context.theme.backgroundColor.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light,
      ),
      child: TitleBarWrapper(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      color: oledDarkTheme.colorScheme.secondary.withOpacity(0.3),
                    ),
                  ),
                ),
                Positioned(
                  left: min(widget.position.dx, context.width - min(context.width - 50, 500) - 25),
                  top: min(widget.position.dy, context.height - min(context.height / 2, 750) - (kIsDesktop || kIsWeb ? 60 : 50)),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: targetValue),
                    curve: Curves.easeOutBack,
                    duration: Duration(milliseconds: 400),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: controller,
                        curve: Interval(0.0, .9, curve: Curves.ease),
                        reverseCurve: Curves.easeInCubic,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).backgroundColor.computeLuminance() > 0.5
                                  ? Theme.of(context).colorScheme.secondary.lightenPercent(50)
                                  : Theme.of(context).colorScheme.secondary.darkenPercent(50),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            width: min(context.width - 50, 500),
                            height: min(context.height / 2, 750) - (kIsDesktop || kIsWeb ? 60 : 50),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListView.builder(
                                shrinkWrap: true,
                                reverse: true,
                                itemBuilder: (context, index) {
                                  return AbsorbPointer(
                                    absorbing: true,
                                    child: Padding(
                                        padding: EdgeInsets.only(left: 5.0, right: 5.0),
                                        child: MessageWidget(
                                          key: Key(widget.messages[index].guid!),
                                          message: widget.messages[index],
                                          olderMessage: index == widget.messages.length - 1 ? null : widget.messages[index + 1],
                                          newerMessage: index == 0 ? null : widget.messages[index - 1],
                                          showHandle: widget.chat.isGroup(),
                                          isFirstSentMessage: false,
                                          showHero: false,
                                          showReplies: true,
                                          bloc: MessageBloc(widget.chat),
                                          autoplayEffect: false,
                                        )),
                                  );
                                },
                                itemCount: widget.messages.length,
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          buildDetailsMenu(context)
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDetailsMenu(BuildContext context) {
    double maxMenuWidth = min(max(context.width * 3 / 5, 200), context.width * 4 / 5);
    double maxHeight = context.height
        - min(context.height / 2, 750) - (kIsDesktop || kIsWeb ? 60 : 50)
        - min(widget.position.dy, context.height - min(context.height / 2, 750) - (kIsDesktop || kIsWeb ? 60 : 50));
    print(maxHeight);
    bool ios = SettingsManager().settings.skin.value == Skins.iOS;

    List<Widget> allActions = [
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            widget.chat.togglePin(!widget.chat.isPinned!);
            if (mounted) setState(() {});
            popPeekView();
          },
          child: ListTile(
            dense: !kIsDesktop && !kIsWeb,
            title: Text(
              widget.chat.isPinned! ? "Unpin" : "Pin",
              style: Theme.of(context).textTheme.bodyText1,
            ),
            trailing: Icon(
              widget.chat.isPinned!
                  ? (ios ? cupertino.CupertinoIcons.pin_slash : Icons.star_outline)
                  : (ios ? cupertino.CupertinoIcons.pin : Icons.star),
              color: Theme.of(context).textTheme.bodyText1!.color,
            ),
          ),
        ),
      ),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            widget.chat.toggleMute(widget.chat.muteType != "mute");
            if (mounted) setState(() {});
            popPeekView();
          },
          child: ListTile(
            dense: !kIsDesktop && !kIsWeb,
            title: Text(
              widget.chat.muteType == "mute" ? 'Show Alerts' : 'Hide Alerts',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            trailing: Icon(
              widget.chat.muteType == "mute"
                  ? (ios ? cupertino.CupertinoIcons.bell : Icons.notifications_active)
                  : (ios ? cupertino.CupertinoIcons.bell_slash : Icons.notifications_off),
              color: Theme.of(context).textTheme.bodyText1!.color,
            ),
          ),
        ),
      ),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            ChatBloc().toggleChatUnread(widget.chat, !widget.chat.hasUnreadMessage!);
            if (mounted) setState(() {});
            popPeekView();
          },
          child: ListTile(
            dense: !kIsDesktop && !kIsWeb,
            title: Text(
              widget.chat.hasUnreadMessage! ? 'Mark Read' : 'Mark Unread',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            trailing: Icon(
              widget.chat.hasUnreadMessage!
                  ? (ios ? cupertino.CupertinoIcons.person_crop_circle_badge_xmark : Icons.mark_chat_unread)
                  : (ios ? cupertino.CupertinoIcons.person_crop_circle_badge_checkmark : Icons.mark_chat_read),
              color: Theme.of(context).textTheme.bodyText1!.color,
            ),
          ),
        ),
      ),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (widget.chat.isArchived!) {
              ChatBloc().unArchiveChat(widget.chat);
            } else {
              ChatBloc().archiveChat(widget.chat);
            }
            if (mounted) setState(() {});
            popPeekView();
          },
          child: ListTile(
            dense: !kIsDesktop && !kIsWeb,
            title: Text(
              widget.chat.isArchived! ? 'Unarchive' : 'Archive',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            trailing: Icon(
              widget.chat.isArchived!
                  ? (ios ? cupertino.CupertinoIcons.tray_arrow_up : Icons.unarchive)
                  : (ios ? cupertino.CupertinoIcons.tray_arrow_down : Icons.archive),
              color: Theme.of(context).textTheme.bodyText1!.color,
            ),
          ),
        ),
      ),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            ChatBloc().deleteChat(widget.chat);
            Chat.deleteChat(widget.chat);
            if (mounted) setState(() {});
            popPeekView();
          },
          child: ListTile(
            dense: !kIsDesktop && !kIsWeb,
            title: Text(
              'Delete',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            trailing: Icon(
              cupertino.CupertinoIcons.trash,
              color: Theme.of(context).textTheme.bodyText1!.color,
            ),
          ),
        ),
      ),
    ];

    List<Widget> detailsActions = [];
    List<Widget> moreActions = [];
    double itemHeight = kIsDesktop || kIsWeb ? 56 : 48;

    double actualHeight = 0;
    int index = 0;

    while (actualHeight <= maxHeight - itemHeight && index < allActions.length) {
      actualHeight += itemHeight;
      detailsActions.add(allActions[index++]);
    }
    moreActions.addAll(allActions.getRange(index, allActions.length));

    // If there is only one 'more' action then it can replace the 'more' button
    if (moreActions.length == 1) {
      detailsActions.add(moreActions.removeAt(0));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: Theme.of(context).colorScheme.secondary.withAlpha(150),
          width: maxMenuWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...detailsActions,
              if (moreActions.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Widget content = Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: moreActions,
                      );
                      Get.dialog(
                          SettingsManager().settings.skin.value == Skins.iOS ? CupertinoAlertDialog(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            content: content,
                          ) : AlertDialog(
                            contentPadding: EdgeInsets.all(5),
                            shape: cupertino.RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            content: content,
                          ),
                          name: 'Popup Menu'
                      );
                    },
                    child: ListTile(
                      dense: !kIsDesktop && !kIsWeb,
                      title: Text("More...", style: Theme.of(context).textTheme.bodyText1),
                      trailing: Icon(
                        SettingsManager().settings.skin.value == Skins.iOS
                            ? cupertino.CupertinoIcons.ellipsis
                            : Icons.more_vert,
                        color: Theme.of(context).textTheme.bodyText1!.color,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}