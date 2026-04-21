import 'dart:async';
import 'dart:io';

import 'package:bluebubbles/app/layouts/settings/widgets/content/next_button.dart';
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

class SharedStreamsPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SharedStreamsPanelState();
}

class _SharedStreamsPanelState extends OptimizedState<SharedStreamsPanel> {

  List<api.SharedAlbum> pendingAlbums = [];
  List<api.SharedAlbum> myAlbums = [];
  List<String> albumItems = [];

  Map<String, api.SyncStatus> syncStatuses = {};

  Timer? refreshTimer;
  (String, BigInt)? failure;

  String syncStatusForAlbum(String album) {
    if (failure != null) return "Failed";
    var status = syncStatuses[album];
    if (status == null) return "Pending...";
    if (status is api.SyncStatus_Synced) {
      return "Synced";
    } else if (status is api.SyncStatus_Syncing) {
      return "Syncing...";
    } else if (status is api.SyncStatus_Downloading) {
      return "Downloading ${status.progress.toDouble().getFriendlySize()} of ${status.total.toDouble().getFriendlySize()}";
    } else if (status is api.SyncStatus_Uploading) {
      return "Uploading ${status.progress.toDouble().getFriendlySize()} of ${status.total.toDouble().getFriendlySize()}";
    }
    throw Exception("Bad status!");
  }
  

  void updateSyncState() async {
    var items = await api.getAlbums(lock: pushService.state!.icloudServices!.sharedstreams!, refresh: false);
    myAlbums = items.$1.where((album) => album.sharingtype == "subscribed" || album.sharingtype == "owned").toList();
    pendingAlbums = items.$1.where((album) => album.sharingtype == "pending").toList();
    albumItems = items.$2;
    var (status, error) = await api.getSyncstatus(lock: pushService.state!.icloudServices!.sharedstreams!);
    syncStatuses = status;
    failure = error;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) => updateSyncState());
    (() async {
      updateSyncState();
      await api.getAlbums(lock: pushService.state!.icloudServices!.sharedstreams!, refresh: true);
      updateSyncState();
    })();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Map<String, bool> loading = {};

  Future<void> _addPhotosToAlbum(api.SharedAlbum album) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      // Get the album's synced folder path
      final dir = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_PICTURES);
      final albumFolder = "$dir/${album.name}";
      await Directory(albumFolder).create(recursive: true);

      int copied = 0;
      for (final file in result.files) {
        if (file.path == null) continue;
        final source = File(file.path!);
        final dest = File("$albumFolder/${file.name}");
        if (!await dest.exists()) {
          await source.copy(dest.path);
          copied++;
        }
      }

      if (copied > 0) {
        showSnackbar('Uploading', 'Added $copied photo${copied > 1 ? 's' : ''} to ${album.name}. Syncing...');
        // Trigger sync to upload the new files
        await api.syncNow(lock: pushService.state!.icloudServices!.sharedstreams!);
        updateSyncState();
      } else {
        showSnackbar('Info', 'No new photos to add.');
      }
    } catch (e, stack) {
      Logger.error('Failed to add photos to shared album', error: e, trace: stack);
      showSnackbar('Error', 'Failed to add photos: ${e.toString()}');
    }
  }

  Widget wrapDelete(Widget child, Function(BuildContext) onPressed) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.30,
        children: [
          SlidableAction(
            label: 'Remove',
            backgroundColor: Colors.red,
            icon: ss.settings.skin.value == Skins.iOS ? CupertinoIcons.trash : Icons.delete_outlined,
            onPressed: (_) async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: context.theme.colorScheme.properSurface,
                    title: Text(
                      "Unsubscribing",
                      style: context.theme.textTheme.titleLarge,
                    ),
                    content: Container(
                      height: 70,
                      child: Center(child: buildProgressIndicator(context)),
                    ),
                  );
                }
              );
              await onPressed(context);
              Get.back();
            },
          ),
        ],
      ),
      child: child,
    );
  }

  String formatDuration(int secondsAbs, {bool useSecs = false}) {
    var seconds = secondsAbs.abs();
    var secs = seconds % 60;
    var minTotal = seconds ~/ 60;
    var mins = minTotal % 60;
    var hrTotal = minTotal ~/ 60;
    var hrs = hrTotal % 24;
    var days = hrTotal ~/ 24;
    String output = seconds.isNegative ? "-" : "";
    if (days > 0) output += "${days}d ";
    if (hrs > 0) output += "${hrs}h ";
    if (mins > 0) output += "${mins}m ";
    if ((secs > 0 && useSecs) || output.trim() == "") output += "${secs}s ";
    return output.trim();
  }

  void promptAllowAll() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: context.theme.colorScheme.properSurface,
            title: Text("Permission Denied.", style: context.theme.textTheme.titleLarge),
            content: Text(
              'Access to all photos is required to scan and sync new photos to your Gallery. Enable in App settings -> Permissions -> Photos and videos -> Always allow all',
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
                child: Text("Open Settings",
                    style: context.theme.textTheme.bodyLarge!
                        .copyWith(color: context.theme.colorScheme.primary)),
                onPressed: () async {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
            ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> invites = [];
    for (var (index, pending) in pendingAlbums.indexed) {
      var isLoading = loading[pending.albumguid] ?? false;
      invites.add(wrapDelete(SettingsTile(
        title: pending.name,
        subtitle: pending.fullname ?? pending.email,
        trailing: isLoading ? buildProgressIndicator(context, size: 18) : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Accept",
                style: context.theme.textTheme.bodyMedium!.apply(color: context.theme.colorScheme.outline.withOpacity(0.85)),
              ),
              const SizedBox(width: 5),
              const NextButton(),
            ]
          ),
        onTap: isLoading ? null : () async {
          try {
            loading[pending.albumguid] = true;
            setState(() { });
            try {
              await api.subscribe(lock: pushService.state!.icloudServices!.sharedstreams!, guid: pending.albumguid);
            } catch (e) {
              // sometimes first one can give 500, try again
              await api.subscribe(lock: pushService.state!.icloudServices!.sharedstreams!, guid: pending.albumguid);
            }
            await api.getAlbums(lock: pushService.state!.icloudServices!.sharedstreams!, refresh: true);
            updateSyncState();
          } catch (e, stack) {
            Logger.error("Failed to subscribe!!", error: e, trace: stack);
            showSnackbar("Error", "Failed to subscribe! Error: ${e.toString()}");
          } finally {
            loading[pending.albumguid] = false;
            setState(() { });
          }
        },
      ), (context) async {
        try {
          try {
            await api.unsubscribe(lock: pushService.state!.icloudServices!.sharedstreams!, guid: pending.albumguid);
          } catch (e) {
            await api.unsubscribe(lock: pushService.state!.icloudServices!.sharedstreams!, guid: pending.albumguid);
          }
          await api.getAlbums(lock: pushService.state!.icloudServices!.sharedstreams!, refresh: true);
          updateSyncState();
        } catch (e, stack) {
          Logger.error("Failed to remove!!", error: e, trace: stack);
          Get.back();
          showSnackbar("Error", "Failed to subscribe! Error: ${e.toString()}");
          rethrow;
        }
      }));
      if (index != pendingAlbums.length - 1) invites.add(const SettingsDivider(padding: EdgeInsets.only(left: 16.0)));
    }

    List<Widget> albums = [
      if (failure != null)
        SettingsTile(
          title: "Failure (retry in ${formatDuration(failure!.$2.toInt())})",
          subtitle: failure!.$1,
          trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Retry",
                  style: context.theme.textTheme.bodyMedium!.apply(color: context.theme.colorScheme.outline.withOpacity(0.85)),
                ),
                const SizedBox(width: 5),
                const NextButton(),
              ]
            ),
          onTap: () async {
            try {
              failure = null;
              setState(() {});
              await api.syncNow(lock: pushService.state!.icloudServices!.sharedstreams!);
            } finally {
              updateSyncState();
            }
          },
        )
    ];
    for (var (index, album) in myAlbums.indexed) {
      var syncing = albumItems.contains(album.albumguid);
      var item = SettingsSwitch(
        title: album.name ?? "",
        subtitle: syncing ? syncStatusForAlbum(album.albumguid) : "Not Syncing",
        initialVal: syncing,
        onChanged: (bool val) async {
          if (val) {
            String? path;
            if (kIsDesktop) {
              path = await FilePicker.platform.getDirectoryPath(dialogTitle: "Folder for ${album.name}");
            } else {
              final PermissionState ps = await PhotoManager.requestPermissionExtend();
              if (!ps.hasAccess) {
                promptAllowAll();
                return;
              }
              var dir = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_PICTURES);
              path = "$dir/${album.name}";
              await Directory(path).create();
              try {
                Directory(path).statSync();
              } catch (e, stack) {
                promptAllowAll();
                Logger.error("Failed to list", error: e, trace: stack);
                rethrow;
              }
            }
            if (path == null) return;
            print(path);
            await api.addAlbum(lock: pushService.state!.icloudServices!.sharedstreams!, guid: album.albumguid, folder: path);
            albumItems.add(album.albumguid);
            updateSyncState();
          } else {
            await api.removeAlbum(lock: pushService.state!.icloudServices!.sharedstreams!, guid: album.albumguid);
            albumItems.remove(album.albumguid);
            setState(() {});
          }

        },
      );
      albums.add(album.email == null ? item : wrapDelete(item, (context) async {
        try {
          try {
            await api.unsubscribe(lock: pushService.state!.icloudServices!.sharedstreams!, guid: album.albumguid);
          } catch (e) {
            await api.unsubscribe(lock: pushService.state!.icloudServices!.sharedstreams!, guid: album.albumguid);
          }
          await api.getAlbums(lock: pushService.state!.icloudServices!.sharedstreams!, refresh: true);
          updateSyncState();
        } catch (e, stack) {
          Logger.error("Failed to remove!!", error: e, trace: stack);
          Get.back();
          showSnackbar("Error", "Failed to subscribe! Error: ${e.toString()}");
          rethrow;
        }
      }));
      // Add Photos button for synced albums
      if (syncing && !kIsDesktop) {
        albums.add(SettingsTile(
          title: "Add Photos to ${album.name ?? 'Album'}",
          leading: Icon(
            iOS ? CupertinoIcons.photo_on_rectangle : Icons.add_photo_alternate_outlined,
            color: context.theme.colorScheme.primary,
          ),
          onTap: () => _addPhotosToAlbum(album),
        ));
      }
      if (index != myAlbums.length - 1) albums.add(const SettingsDivider(padding: EdgeInsets.only(left: 16.0)));
    }

    return SettingsScaffold(
        title: kIsDesktop ? "Shared Albums (FFmpeg required for uploads)" : "Shared Albums",
        initialHeader: pendingAlbums.isEmpty ? "Shared Albums" : "Invites",
        iosSubtitle: iosSubtitle,
        materialSubtitle: materialSubtitle,
        tileColor: tileColor,
        headerColor: headerColor,
        bodySlivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                if (pendingAlbums.isNotEmpty)
                SettingsSection(
                  backgroundColor: tileColor,
                  children: invites
                ),
                if (pendingAlbums.isNotEmpty)
                SettingsHeader(
                    iosSubtitle: iosSubtitle,
                    materialSubtitle: materialSubtitle,
                    text: "Shared Albums"),
                SettingsSection(
                  backgroundColor: tileColor,
                  children: albums,
                ),
                if (invites.isEmpty && albums.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  child: Text("No Albums! Apple users can invite you to a shared photo album and they'll show up here, where you can sync them to your gallery.", style: context.textTheme.bodyMedium!,),
                ),
                if (Platform.isAndroid && !(invites.isEmpty && albums.isEmpty))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  child: Text("Allow all photos if prompted; limited access will cause problems. Shared Albums are synced to a folder in your Photos folder, which will appear as an album in your photo manager. Photos added on this device and removed on other devices will not be removed due to Android's permission model.", style: context.textTheme.bodySmall!.copyWith(color: context.theme.colorScheme.properOnSurface.withOpacity(0.75), height: 1.5),),
                ),
                if (Platform.isAndroid)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                            backgroundColor: context.theme.colorScheme.properSurface,
                            title: Text("Got an email?", style: context.theme.textTheme.titleLarge),
                            content: Text(
                              'Register OpenBubbles for iCloud links in App settings, then simply tap the subscribe button in your email.\n\nSettings -> Open by default -> Add link -> select www.iCloud.com -> Add',
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
                                child: Text("Open Settings",
                                    style: context.theme.textTheme.bodyLarge!
                                        .copyWith(color: context.theme.colorScheme.primary)),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  openAppSettings();
                                },
                              ),
                            ]);
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0 , horizontal: 30),
                    child: Text("Got an email?", style: context.textTheme.bodySmall!.copyWith(color: context.theme.colorScheme.properOnSurface.withOpacity(0.75), height: 1.5),),
                  )
                )
              ],
            ),
          ),
        ]);
  }

  void saveSettings() {
    ss.saveSettings();
  }
}
