import 'package:bluebubbles/app/layouts/conversation_details/dialogs/timeframe_picker.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';

class TimestampSeparator extends StatelessWidget {
  const TimestampSeparator({
    super.key,
    required this.olderMessage,
    required this.message,
  });
  final Message? olderMessage;
  final Message message;

  bool withinTimeThreshold(Message first, Message? second) {
    if (second == null) return true;
    var diff = second.chatViewDate!.difference(first.chatViewDate!).inMinutes.abs();
    return diff > 30 || (first.dateScheduled != null) != (second.dateScheduled != null) 
      || (diff > 5 && first.dateScheduled != null);
  }

  Tuple2<String?, String>? buildTimeStamp() {
    if (ss.settings.skin.value == Skins.Samsung && message.chatViewDate?.day != olderMessage?.chatViewDate?.day) {
      return Tuple2(null, buildSeparatorDateSamsung(message.chatViewDate!));
    } else if (ss.settings.skin.value != Skins.Samsung && withinTimeThreshold(message, olderMessage)) {
      final time = message.chatViewDate!;
      if (ss.settings.skin.value == Skins.iOS) {
        return Tuple2(time.isToday() ? "Today" : buildDate(time), buildTime(time));
      } else {
        return Tuple2(time.isToday() ? "Today" : buildSeparatorDateMaterial(time), buildTime(time));
      }
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = buildTimeStamp();



    var child = timestamp != null ? Padding(
      padding: const EdgeInsets.all(14.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: context.theme.textTheme.labelSmall!.copyWith(color: context.theme.colorScheme.outline, fontWeight: FontWeight.normal),
          children: [
            if (message.dateScheduled != null && olderMessage?.dateScheduled == null)
              TextSpan(
                text: "Send Later\n",
                style: context.theme.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, color: context.theme.colorScheme.outline, height: 2.5),
              ),
            if (timestamp.item1 != null)
              TextSpan(
                text: "${timestamp.item1!} ",
                style: context.theme.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, color: context.theme.colorScheme.outline),
              ),
            TextSpan(text: timestamp.item2),
            if (message.dateScheduled != null)
              TextSpan(
                text: " Edit",
                style: context.theme.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, color: context.theme.primaryColor),
              ),
          ],
        ),
      ),
    ) : const SizedBox.shrink();

    return message.dateScheduled != null ? PullDownButton(
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: context.theme.colorScheme.properSurface.withOpacity(0.9)
      ),
      animationAlignmentOverride: Alignment.bottomCenter,
      itemBuilder: (context) {
        final responsibleMessages = ms(message.getChat()!.guid).struct.messages
        .where((m) => m.dateScheduled != null && m.dateScheduled!.difference(message.dateScheduled!).inMinutes < 5 
          && m.dateScheduled!.difference(message.dateScheduled!).inMinutes >= 0).toList();
        responsibleMessages.sort(Message.sort);
        return [
          PullDownMenuItem(
            title: responsibleMessages.length == 1 ? 'Send Message' : 'Send ${responsibleMessages.length} Messages',
            icon: CupertinoIcons.arrow_up_circle,
            onTap: () async {
              for (var message in responsibleMessages) {
                message.dateScheduled = null;
                message.stagingGuid = message.guid;
                message.dateCreated = DateTime.now();
                message.generateTempGuid();
                message.save();
                outq.queue(OutgoingItem(
                  type: QueueType.sendMessage,
                  chat: message.getChat()!,
                  message: message,
                ), prep: false);
              }
            },
          ),
          PullDownMenuItem(
            title: 'Edit Time',
            icon: CupertinoIcons.clock,
            onTap: () async {
              final date = await showTimeframePicker("Pick date and time", context, presetsAhead: true);
              if (date == null || !date.isAfter(DateTime.now())) {
                return;
              }
              for (var message in responsibleMessages) {
                message.dateScheduled = date;
                message.save();
                outq.queue(OutgoingItem(
                  type: QueueType.sendMessage,
                  chat: message.getChat()!,
                  message: message,
                ), prep: false);
              }
            },
          ),
          PullDownMenuItem(
            title: responsibleMessages.length == 1 ? 'Delete Message' : 'Delete ${responsibleMessages.length} Messages',
            icon: CupertinoIcons.trash,
            iconColor: Colors.red[700],
            onTap: () async {
              for (var message in responsibleMessages) {
                // actually perma deletes for scheduled messages, :shrug:
                await backend.moveToRecycleBin(message.getChat()!, message);
                for (var attachment in (message.fetchAttachments() ?? [])) {
                  if (attachment == null) continue;
                  try {
                    File(attachment.getFile().path!).deleteSync();
                  } catch(e) {
                    Logger.debug("Failed to rm attachment $e");
                  }
                }
                ms(message.getChat()!.guid).removeMessage(message);
                Message.delete(message.guid!);
              }
            },
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => GestureDetector(
        onTap: showMenu,
        child: child
      ),
    ) : child;

  }
}
