import 'dart:async';

enum SendFailureKind {
  resourceUnavailable,
  confirmationTimeout,
  permanent,
  unknown,
}

class SendRetryDecision {
  const SendRetryDecision({
    required this.kind,
    required this.retry,
    this.delay = Duration.zero,
    this.markFailedLogin = false,
  });

  final SendFailureKind kind;
  final bool retry;
  final Duration delay;
  final bool markFailedLogin;
}

class SendRetryPolicy {
  SendRetryPolicy({
    this.budget = const Duration(minutes: 3),
    this.maxResourceWait = const Duration(seconds: 35),
    this.timeoutRetryWait = const Duration(seconds: 2),
    this.maxTimeoutRetries = 1,
  });

  static final RegExp resourceRetryRegex = RegExp(r"retrying in (\d+)s");

  final Duration budget;
  final Duration maxResourceWait;
  final Duration timeoutRetryWait;
  final int maxTimeoutRetries;
  Duration elapsed = Duration.zero;
  int timeoutRetries = 0;

  SendFailureKind classify(Object error) {
    final description = error.toString();
    if (description.contains("Failed to generate resource")) {
      return description.contains("not retrying")
          ? SendFailureKind.permanent
          : SendFailureKind.resourceUnavailable;
    }
    if (description.contains("Send timeout; try again")) {
      return SendFailureKind.confirmationTimeout;
    }
    return SendFailureKind.unknown;
  }

  Duration? resourceRetryWait(Object error) {
    final seconds = int.tryParse(
      resourceRetryRegex.firstMatch(error.toString())?.group(1) ?? "",
    );
    if (seconds == null) return null;
    final wait = Duration(seconds: seconds) + const Duration(seconds: 1);
    return wait > maxResourceWait ? maxResourceWait : wait;
  }

  SendRetryDecision next(Object error, {bool waitForResource = true}) {
    final kind = classify(error);
    if (kind == SendFailureKind.permanent) {
      return const SendRetryDecision(
        kind: SendFailureKind.permanent,
        retry: false,
        markFailedLogin: true,
      );
    }

    Duration? delay;
    if (kind == SendFailureKind.confirmationTimeout &&
        timeoutRetries < maxTimeoutRetries) {
      timeoutRetries++;
      delay = timeoutRetryWait;
    } else if (kind == SendFailureKind.resourceUnavailable && waitForResource) {
      delay = resourceRetryWait(error);
    }

    if (delay == null || elapsed + delay > budget) {
      return SendRetryDecision(kind: kind, retry: false);
    }

    elapsed += delay;
    return SendRetryDecision(kind: kind, retry: true, delay: delay);
  }
}

class InFlightSendRegistry {
  final Map<String, Future<void>> _active = <String, Future<void>>{};

  Future<void> run(String messageId, Future<void> Function() operation) {
    final existing = _active[messageId];
    if (existing != null) return existing;

    final completer = Completer<void>();
    _active[messageId] = completer.future;
    Future<void>.sync(operation).then<void>(
      (_) {
        completer.complete();
        if (identical(_active[messageId], completer.future)) {
          _active.remove(messageId);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        completer.completeError(error, stackTrace);
        if (identical(_active[messageId], completer.future)) {
          _active.remove(messageId);
        }
      },
    );
    return completer.future;
  }
}
