import 'package:bluebubbles/helpers/ui/message_widget_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('safeMessageSubstring', () {
    test('rejects missing text and malformed ranges', () {
      expect(safeMessageSubstring(null, [0, 1]), isNull);
      expect(safeMessageSubstring('hello', []), isNull);
      expect(safeMessageSubstring('hello', [3]), isNull);
    });

    test('clamps cloud annotation ranges to available text', () {
      expect(safeMessageSubstring('hello', [-4, 2]), 'he');
      expect(safeMessageSubstring('hello', [3, 20]), 'lo');
      expect(safeMessageSubstring('hello', [5, 20]), isNull);
      expect(safeMessageSubstring('hello', [4, 2]), isNull);
    });

    test('returns valid annotated text', () {
      expect(safeMessageSubstring('hello world', [6, 11]), 'world');
    });
  });
}
