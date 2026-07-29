---
type: technical_design
title: OpenBubbles Conversation Memory Management
description: Ownership, limits, validation, and rollback guidance for attachment caches and media controllers.
resource: openbubbles-app
tags: [android, flutter, memory, media, lifecycle]
timestamp: 2026-07-28
---

# Conversation memory management

## Scope

This design bounds memory retained by an open conversation without changing
message routing, attachment persistence, package contents, or network behavior.
It addresses encoded attachment previews, sticker data, parsed text, metadata
previews, and the lifetime of audio and video players.

The limits below are architecture-neutral. They apply to every Android build,
not only a Pixel-specific package.

## Ownership model

| Resource | Owner | Lifetime | Release point |
| --- | --- | --- | --- |
| Encoded image preview bytes | `ConversationViewController.imageData` | Current conversation, subject to LRU eviction | Eviction or controller close |
| Sticker bytes | `ConversationViewController.stickerData` | Current conversation, subject to weighted LRU eviction | Eviction or controller close |
| Parsed ML Kit text | `ConversationViewController.mlKitParsedText` | Current conversation, subject to entry LRU eviction | Eviction or controller close |
| Link metadata previews | `ConversationViewController.legacyUrlPreviews` | Current conversation, subject to entry LRU eviction | Eviction or controller close |
| Message audio player | Audio message widget | Mounted widget | Widget dispose |
| Message video player | Video message widget | Mounted widget after the user presses play | Widget dispose |
| Full-screen video player | Full-screen view when it creates the player | Full-screen route | Route dispose |
| Poster images | `ConversationViewController` | Current poster generation | Replacement or controller close |

The controller's audio and video maps are non-owning indexes used for controls
such as pause-on-background. Widgets remain responsible for disposing the
players they create. This prevents both leaks and double-disposal.

## Cache limits

| Cache | Limit |
| --- | --- |
| Encoded image previews | 32 MiB and 48 entries |
| Sticker bytes | 16 MiB and 64 message entries |
| Parsed ML Kit text | 256 entries |
| Metadata previews | 64 entries |

Reads promote entries in least-recently-used order. Replacing or removing an
entry updates byte accounting. An image larger than the entire image-cache
budget is served to its active caller but is not retained. Other bounded maps
reject an oversized value. Replacing an existing key with an oversized object
removes the stale value for that key.

The 32 MiB image budget covers encoded preview bytes only. Flutter's decoded
image cache, native media codecs, player buffers, in-flight file reads, and
full-screen media are separate allocations and can temporarily raise process
memory above these limits.

## Runtime flow

### Image preview

1. A mounted image widget requests bytes from the conversation controller.
2. A cached value is returned immediately when available.
3. Concurrent requests for the same attachment share one in-flight load.
4. The queue retains no `BuildContext`, so it cannot retain a widget subtree.
5. A successful result is inserted into the bounded cache and returned.
6. Failures complete the request and allow the next queued load to proceed.
7. Closing the conversation completes pending requests with empty bytes and
   prevents late work from repopulating the cache.

### Audio and video

Audio and video widgets own their players and cancel every listener or stream
subscription during disposal. Video initialization is lazy and begins only
after the user presses play. When the app backgrounds, the lifecycle service
pauses players belonging to an already registered conversation controller. It
does not create a new controller merely to pause media.

### Stickers and extracted text

Sticker maps use copy-on-write updates so adding one sticker preserves earlier
stickers while keeping weight accounting accurate. ML Kit extractors close in
a `finally` block. Widget-facing asynchronous results check `mounted` before
updating widget state.

## Validation procedure

Use the same release or profile build, device, relay, conversations, and media
set for baseline and changed runs. Debug builds are not suitable for comparative
frame or memory claims.

1. Run unit tests for both bounded-cache implementations.
2. Run Flutter analysis on every changed Dart file.
3. Follow the ADB capture procedure in
   [`VERIFICATION.md`](VERIFICATION.md). On a physical Pixel, perform three
   baseline and three changed runs:
   open a large conversation, scroll through image and sticker history, play
   audio and video, enter and leave full-screen video, background and resume,
   then leave the app idle for five minutes.
4. Record peak PSS, five-minute post-workload PSS and SwapPss, frame timing,
   attachment reload behavior after eviction, and any dropped playback events.
5. Confirm that audio, video, full-screen playback, image previews, stickers,
   metadata, and text extraction still work after eviction and navigation.

Suggested acceptance thresholds:

- Cache unit tests and targeted analysis pass.
- The conversation image cache never retains more than 32 MiB or 48 entries.
- Sticker data never retains more than 16 MiB or 64 message entries.
- No callback updates a disposed widget and no controller is double-disposed.
- Evicted media reloads correctly.
- Median peak PSS improves by at least 15 percent across matched runs.
- Five-minute SwapPss falls by at least 40 percent, with a target below 40 MiB.
- The 95th-percentile frame time does not regress by more than 5 percent.

The percentage thresholds are evaluation targets, not claims about the current
unmeasured implementation.

## Known limitations

- Android controls paging and swap. The application can reduce retained memory
  but cannot guarantee a specific SwapPss value.
- In-flight file reads and full-screen media can temporarily exceed cache
  budgets.
- Mounted image widgets retain their current byte arrays, and queued image
  requests retain distinct `PlatformFile` values until processed. Duplicate
  attachment GUIDs are coalesced, but the distinct-request queue is not yet
  bounded.
- Flutter's decoded image cache and native player buffers require separate
  measurement.
- Attachment files on disk are unchanged.
- Desktop and web use different media implementations and need their own
  behavioral checks.
- Background delivery, relay latency, and download throughput are outside this
  change's scope.

## Rollback

Revert the bounded-cache helpers and the conversation/media lifecycle changes
as one unit. Do not revert only widget ownership or only controller cleanup:
the non-owning controller indexes depend on widgets remaining the sole owners
of their media players. After rollback, rerun the same cache, playback, and
navigation checks to confirm the previous behavior is restored.
