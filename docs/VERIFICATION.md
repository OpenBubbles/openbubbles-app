# Delivery, routing, and performance verification

Use this plan when comparing an app change against a known-good Alpha build.
It separates transport, persistence, rendering, and Android background work so
that a faster WebSocket does not hide a database or notification regression.

## Reproducible build gate

The repository CI workflow (`.github/workflows/build.yml`) currently uses:

```text
Flutter 3.24.0 (stable)
Rust stable
Java 21 (Temurin)
Android SDK and protoc
```

Run the same commands locally from the repository root:

```bash
flutter pub get
flutter test test/helpers/message_helper_test.dart
flutter analyze
flutter build apk --flavor alpha --profile --target-platform android-arm64
flutter build apk --flavor alpha --debug --target-platform android-arm64
```

The focused helper test is the required CI test today. `flutter analyze` is an
additional local gate for source changes. Do not call a build verified when the
machine has a different Flutter or Java major version.

### Environment evidence from the Windows review host

On 2026-07-24 this host had `adb 37.0.0` and Java 8, but `flutter` and `dart`
were not on `PATH`. Therefore no Flutter test, analyzer, or APK build was
claimed locally. The expected next action is to install/use Flutter 3.24.0 and
Java 21, then run the commands above or rely on the GitHub workflow.

## Functional delivery matrix

Run each scenario once on the baseline and at least three times on the changed
build. Use a unique local test ID, not message text, in the timing sheet.

| Scenario | Expected result | Evidence |
| --- | --- | --- |
| iMessage receive, app foreground | One database row and one UI message | relay receive, save, UI timestamps |
| iMessage receive, app background | One notification and one database row | notification ID plus save timestamp |
| Duplicate relay event | One logical message, no duplicate notification | stable server/message ID count |
| Reconnect during receive | Event is retried or recovered, no loss | disconnect, reconnect, save, acknowledgement order |
| Updated message/reaction before base message | Event is eventually applied or boundedly deferred | target ID, retry count, final row |
| Malformed/partial payload | Event rejected safely; process remains alive | redacted error and subsequent message success |
| SMS/MMS/RCS routing | Delivered only by Google Messages in the control test | default-app state and notification source |

For the SMS/RCS control, keep Google Messages as the default SMS app and turn
off OpenBubbles forwarding. Test the forwarding path separately; do not use two
active paths to judge loss or duplication.

## Timing and correctness metrics

Instrument or correlate a redacted event ID at these boundaries:

1. relay/WebSocket receive
2. payload parse/validation
3. incoming queue start
4. database save/upsert complete
5. acknowledgement sent
6. UI listener refresh
7. notification scheduled

Report median and p95 milliseconds for each segment, plus counts of duplicate
IDs, missing IDs, parse failures, notification failures, and reconnects. The
minimum acceptance gate for a delivery fix is zero lost IDs and zero duplicate
IDs in the controlled run. Latency improvements are secondary to correctness.

## On-device performance capture

Use a profile APK for frame and CPU comparisons, and keep the same device,
Android version, screen refresh rate, chat history, network, and test script.
Replace the package name if using another flavor.

```bash
adb shell am force-stop com.bluebubbles.messaging.alpha
adb shell monkey -p com.bluebubbles.messaging.alpha 1
adb shell dumpsys gfxinfo com.bluebubbles.messaging.alpha reset
# Perform one 60-second scroll/open/send/receive script.
adb shell dumpsys gfxinfo com.bluebubbles.messaging.alpha framestats > gfxinfo.txt
adb shell dumpsys meminfo com.bluebubbles.messaging.alpha > meminfo.txt
adb shell dumpsys cpuinfo > cpuinfo.txt
```

Record total frames, missed frames, 90th/95th/99th percentile frame time, peak
RSS, and CPU share. A smoother UI should reduce long frames without trading
away receive or database work.

For battery and background behavior, use a fresh controlled window:

```bash
adb shell dumpsys batterystats --reset
# Leave the same build idle for 30 minutes, then exercise five receives.
adb shell dumpsys batterystats --charged > batterystats.txt
adb shell dumpsys netstats detail > netstats.txt
```

Compare baseline and changed builds under the same network. Look specifically
for reconnect loops, repeated refresh timers, foreground services that never
stop, and notification retry storms.

## Failure triage

- A WebSocket connect without a database save is a receive failure, not a pass.
- An acknowledgement before persistence is a possible loss window after a
  process restart; capture the ordering explicitly.
- Repeated null-avatar or render exceptions can make the app feel slow even if
  transport latency is normal.
- Reaction lookups that miss their target should be bounded and observable, not
  an unbounded retry loop.
- CloudKit plist decoding failures should isolate the malformed item and allow
  later messages to continue.
- Registration/anisette failures should back off; a tight retry loop is both a
  battery and delivery risk.

Attach only redacted logs and a small timing table to a review. Never include
message text, phone numbers, Apple credentials, relay secrets, auth tokens, or
full device identifiers.
