import 'package:bluebubbles/helpers/types/helpers/message_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageHelper.getReactionFallbackText', () {
    test('uses a human-safe reaction label for missing text', () {
      expect(MessageHelper.getReactionFallbackText('Someone', null), 'Someone reacted to a message');
      expect(MessageHelper.getReactionFallbackText('Someone', '  '), 'Someone reacted to a message');
    });

    test('preserves a populated fallback reaction text', () {
      expect(MessageHelper.getReactionFallbackText('Someone', 'liked a message'), 'Someone liked a message');
    });
  });
}
