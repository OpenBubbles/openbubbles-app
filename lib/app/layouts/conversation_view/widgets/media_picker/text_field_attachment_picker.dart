import 'dart:async';
import 'dart:convert';

import 'package:bluebubbles/app/layouts/conversation_details/dialogs/timeframe_picker.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/interactive/polls.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/database/global/payload_data.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/utils/share.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/media_picker/attachment_picker_file.dart';
import 'package:bluebubbles/app/wrappers/theme_switcher.dart';
import 'package:bluebubbles/database/global/platform_file.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:chunked_stream/chunked_stream.dart';
import 'package:file_picker/file_picker.dart' hide PlatformFile;
import 'package:file_picker/file_picker.dart' as pf;
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hand_signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:collection/collection.dart';
import 'package:bluebubbles/helpers/types/constants.dart' as constants;
import 'package:bluebubbles/app/layouts/conversation_view/widgets/media_picker/sticker_picker.dart';

class AttachmentPicker extends StatefulWidget {
  AttachmentPicker({
    super.key,
    required this.controller,
  });
  final ConversationViewController controller;

  @override
  State<AttachmentPicker> createState() => AttachmentPickerState();
}

class AttachmentPickerState extends OptimizedState<AttachmentPicker> {
  List<AssetEntity> _images = <AssetEntity>[];

  ConversationViewController get controller => widget.controller;

  List<Map<String, dynamic>> iconsList = [];

  App? currentApp;
  bool showStickerPicker = false;

  void generateIcons() {
    iconsList = [
      {
        "icon": Icons.how_to_vote,
        "text": "Polls",
        "handle": () async {
          List<TextEditingController> participantController = [TextEditingController(), TextEditingController()];
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
                      var handle = RustPushBBUtils.rustHandleToBB(await controller.chat.ensureHandle());
                      var items = participantController.map((i) => i.text).toList();
                      if (items.last == "") {
                        items.removeLast();
                      }
                      if (items.length < 2) return;
                      controller.pickedApp.value = (null, PayloadData(
                        type: constants.PayloadType.app,
                        appData: [
                          iMessageAppData(
                            appName: "Polls",
                            url: "data:,${base64Encode(utf8.encode(pollMessageToJson(PollMessage(
                              version: 1,
                              item: Item(
                                orderedPollOptions: items.map((i) => OrderedPollOption(
                                  attributedText: i,
                                  canBeEdited: false,
                                  creatorHandle: handle.address,
                                  optionIdentifier: uuid.v4().toUpperCase(),
                                  text: i,
                                )).toList(),
                                creatorHandle: handle.address,
                                title: "",
                              ),
                            ))))}?src=p&c=2",
                            session: uuid.v4().toUpperCase(),
                            ldText: items.map((i) => i).join(", "),
                            userInfo: UserInfo(
                              imageSubtitle: "",
                              imageTitle: "",
                              caption: "ENG: Update your device",
                              secondarySubcaption: "",
                              tertiarySubcaption: "",
                              subcaption: "Learn about how to update your device to see this content.",
                            ),
                            isLive: true,
                            appIcon: base64Encode((await rootBundle.load("assets/images/polls.jpg")).buffer.asUint8List()),
                          )
                        ]
                      ));
                      Get.back();
                    },
                  ),
                ],
                content: SingleChildScrollView(
                  child: StatefulBuilder(builder: (context, state) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: participantController.mapIndexed((i, c) => [
                      if (i == 0)
                      const Text("Requires iOS 26 or above."),
                      const SizedBox(height: 10),
                      TextField(
                        controller: c,
                        decoration: InputDecoration(
                          labelText: "Option ${i + 1}",
                          border: const OutlineInputBorder(),
                        ),
                        autofocus: true,
                        onChanged: (v) {
                          if (participantController[participantController.length - 1].text != "") {
                            participantController.add(TextEditingController());
                            state(() {});
                          }
                          if (participantController.length > 2 && participantController[participantController.length - 2].text == "") {
                            participantController.removeLast();
                            state(() {});
                          }
                        },
                      )
                    ]).flattened.toList(),
                  )),
                ),
                title: Text("New Poll", style: context.theme.textTheme.titleLarge),
                backgroundColor: context.theme.colorScheme.properSurface,
              );
            }
          );
        }
      },
      {
        "icon": iOS ? CupertinoIcons.folder_open : Icons.folder_open_outlined,
        "text": "Files",
        "handle": () async {
          final res = await FilePicker.platform.pickFiles(withReadStream: true, allowMultiple: true);
          if (res == null || res.files.isEmpty) return;

          for (pf.PlatformFile file in res.files) {
            if (file.size / 1024000 > 1000) {
              showSnackbar("Error", "This file is over 1 GB! Please compress it before sending.");
              continue;
            }
            controller.pickedAttachments.add(PlatformFile(
                path: file.path,
                name: file.name,
                bytes: await readByteStream(file.readStream!),
                size: file.size
            ));
          }
        }
      },
      {
        "icon": iOS ? CupertinoIcons.location : Icons.location_on_outlined,
        "text": "Location",
        "handle": () async {
          await Share.location(cm.activeChat!.chat);
        }
      },
      if(controller.chat.isIMessage)
      {
        "icon": iOS ? CupertinoIcons.clock_solid : Icons.lock_clock,
        "text": "Send Later",
        "handle": () async {
          final date = await showTimeframePicker("Pick date and time", context, presetsAhead: true);
          if (date != null && date.isAfter(DateTime.now())) {
            controller.scheduledDate.value = date;
          }
        }
      },
      {
        "icon": iOS ? CupertinoIcons.pencil_outline : Icons.draw,
        "text": "Handwritten",
        "handle": () async {
          Color selectedColor = context.theme.colorScheme.bubble(context, controller.chat.isIMessage);
          final result = (await ColorPicker(
            color: selectedColor,
            onColorChanged: (Color newColor) {
              selectedColor = newColor;
            },
            title: Text(
              "Select Color",
              style: context.theme.textTheme.titleLarge,
            ),
            width: 40,
            height: 40,
            spacing: 0,
            runSpacing: 0,
            borderRadius: 0,
            wheelDiameter: 165,
            enableOpacity: false,
            showColorCode: true,
            colorCodeHasColor: true,
            pickersEnabled: <ColorPickerType, bool>{
              ColorPickerType.wheel: true,
            },
            copyPasteBehavior: const ColorPickerCopyPasteBehavior(
              parseShortHexCode: true,
            ),
            actionButtons: const ColorPickerActionButtons(
              dialogActionButtons: true,
            ),
          ).showPickerDialog(
            context,
            barrierDismissible: false,
            constraints: BoxConstraints(
                minHeight: 480, minWidth: ns.width(context) - 70, maxWidth: ns.width(context) - 70),
          ));
          if (result) {
            final control = HandSignatureControl();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(
                    "Draw Handwritten Message",
                    style: context.theme.textTheme.titleLarge,
                  ),
                  content: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      constraints: const BoxConstraints.expand(),
                      child: HandSignature(
                        control: control,
                        color: selectedColor,
                        width: 1.0,
                        maxWidth: 10.0,
                        type: SignatureDrawType.shape,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text("Cancel", style: context.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text("OK", style: context.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final bytes = await control.toImage(height: 512, fit: false);
                        if (bytes != null) {
                          final uint8 = bytes.buffer.asUint8List();
                          controller.pickedAttachments.add(PlatformFile(
                            path: null,
                            name: "handwritten-${randomString(3)}.png",
                            bytes: uint8,
                            size: uint8.lengthInBytes,
                          ));
                        }
                      },
                    ),
                  ],
                  backgroundColor: context.theme.colorScheme.properSurface,
                );
              },
            );
          }
        }
      },
      {
        "icon": iOS ? CupertinoIcons.smiley : Icons.emoji_emotions_outlined,
        "text": "Stickers",
        "handle": () {
          setState(() {
            showStickerPicker = true;
          });
        }
      },
    ];

    if(!controller.chat.isIMessage) return;
    for (var app in es.cachedStatus) {
      if (app.available == null) return;
      iconsList.insert(0, {
        "logo": base64Decode(app.available!.icon),
        "text": app.available!.name,
        "handle": () {
          setState(() {
            currentApp = app;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getAttachments();
    generateIcons();
  }

  Future<void> getAttachments() async {
    if (kIsDesktop || kIsWeb) return;
    // wait for opening animation to complete
    await Future.delayed(const Duration(milliseconds: 250));
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      showSnackbar("Error", "Storage permission not granted!");
      return;
    }
    List<AssetPathEntity> list = await PhotoManager.getAssetPathList(onlyAll: true);
    if (list.isNotEmpty) {
      _images = await list.first.getAssetListRange(start: 0, end: 24);
      // see if there is a recent attachment
      if (DateTime.now().toLocal().isWithin(_images.first.modifiedDateTime, minutes: 2)) {
        final file = await _images.first.file;
        if (file != null) {
          eventDispatcher.emit('add-custom-smartreply', PlatformFile(
            path: file.path,
            name: file.path.split('/').last,
            size: await file.length(),
            bytes: await file.readAsBytes(),
          ));
        }
      }
    }
    setState(() {});
  }

  Future<void> openFullCamera({String type = 'camera'}) async {
    bool granted = (await Permission.camera.request()).isGranted;
    if (!granted) {
      showSnackbar(
        "Error",
        "Camera access was denied!"
      );
      return;
    }

    late final XFile? file;
    if (type == 'camera') {
      file = await ImagePicker().pickImage(source: ImageSource.camera);
    } else {
      file = await ImagePicker().pickVideo(source: ImageSource.camera);
    }
    if (file != null) {
      controller.pickedAttachments.add(PlatformFile(
        path: file.path,
        name: file.path.split('/').last,
        size: await file.length(),
        bytes: await file.readAsBytes(),
      ));
    }
  }

  IconData getIcon(int index) {
    if (iOS) {
      switch (index) {
        case 0:
          return CupertinoIcons.camera;
        case 1:
          return CupertinoIcons.videocam;
      }
    } else {
      switch (index) {
        case 0:
          return Icons.photo_camera_outlined;
        case 1:
          return Icons.videocam_outlined;
      }
    }
    return Icons.abc;
  }

  String getText(int index) {
    switch (index) {
      case 0:
        return "Photo";
      case 1:
        return "Video";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    if (showStickerPicker) {
      return Stack(
        children: [
          StickerPicker(controller: controller),
          Positioned(
            top: 5,
            left: 5,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  showStickerPicker = false;
                  // Clear sticker state so regular photos don't send as stickers
                  controller.isStickerSend = false;
                  controller.pickedAttachments.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.properSurface.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iOS ? CupertinoIcons.back : Icons.arrow_back,
                  size: 20,
                  color: context.theme.colorScheme.properOnSurface,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (currentApp != null) {
      return SizedBox(
        height: 300,
        child: AndroidView(
          viewType: "extension-keyboard",
          layoutDirection: TextDirection.ltr,
          creationParams: {
            "app-id": currentApp!.appId,
            "user-count": controller.chat.participants.length + 1,
          },
          creationParamsCodec: const StandardMessageCodec(),
        )
      );
    }
    return SizedBox(
      height: 300,
      child: RefreshIndicator(
        onRefresh: () async {
          getAttachments();
        },
        child: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (OverscrollIndicatorNotification overscroll) {
            // prevent stretchy effect
            overscroll.disallowIndicator();
            return true;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 300,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: CustomScrollView(
                  physics: ThemeSwitcher.getScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  slivers: <Widget>[
                    SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: context.theme.colorScheme.properSurface,
                            ),
                            onPressed: () async {
                              switch (index) {
                                case 0:
                                  openFullCamera();
                                  return;
                                case 1:
                                  openFullCamera(type: "video");
                                  return;
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  getIcon(index),
                                  color: context.theme.colorScheme.properOnSurface,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  getText(index),
                                  style: context.theme.textTheme.labelLarge!.copyWith(color: context.theme.colorScheme.properOnSurface)
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: 2,
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(left: 5, right: 5)),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        width: 100,
                        child: CustomScrollView(
                        physics: ThemeSwitcher.getScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.only(top: 10, bottom: 7),
                                  backgroundColor: context.theme.colorScheme.properSurface,
                                ),
                                onPressed: () async {
                                  iconsList[index]["handle"]();
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    if (iconsList[index].containsKey("icon"))
                                    Icon(
                                      iconsList[index]["icon"],
                                      color: context.theme.colorScheme.properOnSurface,
                                    ),
                                    if (iconsList[index].containsKey("logo"))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: ClipRRect(
                                        child: Image.memory(
                                          iconsList[index]["logo"],
                                          height: 25,
                                        ),
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      child: Text(
                                        iconsList[index]["text"],
                                        style: context.theme.textTheme.labelLarge!.copyWith(color: context.theme.colorScheme.properOnSurface),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              );
                            },
                            childCount: iconsList.length,
                            ),
                          ),
                        ],
                      ),
                      )
                    ),
                    const SliverPadding(padding: EdgeInsets.only(left: 5, right: 5)),
                    SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                          final element = _images[index];
                          return AttachmentPickerFile(
                            key: Key("AttachmentPickerFile-${element.id}"),
                            data: element,
                            controller: controller,
                            onTap: () async {
                              final file = await element.file;
                              if (file == null) return;
                              if ((await file.length()) / 1024000 > 1000) {
                                showSnackbar("Error", "This file is over 1 GB! Please compress it before sending.");
                                return;
                              }
                              if (controller.pickedAttachments.firstWhereOrNull((e) => e.path == file.path) != null) {
                                controller.pickedAttachments.removeWhere((e) => e.path == file.path);
                              } else {
                                controller.pickedAttachments.add(PlatformFile(
                                  path: file.path,
                                  name: file.path.split('/').last,
                                  size: await file.length(),
                                ));
                              }
                            },
                          );
                        },
                        childCount: _images.length,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ),
        ),
      ),
    );
  }
}
