import 'package:bluebubbles/database/global/chat_messages.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attaches a reaction that arrives before its base message', () {
    final messages = ChatMessages();
    final reaction = Message(
      guid: 'reaction-1',
      associatedMessageGuid: 'base-1',
      associatedMessageType: 'like',
    );
    final base = Message(guid: 'base-1', text: 'hello');

    messages.addMessages([reaction]);
    messages.addMessages([base]);

    expect(messages.getMessage('base-1'), same(base));
    expect(base.hasReactions, isTrue);
    expect(base.associatedMessages.map((item) => item.guid).toList(), ['reaction-1']);
  });

  test('does not duplicate a reaction when the event is replayed', () {
    final messages = ChatMessages();
    final base = Message(guid: 'base-2', text: 'hello');
    final reaction = Message(
      guid: 'reaction-2',
      associatedMessageGuid: 'base-2',
      associatedMessageType: 'like',
    );

    messages.addMessages([base, reaction, reaction]);

    expect(base.associatedMessages, hasLength(1));
    expect(base.associatedMessages.single, same(reaction));
  });
}
