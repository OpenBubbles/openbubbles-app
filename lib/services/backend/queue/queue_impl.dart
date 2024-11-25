import 'dart:async';
import 'dart:isolate';

import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:get/get.dart';

abstract class Queue extends GetxService {
  bool isProcessing = false;
  List<QueueItem> items = [];
  static List<QueueItem> processingMessages = [];

  Future<void> queue(QueueItem item) async {
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
    if (!isProcessing || (items.isEmpty && item is IncomingItem)) processNextItem();
  }

  Future<dynamic> prepItem(QueueItem _);

  Future<void> processNextItem() async {
    if (items.isEmpty) {
      isProcessing = false;
      if (ls.isDead && !inq.isProcessing && !outq.isProcessing) {
        Logger.info("Done! waiting a bit for any stragglers");
        ls.closeTimer = Timer(const Duration(seconds: 5), () {
          mcs.invokeMethod("engine-done");
        });
      }
      return;
    }

    ls.closeTimer?.cancel();
    ls.closeTimer = null;

    isProcessing = true;
    QueueItem queued = items.removeAt(0);
    processingMessages.add(queued);

    try {
      await handleQueueItem(queued).catchError((err) async {
        if (queued is OutgoingItem && ss.settings.cancelQueuedMessages.value) {
          final toCancel = List<OutgoingItem>.from(items.whereType<OutgoingItem>().where((e) => e.chat.guid == queued.chat.guid));
          for (OutgoingItem i in toCancel) {
            items.remove(i);
            final m = i.message;
            final tempGuid = m.guid;
            m.guid = m.guid!.replaceAll("temp", "error-Canceled due to previous failure");
            m.error = MessageError.BAD_REQUEST.code;
            Message.replaceMessage(tempGuid, m);
          }
        }
      });
      queued.completer?.complete();
    } catch (ex, stacktrace) {
      Logger.error("Failed to handle queued item!", error: ex, trace: stacktrace);
      queued.completer?.completeError(ex);
    }

    processingMessages.remove(queued);
    await processNextItem();
  }

  Future<void> handleQueueItem(QueueItem _);
}
