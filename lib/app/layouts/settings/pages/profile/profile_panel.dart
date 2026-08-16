import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bluebubbles/app/components/avatars/contact_avatar_widget.dart';
import 'package:bluebubbles/app/layouts/settings/pages/profile/posterkit.dart';
import 'package:bluebubbles/app/layouts/settings/pages/profile/profile_scaffold.dart';
import 'package:bluebubbles/app/layouts/settings/pages/theming/avatar/avatar_crop.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/content/next_button.dart';
import 'package:bluebubbles/app/wrappers/theme_switcher.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/settings_widgets.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/main.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:collection/collection.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/services/rustpush/relay_health.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:get/get.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supercharged/supercharged.dart';
import 'package:telephony_plus/telephony_plus.dart';
import 'package:universal_io/io.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:url_launcher/url_launcher.dart';

class ProfilePanel extends StatefulWidget {

  ProfilePanel({super.key});

  @override
  State<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends OptimizedState<ProfilePanel> with WidgetsBindingObserver {
  static const List<int> _syncHistoryOptions = [604800000, 2592000000, 15552000000, 31536000000, 0];
  static const Map<int, String> _syncHistoryLabels = {
    604800000: "7 days",
    2592000000: "1 month",
    15552000000: "6 months",
    31536000000: "1 year",
    0: "No limit",
  };
  final RxDouble opacity = 1.0.obs;
  final RxMap<String, dynamic> accountInfo = RxMap({});
  final RxMap<String, dynamic> accountContact = RxMap({});
  final RxnBool reregisteringIds = RxnBool();

  StreamSubscription<PurchasesResultWrapper>? subscription;
  String? ticket;

  RxList<api.PrivateDeviceInfo> forwardingTargets = RxList([]);

  Rxn<api.QuotaInfo> quotaInfo = Rxn(null);
  Rxn<GoogleSignInCredentials> googleCreds = Rxn(null);

  String relayHealthSubtitle() {
    if (pushService.relayHealthChecking.value) {
      return "Testing the iPhone relay...";
    }

    final checked = pushService.relayLastChecked.value;
    final lastSuccess = pushService.relayLastSuccess.value;
    final checkedText =
        checked == null ? null : buildChatListDateMaterial(checked);
    final successText =
        lastSuccess == null ? null : buildChatListDateMaterial(lastSuccess);

    switch (pushService.relayHealthStatus) {
      case RelayHealthStatus.healthy:
        return "Reachable${checkedText == null ? "" : " as of $checkedText"}. Tap to test again.";
      case RelayHealthStatus.stale:
        return "Last known reachable as of ${checkedText ?? "an earlier check"}. Tap to test again.";
      case RelayHealthStatus.offline:
        final lastSuccessSuffix =
            successText == null ? "" : " Last successful check: $successText.";
        return "Unavailable${checkedText == null ? "" : " as of $checkedText"}.$lastSuccessSuffix Turn on the relay and tap to retry.";
      case RelayHealthStatus.unknown:
        return "Not checked yet. Tap to verify the iPhone is online before registration renewal.";
    }
  }

  Future<void> handleSubscriptionToken(String subscription) async {
    var activated = await http.dio.post("https://hw.openbubbles.app/ticket/${ticket!}/activate", data: {"purchase_token": subscription});
    var useTicket = activated.data["ticket"];
    if (useTicket != ticket) {
      throw Exception("Ticket changed???");
    }
    (() async {
      try {
        reregisteringIds.value = true;
        await api.doReregister(state: pushService.state!.client);
        getDetails();
        showSnackbar("Success", "Registered");
      } catch (e) {
        showSnackbar("Failure", e.toString());
        rethrow;
      } finally {
        reregisteringIds.value = false;
      }
    })();
  }

  Future<T> wrapPromise<T>(Future<T> inner, String text) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.theme.colorScheme.properSurface,
          title: Text(
            text,
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
    T result;
    try {
      result = await inner;
    } catch (e, s) {
      Get.back();
      showSnackbar("Failure! Please try again", e.toString());
      rethrow;
    }
    Get.back();
    return result;
  }

  Future<bool> handlePurchases(PurchasesResultWrapper details) async {
    for (var detail in details.purchasesList) {
      if (detail.purchaseState != PurchaseStateWrapper.purchased) continue;
      ss.settings.hostedToken.value = detail.purchaseToken;
      ss.saveSettings();
      await wrapPromise(handleSubscriptionToken(detail.purchaseToken), "Validating subscription...");
      Logger.info("Purchased token ${detail.purchaseToken}");
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    getDetails();
    subscription = pushService.client.purchasesUpdatedStream.listen((PurchasesResultWrapper details) {
      handlePurchases(details);
    });
    if (pushService.state!.icloudServices != null) api.getQuotaInfo(info: pushService.state!.icloudServices!.tokenProvider).then((quota) => quotaInfo.value = quota);
    if (kIsDesktop) {
      pushService.googleSignIn.signInOffline().then((state) {
        googleCreds.value = state;
      });
    }
    // api.countRecords(state: pushService.state).then((summary) => cloudMessageSummary.value = summary);
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (profileDirty) {
        api.ShareProfileMessage? profile;
        if (cloudKitRecordDirty && ss.settings.nameAndPhotoSharing.value) {
          api.ShareProfileMessage? existing;
          if (ss.settings.shareProfileMessage.value != null) {
            existing = await api.decodeProfileMessage(s: ss.settings.shareProfileMessage.value!);
          }
          Uint8List? image;
          if (ss.settings.userAvatarPath.value != null) {
            image = await File(ss.settings.userAvatarPath.value!).readAsBytes();
          }
          showDialog(
            context: Get.context!,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: context.theme.colorScheme.properSurface,
                title: Text(
                  "Updating profile...",
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

          api.SimplifiedIncomingCallPoster? poster;
          if (ss.settings.userPosterPath.value != null && !kIsDesktop) {
            var data = await File("${ss.settings.userPosterPath.value!}.jpg").readAsBytes();
            print("Parsing file");
            poster = await api.fromPosterSave(poster: data);
          }

          await restorePoster(poster?.poster, ss.settings.userPosterPath.value!);

          api.ShareProfileMessage message;
          try {
            message = await api.setProfile(profiles: pushService.state!.icloudServices!.profilesClient, record: api.IMessageNicknameRecord(
              name: api.IMessageNameRecord(name: ss.settings.userName.value, first: ss.settings.firstName.value!, last: ss.settings.lastName.value!),
              image: image,
              poster: poster != null ? await api.fromPoster(poster: poster) : null,
            ), existing: existing);
          } catch(e, s) {
            Get.back();
            showSnackbar("Error", "Failed to update profile! $e");
            rethrow;
          }
          Get.back();

          ss.settings.sharedContacts.clear();
          ss.settings.dismissedContacts.clear();
          ss.settings.shareProfileMessage.value = await api.encodeProfileMessage(p: message);
          ss.saveSettings();
          profile = message;
        }

        pushService.updateShareState();

        var handle = (await api.getHandles(state: pushService.state!.client)).first;
        var msg = await api.newMsg(
          conversation: api.ConversationData(participants: [handle]),
          sender: handle,
          message: api.Message.updateProfile(api.UpdateProfileMessage(shareContacts: ss.settings.shareContactAutomatically.value, profile: profile)),
        );
        await (backend as RustPushBackend).sendMsg(msg);
      }
    });
  }

  void getDetails() async {
    try {
      final result = await backend.getAccountInfo();
      accountInfo.addAll(result);
      opacity.value = 1.0;
      final result2 = await backend.getAccountContact();
      accountContact.addAll(result2);
    } catch (e, s) {
      Logger.info("err", error: e, trace: s);
    }
    var myHandles = (await api.getMyPhoneHandles(state: pushService.state!.client));
    if (myHandles.isNotEmpty) {
      List<api.PrivateDeviceInfo> pendingTargets = ss.settings.isSmsRouter.value ? await api.getSmsTargets(state: pushService.state!.client, handle: myHandles.first, refresh: true) : [];
      ss.saveSettings();
      forwardingTargets.value = pendingTargets;
    }
    setState(() {});
  }

  Future<void> updateName() async {
    final firstName = TextEditingController(text: ss.settings.firstName.value);
    final lastName = TextEditingController(text: ss.settings.lastName.value);
    done() async {
      if (firstName.text.isEmpty) {
        showSnackbar("Error", "Enter a name!");
        return;
      }
      Get.back();
      ss.settings.firstName.value = firstName.text;
      ss.settings.lastName.value = lastName.text;
      ss.settings.userName.value = "${firstName.text} ${lastName.text}";
      cloudKitRecordDirty = true;
      profileDirty = true;
      await ss.saveSettings();
      setState(() {});
    }
    await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            actions: [
              TextButton(
                child: Text("Cancel", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                onPressed: () => Get.back(),
              ),
              TextButton(
                child: Text("OK", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                onPressed: () async {
                  done.call();
                },
              ),
            ],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstName,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "First Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16,),
                TextField(
                  controller: lastName,
                  onSubmitted: (_) => done.call(),
                  decoration: const InputDecoration(
                    labelText: "Last Name",
                    border: OutlineInputBorder(),
                  ),
                )
              ],
            ),
            title: Text("Change Name", style: context.theme.textTheme.titleLarge),
            backgroundColor: context.theme.colorScheme.properSurface,
          );
        }
    );
  }

  void updatePhoto() async {
    Navigator.of(context).push(
      ThemeSwitcher.buildPageRoute(
        builder: (context) => AvatarCrop(cropped: () {
          cloudKitRecordDirty = true;
          profileDirty = true;
        },),
      ),
    );
  }

  bool cloudKitRecordDirty = false;
  bool profileDirty = false;

  void removePhoto() {
    File file = File(ss.settings.userAvatarPath.value!);
    file.delete();
    ss.settings.userAvatarPath.value = null;
    ss.saveSettings();
    cloudKitRecordDirty = true;
    profileDirty = true;
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      handle: null,
      posterEdited: () {
        cloudKitRecordDirty = true;
        profileDirty = true;
      },
      bodySlivers: [
        SliverToBoxAdapter(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsHeader(
                  iosSubtitle: iosSubtitle,
                  materialSubtitle: materialSubtitle,
                  text: "Your Name and Photo"),
                SettingsSection(
                    backgroundColor: tileColor,
                    children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        mouseCursor: MouseCursor.defer,
                        leading: ContactAvatarWidget(
                          handle: null,
                          borderThickness: 0.1,
                          editable: false,
                          fontSize: 22,
                          size: 50,
                        ),
                        onTap: () async {
                          updateName();
                        },
                        title: RichText(
                          text: TextSpan(
                            style: context.theme.textTheme.bodyLarge,
                            children: MessageHelper.buildEmojiText(
                              ss.settings.redactedMode.value && ss.settings.hideContactInfo.value
                                  ? "User Name" : ss.settings.userName.value,
                              context.theme.textTheme.bodyLarge!,
                            ),
                          ),
                        ),
                        subtitle: Text(ss.settings.redactedMode.value && ss.settings.hideContactInfo.value
                            ? "User iCloud"
                            : ss.settings.iCloudAccount.isEmpty
                            ? "Unknown iCloud account"
                            : ss.settings.iCloudAccount.value, style: context.theme.textTheme.bodyMedium!.apply(color: context.theme.colorScheme.outline)),
                        trailing: Icon(Icons.edit_outlined, color: context.theme.colorScheme.onBackground),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        mouseCursor: MouseCursor.defer,
                        onTap: () async {
                          updatePhoto();
                        },
                        title: Text("Update your photo", style: context.theme.textTheme.bodyLarge!),
                        trailing: Icon(Icons.edit_outlined, color: context.theme.colorScheme.onBackground),
                      ),
                    ),
                  ),
                  Obx(() => ss.settings.userAvatarPath.value != null ? Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        mouseCursor: MouseCursor.defer,
                        onTap: () async {
                          removePhoto();
                        },
                        title: Text("Remove your photo", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.error)),
                        trailing: Icon(Icons.close, color: context.theme.colorScheme.error),
                      ),
                    ),
                  ) : const SizedBox.shrink()),
                ]),
                SettingsHeader(
                    iosSubtitle: iosSubtitle,
                    materialSubtitle: materialSubtitle,
                    text: "Sharing"),
                SettingsSection(
                    backgroundColor: tileColor,
                    children: [
                      Obx(() => SettingsSwitch(
                        onChanged: (bool val) async {
                          if (val && pushService.state!.icloudServices?.profilesClient == null) {
                            showSnackbar("Relog required!", "Relog required to use profile sharing! Relog in Settings -> Reconfigure");
                            return;
                          }
                          if (ss.settings.firstName.value == null || ss.settings.lastName.value == null) {
                            await updateName();
                          }
                          if (ss.settings.firstName.value == null || ss.settings.lastName.value == null) {
                            return;
                          }
                          ss.settings.nameAndPhotoSharing.value = val;
                          profileDirty = true;
                          ss.saveSettings();
                        },
                        initialVal: ss.settings.nameAndPhotoSharing.value,
                        title: "Name and Photo Sharing",
                        backgroundColor: tileColor,
                      )),
                      Obx(() => ss.settings.nameAndPhotoSharing.value ? SettingsOptions<String>(
                        title: "Share Automatically",
                        initial: ss.settings.shareContactAutomatically.value ? "Contacts Only" : "Always Ask",
                        clampWidth: false,
                        options: ["Contacts Only", "Always Ask"],
                        secondaryColor: headerColor,
                        useCupertino: false,
                        capitalize: false,
                        textProcessing: (s) => s,
                        onChanged: (value) async {
                          ss.settings.shareContactAutomatically.value = value == "Contacts Only";
                          profileDirty = true;
                          ss.saveSettings();
                        },
                      ) : const SizedBox.shrink()),
                    ]
                ),
                SettingsHeader(
                    iosSubtitle: iosSubtitle,
                    materialSubtitle: materialSubtitle,
                    text: "Backup"),
                Obx(() => SettingsSection(
                    backgroundColor: tileColor,
                    children: [
                      SettingsSwitch(
                        onChanged: (bool val) async {
                          if (pushService.state!.icloudServices?.keychain == null && val) {
                            showSnackbar("Relog required!", "Relog required to use Backup! Relog in Settings -> Reconfigure");
                            return;
                          }
                          if (val) {
                            if (!await pushService.joinClique()) return;
                            pushService.eraseCloudKitSync();
                          }

                          Logger.info("Enabling messages in iCloud!");
                          ss.settings.cloudSyncingEnabled.value = val;
                          ss.saveSettings();
                          if (!val) {
                            await pushService.resetCloudKitSync();
                          } else {
                            pushService.doCloudKitSync();
                          }
                        },
                        initialVal: ss.settings.cloudSyncingEnabled.value,
                        title: "Messages in iCloud (BETA)",
                        backgroundColor: tileColor,
                      ),
                      if(ss.settings.cloudSyncingEnabled.value)
                      SettingsSwitch(
                        onChanged: (bool val) async {
                          ss.settings.attachmentSyncEnabled.value = val;
                        },
                        initialVal: ss.settings.attachmentSyncEnabled.value,
                        title: "Upload attachments",
                        subtitle: "Disable to reduce iCloud storage usage",
                        backgroundColor: tileColor,
                      ),
                      if(ss.settings.cloudSyncingEnabled.value)
                      SettingsOptions<int>(
                        title: "Sync history",
                        initial: _syncHistoryOptions.contains(ss.settings.syncHistoryTime.value) ? ss.settings.syncHistoryTime.value : 0,
                        clampWidth: false,
                        options: _syncHistoryOptions,
                        secondaryColor: headerColor,
                        useCupertino: false,
                        capitalize: false,
                        textProcessing: (value) => _syncHistoryLabels[value] ?? "No limit",
                        onChanged: (value) async {
                          if (value == null) return;
                          ss.settings.syncHistoryTime.value = value;
                          ss.saveSettings();
                          await pushService.resetCloudKitSync();
                          pushService.doCloudKitSync();
                        },
                      ),
                      if (quotaInfo.value != null && ss.settings.cloudSyncingEnabled.value)
                      Container(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0, left: 15, top: 8.0, right: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Used ${pushService.formatBytes(quotaInfo.value!.messagesBytes)}. ${pushService.formatBytes(quotaInfo.value!.availableBytes)} available in iCloud."),
                                Text("Upgrade to iCloud+ on any Apple device or Windows PC for more storage space.", style: context.theme.textTheme.bodySmall!.copyWith(color: context.theme.colorScheme.properOnSurface.withOpacity(0.75), height: 1.5),)
                              ]
                            ),
                          ),
                      ),
                      if(ss.settings.cloudSyncingEnabled.value && pushService.isSyncing.value == null)
                      SettingsTile(
                        title: "Sync Now",
                        onTap: () async {
                          await pushService.doCloudKitSync();
                        },
                        trailing: const NextButton(),
                      ),
                      if(ss.settings.cloudSyncingEnabled.value)
                      Container(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0, left: 15, top: 8.0, right: 15),
                            child: Text(
                              pushService.isSyncing.value ??
                              ((ss.prefs.getInt("lastSynced") ?? 0) == 0 ? "Not Synced" : "Synced ${buildChatListDateMaterial(DateTime.fromMillisecondsSinceEpoch(ss.prefs.getInt("lastSynced")!))}")
                            )
                          ),
                      ),
                    ]
                )),
                if (kIsDesktop)
                SettingsHeader(
                    iosSubtitle: iosSubtitle,
                    materialSubtitle: materialSubtitle,
                    text: "Contacts Syncing"),
                if (kIsDesktop)
                Obx(() => SettingsSection(
                    backgroundColor: tileColor,
                    children: [
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
                      if (ss.settings.contactSyncProvider.value == "Google" && googleCreds.value == null)
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
                      if (ss.settings.contactSyncProvider.value == "Google" && googleCreds.value != null)
                      SettingsTile(
                        title: "Sign Out",
                        onTap: () async {
                          await pushService.googleSignIn.signOut();
                          googleCreds.value = null;
                        },
                        trailing: const NextButton(),
                      ),
                      if (ss.settings.contactSyncProvider.value == "CardDav")
                      SettingsTile(
                        title: "Set CardDav Server Details",
                        onTap: () async {
                          pushService.updateCardDav();
                        },
                        trailing: const NextButton(),
                      ),
                    ]
                )),
                SettingsHeader(
                    iosSubtitle: iosSubtitle,
                    materialSubtitle: materialSubtitle,
                    text: "Apple Account Info"),
                Skeletonizer(
                  enabled: accountInfo.isEmpty,
                  child: SettingsSection(
                    backgroundColor: tileColor,
                    children: [
                      Obx(() {
                        bool redact = ss.settings.redactedMode.value;
                        return Container(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0, left: 15, top: 8.0, right: 15),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: opacity.value,
                              child: SelectableText.rich(
                                TextSpan(children: [
                                  TextSpan(text: redact ? "Account Name - Apple ID" : "${accountInfo['account_name']} - ${accountInfo['apple_id']}"),
                                  const TextSpan(text: "\n"),
                                  const TextSpan(text: "iMessage Status: ", style: TextStyle(height: 3.0)),
                                  TextSpan(
                                      text: accountInfo['login_status_message'],
                                      style: TextStyle(color: getIndicatorColor((accountInfo['login_status_message']?.startsWith("Connected") ?? false) ? SocketState.connected : SocketState.disconnected))),
                                  const TextSpan(text: "\n"),
                                  const TextSpan(text: "SMS Forwarding Status: "),
                                  TextSpan(
                                      text: accountInfo['sms_forwarding_enabled'] == true ? "ENABLED" : "DISABLED",
                                      style: TextStyle(color: getIndicatorColor(accountInfo['sms_forwarding_enabled'] == true ? SocketState.connected : SocketState.disconnected))),
                                  const TextSpan(text: "  |  "),
                                  TextSpan(
                                      text: accountInfo['sms_forwarding_capable'] == true ? "CAPABLE" : "INCAPABLE",
                                      style: TextStyle(color: getIndicatorColor(accountInfo['sms_forwarding_capable'] == true ? SocketState.connected : SocketState.disconnected))),
                                  const TextSpan(text: "\n"),
                                  const TextSpan(text: "VETTED ALIASES\n", style: TextStyle(fontWeight: FontWeight.w700, height: 3.0)),
                                  ...((accountInfo['vetted_aliases'] as List<dynamic>? ?? [])).map((e) => [
                                    TextSpan(text: "⬤  ", style: TextStyle(color: getIndicatorColor(e['Status'] == 3 ? SocketState.connected : SocketState.disconnected))),
                                    TextSpan(text: redact ? (GetUtils.isEmail(e['Alias']) ? "Redacted Email\n" : "Redacted Phone\n") : "${e['Alias']}\n")
                                  ]).toList().flattened,
                                  const TextSpan(text: "\n"),
                                  const TextSpan(text: "Tap to update values...", style: TextStyle(fontStyle: FontStyle.italic)),
                                ]),
                                onTap: () {
                                  opacity.value = 0.0;
                                  getDetails();
                                },
                              ),
                            ),
                          ));
                      }),
                      if ((accountInfo["can_pnr"] ?? false) &&
                          !ss.settings.deviceIsHosted.value)
                        Obx(() {
                          if (!pushService.relayHealthAvailable.value) {
                            return const SizedBox.shrink();
                          }
                          final checking =
                              pushService.relayHealthChecking.value;
                          final status = pushService.relayHealthStatus;
                          final color = checking
                              ? context.theme.colorScheme.outline
                              : status == RelayHealthStatus.healthy
                                  ? getIndicatorColor(SocketState.connected)
                                  : status == RelayHealthStatus.offline
                                      ? getIndicatorColor(
                                          SocketState.disconnected)
                                      : context.theme.colorScheme.outline;
                          return SettingsTile(
                            title: "iPhone Relay",
                            subtitle: relayHealthSubtitle(),
                            isThreeLine: true,
                            leading:
                                Icon(Icons.phone_iphone, color: color),
                            trailing: checking
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              color),
                                    ),
                                  )
                                : Icon(
                                    status == RelayHealthStatus.healthy
                                        ? Icons.check_circle
                                        : status == RelayHealthStatus.offline
                                            ? Icons.error
                                            : Icons.help_outline,
                                    color: color,
                                  ),
                            onTap: checking
                                ? null
                                : () async {
                                    final result =
                                        await pushService.checkRelayHealth();
                                    if (result == true) {
                                      showSnackbar("iPhone Relay",
                                          "The relay is online and responding.");
                                    } else if (result == false) {
                                      showSnackbar("iPhone Relay",
                                          "The relay could not be reached. Check its power, Wi-Fi, and ValidationRelay status.");
                                    }
                                  },
                          );
                        }),
                      if (accountInfo['login_status_message']?.startsWith("Deregistered") ?? false)
                        Container(
                          color: tileColor,
                          child: SettingsDivider(color: context.theme.colorScheme.surfaceVariant, padding: EdgeInsets.zero,),
                        ),
                      if ((accountInfo['login_status_message']?.startsWith("Deregistered") ?? false) || (accountInfo['login_status_message']?.contains("Subscription not active!") ?? false))
                        SettingsTile(
                        title: accountInfo['login_status_message']!.contains("Device not reserved!") ? "Reserve a new device" : accountInfo['login_status_message']!.contains("Subscription not active!") ? "Renew subscription" : "Retry now",
                        onTap: () async {
                          if (accountInfo['login_status_message']!.contains("Subscription not active!") || accountInfo['login_status_message']!.contains("Device not reserved!")) {
                            wrapPromise((() async {
                              ticket = await api.validateRelay(configRef: pushService.state!.osConfig);
                              if (ticket == null) {
                                var isNotReserved = accountInfo['login_status_message']!.contains("Device not reserved!");

                                final status = await http.dio.get("https://hw.openbubbles.app/status");
                                var hasCapacity = status.data["available"];
                                var description = "When an OpenBubbles subscription becomes invalid, we reserve your device for a few days as a courtesy should you choose to restart your subscription. Unfortunately, however, we have already released your device to another user.";
                                if (hasCapacity) {
                                  description += " We have more devices available, however, you will have to re-activate. Backing up your messages now is recommended in case you aren't able to get back in.";
                                } else {
                                  description += " Double unfortunately, we are currently out of devices. Please check back later.";
                                }
                                // if we're not told we're not active, that means we have lost privileges to our device.
                                Timer(const Duration(milliseconds: 100), () {
                                  showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      "We're so sorry!",
                                      style: context.theme.textTheme.titleLarge,
                                    ),
                                    backgroundColor: context.theme.colorScheme.properSurface,
                                    content: Text(description, style: context.theme.textTheme.bodyLarge),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                            "Close",
                                            style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
                                        ),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                      if (hasCapacity)
                                      TextButton(
                                        child: Text(
                                            isNotReserved ? "Get a new device" :"Restart subscription",
                                            style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          pushService.markFailedToLogin(hw: true, ui: true);
                                        }
                                      ),
                                      if (!hasCapacity && isNotReserved)
                                      TextButton(
                                        child: Text(
                                            "Get a refund",
                                            style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          pushService.offerHostedRefund(true);
                                        }
                                      ),
                                    ],
                                  ),
                                );
                                });
                                return;
                              }
                              pushService.client.runWithClientNonRetryable<void>((client) async {
                                var purchases = await client.queryPurchases(ProductType.subs);
                                if (await handlePurchases(purchases)) return;

                                var details = await client.queryProductDetails(productList: [const ProductWrapper(productId: 'monthly_hosted', productType: ProductType.subs)]);
                                if (details.productDetailsList.isEmpty) {
                                  return;
                                }
                                client.launchBillingFlow(product: 'monthly_hosted', offerToken: details.productDetailsList.first.subscriptionOfferDetails?.first.offerIdToken);
                              });
                            })(), "Validating subscription...");
                            return;
                          }
                          try {
                            reregisteringIds.value = true;
                            await api.doReregister(state: pushService.state!.client);
                            getDetails();
                            showSnackbar("Success", "Registered");
                          } catch (e) {
                            showSnackbar("Failure", e.toString());
                            rethrow;
                          } finally {
                            reregisteringIds.value = false;
                          }
                        },
                        trailing: Obx(() => reregisteringIds.value == null
                            ? const NextButton()
                            : reregisteringIds.value == true ? Container(
                            constraints: const BoxConstraints(
                              maxHeight: 20,
                              maxWidth: 20,
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(context.theme.colorScheme.primary),
                            )) : Icon(Icons.check, color: context.theme.colorScheme.outline))
                        ),
                      if (!(accountInfo['can_pnr'] ?? true) && !kIsDesktop)
                        SettingsTile(
                          title: "Add your phone number",
                          onTap: () async {
                            pushService.wantAddNumber();
                          },
                          trailing: const NextButton(),
                          leading: Icon(Icons.add, color: context.theme.colorScheme.outline),
                        ),
                        if (accountInfo['login_status_message']?.contains("Sorry, your hosted device is currently offline!") ?? false)
                        SettingsTile(
                        title: "Get a different Hosted Device",
                        onTap: () async {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                "Get a different hosted device?",
                                style: context.theme.textTheme.titleLarge,
                              ),
                              backgroundColor: context.theme.colorScheme.properSurface,
                              content: Text("You will have to log in again with your Apple Account.", style: context.theme.textTheme.bodyLarge),
                              actions: [
                                TextButton(
                                  child: Text(
                                      "Cancel",
                                      style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                TextButton(
                                  child: Text(
                                      "Change",
                                      style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
                                  ),
                                  onPressed: () {
                                    wrapPromise((() async {
                                      Navigator.of(context).pop();
                                      var relay = await api.validateRelay(configRef: pushService.state!.osConfig);
                                      if (relay == null) {
                                        throw Exception("Failed to validate!");
                                      }
                                      final status = await http.dio.post("https://hw.openbubbles.app/swap-token", options: Options(
                                        headers: {
                                          "Authorization": "Bearer $relay"
                                        }
                                      ));

                                      if (status.statusCode != 200) {
                                        if (status.data.toString().contains("No device available!")) {
                                          Timer(const Duration(milliseconds: 100), () => pushService.offerHostedRefund(false));
                                        }
                                        throw Exception("Failed to swap ${status.data}");
                                      }

                                      var newTicket = status.data["new_ticket"];
                                      var config = await api.configFromRelay(code: newTicket, host: "https://hw.openbubbles.app");
                                      await api.setIdentity(statePath: pushService.statePath, config: config, identity: api.newNgmIdentity());
                                      api.resetAnisette(path: pushService.statePath);

                                      await pushService.markFailedToLogin(hw: true, logout: true);

                                      var list = ss.settings.cachedCodes.entries.toList();
                                      for (var items in list) {
                                        if (!items.key.startsWith("sms-auth-")) continue;
                                        ss.settings.cachedCodes.remove(items.key);
                                      }
                                      ss.saveSettings();
                                    })(), "Changing device...");
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        trailing: Obx(() => reregisteringIds.value == null
                            ? const NextButton()
                            : reregisteringIds.value == true ? Container(
                            constraints: const BoxConstraints(
                              maxHeight: 20,
                              maxWidth: 20,
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(context.theme.colorScheme.primary),
                            )) : Icon(Icons.check, color: context.theme.colorScheme.outline))
                        ),
                      if ((accountInfo['vetted_aliases'] as List<dynamic>? ?? []).any((a) => (a['Alias'] as String).isEmail))
                        SettingsTile(
                          title: "Get a verification code",
                          onTap: () async {
                            var code = await api.get2FaCode(anisette: pushService.state!.anisette);
                            await showDialog(
                              context: context,
                              builder: (_) {
                                return AlertDialog(
                                  actions: [
                                    TextButton(
                                      child: Text("OK", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                                      onPressed: () async {
                                        Get.back();
                                      },
                                    ),
                                  ],
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("Use this code to log into your Apple Account on another device.", style: context.textTheme.bodyLarge,),
                                      const SizedBox(height: 30,),
                                      Text(code.toString().padLeft(6, '0'), style: context.textTheme.displaySmall?.copyWith(color: context.textTheme.bodyLarge?.color, letterSpacing: 20),),
                                      const SizedBox(height: 30,),
                                      Text("Do not share it with anyone. Apple will never call or text you for this code.", style: context.textTheme.bodyLarge,),
                                    ],
                                  ),
                                  title: Text("Verification code", style: context.theme.textTheme.titleLarge),
                                  backgroundColor: context.theme.colorScheme.properSurface,
                                );
                              }
                          );
                          },
                          trailing: const NextButton(),
                        ),
                      if (!(accountInfo['login_status_message']?.contains("Subscription not active!") ?? false) && ss.settings.deviceIsHosted.value)
                        SettingsTile(
                        title: "Manage subscription",
                        onTap: () async {
                          launchUrl(Uri.parse("https://play.google.com/store/account/subscriptions?sku=monthly_hosted&package=com.openbubbles.messaging"), mode: LaunchMode.externalNonBrowserApplication);
                        },
                        trailing: const NextButton()
                      ),
                      if (accountInfo['active_alias'] != null)
                        SettingsOptions<String>(
                          title: "Start Chats Using",
                          initial: accountInfo['active_alias'],
                          clampWidth: false,
                          options: accountInfo['vetted_aliases'].map((e) => e['Alias'].toString()).toList().cast<String>(),
                          secondaryColor: headerColor,
                          useCupertino: false,
                          textProcessing: (str) => ss.settings.redactedMode.value ? (GetUtils.isEmail(str) ? "Redacted Email" : "Redacted Phone") : str,
                          capitalize: false,
                          onChanged: (value) async {
                            if (value == null) return;
                            accountInfo['active_alias'] = value;
                            setState(() {});
                            await backend.setDefaultHandle(value);
                          },
                        ),
                    if (usingRustPush && Platform.isAndroid && (accountInfo["can_forward"] ?? false))
                      Obx(() => SettingsSwitch(
                          onChanged: (bool val) async {
                            if (val) {
                              var granted = await TelephonyPlus().requestPermissions();
                              if (!granted) {
                                showSnackbar("SMS denied", "Please enable SMS permission in settings");
                                return;
                              }
                            }
                            var myHandles = (await api.getMyPhoneHandles(state: pushService.state!.client));
                            ss.settings.isSmsRouter.value = val;

                            List<api.PrivateDeviceInfo> pendingTargets = val ? await api.getSmsTargets(state: pushService.state!.client, handle: myHandles.first, refresh: true) : [];
                            if (!val) {
                              await (backend as RustPushBackend).broadcastSmsForwardingState(false, ss.settings.smsRoutingTargets);
                            }
                            ss.settings.smsRoutingTargets.retainWhere((element) => pendingTargets.any((e) => e.uuid == element));
                            ss.saveSettings();
                            setState(() {
                              forwardingTargets.value = pendingTargets;
                            });
                          },
                          initialVal: ss.settings.isSmsRouter.value,
                          title: "Text message forwarding (BETA)",
                          subtitle: "See your Android SMS messages on your other Apple devices",
                          backgroundColor: tileColor,
                          isThreeLine: true,
                        )),
                      if (!ss.settings.redactedMode.value)
                      ...(usingRustPush && Platform.isAndroid && ss.settings.isSmsRouter.value ? 
                        forwardingTargets.filter((target) => target.uuid != null && target.deviceName != null).map((target) => SettingsSwitch(
                          onChanged: (bool val) async {
                            if (!target.isHsaTrusted) {
                              showSnackbar("Can't enable SMS forwarding!", "Re-log in with 2fa on the other device");
                              return;
                            }
                            if (ss.settings.smsRoutingTargets.contains(target.uuid)) {
                              ss.settings.smsRoutingTargets.remove(target.uuid);
                              setState(() { });
                              await (backend as RustPushBackend).broadcastSmsForwardingState(false, [target.uuid!]);
                            } else {
                              ss.settings.smsRoutingTargets.add(target.uuid!);
                              setState(() { });                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
                              await (backend as RustPushBackend).broadcastSmsForwardingState(true, [target.uuid!]);
                            }
                            ss.saveSettings();
                          },
                          initialVal: ss.settings.smsRoutingTargets.contains(target.uuid),
                          title: target.deviceName!,
                          backgroundColor: tileColor,
                        ))
                       : [])
                    ],
                  )),
                if (!isNullOrEmpty(accountContact['name']))
                  SettingsHeader(
                      iosSubtitle: iosSubtitle,
                      materialSubtitle: materialSubtitle,
                      text: "iMessage Contact Card"),
                if (!isNullOrEmpty(accountContact['name']))
                  SettingsSection(
                    backgroundColor: tileColor,
                    children: [
                      SettingsTile(
                        leading: (accountContact['avatar'] == null) ? const CircleAvatar() : ContactAvatarWidget(
                          handle: null,
                          contact: isNullOrEmpty(accountContact['avatar']) ? null : Contact(id: randomString(9), displayName: "", avatar: base64Decode(accountContact['avatar'])),
                        ),
                        title: accountContact['name'],
                        subtitle: "Your sharable iMessage contact card",
                      ),
                      const SettingsSubtitle(subtitle: "Visit iMessage settings on your Mac to update.")
                    ],
                  ),
              ],
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(top: 50),
        ),
      ],
    );
  }
}
