import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/services/network/attachment_download_queue.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:path/path.dart';
import 'package:universal_io/io.dart';

/// Get an instance of our [AttachmentDownloadService]
AttachmentDownloadService attachmentDownloader = Get.isRegistered<AttachmentDownloadService>()
    ? Get.find<AttachmentDownloadService>() : Get.put(AttachmentDownloadService());

class AttachmentDownloadService extends GetxService {
  int maxDownloads = 2;
  final RxList<String> downloaders = <String>[].obs;
  final AttachmentDownloadQueue<AttachmentDownloadController> _downloaders =
      AttachmentDownloadQueue<AttachmentDownloadController>();

  AttachmentDownloadController? getController(String? guid) {
    return _downloaders.all.firstWhereOrNull((element) => element.attachment.guid == guid);
  }

  AttachmentDownloadController startDownload(Attachment a,
      {Function(PlatformFile)? onComplete, Function? onError, bool prioritized = false}) {
    final existing = getController(a.guid);
    if (existing != null) {
      if (onComplete != null && !existing.completeFuncs.contains(onComplete)) {
        existing.completeFuncs.add(onComplete);
      }
      if (onError != null && !existing.errorFuncs.contains(onError)) {
        existing.errorFuncs.add(onError);
      }
      if (prioritized && !existing.isFetching) prioritize(existing);
      return existing;
    }
    return Get.put(AttachmentDownloadController(
      attachment: a,
      onComplete: onComplete,
      onError: onError,
      prioritized: prioritized,
    ), tag: a.guid!);
  }

  void _addToQueue(AttachmentDownloadController downloader) {
    downloaders.add(downloader.attachment.guid!);
    final chatGuid = downloader.attachment.message.target?.chat.target?.guid ?? "unknown";
    _downloaders.add(chatGuid, downloader, prioritized: downloader.prioritized);
    _fetchNext();
  }

  void _removeFromQueue(AttachmentDownloadController downloader) {
    downloaders.remove(downloader.attachment.guid!);
    final chatGuid = downloader.attachment.message.target?.chat.target?.guid ?? "unknown";
    _downloaders.remove(chatGuid, downloader);
    Get.delete<AttachmentDownloadController>(tag: downloader.attachment.guid!);
    _fetchNext();
  }

  void prioritize(AttachmentDownloadController downloader) {
    if (downloader.isFetching) return;
    final chatGuid = downloader.attachment.message.target?.chat.target?.guid ?? "unknown";
    _downloaders.prioritize(chatGuid, downloader);
    _fetchNext();
  }

  void _fetchNext() {
    if (_downloaders.all.where((e) => e.isFetching).length >= maxDownloads) return;
    final next = _downloaders.next(
      activeChatGuid: cm.activeChat?.chat.guid,
      isFetching: (downloader) => downloader.isFetching,
    );
    next?.fetchAttachment();
  }
}

class AttachmentDownloadController extends GetxController {
  final Attachment attachment;
  final List<Function(PlatformFile)> completeFuncs = [];
  final List<Function> errorFuncs = [];
  final RxnNum progress = RxnNum();
  final Rxn<PlatformFile> file = Rxn<PlatformFile>();
  final RxBool error = RxBool(false);
  final bool prioritized;
  Stopwatch stopwatch = Stopwatch();
  bool isFetching = false;

  AttachmentDownloadController({
    required this.attachment,
    Function(PlatformFile)? onComplete,
    Function? onError,
    this.prioritized = false,
  }) {
    if (onComplete != null) completeFuncs.add(onComplete);
    if (onError != null) errorFuncs.add(onError);
  }

  @override
  void onInit() {
    attachmentDownloader._addToQueue(this);
    super.onInit();
  }

  Future<void> fetchAttachment() async {
    if (attachment.guid == null || attachment.guid!.contains("temp")) return;
    isFetching = true;
    stopwatch.start();
    PlatformFile response;
    try {
        response = await backend.downloadAttachment(attachment,
          onReceiveProgress: (count, total) => setProgress(kIsWeb ? (count / total) : (count / attachment.totalBytes!)));
    } catch (e, stack) {
      Logger.error("Attachment fetch error", error: e, trace: stack);
      if (!kIsWeb) {
        File file = File(attachment.path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      for (Function f in errorFuncs) {
        f.call();
      }

      error.value = true;
      attachmentDownloader._removeFromQueue(this);
      return;
    }
    if (!kIsWeb && !kIsDesktop && response.path == null) {
      File _file = await File(attachment.path).create(recursive: true);
      await _file.writeAsBytes(response.bytes!);
      response.path = attachment.path;
    }
    Logger.info("Finished fetching attachment");
    stopwatch.stop();
    Logger.info("Attachment downloaded in ${stopwatch.elapsedMilliseconds} ms");

    try {
      // Compress the attachment
      if (!kIsWeb) {
        await as.loadAndGetProperties(attachment, actualPath: attachment.path);
        attachment.save(null);
      }
    } catch (ex) {
      // So what if it crashes here.... I don't care...
    }

    // Finish the downloader
    attachmentDownloader._removeFromQueue(this);
    // Add attachment to sink based on if we got data

    file.value = response;
    for (Function f in completeFuncs) {
      f.call(file.value);
    }
    if (kIsDesktop) {
      if (attachment.bytes != null) {
        File _file = await File(attachment.path).create(recursive: true);
        await _file.writeAsBytes(attachment.bytes!.toList());
      }
    }
    if (ss.settings.autoSave.value
        && !kIsWeb
        && !kIsDesktop
        && !(attachment.isOutgoing ?? false)
        && !(attachment.message.target?.isInteractive ?? false)) {
      String filePath = "/storage/emulated/0/Download/";
      if (attachment.mimeType?.startsWith("image") ?? false) {
        await as.saveToDisk(file.value!, isAutoDownload: true);
      } else if (file.value?.bytes != null) {
        await File(join(filePath, file.value!.name)).writeAsBytes(file.value!.bytes!);
      }
    }
  }

  void setProgress(double value) {
    if (value.isNaN) {
      value = 0;
    } else if (value.isInfinite) {
      value = 1.0;
    } else if (value.isNegative) {
      value = 0;
    }

    progress.value = value.clamp(0, 1);
  }
}
