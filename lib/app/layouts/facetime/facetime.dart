import 'dart:async';
import 'dart:io';

import 'package:bluebubbles/app/components/avatars/contact_avatar_group_widget.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/content/next_button.dart';
import 'package:bluebubbles/database/io/handle.dart';
import 'package:bluebubbles/database/io/chat.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/settings_widgets.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:external_path/external_path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bluebubbles/app/layouts/facetime/facetime_creator.dart';

class FaceTimePanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _FaceTimePanelState();
}

class _FaceTimePanelState extends OptimizedState<FaceTimePanel> {

  @override
  void initState() {
    super.initState();
    pushService.updateState();
  }

  @override
  void dispose() {
    // refreshTimer?.cancel();
    super.dispose();
  }

  Widget buildSession(api.FTSession session, bool active) {
    var participants = session.members.where((a) => !session.myHandles.contains(a.handle)).map((a) {
      if (a.nickname != null) {
        return Handle(address: "Maybe: ${a.nickname}");
      } else {
        return RustPushBBUtils.rustHandleToBB(a.handle);
      }
    }).toList();
    return SettingsTile(
      key: ValueKey(session.groupId),
      title: participants.isEmpty ? "Empty" : participants.map((a) => a.displayName).join(", "),
      subtitle: active ? "Tap to Join" : "FaceTime",
      leading: ContactAvatarGroupWidget(
              chat: Chat(guid: "", participants: participants),
              size: 40,
              editable: false,
            ),
      trailing: active ? Container(
        child: Icon(CupertinoIcons.videocam_fill, size: 20, color: context.theme.colorScheme.onBubble(context, false),),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.theme.colorScheme.bubble(context, false),
        ),
      ) : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (session.mode == api.FTMode.outgoing)
          Icon(Icons.call_made, color: context.theme.colorScheme.bubble(context, false), size: 17,),
          if (session.mode == api.FTMode.incoming)
          Icon(Icons.call_received, color: context.theme.colorScheme.bubble(context, false), size: 17,),
          if (session.mode == api.FTMode.missed)
          const Icon(Icons.call_missed, color: Colors.redAccent, size: 17),
          if (session.mode == api.FTMode.missedOutgoing)
          const Icon(Icons.call_missed_outgoing, color: Colors.redAccent, size: 17),
          if (session.mode != null)
          const SizedBox(width: 5),
          if (session.startTime != null)
          Text(
            buildDate(DateTime.fromMillisecondsSinceEpoch(session.startTime!)),
            style: context.theme.textTheme.bodyMedium!.apply(color: context.theme.colorScheme.outline.withOpacity(0.85)),
          ),
        ]
      ),
      onTap: () async {
        if (session.members.length == 2) {
          // 1-1 facetime, call again
          await pushService.placeOutgoingCall(session.myHandles.first, [session.members.firstWhere((a) => !session.myHandles.contains(a.handle)).handle]);
          return;
        }
        pushService.chosenFTRoomGuid = session.groupId;
        // should be cached
        var link = await api.getFtLink(state: pushService.state, usage: "next");
        var desc = participants.map((p) => p.displayName).join(" & ");
        // rotate link
        pushService.rotateLink().catchError((e, s) {
          Logger.error("Failed to rotate link", error: e, trace: s);
        });

        if (Platform.isAndroid) {
          await mcs.invokeMethod("launch-facetime", {'link': link, 'desc': desc, 'callUuid': session.groupId});
        } else {
          await launchUrl(
              Uri.parse(link),
              mode: LaunchMode.externalApplication
          );
        }
      },
    );
  }

  void addParticipantToCall() async {
    showAddParticipant(context, chat, isOngoingCall: true);
  }

  void removeParticipantFromCall(String participant) async {
    final response = await pushService.removeMember(participant);
    if (response) {
      showSnackbar("Notice", "Removed $participant successfully!");
    } else {
      showSnackbar("Error", "Failed to remove $participant!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => SettingsScaffold(
        title: "FaceTime",
        initialHeader: pushService.activeSessions.isEmpty ? "Calls" : "Active",
        iosSubtitle: iosSubtitle,
        materialSubtitle: materialSubtitle,
        tileColor: tileColor,
        headerColor: headerColor,
        actions: [
          IconButton(
            icon: Icon(iOS ? CupertinoIcons.add : Icons.add, color: context.theme.colorScheme.primary),
            onPressed: () {
              ns.push(
                context,
                const FaceTimeCreator(),
              );
            },
          ),
        ],
        bodySlivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                if (pushService.activeSessions.isNotEmpty)
                SettingsSection(
                  backgroundColor: tileColor,
                  children: pushService.activeSessions.map((s) => buildSession(s, true)).toList(),
                ),
                if (pushService.activeSessions.isNotEmpty && pushService.sessions.isNotEmpty)
                SettingsHeader(
                    iosSubtitle: iosSubtitle,
                    materialSubtitle: materialSubtitle,
                    text: "Calls"),
                if (pushService.sessions.isNotEmpty)
                SettingsSection(
                  backgroundColor: tileColor,
                  children: [
                    ListView.builder(itemBuilder: (context, idx) => buildSession(pushService.sessions[idx], false), itemCount: pushService.sessions.length,
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), findChildIndexCallback: (key) => findChildIndexByKey(pushService.sessions, key, (item) => item.groupId),)
                  ]
                ),
                if (pushService.sessions.isEmpty && pushService.activeSessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  child: Text("No Calls! Users can add you to FaceTime calls. They'll show up here, where you can join them.", style: context.textTheme.bodyMedium!,),
                ),
                if (chat.isGroup)
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0, bottom: 5.0),
                    child: Text("ONGOING CALL",
                        style: context.theme.textTheme.bodyMedium!.copyWith(color: context.theme.colorScheme.outline)),
                  ),
                if (chat.isGroup)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        mouseCursor: MouseCursor.defer,
                        onTap: () async {
                          addParticipantToCall();
                        },
                        title: Text("Add participant to call", style: context.theme.textTheme.bodyLarge!),
                        trailing: Icon(Icons.add, color: context.theme.colorScheme.onBackground),
                      ),
                    ),
                  ),
                if (chat.isGroup)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        mouseCursor: MouseCursor.defer,
                        onTap: () async {
                          final participant = await showDialog<String>(
                            context: context,
                            builder: (BuildContext context) {
                              return SimpleDialog(
                                title: Text("Select participant to remove"),
                                children: chat.participants.map((participant) {
                                  return SimpleDialogOption(
                                    onPressed: () {
                                      Navigator.pop(context, participant.address);
                                    },
                                    child: Text(participant.address),
                                  );
                                }).toList(),
                              );
                            },
                          );
                          if (participant != null) {
                            removeParticipantFromCall(participant);
                          }
                        },
                        title: Text("Remove participant from call", style: context.theme.textTheme.bodyLarge!),
                        trailing: Icon(Icons.remove, color: context.theme.colorScheme.onBackground),
                      ),
                    ),
                  ),
              ]),
          )
        ])
      );
  }

  void saveSettings() {
    ss.saveSettings();
  }
}
