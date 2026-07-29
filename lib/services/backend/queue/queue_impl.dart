import 'dart:async';

import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:get/get.dart';

abstract class Queue extends GetxService {
  RxBool isProcessing = false.obs;
  List<QueueItem> items = [];
  bool _runnerActive = false;

  Future<void> queue(QueueItem item, {bool prep = true}) async {
    try {
      if (prep) {
        final returned = await prepItem(item);
        // we may get a link split into 2 messages
        if (item is OutgoingItem && returned is List) {
          items.addAll(returned.map((e) => OutgoingItem(
            type: item.type,
            chat: item.chat,
            message: e,
            completer: item.completer,
            selected: item.selected,
            reaction: item.reaction,
          )));
        } else {
          items.add(item);
        }
      } else {
        items.add(item);
      }
    } catch (ex, stacktrace) {
      if (item.completer != null && !item.completer!.isCompleted) {
        item.completer!.completeError(ex, stacktrace);
      }
      rethrow;
    }
    _startRunner();
  }

  Future<dynamic> prepItem(QueueItem _);

  void _startRunner() {
    if (_runnerActive) return;
    _runnerActive = true;
    unawaited(processNextItem());
  }

  Future<void> processNextItem() async {
    isProcessing.value = true;
    try {
      while (items.isNotEmpty) {
        ls.closeTimer?.cancel();
        ls.closeTimer = null;

        final queued = items.removeAt(0);
        try {
          await handleQueueItem(queued);
          if (queued.completer != null && !queued.completer!.isCompleted) {
            queued.completer!.complete();
          }
        } catch (ex, stacktrace) {
          Logger.error("Failed to handle queued item!", error: ex, trace: stacktrace);
          if (queued is OutgoingItem && ss.settings.cancelQueuedMessages.value) {
            final toCancel = List<OutgoingItem>.from(items.whereType<OutgoingItem>().where((e) => e.chat.guid == queued.chat.guid));
            for (final i in toCancel) {
              items.remove(i);
              final m = i.message;
              final tempGuid = m.guid;
              m.guid = m.guid!.replaceAll("temp", "error-Canceled due to previous failure");
              m.error = MessageError.BAD_REQUEST.code;
              Message.replaceMessage(tempGuid, m);
            }
          }
          if (queued.completer != null && !queued.completer!.isCompleted) {
            queued.completer!.completeError(ex, stacktrace);
          }
        }
      }
    } finally {
      isProcessing.value = false;
      _runnerActive = false;
      if (items.isNotEmpty) _startRunner();
      if (ls.isDead && !inq.isProcessing.value && !outq.isProcessing.value) {
        Logger.info("Done! waiting a bit for any stragglers");
        ls.closeTimer = Timer(const Duration(seconds: 5), () {
          mcs.invokeMethod("engine-done");
        });
      }
    }
  }

  Future<void> handleQueueItem(QueueItem _);
}
