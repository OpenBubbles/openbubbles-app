import 'package:bluebubbles/helpers/ui/text_direction_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every case rtl_detection_test.dart asserts, so the memo can be checked to
/// return the same answers cold and warm.
const List<(String?, TextDirection)> _cases = <(String?, TextDirection)>[
  ('سلام', TextDirection.rtl),
  ('سلام 😂', TextDirection.rtl),
  ('چطوری، خوبی؟', TextDirection.rtl),
  ('😂 سلام', TextDirection.rtl),
  ('"سلام"', TextDirection.rtl),
  ('۱۲۳ سلام', TextDirection.rtl),
  ('hello', TextDirection.ltr),
  ('hello 😂', TextDirection.ltr),
  ('😂 hello', TextDirection.ltr),
  ('', TextDirection.ltr),
  (null, TextDirection.ltr),
  ('سلام hello', TextDirection.rtl),
  ('hello سلام', TextDirection.ltr),
  // All-neutral: no strongly-directional character at all, so this is the case
  // the memo exists for — the scan runs to the end of the string.
  ('1234567890 !@#\$%^&*()', TextDirection.ltr),
  ('😂🎉👍🏽❤️🇮🇷', TextDirection.ltr),
];

void main() {
  setUp(clearTextDirectionCache);

  test('memoized result equals the uncached result, cold and warm', () {
    for (final (String? text, TextDirection expected) in _cases) {
      clearTextDirectionCache();
      expect(getTextDirection(text), expected, reason: 'cold: $text');
      // Warm: same key, now served from the memo.
      expect(getTextDirection(text), expected, reason: 'warm: $text');
      // And repeatedly, to catch a memo that corrupts itself on re-read.
      for (int i = 0; i < 5; i++) {
        expect(getTextDirection(text), expected, reason: 'repeat $i: $text');
      }
    }
  });

  test('a value equal to but not identical with the cached key still hits', () {
    // The call sites pass Message.fullText, which builds a NEW String on every
    // call — so the memo has to key on value, not identity.
    const String subject = 'سلام';
    final String first = <String>[subject, 'خوبی؟'].join('\n');
    final String second = <String>[subject, 'خوبی؟'].join('\n');
    expect(identical(first, second), isFalse, reason: 'the two must be distinct instances');

    expect(getTextDirection(first), TextDirection.rtl);
    final int afterFirst = textDirectionCacheLength;
    expect(getTextDirection(second), TextDirection.rtl);
    expect(textDirectionCacheLength, afterFirst, reason: 'an equal string must not add a second entry');
  });

  test('null and empty are answered without occupying the memo', () {
    expect(getTextDirection(null), TextDirection.ltr);
    expect(getTextDirection(''), TextDirection.ltr);
    expect(textDirectionCacheLength, 0);
  });

  test('the memo is bounded at its capacity', () {
    final int capacity = textDirectionCacheCapacity;
    for (int i = 0; i < capacity * 2 + 7; i++) {
      getTextDirection('message number $i');
    }
    expect(textDirectionCacheLength, lessThanOrEqualTo(capacity));
    expect(textDirectionCacheLength, capacity, reason: 'should be full, not undersized');
  });

  test('eviction is insertion-ordered, and a hit does NOT promote', () {
    final int capacity = textDirectionCacheCapacity;
    for (int i = 0; i < capacity; i++) {
      getTextDirection('key $i');
    }
    expect(textDirectionCacheLength, capacity);
    expect(textDirectionCacheContains('key 0'), isTrue);

    // Read the oldest key. Under a move-to-end LRU this would promote it to
    // most-recently-used; under insertion-order eviction it stays oldest. That
    // difference is the whole point — promoting costs a remove plus a re-insert
    // (34 ns/hit measured) against a 13 ns scan, so it would make ordinary text
    // slower than having no memo at all.
    getTextDirection('key 0');
    expect(textDirectionCacheLength, capacity, reason: 'a hit must not grow the memo');

    // One more distinct key overflows the bound and evicts exactly one entry.
    getTextDirection('overflow');
    expect(textDirectionCacheLength, capacity);

    // The evicted one is the OLDEST INSERTED, despite having just been read.
    // A move-to-end LRU would have kept 'key 0' and dropped 'key 1' instead, so
    // these two assertions fail against that implementation.
    expect(textDirectionCacheContains('key 0'), isFalse, reason: 'oldest-inserted must be evicted even though it was just read');
    expect(textDirectionCacheContains('key 1'), isTrue, reason: 'the next-oldest must survive');
    expect(textDirectionCacheContains('overflow'), isTrue);
  });

  test('evicted entries are recomputed correctly, not lost', () {
    final int capacity = textDirectionCacheCapacity;
    const String farsi = 'سلام خوبی';
    expect(getTextDirection(farsi), TextDirection.rtl);
    // Flood past capacity so the Farsi entry is certainly evicted.
    for (int i = 0; i < capacity + 10; i++) {
      getTextDirection('filler $i');
    }
    // Still correct — the memo is an optimization, never the source of truth.
    expect(getTextDirection(farsi), TextDirection.rtl);
  });

  test('memo does not confuse two strings with the same length', () {
    expect(getTextDirection('abcd'), TextDirection.ltr);
    expect(getTextDirection('سلام'), TextDirection.rtl);
    expect(getTextDirection('abcd'), TextDirection.ltr);
    expect(getTextDirection('سلام'), TextDirection.rtl);
    expect(textDirectionCacheLength, 2);
  });

  test('clearTextDirectionCache empties the memo without changing answers', () {
    expect(getTextDirection('سلام'), TextDirection.rtl);
    expect(textDirectionCacheLength, 1);
    clearTextDirectionCache();
    expect(textDirectionCacheLength, 0);
    expect(getTextDirection('سلام'), TextDirection.rtl);
  });
}
