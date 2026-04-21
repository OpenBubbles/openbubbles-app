import 'dart:convert';

import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/settings_widgets.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/utils/share.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:intl/intl.dart';
import 'package:path/path.dart' hide context;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:universal_io/io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:async/async.dart';

class BackupRestorePanel extends StatefulWidget {
  BackupRestorePanel({
    Key? key,
  });

  @override
  State<BackupRestorePanel> createState() => _BackupRestorePanelState();
}

class _BackupRestorePanelState extends OptimizedState<BackupRestorePanel> {
  List<Map<String, dynamic>> settings = [];
  List<Map<String, dynamic>> themes = [];
  bool? fetching = true;

  /// Reads all sticker files and returns them as a list of {filename, data} maps.
  Future<List<Map<String, String>>> _exportStickers() async {
    if (kIsWeb) return [];
    try {
      final stickerDir = Directory(await fs.stickersDirectory);
      if (!await stickerDir.exists()) return [];
      final stickers = <Map<String, String>>[];
      await for (final entity in stickerDir.list()) {
        if (entity is File) {
          final bytes = await entity.readAsBytes();
          stickers.add({
            'filename': basename(entity.path),
            'data': base64Encode(bytes),
          });
        }
      }
      return stickers;
    } catch (e) {
      Logger.warn('Failed to export stickers: $e');
      return [];
    }
  }

  /// Restores stickers from a backup map's "stickers" key.
  Future<void> _restoreStickers(Map<String, dynamic> map) async {
    if (kIsWeb) return;
    final stickersData = map['stickers'];
    if (stickersData == null || stickersData is! List) return;
    try {
      final stickerDir = await fs.stickersDirectory;
      for (final item in stickersData) {
        if (item is Map && item['filename'] != null && item['data'] != null) {
          final file = File(join(stickerDir, item['filename']));
          await file.writeAsBytes(base64Decode(item['data']));
        }
      }
      Logger.info('Restored ${stickersData.length} stickers from backup');
    } catch (e) {
      Logger.warn('Failed to restore stickers: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getBackups();
  }

  void getBackups() async {
    if (backend.getRemoteService() == null) {
      setState(() {
        fetching = false;
      });
      return;
    }
    final response1 = await http.getSettings().catchError((_) {
      setState(() {
        fetching = null;
      });
      return Response(requestOptions: RequestOptions(path: ''));
    });
    if (response1.statusCode == 200 && response1.data['data'] != null) {
      settings = response1.data['data'].cast<Map<String, dynamic>>();
      settings.sort((a, b) => DateTime.fromMillisecondsSinceEpoch(b['timestamp'] ?? 0).compareTo(DateTime.fromMillisecondsSinceEpoch(a['timestamp'] ?? 0)));
      final response2 = await http.getTheme().catchError((_) {
        setState(() {
          fetching = null;
        });
        return Response(requestOptions: RequestOptions(path: ''));
      });
      if (response2.statusCode == 200 && response2.data['data'] != null) {
        themes = response2.data['data'].cast<Map<String, dynamic>>();
        setState(() {
          fetching = false;
        });
      }
    }
  }

  void deleteSettings(String name) {
    setState(() {
      settings.removeWhere((element) => element["name"] == name);
    });
    http.deleteSettings(name);
  }

  void deleteTheme(String name) {
    setState(() {
      themes.removeWhere((element) => element["name"] == name);
    });
    http.deleteTheme(name);
  }

  Future<String> defaultName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return "Android (${androidInfo.model})";
    } else if (kIsWeb) {
      WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
      return "Web (${webInfo.browserName.name})";
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      return "Windows (${windowsInfo.computerName})";
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      return "Linux (${linuxInfo.name})";
    }

    return "Unknown Device";
  }

  Future<bool?> showMethodDialog() async {
    if (backend.getRemoteService() == null) {
      return false;
    }
    return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: context.theme.colorScheme.properSurface,
            title: Text(
              "Choose Backup Location",
              style: context.theme.textTheme.titleLarge,
            ),
            content: Text(
                "Local - Save a backup to this device.\nCloud - Save a backup to the server for use across all your devices.",
                style: context.theme.textTheme.bodyLarge
            ),
            actions: [
              TextButton(
                  child: Text(
                      "Local",
                      style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  }
              ),
              TextButton(
                  child: Text(
                      "Cloud",
                      style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  }
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => SettingsScaffold(
        title: "Backup and Restore",
        initialHeader: fetching == false ? "Settings Backups" : null,
        iosSubtitle: iosSubtitle,
        materialSubtitle: materialSubtitle,
        tileColor: tileColor,
        headerColor: headerColor,
        actions: [
          IconButton(
            icon: Icon(iOS ? CupertinoIcons.arrow_counterclockwise : Icons.refresh, color: context.theme.colorScheme.onBackground),
            onPressed: () {
              setState(() {
                fetching = true;
                settings.clear();
                themes.clear();
              });
              getBackups();
            },
          ),
        ],
        bodySlivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              if (fetching == null || fetching == true)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            fetching == null ? "Something went wrong!" : "Getting backups...",
                            style: context.theme.textTheme.labelLarge,
                          ),
                        ),
                        if (fetching == true)
                          buildProgressIndicator(context, size: 15),
                      ],
                    ),
                  ),
                ),
              if (fetching == false)
                SettingsSection(
                  backgroundColor: tileColor,
                  children: [
                    if (settings.isNotEmpty)
                      Material(
                        color: Colors.transparent,
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          findChildIndexCallback: (key) => findChildIndexByKey(settings, key, (item) => item["name"]),
                          itemBuilder: (context, index) {
                            final item = settings[index];
                            return ListTile(
                              key: ValueKey(item["name"]),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              mouseCursor: SystemMouseCursors.click,
                              title: RichText(
                                text: TextSpan(
                                  style: context.textTheme.titleMedium,
                                  children: [
                                    TextSpan(text: item["name"]),
                                    const TextSpan(text: "\n"),
                                    TextSpan(
                                      text: (item["timestamp"] is int) ? DateFormat("MMMM d, yyyy h:mm:ss a").format(DateTime.fromMillisecondsSinceEpoch(item["timestamp"])) : null,
                                      style: context.textTheme.titleSmall!.copyWith(color: context.theme.colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                              subtitle: !isNullOrEmpty(item["description"]) ? Text(item["description"]) : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                  children: [
                                IconButton(
                                    icon: Icon(iOS ? CupertinoIcons.arrow_2_circlepath : Icons.sync),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_context) => areYouSure(_context,
                                            title: "Overwrite Backup?",
                                            content: const Text("Are you sure you want to replace this backup with your current Settings?"),
                                            onNo: () => Navigator.of(_context).pop(),
                                            onYes: () async {
                                              Map<String, dynamic> json = ss.settings.toMap();
                                              json["stickers"] = await _exportStickers();
                                              json["description"] = item["description"];
                                              json["timestamp"] = DateTime.now().millisecondsSinceEpoch;
                                              Response response = await http.setSettings(item["name"], json);
                                              Navigator.of(_context).pop();
                                              if (response.statusCode != 200) {
                                                showSnackbar(
                                                  "Error",
                                                  "Somthing went wrong",
                                                );
                                              } else {
                                                showSnackbar(
                                                  "Success",
                                                  "Settings exported successfully to server",
                                                );
                                              }
                                              setState(() {
                                                fetching = true;
                                                settings.clear();
                                                themes.clear();
                                              });
                                              getBackups();
                                            },
                                        ),
                                      );
                                    }),
                                IconButton(
                                    icon: Icon(iOS ? CupertinoIcons.trash : Icons.delete_outlined),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => areYouSure(context,
                                            title: "Delete Backup?",
                                            content: const Text("Are you sure you want to delete this settings backup?"),
                                            onNo: () => Navigator.of(context).pop(),
                                            onYes: () {
                                              deleteSettings(item["name"]);
                                              Navigator.of(context).pop();
                                            }),
                                      );
                                    })
                              ]),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => areYouSure(context,
                                      title: "Restore Backup?",
                                      content: const Text("Are you sure you want to restore this backup, overwriting your current Settings?"),
                                      onNo: () => Navigator.of(context).pop(),
                                      onYes: () async {
                                        Navigator.of(context).pop();
                                        try {
                                          Settings.updateFromMap(item);
                                          await _restoreStickers(item);
                                          showSnackbar("Success", "Settings restored successfully");
                                        } catch (e, s) {
                                          Logger.error("Failed to restore settings backup!", error: e, trace: s);
                                          showSnackbar("Error", "Failed to restore settings backup! Error: ${e.toString()}");
                                        }
                                      }
                                  ),
                                );
                              },
                              onLongPress: () async {
                                const encoder = JsonEncoder.withIndent("     ");
                                final str = encoder.convert(item);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      "Settings Data",
                                      style: context.theme.textTheme.titleLarge,
                                    ),
                                    backgroundColor: context.theme.colorScheme.properSurface,
                                    content: SizedBox(
                                      width: ns.width(context) * 3 / 5,
                                      height: context.height * 1 / 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                            color: context.theme.colorScheme.background,
                                            borderRadius: const BorderRadius.all(Radius.circular(10))
                                        ),
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
                                        child: Text(
                                            "Close",
                                            style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
                                        ),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              isThreeLine: !isNullOrEmpty(item["description"]),
                            );
                          },
                          itemCount: settings.length,
                        ),
                      ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        mouseCursor: SystemMouseCursors.click,
                        title: Text("Create New", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                        leading: Container(
                          width: 40 * ss.settings.avatarScale.value,
                          height: 40 * ss.settings.avatarScale.value,
                          decoration: BoxDecoration(
                            color: !iOS ? null : context.theme.colorScheme.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: iOS ? null : Border.all(color: context.theme.colorScheme.primary, width: 3)
                          ),
                          child: Icon(
                            Icons.add,
                            color: context.theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        onTap: () async {
                          final method = await showMethodDialog();
                          if (method == null) return;
                          final deviceName = await defaultName();
                          final TextEditingController nameController = TextEditingController(text: deviceName);
                          final TextEditingController descController = TextEditingController();

                          void onDone(_context) async {
                            String name = nameController.text;
                            final desc = descController.text;
                            if (name.isEmpty) {
                              return showSnackbar("Error", "Provide a name!");
                            } else if (settings.firstWhereOrNull((s) => s["name"] == name) != null) {
                              bool yes = false;
                              await showDialog(context: _context, builder: (__context) =>
                                  areYouSure(__context,
                                      title: "Overwrite Backup?",
                                      content: const Text("Are you sure you want to replace this backup with your current Settings?"),
                                      onNo: () {
                                    Navigator.of(__context).pop();
                                    },
                                      onYes: () {
                                    Navigator.of(__context).pop();
                                    Navigator.of(_context).pop();
                                    yes = true;
                                    },
                                  ),
                              );
                              if (!yes) return;
                            } else {
                              Navigator.of(_context).pop();
                            }
                            Map<String, dynamic> json = ss.settings.toMap();
                            json["stickers"] = await _exportStickers();
                            if (desc.isNotEmpty) {
                              json["description"] = desc;
                            }
                            // these are per-registration keys
                            json.remove("smsForwardingTargets");
                            json.remove("isSmsRouter");

                            final timestamp = DateTime.now().millisecondsSinceEpoch;
                            json["timestamp"] = timestamp;
                            if (method) {
                              var response = await http.setSettings(name, json);
                              if (response.statusCode != 200) {
                                showSnackbar(
                                  "Error",
                                  "Somthing went wrong",
                                );
                              } else {
                                showSnackbar(
                                  "Success",
                                  "Settings exported successfully to server",
                                );
                              }
                            } else {
                              String directoryPath = "/storage/emulated/0/Download/BB-Settings-";
                              String filePath = "$directoryPath$name.json";
                              if (kIsWeb) {
                                final bytes = utf8.encode(jsonEncode(json));
                                final content = base64.encode(bytes);
                                html.AnchorElement(
                                    href: "data:application/octet-stream;charset=utf-16le;base64,$content")
                                  ..setAttribute("download", basename(filePath))
                                  ..click();
                                return;
                              }
                              if (kIsDesktop) {
                                String? _filePath = await FilePicker.platform.saveFile(
                                  initialDirectory: (await getDownloadsDirectory())?.path,
                                  dialogTitle: 'Choose a location to save this file',
                                  fileName: "BB-Settings-$name.json",
                                  type: FileType.custom,
                                  allowedExtensions: ["json"],
                                );
                                if (_filePath == null) {
                                  return showSnackbar('Failed', 'You didn\'t select a file path!');
                                }
                                filePath = _filePath;
                              }
                              File file = File(filePath);
                              await file.create(recursive: true);
                              String jsonString = jsonEncode(json);
                              await file.writeAsString(jsonString);
                              showSnackbar(
                                "Success",
                                "Settings exported successfully to ${kIsDesktop ? filePath : "downloads folder"}",
                                durationMs: kIsDesktop ? 4000 : 2000,
                                button: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Get.theme.colorScheme.secondary,
                                  ),
                                  onPressed: () {
                                    if (kIsDesktop) {
                                      launchUrl(Uri.file(dirname(filePath)));
                                    }
                                    Share.file("BlueBubbles Settings", filePath);
                                  },
                                  child: Text(kIsDesktop ? "OPEN FOLDER": "SHARE", style: TextStyle(color: context.theme.colorScheme.onSecondary)),
                                ),
                              );
                            }
                            setState(() {
                              fetching = true;
                              settings.clear();
                              themes.clear();
                            });
                            getBackups();
                          }

                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(
                                  "Settings Backup Creation",
                                  style: context.theme.textTheme.titleLarge,
                                ),
                                backgroundColor: context.theme.colorScheme.properSurface,
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Focus(
                                      onKeyEvent: (node, event) {
                                        if (event is KeyDownEvent && !HardwareKeyboard.instance.isShiftPressed && event.logicalKey == LogicalKeyboardKey.tab) {
                                          node.nextFocus();
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: TextField(
                                        cursorColor: context.theme.colorScheme.primary,
                                        autocorrect: true,
                                        autofocus: true,
                                        controller: nameController,
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: context.theme.colorScheme.outline),
                                              borderRadius: BorderRadius.circular(20)),
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: context.theme.colorScheme.primary),
                                              borderRadius: BorderRadius.circular(20)),
                                          labelText: "Name",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Focus(
                                      onKeyEvent: (node, event) {
                                        if (event is KeyDownEvent && HardwareKeyboard.instance.isShiftPressed && event.logicalKey == LogicalKeyboardKey.tab) {
                                          node.previousFocus();
                                          node.previousFocus(); // This is intentional. Should probably figure out why it's needed
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: TextField(
                                        cursorColor: context.theme.colorScheme.primary,
                                        autocorrect: true,
                                        autofocus: false,
                                        controller: descController,
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (_) {
                                          onDone.call(context);
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: context.theme.colorScheme.outline),
                                              borderRadius: BorderRadius.circular(20)),
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: context.theme.colorScheme.primary),
                                              borderRadius: BorderRadius.circular(20)),
                                          labelText: "Description (Optional)",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    child: Text("Cancel", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text("OK", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                                    onPressed: () {
                                      onDone.call(context);
                                    },
                                  ),
                                ],
                              );
                            }
                          );
                        },
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        mouseCursor: SystemMouseCursors.click,
                        title: Text("Restore Local", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                        leading: Container(
                          width: 40 * ss.settings.avatarScale.value,
                          height: 40 * ss.settings.avatarScale.value,
                          decoration: BoxDecoration(
                              color: !iOS ? null : context.theme.colorScheme.primaryContainer.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: iOS ? null : Border.all(color: context.theme.colorScheme.primary, width: 3)
                          ),
                          child: Icon(
                            Icons.upload,
                            color: context.theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        onTap: () async {
                          final res = await FilePicker.platform.pickFiles(withData: true, type: FileType.custom, allowedExtensions: ["json"]);
                          if (res == null || res.files.isEmpty || res.files.first.bytes == null) return;
                          showDialog(
                            context: context,
                            builder: (context) => areYouSure(context,
                                title: "Restore Settings?",
                                content: const Text("Are you sure you want to restore this backup, overwriting your current Settings?"),
                                onNo: () => Navigator.of(context).pop(),
                                onYes: () async {
                                  Navigator.of(context).pop();
                                  try {
                                    String jsonString = const Utf8Decoder().convert(res.files.first.bytes!);
                                    Map<String, dynamic> json = jsonDecode(jsonString);
                                    Settings.updateFromMap(json);
                                    await _restoreStickers(json);
                                    showSnackbar("Success", "Settings restored successfully");
                                  } catch (e, s) {
                                    Logger.error("Failed to restore settings backup!", error: e, trace: s);
                                    showSnackbar("Error", "Failed to restore settings backup! Error: ${e.toString()}");
                                  }
                                }
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              if (fetching == false)
                SettingsHeader(
                  iosSubtitle: iosSubtitle,
                  materialSubtitle: materialSubtitle,
                  text: "Theme Backups",
                ),
              if (fetching == false)
                SettingsSection(
                  backgroundColor: tileColor,
                  children: [
                    if (themes.isNotEmpty)
                      Material(
                        color: Colors.transparent,
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          findChildIndexCallback: (key) => findChildIndexByKey(themes, key, (item) => item['name']),
                          itemBuilder: (context, index) {
                            final item = themes[index];
                            final data = item["data"];
                            return ListTile(
                              key: ValueKey(item["name"]),
                              mouseCursor: SystemMouseCursors.click,
                              title: Text(item["name"]),
                              subtitle: !item.containsKey('data')
                                  ? Text("Incompatible backup!", style: context.theme.textTheme.bodyMedium!.copyWith(color: context.theme.colorScheme.error))
                                  : Text("${Brightness.values[data["colorScheme"]["brightness"]].name.capitalizeFirst!} theme"),
                              leading: !item.containsKey('data') ? null : Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Container(
                                          height: 12,
                                          width: 12,
                                          decoration: BoxDecoration(
                                            color: Color(data["colorScheme"]["primary"]),
                                            borderRadius: const BorderRadius.all(Radius.circular(4)),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Container(
                                          height: 12,
                                          width: 12,
                                          decoration: BoxDecoration(
                                            color: Color(data["colorScheme"]["secondary"]),
                                            borderRadius: const BorderRadius.all(Radius.circular(4)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Container(
                                          height: 12,
                                          width: 12,
                                          decoration: BoxDecoration(
                                            color: Color(data["colorScheme"]["primaryContainer"]),
                                            borderRadius: const BorderRadius.all(Radius.circular(4)),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Container(
                                          height: 12,
                                          width: 12,
                                          decoration: BoxDecoration(
                                            color: Color(data["colorScheme"]["tertiary"]),
                                            borderRadius: const BorderRadius.all(Radius.circular(4)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(iOS ? CupertinoIcons.trash : Icons.delete_outlined),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => areYouSure(context,
                                        title: "Delete Backup?",
                                        content: const Text("Are you sure you want to delete this theme backup?"),
                                        onNo: () => Navigator.of(context).pop(),
                                        onYes: () {
                                          deleteTheme(item["name"]);
                                          Navigator.of(context).pop();
                                        }
                                    ),
                                  );
                                },
                              ),
                              onTap: () async {
                                if (!item.containsKey('data')) {
                                  return showSnackbar("Error", "This theme was created on the old theming engine and cannot be restored");
                                }
                                showDialog(
                                    context: context,
                                    builder: (context) => areYouSure(context,
                                        title: "Restore Backup?",
                                        content: const Text("Are you sure you want to restore this backup, overwriting your current theme?"),
                                        onNo: () => Navigator.of(context).pop(),
                                        onYes: () {
                                          Navigator.of(context).pop();
                                          try {
                                            ThemeStruct object = ThemeStruct.fromMap(item);
                                            object.id = null;
                                            object.save();
                                            showSnackbar("Success", "Theme restored successfully");
                                          } catch (e, s) {
                                            Logger.error("Failed to restore theme backup!", error: e, trace: s);
                                            showSnackbar("Error", "Failed to restore theme backup! Error: ${e.toString()}");
                                          }
                                        }
                                    ),
                                );
                              },
                              onLongPress: () async {
                                const encoder = JsonEncoder.withIndent("     ");
                                final str = encoder.convert(item);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      "Theme Data",
                                      style: context.theme.textTheme.titleLarge,
                                    ),
                                    backgroundColor: context.theme.colorScheme.properSurface,
                                    content: SizedBox(
                                      width: ns.width(context) * 3 / 5,
                                      height: context.height * 1 / 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                            color: context.theme.colorScheme.background,
                                            borderRadius: const BorderRadius.all(Radius.circular(10))
                                        ),
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
                                        child: Text(
                                            "Close",
                                            style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
                                        ),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          itemCount: themes.length,
                        ),
                      ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        mouseCursor: SystemMouseCursors.click,
                        title: Text("Create New", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                        leading: Container(
                          width: 40 * ss.settings.avatarScale.value,
                          height: 40 * ss.settings.avatarScale.value,
                          decoration: BoxDecoration(
                            color: !iOS ? null : context.theme.colorScheme.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: iOS ? null : Border.all(color: context.theme.colorScheme.primary, width: 3)
                          ),
                          child: Icon(
                            Icons.add,
                            color: context.theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        onTap: () async {
                          final method = await showMethodDialog();
                          if (method == null) return;
                          List<ThemeStruct> allThemes = ThemeStruct.getThemes().where((element) => !element.isPreset).toList();
                          if (allThemes.isEmpty) {
                            return showSnackbar(
                              "Notice",
                              "No custom themes found!",
                            );
                          }
                          if (method) {
                            bool errored = false;
                            for (ThemeStruct e in allThemes) {
                              var response = await http.setTheme(e.name.characters.take(50).string, e.toMap());
                              if (response.statusCode != 200) {
                                errored = true;
                              }
                            }
                            if (errored) {
                              showSnackbar(
                                "Error",
                                "Somthing went wrong",
                              );
                            } else {
                              showSnackbar(
                                "Success",
                                "Themes exported successfully to server",
                              );
                            }
                          } else {
                            final List<Map<String, dynamic>> themeData = [];
                            for (ThemeStruct e in allThemes) {
                              themeData.add(e.toMap());
                            }
                            String jsonStr = jsonEncode(themeData);
                            String directoryPath = "/storage/emulated/0/Download/BlueBubbles-theming-";
                            DateTime now = DateTime.now().toLocal();
                            String filePath = "$directoryPath${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.json";
                            if (kIsWeb) {
                              final bytes = utf8.encode(jsonStr);
                              final content = base64.encode(bytes);
                              html.AnchorElement(
                                  href: "data:application/octet-stream;charset=utf-16le;base64,$content")
                                ..setAttribute("download", basename(filePath))
                                ..click();
                              return;
                            }
                            if (kIsDesktop) {
                              String? _filePath = await FilePicker.platform.saveFile(
                                initialDirectory: (await getDownloadsDirectory())?.path,
                                dialogTitle: 'Choose a location to save this file',
                                fileName: "BlueBubbles-theming-${now.year}${now.month}${now.day}_${now
                                    .hour}${now.minute}${now.second}.json",
                                type: FileType.custom,
                                allowedExtensions: ["json"],
                              );
                              if (_filePath == null) {
                                return showSnackbar('Failed', 'You didn\'t select a file path!');
                              }
                              filePath = _filePath;
                            }
                            File file = File(filePath);
                            await file.create(recursive: true);
                            await file.writeAsString(jsonStr);
                            showSnackbar(
                              "Success",
                              "Theming exported successfully to ${kIsDesktop ? filePath : "downloads folder"}",
                              durationMs: kIsDesktop ? 4000 : 2000,
                              button: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Get.theme.colorScheme.secondary,
                                ),
                                onPressed: () {
                                  if (kIsDesktop) {
                                    launchUrl(Uri.file(dirname(filePath)));
                                    return;
                                  }
                                  Share.file("BlueBubbles Theming", filePath);
                                },
                                child: Text(kIsDesktop ? "OPEN FOLDER" : "SHARE", style: TextStyle(color: context.theme.colorScheme.onSecondary)),
                              ),
                            );
                          }
                          setState(() {
                            fetching = true;
                            settings.clear();
                            themes.clear();
                          });
                          getBackups();
                        },
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        mouseCursor: SystemMouseCursors.click,
                        title: Text("Restore Local", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                        leading: Container(
                          width: 40 * ss.settings.avatarScale.value,
                          height: 40 * ss.settings.avatarScale.value,
                          decoration: BoxDecoration(
                              color: !iOS ? null : context.theme.colorScheme.primaryContainer.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: iOS ? null : Border.all(color: context.theme.colorScheme.primary, width: 3)
                          ),
                          child: Icon(
                            Icons.upload,
                            color: context.theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        onTap: () async {
                          final res = await FilePicker.platform
                              .pickFiles(withData: true, type: FileType.custom, allowedExtensions: ["json"]);
                          if (res == null || res.files.isEmpty || res.files.first.bytes == null) return;

                          showDialog(
                              context: context,
                              builder: (context) => areYouSure(context,
                                  title: "Restore Backup?",
                                  content: const Text("Are you sure you want to restore this backup, overwriting your current theme?"),
                                  onNo: () => Navigator.of(context).pop(),
                                  onYes: () {
                                    Navigator.of(context).pop();
                                    try {
                                      String jsonString = const Utf8Decoder().convert(res.files.first.bytes!);
                                      List<dynamic> json = jsonDecode(jsonString);
                                      for (var e in json) {
                                        ThemeStruct object = ThemeStruct.fromMap(e);
                                        if (object.isPreset) continue;
                                        object.id = null;
                                        object.save();
                                      }
                                      showSnackbar("Success", "Theming restored successfully");
                                    } catch (e, s) {
                                      Logger.error("Failed to restore theme backup!", error: e, trace: s);
                                      showSnackbar("Error", "Failed to restore theme backup! Error: ${e.toString()}");
                                    }
                                  }
                              ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              if (fetching == false)
                SettingsHeader(
                  iosSubtitle: iosSubtitle,
                  materialSubtitle: materialSubtitle,
                  text: "Messages Backups",
                ),
              if (fetching == false)
                SettingsSection(
                  backgroundColor: tileColor,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        mouseCursor: SystemMouseCursors.click,
                        title: Text("Create New", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                        subtitle: Text("Only attachments under 16mb saved", style: context.theme.textTheme.bodySmall),
                        leading: Container(
                          width: 40 * ss.settings.avatarScale.value,
                          height: 40 * ss.settings.avatarScale.value,
                          decoration: BoxDecoration(
                            color: !iOS ? null : context.theme.colorScheme.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: iOS ? null : Border.all(color: context.theme.colorScheme.primary, width: 3)
                          ),
                          child: Icon(
                            Icons.add,
                            color: context.theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        onTap: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: context.theme.colorScheme.properSurface,
                                title: Text(
                                  "Creating backup...",
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
                            });
                          try {
                            final List<Map<String, dynamic>> chatData = [];
                            for (var chat in chats.chats) {
                              chatData.add(chat.toMap());
                            }
                            final List<Map<String, dynamic>> msgData = [];
                            for (var message in Database.messages.getAll()) {
                              var map = message.toMap(includeObjects: true);
                              map["chat"] = message.chat.target?.guid;
                              msgData.add(map);
                            }
                            final List<String> attMap = [];
                            final List<Map<String, dynamic>> msgAtts = [];
                            for (var att in Database.attachments.getAll()) {
                              var map = att.toMap();
                              var file = File(att.path);
                              if (file.existsSync() && file.lengthSync() < 16777216 /* 16 mb */) {
                                map["bytes_id"] = attMap.length;
                                attMap.add(att.path);
                              }
                              msgAtts.add(map);
                            }
                            String jsonStr = jsonEncode({
                              "chats": chatData,
                              "messages": msgData,
                              "atts": msgAtts,
                            });
                            String directoryPath = "/storage/emulated/0/Download/BlueBubbles-chats-";
                            DateTime now = DateTime.now().toLocal();
                            String filePath = "$directoryPath${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.json";
                            if (kIsDesktop) {
                              String? _filePath = await FilePicker.platform.saveFile(
                                initialDirectory: (await getDownloadsDirectory())?.path,
                                dialogTitle: 'Choose a location to save this file',
                                fileName: "BlueBubbles-chats-${now.year}${now.month}${now.day}_${now
                                    .hour}${now.minute}${now.second}.json",
                                type: FileType.custom,
                                allowedExtensions: ["json"],
                              );
                              if (_filePath == null) {
                                return showSnackbar('Failed', 'You didn\'t select a file path!');
                              }
                              filePath = _filePath;
                            }

                            Uint8List int32BigEndianBytes(int value) =>
                                Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);

                            File file = File(filePath);
                            await file.create(recursive: true);
                            Uint8List jsonString = const Utf8Encoder().convert(jsonStr);
                            await file.writeAsBytes(int32BigEndianBytes(jsonString.length), mode: FileMode.append);
                            await file.writeAsBytes(jsonString, mode: FileMode.append);
                            for (var att in attMap) {
                              var attFile = File(att);
                              await file.writeAsBytes(int32BigEndianBytes(attFile.lengthSync()), mode: FileMode.append);
                              await file.writeAsBytes(await attFile.readAsBytes(), mode: FileMode.append);
                            }
                            Get.back(closeOverlays: true);
                            showSnackbar(
                              "Success",
                              "Message exported successfully to ${kIsDesktop ? filePath : "downloads folder"}",
                              durationMs: kIsDesktop ? 4000 : 2000,
                              button: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Get.theme.colorScheme.secondary,
                                ),
                                onPressed: () {
                                  if (kIsDesktop) {
                                    launchUrl(Uri.file(dirname(filePath)));
                                    return;
                                  }
                                  Share.file("BlueBubbles Chats", filePath);
                                },
                                child: Text(kIsDesktop ? "OPEN FOLDER" : "SHARE", style: TextStyle(color: context.theme.colorScheme.onSecondary)),
                              ),
                            );
                            
                            setState(() {
                              fetching = true;
                              settings.clear();
                              themes.clear();
                            });
                            getBackups();
                          } catch(e) {
                            Get.back(closeOverlays: true);
                            rethrow;
                          }
                        },
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        mouseCursor: SystemMouseCursors.click,
                        title: Text("Restore Local", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                        leading: Container(
                          width: 40 * ss.settings.avatarScale.value,
                          height: 40 * ss.settings.avatarScale.value,
                          decoration: BoxDecoration(
                              color: !iOS ? null : context.theme.colorScheme.primaryContainer.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: iOS ? null : Border.all(color: context.theme.colorScheme.primary, width: 3)
                          ),
                          child: Icon(
                            Icons.upload,
                            color: context.theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        onTap: () async {
                          final res = await FilePicker.platform
                              .pickFiles(type: FileType.custom, allowedExtensions: ["json"], withReadStream: true);
                          if (res == null || res.files.isEmpty) return;

                          showDialog(
                              context: context,
                              builder: (context) => areYouSure(context,
                                  title: "Restore Backup?",
                                  content: const Text("Are you sure you want to restore this backup? All existing messages will be replaced."),
                                  onNo: () => Navigator.of(context).pop(),
                                  onYes: () async {
                                    Navigator.of(context).pop();
                                    try {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: context.theme.colorScheme.properSurface,
                                            title: Text(
                                              "Restoring backup...",
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
                                        });
                                      try {
                                        chats.restoring = true;
                                        var file = res.files.first.readStream!;
                                        var chunked = ChunkedStreamReader(file);
                                        int listToInt(Uint8List list) {
                                          ByteData byteData = ByteData.sublistView(list);
                                          return byteData.getUint32(0, Endian.big);
                                        }
                                        int size = listToInt(await chunked.readBytes(4));
                                        String jsonString = const Utf8Decoder().convert(await chunked.readBytes(size));
                                        List<File> files = [];
                                        for (int i = 0; true; i++) {
                                          Uint8List sizeList = await chunked.readBytes(4);
                                          if (sizeList.isEmpty) break;
                                          int size = listToInt(sizeList);
                                          var data = await chunked.readBytes(size);
                                          File file = File(join((await getTemporaryDirectory()).path, "restorefile", i.toString()));
                                          await file.create(recursive: true);
                                          files.add(file);
                                          await file.writeAsBytes(data);
                                        }
                                        Map<dynamic, dynamic> json = jsonDecode(jsonString);
                                        Database.chats.removeAll();
                                        Database.handles.removeAll();
                                        Database.messages.removeAll();
                                        Database.attachments.removeAll();
                                        for (var usedChat in json["chats"]) {
                                          var chat = Chat.fromMap(usedChat);
                                          chat.id = null;
                                          chat.save();
                                          await chats.addChat(chat);
                                        }
                                        for (var usedMessage in json["messages"]) {
                                          var msg = Message.fromMap(usedMessage);
                                          msg.id = null;
                                          msg.save(chat: Chat.findOne(guid: usedMessage["chat"]));
                                        }
                                        for (var myAtt in json["atts"]) {
                                          var att = Attachment.fromMap(myAtt);
                                          att.id = null;
                                          if (myAtt.containsKey("bytes_id")) {
                                            var file = File(att.path);
                                            await file.create(recursive: true);
                                            files[myAtt["bytes_id"]].rename(att.path);
                                          }
                                          att.save(null);
                                        }
                                        Get.back(closeOverlays: true);
                                        showSnackbar("Success", "Chats restored successfully");
                                      } catch(e) {
                                        Get.back(closeOverlays: true);
                                        rethrow;
                                      }
                                    } catch (e, s) {
                                      Logger.error("Chat restore error", error: e, trace: s);
                                      showSnackbar("Error", "Something went wrong");
                                    } finally {
                                      chats.restoring = false;
                                    }
                                  }
                              ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ]),
          ),
        ]
    ));
  }
}
