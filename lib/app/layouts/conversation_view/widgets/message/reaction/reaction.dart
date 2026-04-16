import 'dart:async';
import 'dart:math';

import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/popup/message_popup.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/reaction/reaction_clipper.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:universal_io/io.dart';

class ReactionWidget extends StatefulWidget {
  const ReactionWidget({
    super.key,
    required this.message,
    required this.reaction,
    this.reactions,
  });

  final Message? message;
  final Message reaction;
  final List<Message>? reactions;

  @override
  ReactionWidgetState createState() => ReactionWidgetState();
}

class ReactionWidgetState extends OptimizedState<ReactionWidget> {
  late Message reaction = widget.reaction;
  late final StreamSubscription sub;
  bool hasStream = false;

  List<Message>? get reactions => widget.reactions;
  bool get reactionIsFromMe => reaction.isFromMe!;
  bool get messageIsFromMe => widget.message?.isFromMe ?? true;
  String get reactionType => reaction.associatedMessageType!;

  ConversationViewController? get controller => cvc(reaction.chat.target!);

  static const double iosSize = 35;

  @override
  void initState() {
    super.initState();
    updateReaction();
    updateObx(() {
      if (!kIsWeb && widget.message != null) {
        final messageQuery = Database.messages.query(Message_.id.equals(reaction.id!)).watch();
        sub = messageQuery.listen((Query<Message> query) async {
          final _message = await runAsync(() {
            return Database.messages.get(reaction.id!);
          });
          if (_message != null) {
            if (_message.guid != reaction.guid || _message.dateDelivered != reaction.dateDelivered) {
              setState(() {
                reaction = _message;
                updateReaction();
              });
            } else {
              reaction = _message;
              updateReaction();
            }
            getActiveMwc(widget.message!.guid!)?.updateAssociatedMessage(reaction, updateHolder: false);
          }
        });

        hasStream = true;
      } else if (kIsWeb && widget.message != null) {
        sub = WebListeners.messageUpdate.listen((tuple) {
          final _message = tuple.item1;
          final tempGuid = tuple.item2;
          if (tempGuid == reaction.guid || _message.guid == reaction.guid) {
            setState(() {
              reaction = _message;
              updateReaction();
            });
            getActiveMwc(widget.message!.guid!)?.updateAssociatedMessage(reaction, updateHolder: false);
          }
        });
      }
    });
  }

  Future<void> checkImage(Attachment attachment) async {
    final pathName = attachment.path;
    // Check via the image package to make sure this is a valid, render-able image
    // final image = await compute(decodeIsolate, PlatformFile(
    //     path: pathName,
    //     name: attachment.transferName!,
    //     bytes: attachment.bytes,
    //     size: attachment.totalBytes ?? 0,
    //   ),
    // );
    final bytes = await File(pathName).readAsBytes();
    controller!.stickerData[reaction.guid!] = {
      attachment.guid!: (bytes, null)
    };
    setState(() {});
  }

  void updateReaction() async {
    if (reactionType != ReactionTypes.STICKERBACK) return;
    reaction.fetchAttachments();
    for (Attachment? attachment in reaction.attachments) {
      // If we've already loaded it, don't try again
      if (controller!.stickerData.keys.contains(attachment!.guid)) continue;

      final pathName = attachment.path;
      if (await FileSystemEntity.type(pathName) == FileSystemEntityType.notFound) {
        attachmentDownloader.startDownload(attachment, onComplete: (_) async {
          await checkImage(attachment);
        });
      } else {
        await checkImage(attachment);
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && hasStream) sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var emoji = ReactionTypes.reactionToEmoji[reactionType] ?? reaction.associatedMessageEmoji ?? "X";

    if (ss.settings.skin.value != Skins.iOS) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: reactionIsFromMe ? context.theme.colorScheme.primary : context.theme.colorScheme.properSurface,
          border: Border.all(color: context.theme.colorScheme.background),
          shape: BoxShape.circle,
        ),
        child: GestureDetector(
          onTap: () {
            if (reactions == null) return;
            for (Message m in reactions!) {
              if (!m.isFromMe!) {
                m.handle ??= m.getHandle();
              }
            }
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                    child: Theme(
                      data: context.theme.copyWith(
                        // in case some components still use legacy theming
                        primaryColor: context.theme.colorScheme.bubble(context, true),
                        colorScheme: context.theme.colorScheme.copyWith(
                          primary: context.theme.colorScheme.bubble(context, true),
                          onPrimary: context.theme.colorScheme.onBubble(context, true),
                          surface: ss.settings.monetTheming.value == Monet.full ? null : (context.theme.extensions[BubbleColors] as BubbleColors?)?.receivedBubbleColor,
                          onSurface: ss.settings.monetTheming.value == Monet.full ? null : (context.theme.extensions[BubbleColors] as BubbleColors?)?.onReceivedBubbleColor,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          Positioned(
                            bottom: 10,
                            left: 15,
                            right: 15,
                            child: ReactionDetails(reactions: reactions!)
                          ),
                        ],
                      ),
                    ),
                  );
                },
                fullscreenDialog: true,
                opaque: false,
                barrierDismissible: true,
              ),
            );
          },
          child: Center(
            child: Builder(
                builder: (context) {
                  if (reactionType == ReactionTypes.STICKERBACK) {
                    var image = controller!.stickerData[reaction.guid]?[reaction.attachments[0]?.guid]?.$1;
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
                    emoji,
                    style: const TextStyle(fontSize: 15, fontFamily: 'Apple Color Emoji'),
                    textAlign: TextAlign.center,
                  );
                  // rotate thumbs down to match iOS
                  if (reactionType == "dislike") {
                    return Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: FractionalOffset.center,
                      child: text,
                    );
                  }
                  return text;
                }
            ),
          ),
        )
      );
    }
    return Stack(
      alignment: messageIsFromMe ? Alignment.centerRight : Alignment.centerLeft,
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -1,
          left: messageIsFromMe ? 0 : -1,
          right: !messageIsFromMe ? 0 : -1,
          child: ClipPath(
            clipper: ReactionBorderClipper(isFromMe: messageIsFromMe),
            child: Container(
              width: iosSize + 2,
              height: iosSize + 2,
              color: context.theme.colorScheme.background,
            ),
          ),
        ),
        ClipPath(
          clipper: ReactionClipper(isFromMe: messageIsFromMe),
          child: Container(
            width: iosSize,
            height: iosSize,
            color: reactionIsFromMe
                ? context.theme.colorScheme.primary
                : context.theme.colorScheme.properSurface,
            alignment: messageIsFromMe ? Alignment.topRight : Alignment.topLeft,
            child: SizedBox(
              width: iosSize*0.8,
              height: iosSize*0.8,
              child: Center(
                child: Builder(
                  builder: (context) {
                    if (reactionType == ReactionTypes.STICKERBACK) {
                      var image = controller!.stickerData[reaction.guid]?[reaction.attachments[0]?.guid]?.$1;
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
                      emoji,
                      style: const TextStyle(fontSize: 16, fontFamily: 'Apple Color Emoji'),
                      textAlign: TextAlign.center,
                    );
                    // rotate thumbs down to match iOS
                    if (reactionType == "dislike") {
                      return Transform(
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: FractionalOffset.center,
                        child: text,
                      );
                    }
                    return text;
                  }
                ),
              ),
            )
          )
        ),
        Positioned(
          left: !messageIsFromMe ? 0 : -75,
          right: messageIsFromMe ? 0 : -75,
          child: Obx(() {
            if (reaction.error > 0 || reaction.guid!.startsWith("error-")) {
              int errorCode = reaction.error;
              String errorText = "An unknown internal error occurred.";
              if (errorCode == 22) {
                errorText = "The recipient is not registered with iMessage!";
              } else if (reaction.guid!.startsWith("error-")) {
                errorText = reaction.guid!.substring(reaction.guid!.indexOf('-') + 1);
              }

              return DeferPointer(
                child: GestureDetector(
                  child: Icon(
                    ss.settings.skin.value == Skins.iOS ? CupertinoIcons.exclamationmark_circle : Icons.error_outline,
                    color: context.theme.colorScheme.error,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: context.theme.colorScheme.properSurface,
                          title: Text("Message failed to send", style: context.theme.textTheme.titleLarge),
                          content: Text("Error ($errorCode): $errorText", style: context.theme.textTheme.bodyLarge),
                          actions: <Widget>[
                            TextButton(
                              child: Text(
                                  "Retry",
                                  style: context.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)
                              ),
                              onPressed: () async {
                                // Remove the original message and notification
                                Navigator.of(context).pop();
                                Message.delete(reaction.guid!);
                                await notif.clearFailedToSend(cm.activeChat!.chat.id!);
                                getActiveMwc(reaction.associatedMessageGuid!)?.removeAssociatedMessage(reaction);
                                // Re-send
                                final selected = getActiveMwc(reaction.associatedMessageGuid!)!.message;
                                outq.queue(OutgoingItem(
                                  type: QueueType.sendMessage,
                                  chat: cm.activeChat!.chat,
                                  message: Message(
                                    associatedMessageGuid: selected.guid,
                                    associatedMessageType: reaction.associatedMessageType,
                                    associatedMessagePart: reaction.associatedMessagePart,
                                    dateCreated: DateTime.now(),
                                    hasAttachments: false,
                                    isFromMe: true,
                                    handleId: 0,
                                  ),
                                  selected: selected,
                                  reaction: reaction.associatedMessageType!,
                                ));
                              },
                            ),
                            TextButton(
                              child: Text(
                                  "Remove",
                                  style: context.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)
                              ),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                // Delete the message from the DB
                                Message.delete(reaction.guid!);
                                // Remove the message from the Bloc
                                getActiveMwc(reaction.associatedMessageGuid!)?.removeAssociatedMessage(reaction);
                                final chat = cm.activeChat!.chat;
                                await notif.clearFailedToSend(chat.id!);
                                // Get the "new" latest info
                                List<Message> latest = Chat.getMessages(chat, limit: 1);
                                chat.latestMessage = latest.first;
                                chat.save();
                              },
                            ),
                            TextButton(
                              child: Text(
                                  "Cancel",
                                  style: context.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)
                              ),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await notif.clearFailedToSend(cm.activeChat!.chat.id!);
                              },
                            )
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        )
      ],
    );
  }
}

