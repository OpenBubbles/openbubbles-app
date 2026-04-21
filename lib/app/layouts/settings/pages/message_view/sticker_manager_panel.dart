import 'dart:typed_data';

import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' hide context;
import 'package:universal_io/io.dart';

class StickerManagerPanel extends StatefulWidget {
  @override
  State<StickerManagerPanel> createState() => _StickerManagerPanelState();
}

class _StickerManagerPanelState extends OptimizedState<StickerManagerPanel> {
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
        _stickers.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      }
    } catch (e) {
      Logger.error('Failed to load stickers', error: e);
    }
    _loading = false;
    setState(() {});
  }

  Future<void> addStickers() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    try {
      final stickerDir = await fs.stickersDirectory;
      for (final file in result.files) {
        if (file.path != null) {
          final dest = join(stickerDir, file.name);
          await File(file.path!).copy(dest);
        }
      }
      showSnackbar('Success', 'Added ${result.files.length} sticker${result.files.length > 1 ? 's' : ''}!');
      await loadStickers();
    } catch (e) {
      Logger.error('Failed to add stickers', error: e);
      showSnackbar('Error', 'Failed to add stickers.');
    }
  }

  Future<void> deleteSticker(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Sticker', style: context.theme.textTheme.titleLarge),
        content: Text('Are you sure you want to delete this sticker?'),
        backgroundColor: context.theme.colorScheme.properSurface,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: context.theme.textTheme.bodyLarge!.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await file.delete();
        showSnackbar('Deleted', 'Sticker removed.');
        await loadStickers();
      } catch (e) {
        Logger.error('Failed to delete sticker', error: e);
        showSnackbar('Error', 'Failed to delete sticker.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.colorScheme.background,
      appBar: AppBar(
        title: Text('Manage Stickers', style: context.theme.textTheme.titleLarge),
        centerTitle: ss.settings.skin.value == Skins.iOS,
        backgroundColor: context.theme.colorScheme.background,
        leading: buildBackButton(context),
        actions: [
          IconButton(
            icon: Icon(iOS ? CupertinoIcons.add : Icons.add),
            onPressed: addStickers,
            tooltip: 'Add Stickers',
          ),
        ],
      ),
      body: _loading
          ? Center(child: buildProgressIndicator(context))
          : _stickers.isEmpty
              ? Center(
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
                          'No stickers yet',
                          style: context.theme.textTheme.bodyLarge?.copyWith(
                            color: context.theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add images as stickers,\nor save them from the attachment viewer.',
                          textAlign: TextAlign.center,
                          style: context.theme.textTheme.bodySmall?.copyWith(
                            color: context.theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _stickers.length,
                    itemBuilder: (context, index) {
                      return _StickerManagerTile(
                        key: ValueKey(_stickers[index].path),
                        file: _stickers[index],
                        onDelete: () => deleteSticker(_stickers[index]),
                      );
                    },
                  ),
                ),
    );
  }
}

class _StickerManagerTile extends StatefulWidget {
  const _StickerManagerTile({
    super.key,
    required this.file,
    required this.onDelete,
  });

  final File file;
  final VoidCallback onDelete;

  @override
  State<_StickerManagerTile> createState() => _StickerManagerTileState();
}

class _StickerManagerTileState extends OptimizedState<_StickerManagerTile> {
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Image.memory(
              image!,
              fit: BoxFit.cover,
              cacheWidth: 300,
            )
          else
            Container(
              color: context.theme.colorScheme.properSurface,
              child: Center(child: buildProgressIndicator(context)),
            ),
          // Long-press delete overlay
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onLongPress: widget.onDelete,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          // File name label at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                basenameWithoutExtension(widget.file.path),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
