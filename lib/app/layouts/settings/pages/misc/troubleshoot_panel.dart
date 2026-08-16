import 'package:bluebubbles/app/layouts/settings/pages/misc/logging_panel.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/content/log_level_selector.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/content/next_button.dart';
import 'package:bluebubbles/helpers/backend/settings_helpers.dart';
import 'package:bluebubbles/main.dart';
import 'package:bluebubbles/services/backend/sync/chat_sync_manager.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/settings_widgets.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/share.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:universal_io/io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;




class TroubleshootPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TroubleshootPanelState();
}

class _TroubleshootPanelState extends OptimizedState<TroubleshootPanel> {
  final RxnBool resyncingHandles = RxnBool();
  final RxnBool resyncingChats = RxnBool();
  final RxInt logFileCount = 1.obs;
  final RxInt logFileSize = 0.obs;
  final RxBool optimizationsDisabled = false.obs;
  final TextEditingController participantController = TextEditingController();

  bool isExportingLogs = false;
  final RxnBool reregisteringIds = RxnBool();

  @override
  void initState() {
    super.initState();

    // Count how many .log files are in the log directory
    final Directory logDir = Directory(Logger.logDir);
    if (logDir.existsSync()) {
      final List<FileSystemEntity> files = logDir.listSync();
      final logFiles =
          files.where((file) => file.path.endsWith(".log")).toList();
      logFileCount.value = logFiles.length;

      // Size in KB
      for (final file in logFiles) {
        logFileSize.value += file.statSync().size ~/ 1024;
      }
    }

    // Check if battery optimizations are disabled
    if (Platform.isAndroid) {
      DisableBatteryOptimization.isAllBatteryOptimizationDisabled.then((value) {
        optimizationsDisabled.value = value ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWebOrDesktop = kIsWeb || kIsDesktop;
    return SettingsScaffold(
        title: "Developer Tools",
        initialHeader: (isWebOrDesktop) ? "Contacts" : "Logging",
        iosSubtitle: iosSubtitle,
        materialSubtitle: materialSubtitle,
        tileColor: tileColor,
        headerColor: headerColor,
        bodySlivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                if (isWebOrDesktop)
                  SettingsSection(
                    backgroundColor: tileColor,
                    children: [
                      SettingsTile(
                        onTap: () async {
                          final RxList<String> log = <String>[].obs;
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    backgroundColor:
                                        context.theme.colorScheme.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    titlePadding:
                                        const EdgeInsets.only(top: 15),
                                    title: Text("Fetching contacts...",
                                        style:
                                            context.theme.textTheme.titleLarge),
                                    content: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: ns.width(context) * 4 / 5,
                                        height: context.height * 1 / 3,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            color: context
                                                .theme.colorScheme.background,
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          child: Obx(() => ListView.builder(
                                                physics:
                                                    const AlwaysScrollableScrollPhysics(
                                                        parent:
                                                            BouncingScrollPhysics()),
                                                itemBuilder: (context, index) {
                                                  return Text(
                                                    log[index],
                                                    style: TextStyle(
                                                      color: context
                                                          .theme
                                                          .colorScheme
                                                          .onBackground,
                                                      fontSize: 10,
                                                    ),
                                                  );
                                                },
                                                itemCount: log.length,
                                              )),
                                        ),
                                      ),
                                    ),
                                  ));
                          await cs.fetchNetworkContacts(logger: (newLog) {
                            log.add(newLog);
                          });
                        },
                        leading: const SettingsLeadingIcon(
                          iosIcon: CupertinoIcons.group,
                          materialIcon: Icons.contacts,
                        ),
                        title: "Fetch Contacts With Verbose Logging",
                        subtitle:
                            "This will fetch contacts from the server with extra info to help devs debug contacts issues",
                      ),
                    ],
                  ),
                if (isWebOrDesktop)
                  SettingsHeader(
                      iosSubtitle: iosSubtitle,
                      materialSubtitle: materialSubtitle,
                      text: "Logging"),
                SettingsSection(backgroundColor: tileColor, children: [
                  const LogLevelSelector(),
                  SettingsTile(
                    title: "View Latest Log",
                    subtitle: "View the latest log file. Useful for debugging issues, in app.",
                    leading: const SettingsLeadingIcon(
                      iosIcon: CupertinoIcons.doc_append,
                      materialIcon: Icons.document_scanner_rounded,
                      containerColor: Colors.blueAccent,
                    ),
                    onTap: () {
                      ns.pushSettings(
                        context,
                        LoggingPanel(),
                      );
                    },
                    trailing: const NextButton(),
                  ),
                  if (Platform.isAndroid)
                    const SettingsDivider(padding: EdgeInsets.only(left: 16.0)),
                  if (Platform.isAndroid)
                    SettingsTile(
                        leading: const SettingsLeadingIcon(
                          iosIcon: CupertinoIcons.share_up,
                          materialIcon: Icons.share,
                          containerColor: Colors.green,
                        ),
                        title: "Download / Share Logs",
                        subtitle:
                            "${logFileCount.value} log file(s) | ${logFileSize.value} KB",
                        onTap: () async {
                          if (logFileCount.value == 0) {
                            showSnackbar("No Logs", "There are no logs to download!");
                            return;
                          }

                          if (isExportingLogs) return;
                          isExportingLogs = true;

                          try {
                            showSnackbar("Please Wait", "Compressing ${logFileCount.value} log file(s)...");
                            String filePath = Logger.compressLogs();
                            final File zippedLogFile = File(filePath);

                            // Copy the file to downloads
                            String newPath = await fs.saveToDownloads(zippedLogFile);

                            // Delete the original file
                            zippedLogFile.deleteSync();

                            // Let the user know what happened
                            showSnackbar(
                              "Logs Exported",
                              "Logs have been exported to your downloads folder. Tap here to share it.",
                              durationMs: 5000,
                              onTap: (snackbar) async {
                                Share.file("BlueBubbles Logs", newPath);
                              },
                            );
                          } catch (ex, stacktrace) {
                            Logger.error("Failed to export logs!", error: ex, trace: stacktrace);
                            showSnackbar("Failed to export logs!", "Error: ${ex.toString()}");
                          } finally {
                            isExportingLogs = false;
                          }
                        }),
                  if (kIsDesktop)
                    const SettingsDivider(padding: EdgeInsets.only(left: 16.0)),
                  if (kIsDesktop)
                    SettingsTile(
                        leading: const SettingsLeadingIcon(
                          iosIcon: CupertinoIcons.doc,
                          materialIcon: Icons.file_open,
                        ),
                        title: "Open Logs",
                        subtitle: Logger.logDir,
                        onTap: () async {
                          final File logFile = File(Logger.logDir);
                          if (logFile.existsSync()) {
                            logFile.createSync(recursive: true);
                          }
                          await launchUrl(Uri.file(logFile.path));
                        }),
                  const SettingsDivider(padding: EdgeInsets.only(left: 16.0)),
                  SettingsTile(
                      leading: const SettingsLeadingIcon(
                        iosIcon: CupertinoIcons.trash,
                        materialIcon: Icons.delete,
                        containerColor: Colors.redAccent,
                      ),
                      title: "Clear Logs",
                      subtitle: "Deletes all stored log files.",
                      onTap: () async {
                        Logger.clearLogs();
                        showSnackbar(
                            "Logs Cleared", "All logs have been deleted.");
                        logFileCount.value = 0;
                        logFileSize.value = 0;
                      }),
                  if (kIsDesktop) const SettingsDivider(),
                  if (kIsDesktop)
                    SettingsTile(
                      leading: const SettingsLeadingIcon(
                        iosIcon: CupertinoIcons.folder,
                        materialIcon: Icons.folder,
                      ),
                      title: "Open App Data Location",
                      subtitle: fs.appDocDir.path,
                      onTap: () async =>
                          await launchUrl(Uri.file(fs.appDocDir.path)),
                    ),
                ]),
                if (Platform.isAndroid)
                  SettingsHeader(
                      iosSubtitle: iosSubtitle,
                      materialSubtitle: materialSubtitle,
                      text: "Optimizations"),
                if (Platform.isAndroid)
                  SettingsSection(backgroundColor: tileColor, children: [
                    SettingsTile(
                        onTap: () async {
                          if (optimizationsDisabled.value) {
                            showSnackbar("Already Disabled",
                                "Battery optimizations are already disabled for BlueBubbles");
                            return;
                          }

                          final optsDisabled =
                              await disableBatteryOptimizations();
                          if (!optsDisabled) {
                            showSnackbar("Error",
                                "Battery optimizations were not disabled. Please try again.");
                          }
                        },
                        leading: Obx(() => SettingsLeadingIcon(
                          iosIcon: CupertinoIcons.battery_25,
                          materialIcon: Icons.battery_5_bar,
                          containerColor: optimizationsDisabled.value ? Colors.green : Colors.redAccent,
                        )),
                        title: "Disable Battery Optimizations",
                        subtitle: "Allow app to run in the background via the OS. This may not do anything on some devices.",
                        trailing: Obx(() => !optimizationsDisabled.value
                            ? const NextButton()
                            : Icon(Icons.check,
                                color: context.theme.colorScheme.outline))),
                  ]),

                
                SettingsHeader(
                  iosSubtitle: iosSubtitle,
                  materialSubtitle: materialSubtitle,
                  text: "Troubleshooting"),
                SettingsSection(
                  backgroundColor: tileColor,
                  children: [
                    SettingsTile(
                      leading: const SettingsLeadingIcon(
                        iosIcon: CupertinoIcons.share,
                        materialIcon: Icons.share,
                      ),
                      title: "Export OB logs",
                      subtitle: "Last 24-48 hours saved. Contains sensitive information (such as messages and identifiers); do not share publicly.",
                      onTap: () async {
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
                        // Copy the file to downloads

                        final Directory logDir = Directory(Logger.logDir);
                        final date = DateTime.now().toIso8601String().split('T').first;
                        final File logFile =
                            File("${fs.appDocDir.path}/openbubbles-logs-$date.log");
                        if (logFile.existsSync()) logFile.deleteSync();

                        await logFile.writeAsBytes(total);

                        String newPath = await fs.saveToDownloads(logFile);

                        // Delete the original file
                        logFile.deleteSync();

                        // Let the user know what happened
                        showSnackbar(
                          "Logs Exported",
                          "Logs have been exported to your downloads folder. Tap here to share it.",
                          durationMs: 5000,
                          onTap: (snackbar) async {
                            Share.file("OpenBubbles Logs", newPath);
                          },
                        );
                        // Logger.writeLogToFile(total);
                      },
                    ),
                    SettingsTile(
                        onTap: () async {
                          await ss.prefs.remove("lastOpenedChat");
                          showSnackbar("Success", "Successfully cleared the last opened chat!");
                        },
                        leading: const SettingsLeadingIcon(
                          iosIcon: CupertinoIcons.rectangle_badge_xmark,
                          materialIcon: Icons.folder_delete_outlined,
                          containerColor: Colors.orange,
                        ),
                        title: "Clear Last Opened Chat",
                        subtitle: "Use this if you are experiencing the app opening an incorrect chat"
                    )
                  ]),
                if (!kIsWeb && backend.getRemoteService() != null)
                  SettingsHeader(
                      iosSubtitle: iosSubtitle,
                      materialSubtitle: materialSubtitle,
                      text: "Database Re-syncing"),
                if (!kIsWeb && backend.getRemoteService() != null)
                  SettingsSection(backgroundColor: tileColor, children: [
                    SettingsTile(
                        title: "Sync Handles & Contacts",
                        subtitle:
                            "Run this troubleshooter if you are experiencing issues with missing or incorrect contact names and photos",
                        onTap: () async {
                          resyncingHandles.value = true;
                          try {
                            final handleSyncer = HandleSyncManager();
                            await handleSyncer.start();
                            eventDispatcher.emit("refresh-all", null);

                            showSnackbar("Success",
                                "Successfully re-synced handles! You may need to close and re-open the app for changes to take effect.");
                          } catch (ex, stacktrace) {
                            Logger.error("Failed to reset contacts!", error: ex, trace: stacktrace);

                            showSnackbar("Failed to re-sync handles!",
                                "Error: ${ex.toString()}");
                          } finally {
                            resyncingHandles.value = false;
                          }
                        },
                        trailing: Obx(() => resyncingHandles.value == null
                            ? const SizedBox.shrink()
                            : resyncingHandles.value == true
                                ? Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 20,
                                      maxWidth: 20,
                                    ),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          context.theme.colorScheme.primary),
                                    ))
                                : Icon(Icons.check,
                                    color: context.theme.colorScheme.outline))),
                    const SettingsDivider(padding: EdgeInsets.only(left: 16.0)),
                    SettingsTile(
                        title: "Sync Chat Info",
                        subtitle: "This will re-sync all chat data & icons from the server to ensure that you have the most up-to-date information.\n\nNote: This will overwrite any group chat icons that are not locked!",
                        onTap: () async {
                          resyncingChats.value = true;
                          try {
                            showSnackbar("Please Wait...", "This may take a few minutes.");

                            final chatSyncer = ChatSyncManager();
                            await chatSyncer.start();
                            eventDispatcher.emit("refresh-all", null);

                            showSnackbar("Success",
                                "Successfully synced your chat info! You may need to close and re-open the app for changes to take effect.");
                          } catch (ex, stacktrace) {
                            Logger.error("Failed to sync chat info!", error: ex, trace: stacktrace);
                            showSnackbar("Failed to sync chat info!",
                                "Error: ${ex.toString()}");
                          } finally {
                            resyncingChats.value = false;
                          }
                        },
                        trailing: Obx(() => resyncingChats.value == null
                            ? const SizedBox.shrink()
                            : resyncingChats.value == true
                                ? Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 20,
                                      maxWidth: 20,
                                    ),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          context.theme.colorScheme.primary),
                                    ))
                                : Icon(Icons.check,
                                    color: context.theme.colorScheme.outline)))
                  ]),
              if (usingRustPush)
                SettingsHeader(
                  iosSubtitle: iosSubtitle,
                  materialSubtitle: materialSubtitle,
                  text: "iMessage"
                ),
              if (usingRustPush)
                SettingsSection(
                  backgroundColor: tileColor,
                  children: [
                    SettingsTile(
                      title: "Clear identity cache",
                      subtitle: "Run this troubleshooter if you're having trouble sending messages.",
                      onTap: () async {
                        await api.invalidateIdCache(client: pushService.state!.client);
                        showSnackbar("Success", "Identity cache cleared! Try re-sending any messages.");
                      }),
                    SettingsTile(
                      title: "Clear peer caches",
                      subtitle: "Run this troubleshooter if you are told to do so.",
                      onTap: () async {
                        if (reregisteringIds.value ?? false) return;
                        try {
                          reregisteringIds.value = true;
                          await pushService.invalidatePeerCaches();
                          showSnackbar("Success", "Cleared peer caches");
                        } catch (e) {
                          showSnackbar("Failure", e.toString());
                          rethrow;
                        } finally {
                          reregisteringIds.value = false;
                        }
                      },
                      trailing: Obx(() => reregisteringIds.value == null
                          ? const SizedBox.shrink()
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
                    SettingsTile(
                      title: "Reregister",
                      subtitle: "Run this troubleshooter if you are told to do so.",
                      onTap: () async {
                        if (reregisteringIds.value ?? false) return;
                        try {
                          reregisteringIds.value = true;
                          await api.doReregister(state: pushService.state!.client);
                          showSnackbar("Success", "Registered");
                        } catch (e) {
                          showSnackbar("Failure", e.toString());
                          rethrow;
                        } finally {
                          reregisteringIds.value = false;
                        }
                      },
                      trailing: Obx(() => reregisteringIds.value == null
                          ? const SizedBox.shrink()
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
                    SettingsTile(
                      title: "Clear FaceTime Handles",
                      subtitle: "Run this troubleshooter if you cannot use FaceTime. This will delete all links asscoiated with your account.",
                      onTap: () async {
                        if (reregisteringIds.value ?? false) return;
                        try {
                          reregisteringIds.value = true;
                          await api.clearLinks(facetime: pushService.state!.ftClient);
                          showSnackbar("Success", "Cleared Links!");
                        } catch (e) {
                          showSnackbar("Failure", e.toString());
                          rethrow;
                        } finally {
                          reregisteringIds.value = false;
                        }
                      },
                      trailing: Obx(() => reregisteringIds.value == null
                          ? const SizedBox.shrink()
                          : reregisteringIds.value == true ? Container(
                          constraints: const BoxConstraints(
                            maxHeight: 20,
                            maxWidth: 20,
                          ),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(context.theme.colorScheme.primary),
                          )) : Icon(Icons.check, color: context.theme.colorScheme.outline))
                      )
                  ]),
                if (usingRustPush && Platform.isAndroid)
                  Obx(() => ss.settings.developerEnabled.value
                      ? SettingsHeader(
                          iosSubtitle: iosSubtitle,
                          materialSubtitle: materialSubtitle,
                          text: "FaceTime Diagnostics",
                        )
                      : const SizedBox.shrink()),
                if (usingRustPush && Platform.isAndroid)
                  Obx(() => ss.settings.developerEnabled.value
                      ? SettingsSection(
                          backgroundColor: tileColor,
                          children: [
                            SettingsSwitch(
                              initialVal: ss.settings.faceTimeDiagnosticsEnabled.value,
                              onChanged: (bool val) async {
                                ss.settings.faceTimeDiagnosticsEnabled.value = val;
                                await ss.settings.saveOne('faceTimeDiagnosticsEnabled');
                              },
                              title: "Enable FaceTime diagnostics",
                              subtitle: "Logs FaceTime WebView, join, permission, and media state for debugging. Join recovery and End Call remain enabled when this is off.",
                              isThreeLine: true,
                              backgroundColor: tileColor,
                            ),
                          ],
                        )
                      : const SizedBox.shrink()),
                if(!kIsDesktop)
                SettingsHeader(
                  iosSubtitle: iosSubtitle,
                  materialSubtitle: materialSubtitle,
                  text: "Extensions"
                ),
                if(!kIsDesktop)
                SettingsSection(
                  backgroundColor: tileColor,
                  children: [
                    Obx(() => SettingsSwitch(
                      onChanged: (bool val) async {
                        if (val) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                  backgroundColor: context.theme.colorScheme.properSurface,
                                  title: Text("Enable development mode?", style: context.theme.textTheme.titleLarge),
                                  content: Text(
                                    'This mode is intended for developer use only. Extensions added through this mode have not been reviewed or approved by neither OpenBubbles or Google. You are responsible for ensuring the safety of your data and any extensions you add.',
                                    style: context.theme.textTheme.bodyLarge,
                                  ),
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
                                      child: Text("Enable",
                                          style: context.theme.textTheme.bodyLarge!
                                              .copyWith(color: context.theme.colorScheme.primary)),
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        ss.settings.developerEnabled.value = true;
                                        ss.settings.save();
                                      },
                                    ),
                                  ]);
                            },
                          );
                          return;
                        }
                        ss.settings.developerEnabled.value = val;
                        if (!val) {
                          ss.settings.faceTimeDiagnosticsEnabled.value = false;
                          await ss.settings.saveMany([
                            'developerEnabled',
                            'faceTimeDiagnosticsEnabled',
                          ]);
                        } else {
                          await ss.settings.saveOne('developerEnabled');
                        }
                        showSnackbar("Success", "Restart device or force quit OpenBubbles to unload extensions");
                      },
                      initialVal: ss.settings.developerEnabled.value,
                      title: "Enable Developer Mode",
                      backgroundColor: tileColor,
                    )),
                  ],
                ),
                if (kIsDesktop) const SizedBox(height: 100),
              ],
            ),
          ),
          if(!kIsDesktop)
          Obx(() => SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final addMember = ListTile(
                mouseCursor: MouseCursor.defer,
                title: Text("Add Service Name", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                leading: Container(
                  width: 40 * ss.settings.avatarScale.value,
                  height: 40 * ss.settings.avatarScale.value,
                  decoration: BoxDecoration(
                    color: !iOS ? null : context.theme.colorScheme.properSurface,
                    shape: BoxShape.circle,
                    border: iOS ? null : Border.all(color: context.theme.colorScheme.primary, width: 3)
                  ),
                  child: Icon(
                    Icons.add,
                    color: context.theme.colorScheme.primary,
                    size: 20
                  ),
                ),
                onTap: () {
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
                            child: Text("OK", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                            onPressed: () async {
                              ss.settings.developerMode.add(participantController.text);
                              ss.saveSettings();
                              await es.refreshCache();
                              Get.back();
                            },
                          ),
                        ],
                        content: TextField(
                          controller: participantController,
                          decoration: const InputDecoration(
                            labelText: "Service Name",
                            border: OutlineInputBorder(),
                          ),
                          autofillHints: [AutofillHints.telephoneNumber, AutofillHints.email],
                        ),
                        title: Text("Add", style: context.theme.textTheme.titleLarge),
                        backgroundColor: context.theme.colorScheme.properSurface,
                      );
                    }
                  );
                },
              );

              final refreshCache = ListTile(
                mouseCursor: MouseCursor.defer,
                title: Text("Reload extensions", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                leading: Container(
                  width: 40 * ss.settings.avatarScale.value,
                  height: 40 * ss.settings.avatarScale.value,
                  decoration: BoxDecoration(
                    color: !iOS ? null : context.theme.colorScheme.properSurface,
                    shape: BoxShape.circle,
                    border: iOS ? null : Border.all(color: context.theme.colorScheme.primary, width: 3)
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: context.theme.colorScheme.primary,
                    size: 20
                  ),
                ),
                onTap: () async {
                  await es.refreshCache();
                  showSnackbar("Success", "Extensions reloaded!");
                },
              );

              final clear = ListTile(
                mouseCursor: MouseCursor.defer,
                title: Text("Clear services", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.error)),
                leading: Container(
                  width: 40 * ss.settings.avatarScale.value,
                  height: 40 * ss.settings.avatarScale.value,
                  decoration: BoxDecoration(
                    color: !iOS ? null : context.theme.colorScheme.properSurface,
                    shape: BoxShape.circle,
                    border: iOS ? null : Border.all(color: context.theme.colorScheme.primary, width: 3)
                  ),
                  child: Icon(
                    Icons.clear_all,
                    color: context.theme.colorScheme.error,
                    size: 20
                  ),
                ),
                onTap: () async {
                  ss.settings.developerMode.clear();
                  ss.saveSettings();
                  showSnackbar("Success", "Restart device or force quit OpenBubbles to unload extensions");
                },
              );

              if (index == ss.settings.developerMode.length) {
                return addMember;
              }
              if (index == ss.settings.developerMode.length + 1) {
                return refreshCache;
              }
              if (index == ss.settings.developerMode.length + 2) {
                return clear;
              }

              return ListTile(
                mouseCursor: MouseCursor.defer,
                title: Text(ss.settings.developerMode[index]),
              );
            }, childCount: ss.settings.developerEnabled.value ? ss.settings.developerMode.length + 3 : 0),
          ),)
        ]);
  }
}
