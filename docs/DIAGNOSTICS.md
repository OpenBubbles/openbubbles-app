# Diagnostics and delivery troubleshooting

Use this guide to collect evidence for slow delivery, duplicate messages,
rendering failures, battery drain, or incorrect routing. The goal is a small,
redacted reproduction, not a permanent verbose log.

## Controlled reproduction

1. Keep Google Messages as the default SMS app.
2. Turn off OpenBubbles SMS forwarding while testing iMessage delivery.
3. Turn on OpenBubbles Developer Mode.
4. Force-close and reopen the test build.
5. Send one uniquely identifiable test message in each direction.
6. Record the sender, receiver, network (Wi-Fi or cellular), and approximate
   timestamps locally. Do not put message text or phone numbers in a public
   issue.
7. Export only the relevant log window and remove credentials and personal
   content before sharing.

For Android-side timing, a developer can also collect a bounded window with
the package filter (replace the package if testing a different flavor):

```bash
adb logcat -c
adb shell am force-stop com.bluebubbles.messaging.alpha
adb shell monkey -p com.bluebubbles.messaging.alpha 1
# Reproduce one operation, then stop capture promptly.
adb logcat -d -v threadtime -t 2000 > openbubbles-log.txt
```

Do not attach an unfiltered `logcat` dump. It can contain notification text,
contact data, URLs, and platform identifiers.

## What to look for

### Slow or missing receives

Trace the sequence, in order:

1. relay/WebSocket receive
2. event parsing and validation
3. message-service queueing
4. database save/upsert
5. acknowledgement back to the relay
6. UI refresh and notification

A transport connection without a database save is not a delivered message.
An acknowledgement before persistence can create a loss window after a process
restart. Any instrumentation should use a short redacted event ID and elapsed
milliseconds, never message text or a secret.

### Duplicates or wrong app routing

Check that only one SMS/MMS/RCS path is enabled. If both Google Messages and
OpenBubbles forwarding are enabled, disable forwarding and repeat the test.
For iMessage, verify that the event is not being inserted once from the live
stream and again from a refresh/reconnect path. Compare stable server/message
IDs rather than message text.

### Battery drain

Look for reconnect loops, unbounded timers, repeated database refreshes, or
notifications that fail and retry continuously. A healthy relay should use
bounded reconnect backoff and one active connection manager. Compare Android
battery statistics over the same time window with the test build stopped.

### UI/rendering failures

Repeated `LateError`, null avatar, or “unexpected error occurred when
rendering” entries indicate a UI data-shape problem. Capture the incident ID,
screen, and safe event timing. Do not work around a rendering failure by
silently dropping the entire conversation.

### Registration and validation

Registration input should not be decoded until it matches the complete expected
format. Validation errors should be surfaced as a bounded failure and retry,
not a tight loop. Relay registration secrets belong in Keychain on iOS and must
never appear in logs or shared preferences.

## Current audit themes

The recent field logs identified four recurring classes to keep covered by
tests and review:

- notification avatar data can be incomplete;
- CloudKit plist decoding can receive an unexpected byte-array shape;
- reaction events can race message persistence;
- anisette/validation WebSockets can reset during provisioning.

These are not all necessarily present in every build. When a fix is proposed,
include the before/after log counts and a focused test or reproduction.

## Privacy and retention

Keep raw captures in a local, access-controlled folder. Delete them when the
issue is closed. Redact before uploading to GitHub, Discord, or a bug tracker.
Never request or paste an Apple password, two-factor code, registration secret,
private key, or full device identifier into an issue.
