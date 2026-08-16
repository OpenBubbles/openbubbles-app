import 'dart:async';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('send waits for the composer handler to finish', () async {
    final controller =
        ConversationViewController(Chat(guid: 'iMessage;-;send-await-test'));
    final handler = Completer<void>();
    controller.sendFunc = (_, __, ___) => handler.future;

    var completed = false;
    final sending = controller
        .send(
          [],
          AttributedBody.raw('message'),
          '',
          null,
          null,
          null,
          null,
          false,
          null,
        )
        .then((_) => completed = true);

    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    handler.complete();
    await sending;
    expect(completed, isTrue);
  });

  test('send fails when the composer handler is not ready', () async {
    final controller =
        ConversationViewController(Chat(guid: 'iMessage;-;send-missing-test'));

    await expectLater(
      controller.send(
        [],
        AttributedBody.raw('message'),
        '',
        null,
        null,
        null,
        null,
        false,
        null,
      ),
      throwsStateError,
    );
  });
}
