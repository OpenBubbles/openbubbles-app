import 'dart:async';

import 'package:bluebubbles/services/rustpush/send_retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("SendRetryPolicy", () {
    test("retries a transient resource failure", () {
      final policy = SendRetryPolicy();

      final decision = policy.next(
        "Failed to generate resource: retrying in 4s",
      );

      expect(decision.kind, SendFailureKind.resourceUnavailable);
      expect(decision.retry, isTrue);
      expect(decision.delay, const Duration(seconds: 5));
    });

    test("does not retry permanent resource failure", () {
      final policy = SendRetryPolicy();

      final decision = policy.next("Failed to generate resource: not retrying");

      expect(decision.kind, SendFailureKind.permanent);
      expect(decision.retry, isFalse);
      expect(decision.markFailedLogin, isTrue);
    });

    test("stops when the reconnect budget is exhausted", () {
      final policy = SendRetryPolicy(budget: const Duration(seconds: 6));

      expect(
        policy.next("Failed to generate resource: retrying in 4s").retry,
        isTrue,
      );
      final exhausted = policy.next(
        "Failed to generate resource: retrying in 4s",
      );

      expect(exhausted.retry, isFalse);
      expect(policy.elapsed, const Duration(seconds: 5));
    });

    test("allows only one confirmation-timeout retry", () {
      final policy = SendRetryPolicy();

      expect(policy.next("Send timeout; try again").retry, isTrue);
      expect(policy.next("Send timeout; try again").retry, isFalse);
    });
  });

  test("coalesces duplicate sends by message id", () async {
    final registry = InFlightSendRegistry();
    final gate = Completer<void>();
    var calls = 0;

    final first = registry.run("message-1", () async {
      calls++;
      await gate.future;
    });
    final second = registry.run("message-1", () async {
      calls++;
    });

    expect(identical(first, second), isTrue);
    expect(calls, 1);
    gate.complete();
    await first;

    await registry.run("message-1", () async {
      calls++;
    });
    expect(calls, 2);
  });
}
