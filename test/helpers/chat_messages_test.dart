import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('includes the originator when it is loaded before its replies', () {
    final messages = ChatMessages();
    final originator = Message(guid: 'thread-1', text: 'originator');
    final reply = Message(
      guid: 'reply-1',
      text: 'reply',
      threadOriginatorGuid: 'thread-1',
      threadOriginatorPart: '0',
    );

    messages.addMessages([originator, reply]);

    expect(
      messages.threads('thread-1', 0).map((message) => message.guid),
      containsAll(['thread-1', 'reply-1']),
    );
  });

  test('includes the originator when it is loaded after its replies', () {
    final messages = ChatMessages();
    final originator = Message(guid: 'thread-2', text: 'originator');
    final reply = Message(
      guid: 'reply-2',
      text: 'reply',
      threadOriginatorGuid: 'thread-2',
      threadOriginatorPart: '0',
    );

    messages.addMessages([reply, originator]);

    expect(
      messages.threads('thread-2', 0).map((message) => message.guid),
      containsAll(['thread-2', 'reply-2']),
    );
  });

  test('returns every message in a lengthy reply chain', () {
    final messages = ChatMessages();
    final originator = Message(guid: 'thread-long', text: 'originator');
    final replies = List.generate(
      100,
      (index) => Message(
        guid: 'reply-long-$index',
        text: 'reply $index',
        threadOriginatorGuid: 'thread-long',
        threadOriginatorPart: '0',
      ),
    );

    messages.addMessages([originator, ...replies]);

    final thread = messages.threads('thread-long', 0);
    expect(thread, hasLength(101));
    expect(thread.map((message) => message.guid).toSet(), hasLength(101));
  });

  test('keeps multi-digit reply part indexes intact', () {
    final reply = Message(
      guid: 'reply-part-12',
      threadOriginatorGuid: 'thread-multipart',
      threadOriginatorPart: '12:4:8',
    );

    expect(reply.normalizedThreadPart, 12);
  });
}
