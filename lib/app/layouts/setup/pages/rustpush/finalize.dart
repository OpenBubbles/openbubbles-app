import 'dart:async';
import 'dart:convert';

import 'package:bluebubbles/app/layouts/conversation_list/pages/conversation_list.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/content/next_button.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/content/settings_dropdown.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/content/settings_switch.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/content/settings_tile.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/layout/settings_header.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/layout/settings_section.dart';
import 'package:bluebubbles/app/layouts/setup/pages/page_template.dart';
import 'package:bluebubbles/app/layouts/setup/setup_view.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/services/ui/contact_service.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:get/get.dart' hide Response;
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:telephony_plus/telephony_plus.dart';

class FinalizePage extends StatefulWidget {
  @override
  State<FinalizePage> createState() => _FinalizePageState();
}

class _FinalizePageState extends OptimizedState<FinalizePage> {
  final controller = Get.find<SetupViewController>();
  final FocusNode doneFocusNode = FocusNode();

  List<String> handles = [];
  Rxn<GoogleSignInCredentials> googleCreds = Rxn(null);

  void scrollFocusIntoView(FocusNode node) {
    if (!node.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = node.context;
      if (context == null) return;
      Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 200), alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
    });
  }

  @override
  void initState() {
    super.initState();
    api.getHandles(state: pushService.state!.client).then((result) {
      setState(() {
        handles = result;
      });
    });
    if (kIsDesktop) {
      pushService.googleSignIn.signInOffline().then((state) {
        googleCreds.value = state;
      });
    }
    doneFocusNode.addListener(() {
      scrollFocusIntoView(doneFocusNode);
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      doneFocusNode.requestFocus();
    });
  }

  bool isActivateKey(LogicalKeyboardKey key) => key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.space;

  @override
  Widget build(BuildContext context) {
    var handlesMapped = handles.map((handle) => handle.replaceFirst("tel:", "").replaceAll("mailto:", "")).toList();
    var handle = ss.settings.defaultHandle.value.replaceFirst("tel:", "").replaceAll("mailto:", "");
    var initHandle = handlesMapped.contains(handle) ? handle : handlesMapped.firstOrNull;
    return SetupPageTemplate(
      title: "Done!",
      subtitle: "",
      customSubtitle: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You can be reached on iMessage at",
              style: context.theme.textTheme.bodyLarge!.apply(
                fontSizeDelta: 1.5,
                color: context.theme.colorScheme.outline,
              ).copyWith(height: 2)
            ),
            ...handles.map((e) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                e.replaceFirst("tel:", "").replaceAll("mailto:", ""),
                style: context.theme.textTheme.titleMedium,
              ),
            )),
            if (!controller.supportsPhoneReg.value && !kIsDesktop)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: GestureDetector(
                  child: Row(
                  children: [
                    Icon(Icons.add, color: context.theme.textTheme.titleMedium!.color!,),
                    const SizedBox(width: 5,),
                    Text(
                      "Add your number",
                      style: context.theme.textTheme.titleMedium,
                    )
                  ],
                ),
                onTap: () {
                  pushService.wantAddNumber();
                },
              )
            ),
            if (handles.length > 1)
            SettingsOptions<String>(
              title: "Start Chats Using",
              initial: initHandle ?? "",
              clampWidth: false,
              options: handlesMapped,
              secondaryColor: headerColor,
              useCupertino: false,
              textProcessing: (str) => ss.settings.redactedMode.value ? (GetUtils.isEmail(str) ? "Redacted Email" : "Redacted Phone") : str,
              capitalize: false,
              onChanged: (value) async {
                if (value == null) return;
                setState(() {});
                await backend.setDefaultHandle(value);
              },
            ),
            if (kIsDesktop)
            SettingsOptions<String>(
              title: "Sync contacts with",
              initial: ss.settings.contactSyncProvider.value,
              clampWidth: false,
              options: ["iCloud", "Google", "CardDav"],
              secondaryColor: headerColor,
              useCupertino: false,
              textProcessing: (str) => str,
              capitalize: false,
              onChanged: (value) async {
                ss.settings.ctags.clear();
                ss.settings.tokens.clear();
                ss.settings.contactSyncProvider.value = value ?? "iCloud";
                ss.saveSettings();
                cs.refreshContacts();
              },
            ),
            if (kIsDesktop && ss.settings.contactSyncProvider.value == "Google" && googleCreds.value == null)
            SettingsTile(
              title: "Sign In",
              onTap: () async {
                final credentials = await pushService.googleSignIn.signIn();
                if (credentials != null) {
                  print('Signed in successfully: ${credentials.accessToken}');
                  googleCreds.value = credentials;
                  cs.refreshContacts();
                } else {
                  print('Sign in failed');
                }
              },
              trailing: const NextButton(),
            ),
            if (kIsDesktop && ss.settings.contactSyncProvider.value == "Google" && googleCreds.value != null)
            SettingsTile(
              title: "Sign Out",
              onTap: () async {
                await pushService.googleSignIn.signOut();
                googleCreds.value = null;
              },
              trailing: const NextButton(),
            ),
            if (kIsDesktop && ss.settings.contactSyncProvider.value == "CardDav")
            SettingsTile(
              title: "Set CardDav Server Details",
              onTap: () async {
                pushService.updateCardDav();
              },
              trailing: const NextButton(),
            ),
          ],
        ),
      ),
      customButton: Column(
        children: [
          ErrorText(parentController: controller),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Theme(
                    data: context.theme.copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        labelStyle: TextStyle(color: context.theme.colorScheme.outline),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (ss.settings.macIsMine.value && !controller.supportsPhoneReg.value)
                          const Padding(padding: EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              "Share your Mac with up to 20 friends in settings!",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Focus(
                              focusNode: doneFocusNode,
                              onKey: (node, event) {
                                if (event is RawKeyDownEvent && isActivateKey(event.logicalKey)) {
                                  connect();
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: ss.settings.isDumb.value && doneFocusNode.hasFocus
                                    ? Border.all(
                                        color: context.theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                                        width: 2,
                                      )
                                    : null,
                                gradient: LinearGradient(
                                  begin: AlignmentDirectional.topStart,
                                  colors: [HexColor('2772C3'), HexColor('5CA7F8').darkenPercent(5)],
                                ),
                              ),
                              height: 40,
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                                  maximumSize: MaterialStateProperty.all(const Size(200, 36)),
                                  minimumSize: MaterialStateProperty.all(const Size(30, 30)),
                                ),
                                onPressed: () async {
                                  connect();
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Done",
                                        style: context.theme.textTheme.bodyLarge!
                                            .apply(fontSizeFactor: 1.1, color: Colors.white)),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.check, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> connect() async {
    Get.offAll(() => ConversationList(
        showArchivedChats: false,
        showUnknownSenders: false,
      ),
      routeName: "",
      duration: Duration.zero,
      transition: Transition.noTransition
    );
    Get.delete<SetupViewController>(force: true);
  }

}
