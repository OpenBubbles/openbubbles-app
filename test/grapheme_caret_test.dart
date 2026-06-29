// Unit test for the app-side caret clamp wired into SpellCheckTextEditingController.set value.
// Proves the same prevention as the framework fix (flutter/flutter#188719) without a Flutter
// upgrade: a caret inside a surrogate pair is snapped to the pair boundary, so the next edit can't
// split the emoji.
//
// Run: C:\tools\flutter\bin\flutter.bat test test/grapheme_caret_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/helpers/ui/grapheme_caret.dart';

void main() {
  // 'a😓b' -> code units [0061, D83D, DE13, 0062]; offset 2 is between D83D and DE13.
  const String text = 'a😓b';

  TextEditingValue v(int base, [int? extent]) =>
      TextEditingValue(text: text, selection: TextSelection(baseOffset: base, extentOffset: extent ?? base));

  test('a collapsed caret inside the pair is snapped to the pair start', () {
    expect(snapSelectionOffSurrogatePairs(v(2)).selection, const TextSelection.collapsed(offset: 1));
  });

  test('boundary carets are unchanged', () {
    for (final int offset in <int>[0, 1, 3, 4]) {
      expect(snapSelectionOffSurrogatePairs(v(offset)).selection.baseOffset, offset);
    }
  });

  test('a selection endpoint inside the pair is snapped (both ends handled)', () {
    // base inside the pair, extent at a boundary.
    final TextEditingValue out = snapSelectionOffSurrogatePairs(v(2, 4));
    expect(out.selection.baseOffset, 1);
    expect(out.selection.extentOffset, 4);
  });

  test('invalid/empty selection is left alone', () {
    const TextEditingValue none = TextEditingValue(text: text);
    expect(snapSelectionOffSurrogatePairs(none).selection, none.selection);
  });

  test('inserting at the snapped caret keeps the emoji intact', () {
    final int caret = snapSelectionOffSurrogatePairs(v(2)).selection.baseOffset; // 1
    final String edited = text.replaceRange(caret, caret, 'x'); // 'ax😓b'
    // No lone surrogate remains.
    final List<int> u = edited.codeUnits;
    bool lone = false;
    for (int i = 0; i < u.length; i++) {
      final int c = u[i];
      if (c >= 0xD800 && c <= 0xDBFF) {
        if (i + 1 >= u.length || !(u[i + 1] >= 0xDC00 && u[i + 1] <= 0xDFFF)) lone = true;
        i++;
      } else if (c >= 0xDC00 && c <= 0xDFFF) {
        lone = true;
      }
    }
    expect(lone, isFalse);
    expect(edited.contains('😓'), isTrue);
  });
}
