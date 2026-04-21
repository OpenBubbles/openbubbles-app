import 'dart:typed_data';

import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' hide context;
import 'package:universal_io/io.dart';

class StickerPicker extends StatefulWidget {
  StickerPicker({
    super.key,
    required this.controller,
  });
  final ConversationViewController controller;

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends OptimizedState<StickerPicker> {
  List<File> _stickers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadStickers();
  }

  Future<void> loadStickers() async {
    try {
      final stickerDir = await fs.stickersDirectory;
      final dir = Directory(stickerDir);
      if (await dir.exists()) {
        final entities = dir.listSync();
        _stickers = entities
            .whereType<File>()
            .where((f) {
              final mimeType = mime(f.path);
              return mimeType != null && mimeType.startsWith('image/');
            })
            .toList();
        // Sort by most recently modified first
        _stickers.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      }
    } catch (e) {
      Logger.error('Failed to load stickers', error: e);
    }
    _loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 300,
        child: Center(child: buildProgressIndicator(context)),
      );
    }

    if (_stickers.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iOS ? CupertinoIcons.smiley : Icons.emoji_emotions_outlined,
                  size: 48,
                  color: context.theme.colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'No stickers saved yet',
                  style: context.theme.textTheme.bodyLarge?.copyWith(
                    color: context.theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Save images as stickers from the attachment viewer,\nor add image files to the stickers folder.',
                  textAlign: TextAlign.center,
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    color: context.theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: CustomScrollView(
          scrollDirection: Axis.horizontal,
          slivers: [
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: _stickers.length,
                (context, index) {
                  return _StickerPickerFile(
                    file: _stickers[index],
                    controller: widget.controller,
                    onTap: () async {
                      final file = _stickers[index];
                      final bytes = await file.readAsBytes();
                      final name = basename(file.path);

                      // Check if already selected — deselect
                      if (widget.controller.pickedAttachments.firstWhereOrNull(
                              (e) => e.path == file.path) !=
                          null) {
                        widget.controller.pickedAttachments
                            .removeWhere((e) => e.path == file.path);
                        // Clear sticker flag if no attachments remain
                        if (widget.controller.pickedAttachments.isEmpty) {
                          widget.controller.isStickerSend = false;
                        }
                      } else {
                        widget.controller.pickedAttachments.add(PlatformFile(
                          path: file.path,
                          name: name,
                          size: bytes.length,
                        ));
                        widget.controller.isStickerSend = true;
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerPickerFile extends StatefulWidget {
  _StickerPickerFile({
    required this.file,
    required this.controller,
    required this.onTap,
  });
  final File file;
  final ConversationViewController controller;
  final Function() onTap;

  @override
  State<_StickerPickerFile> createState() => _StickerPickerFileState();
}

class _StickerPickerFileState extends OptimizedState<_StickerPickerFile>
    with AutomaticKeepAliveClientMixin {
  Uint8List? image;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final path = widget.file.path;
      final mimeType = mime(path);
      if (mimeType == 'image/heic' ||
          mimeType == 'image/heif' ||
          mimeType == 'image/tif' ||
          mimeType == 'image/tiff') {
        final fakeAttachment = Attachment(
          transferName: path,
          mimeType: mimeType!,
        );
        image = await as.loadAndGetProperties(fakeAttachment,
            actualPath: path, onlyFetchData: true, isPreview: true);
      } else {
        image = await widget.file.readAsBytes();
      }
      setState(() {});
    } catch (e) {
      Logger.error('Failed to load sticker thumbnail', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      bool containsThis = widget.controller.pickedAttachments
              .firstWhereOrNull((e) => e.path == widget.file.path) !=
          null;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.all(containsThis ? 10 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (image != null)
                Image.memory(
                  image!,
                  fit: BoxFit.cover,
                  width: 150,
                  height: 150,
                  cacheWidth: 300,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame == null) {
                      return Positioned.fill(
                        child: Container(
                          color: context.theme.colorScheme.properSurface,
                        ),
                      );
                    } else {
                      return child;
                    }
                  },
                ),
              if (image == null)
                Positioned.fill(
                  child: Container(
                    color: context.theme.colorScheme.properSurface,
                    alignment: Alignment.center,
                    child: buildProgressIndicator(context),
                  ),
                ),
              if (containsThis)
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.colorScheme.primary),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Icon(
                      iOS ? CupertinoIcons.check_mark : Icons.check,
                      color: context.theme.colorScheme.onPrimary,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  @override
  bool get wantKeepAlive => true;
}
