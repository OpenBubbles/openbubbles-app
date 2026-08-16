import 'package:bluebubbles/services/network/attachment_download_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("a tapped attachment moves ahead of older queued work in its chat", () {
    final queue = AttachmentDownloadQueue<String>();
    queue.add("chat", "first");
    queue.add("chat", "second");
    queue.add("chat", "third");

    expect(queue.prioritize("chat", "third"), isTrue);
    expect(queue.forChat("chat"), <String>["third", "first", "second"]);
  });

  test("prioritizing an already queued item does not duplicate it", () {
    final queue = AttachmentDownloadQueue<String>();
    queue.add("chat", "first");
    queue.add("chat", "second");

    queue.add("chat", "second", prioritized: true);

    expect(queue.forChat("chat"), <String>["second", "first"]);
  });

  test("active chat ordering wins while preserving FIFO elsewhere", () {
    final queue = AttachmentDownloadQueue<String>();
    queue.add("other", "other-1");
    queue.add("active", "active-1");
    queue.add("active", "active-2");

    expect(
      queue.next(activeChatGuid: "active", isFetching: (_) => false),
      "active-1",
    );
    queue.prioritize("active", "active-2");
    expect(
      queue.next(activeChatGuid: "active", isFetching: (_) => false),
      "active-2",
    );
  });

  test("prioritizing the first queued item preserves stable order", () {
    final queue = AttachmentDownloadQueue<String>();
    queue.add("chat", "active");
    queue.add("chat", "waiting");

    expect(queue.prioritize("chat", "active"), isTrue);
    expect(queue.forChat("chat"), <String>["active", "waiting"]);
  });
}
