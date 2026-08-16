import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/services/rustpush/profile_retry_policy.dart';

void main() {
  group("ProfileRetryPolicy", () {
    test("classifies service and network failures as transient", () {
      final policy = ProfileRetryPolicy();

      expect(
        policy.classify(StateError("Profile service unavailable")),
        ProfileFailureKind.transient,
      );
      expect(
        policy.classify(TimeoutExceptionForTest()),
        ProfileFailureKind.transient,
      );
      expect(
        policy.classify(Exception("socket reset by peer")),
        ProfileFailureKind.transient,
      );
    });

    test("does not retry permanent payload failures", () {
      final policy = ProfileRetryPolicy();

      expect(
        policy.classify(Exception("invalid plist signature")),
        ProfileFailureKind.permanent,
      );
      expect(
        policy.classify(Exception("record not found")),
        ProfileFailureKind.permanent,
      );
    });

    test("suppresses duplicate schedules and exhausts the retry budget", () {
      final policy = ProfileRetryPolicy(
        delays: const <Duration>[Duration(seconds: 1), Duration(seconds: 2)],
      );

      expect(policy.schedule("profile-1"), const Duration(seconds: 1));
      expect(policy.schedule("profile-1"), isNull);
      policy.timerFired("profile-1");
      expect(policy.schedule("profile-1"), const Duration(seconds: 2));
      policy.timerFired("profile-1");
      expect(policy.schedule("profile-1"), isNull);
      expect(policy.isEmpty, isTrue);
    });

    test("completion resets attempts for a later independent fetch", () {
      final policy = ProfileRetryPolicy(
        delays: const <Duration>[Duration(seconds: 1)],
      );

      expect(policy.schedule("profile-1"), const Duration(seconds: 1));
      policy.complete("profile-1");
      expect(policy.schedule("profile-1"), const Duration(seconds: 1));
    });
  });
}

class TimeoutExceptionForTest implements Exception {
  @override
  String toString() => "timeout while fetching profile";
}
