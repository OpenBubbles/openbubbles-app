import 'dart:async';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/queue/queue_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestItem extends QueueItem {
  _TestItem({Completer<void>? completer})
      : super(type: QueueType.newMessage, completer: completer);
}

class _TestQueue extends Queue {
  int active = 0;
  int maxActive = 0;
  bool fail = false;

  @override
  Future<dynamic> prepItem(QueueItem item) async {}

  @override
  Future<void> handleQueueItem(QueueItem item) async {
    active++;
    maxActive = active > maxActive ? active : maxActive;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    active--;
    if (fail) throw StateError('expected test failure');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runs queued items with one active runner', () async {
    final queue = _TestQueue();
    final first = Completer<void>();
    final second = Completer<void>();

    await Future.wait([
      queue.queue(_TestItem(completer: first)),
      queue.queue(_TestItem(completer: second)),
    ]);
    await Future.wait([first.future, second.future]);

    expect(queue.maxActive, 1);
    expect(queue.isProcessing.value, isFalse);
  });

  test('completes a failed item with an error', () async {
    final queue = _TestQueue()..fail = true;
    final completion = Completer<void>();

    await queue.queue(_TestItem(completer: completion));

    await expectLater(completion.future, throwsStateError);
    expect(queue.isProcessing.value, isFalse);
  });
}
