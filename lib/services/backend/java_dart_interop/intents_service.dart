import 'dart:async';

import 'package:bluebubbles/app/layouts/facetime/facetime.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_page.dart';
import 'package:bluebubbles/app/layouts/settings/pages/misc/shared_streams_panel.dart';
import 'package:bluebubbles/app/layouts/settings/pages/passwords/passwords_panel.dart';
import 'package:bluebubbles/app/layouts/settings/pages/profile/profile_panel.dart';
import 'package:bluebubbles/app/layouts/settings/pages/scheduling/scheduled_messages_panel.dart';
import 'package:bluebubbles/app/layouts/settings/pages/server/server_management_panel.dart';
import 'package:bluebubbles/app/wrappers/theme_switcher.dart';
import 'package:bluebubbles/helpers/backend/startup_tasks.dart';
import 'package:bluebubbles/helpers/ui/facetime_helpers.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';

import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/layouts/chat_creator/chat_creator.dart';
import 'package:bluebubbles/app/layouts/conversation_view/pages/conversation_view.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Intent;
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:receive_intent/receive_intent.dart';
import 'package:tuple/tuple.dart';
import 'package:universal_io/io.dart';
import 'package:url_launcher/url_launcher.dart';

IntentsService intents = Get.isRegistered<IntentsService>() ? Get.find<IntentsService>() : Get.put(IntentsService());

class IntentsService extends GetxService {
  late final StreamSubscription sub;

  Future<void> init() async {
    if (kIsWeb || kIsDesktop) return;

    final intent = await ReceiveIntent.getInitialIntent();
    handleIntent(intent);

    sub = ReceiveIntent.receivedIntentStream.listen((Intent? intent) {
      handleIntent(intent);
    }, onError: (err) {
      Logger.error("Failed to get intent!", error: err);
    });
  }

  @override
  void onClose() async {
    await sub.cancel();
    super.onClose();
  }

  void handleIntent(Intent? intent) async {
    if (intent == null) return;

    switch (intent.action) {
      case "com.bluebubbles.messaging.CallBackFT":
      final id = intent.extra!["callUuid"];
      var call = pushService.activeSessions.firstWhereOrNull((a) => a.groupId == id);
      if (call == null) {
        call = pushService.sessions.firstWhereOrNull((a) => a.groupId == id);
        if (call == null) {
          Logger.warn("callback uuid $id not found!");
          return;
        }
      }
      var handles = call.members.map((a) => a.handle).where((a) => a != call!.myHandles.first && !a.startsWith("temp:")).toList();
      pushService.placeOutgoingCall(call.myHandles.first, handles);
      mcs.invokeMethod(
        "delete-notification",
        {
          "notification_id": intent.extra!["notificationId"],
          "tag": NotificationsService.NEW_MESSAGE_TAG
        }
      );
      return;
      case "com.bluebubbles.messaging.RecentCalls":
        Navigator.of(Get.context!).push(
          ThemeSwitcher.buildPageRoute(
            builder: (BuildContext context) {
              return FaceTimePanel();
            },
          ),
        );
        return;
      case "android.intent.action.SEND":
      case "android.intent.action.SEND_MULTIPLE":
        final id = intent.extra?["android.intent.extra.shortcut.ID"];
        final text = intent.extra?["android.intent.extra.TEXT"];
        final files = <PlatformFile>[];
        if (intent.extra?["android.intent.extra.STREAM"] != null) {
          final data = intent.extra!["android.intent.extra.STREAM"];
          if (data is List) {
            for (String? s in data) {
              if (s == null) continue;
              final path = await mcs.invokeMethod("get-content-uri-path", {"uri": s});
              final bytes = await File(path).length();
              files.add(PlatformFile(
                path: path,
                name: basename(path),
                size: bytes,
              ));
            }
          } else if (data != null) {
            final path = await mcs.invokeMethod("get-content-uri-path", {"uri": data});
            final bytes = await File(path).length();
            files.add(PlatformFile(
              path: path,
              name: basename(path),
              size: bytes,
            ));
          }
        }
        await openChat(id, text: text, attachments: files);
        return;
      default:
        if (intent.data?.startsWith("imessage://") ?? false) {
          final uri = Uri.tryParse(intent.data!.replaceFirst("imessage://", "imessage:").replaceFirst("&body=", "?body="));
          if (uri != null) {
            final address = uri.path;
            final handle = Handle.findOne(addressAndService: Tuple2(address, "iMessage"));
            ns.pushAndRemoveUntil(
              Get.context!,
              ChatCreator(
                initialSelected: [SelectedContact(displayName: handle?.displayName ?? address, address: address)],
                initialText: uri.queryParameters['body'],
              ),
              (route) => route.isFirst,
            );
          }
        } else if (intent.extra?["chatGuid"] != null) {
          final guid = intent.extra!["chatGuid"]!;
          final bubble = intent.extra!["bubble"] == true;
          ls.isBubble = bubble;
          await openChat(guid);
        } else if (intent.extra?["callUuid"] != null) {
          await StartupTasks.waitForUI();
          Logger.info(intent.action);
        }
    }
  }

  Future<void> answerFaceTime(String callUuid) async {
    if (Get.context != null) {
      showDialog(
          context: Get.context!,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: context.theme.colorScheme.properSurface,
              title: Text(
                "Generating link for call...",
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
      hideFaceTimeOverlay(callUuid);
    }

    String? link;
    try {
      final call = await http.answerFaceTime(callUuid);
      link = call.data?["data"]?["link"];
    } catch (_) {}
    if (Get.context != null) {
      Navigator.of(Get.context!).pop();
    }
    if (link == null) {
      return showSnackbar("Failed to answer FaceTime", "Unable to generate FaceTime link!");
    }

    if (!kIsWeb) {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } else if (kIsWeb) {
      // TODO: Implement web FaceTime
    }
  }

  Future<void> openChat(String? guid, {String? text, List<PlatformFile> attachments = const []}) async {
    Logger.info("Handling open chat intent with guid: $guid", tag: "IntentsService");

    if (guid == null) {
      Logger.debug("Opening new chat creator..", tag: "IntentsService");
      await StartupTasks.waitForUI();
      ns.pushAndRemoveUntil(
        Get.context!,
        ChatCreator(
          initialAttachments: attachments,
          initialText: text,
        ),
        (route) => route.isFirst,
      );
    } else if (guid == "-1") {
      Logger.debug("Popping all routes...", tag: "IntentsService");
      if (cm.activeChat != null) {
        Navigator.of(Get.context!).popUntil((route) => route.isFirst);
      }
    } else if (guid == "-2") {
      Logger.debug("Opening server management panel...", tag: "IntentsService");
      Navigator.of(Get.context!).push(
        ThemeSwitcher.buildPageRoute(
          builder: (BuildContext context) {
            return ServerManagementPanel();
          },
        ),
      );
    } else if (guid == "-51" || guid == '-53') {
      Logger.debug("Opening profile panel...", tag: "IntentsService");
      ns.pushLeft(Get.context!, ProfilePanel());
    } else if (guid == "-52") {
      Logger.debug("Opening shared streams panel...", tag: "IntentsService");
      ns.pushLeft(Get.context!, SharedStreamsPanel());
    } else if (guid == "-54") {
      Logger.debug("Opening find my panel...", tag: "IntentsService");
      ns.pushLeft(Get.context!, FindMyPage());
    } else if (guid == "-55") {
      Logger.debug("Opening passwords panel...", tag: "IntentsService");
      ns.pushLeft(Get.context!, const PasswordsPanel());
    } else if (guid.contains("scheduled")) {
      Logger.debug("Opening scheduled messages panel...", tag: "IntentsService");
      Navigator.of(Get.context!).push(
        ThemeSwitcher.buildPageRoute(
          builder: (BuildContext context) {
            return ScheduledMessagesPanel();
          },
        ),
      );
    } else {
      Logger.debug("Opening existing chat (Attachments: ${attachments.length}; Text: ${text?.shorten(10) ?? 'N/A'})", tag: "IntentsService");
      final chat = Chat.findOne(guid: guid);
      if (chat == null) {
        Logger.debug("Chat not found with guid: $guid", tag: "IntentsService");
        return;
      }

      bool chatIsOpen = cm.activeChat?.chat.guid == guid;
      Logger.debug("Chat is active: $chatIsOpen", tag: "IntentsService");

      setPickedAttachments() {
        if (attachments.isNotEmpty) {
          cvc(chat).pickedAttachments.value = attachments;
        }

        if (text != null && text.isNotEmpty) {
          cvc(chat).textController.text = text;
        }
      }

      if (!chatIsOpen) {
        Logger.debug("Navigating to conversation view...", tag: "IntentsService");
        await StartupTasks.waitForUI();
        if (cm.activeChat != null) {
          Navigator.of(Get.context!).popUntil((route) => route.isFirst);
        }
        await Future.delayed(const Duration(seconds: 1));
        await ns.pushAndRemoveUntil(
          Get.context!,
          ConversationView(
            chat: chat,
            onInit: () => setPickedAttachments(),
          ),
          (route) => route.isFirst,
        );
      } else {
        Logger.debug("Chat is already open, not navigating", tag: "IntentsService");
        setPickedAttachments();
      }
    }
  }
}
