import 'dart:typed_data';

import 'package:bluebubbles/helpers/memory/bounded_byte_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Uint8List bytes(int length, int marker) =>
      Uint8List.fromList(List<int>.filled(length, marker));

  test('evicts least recently used bytes when the byte budget is exceeded', () {
    final cache = BoundedByteCache(maximumSizeBytes: 10, maximumEntries: 10);

    cache['first'] = bytes(4, 1);
    cache['second'] = bytes(4, 2);
    expect(cache['first'], isNotNull); // Make second the least-recently used.
    cache['third'] = bytes(4, 3);

    expect(cache['first'], isNotNull);
    expect(cache['second'], isNull);
    expect(cache['third'], isNotNull);
    expect(cache.currentSizeBytes, 8);
  });

  test('evicts least recently used entries when the entry limit is exceeded',
      () {
    final cache = BoundedByteCache(maximumSizeBytes: 100, maximumEntries: 2);

    cache['first'] = bytes(1, 1);
    cache['second'] = bytes(1, 2);
    cache['third'] = bytes(1, 3);

    expect(cache['first'], isNull);
    expect(cache['second'], isNotNull);
    expect(cache['third'], isNotNull);
    expect(cache.length, 2);
  });

  test('replacement and removal keep byte accounting accurate', () {
    final cache = BoundedByteCache(maximumSizeBytes: 20, maximumEntries: 4);

    cache['item'] = bytes(8, 1);
    cache['item'] = bytes(3, 2);
    expect(cache.currentSizeBytes, 3);

    expect(cache.remove('item'), isNotNull);
    expect(cache.currentSizeBytes, 0);
    expect(cache.isEmpty, isTrue);
  });

  test('does not retain one item larger than the entire cache budget', () {
    final cache = BoundedByteCache(maximumSizeBytes: 10, maximumEntries: 4);

    cache['small'] = bytes(4, 1);
    cache['oversized'] = bytes(11, 2);

    expect(cache['small'], isNotNull);
    expect(cache['oversized'], isNull);
    expect(cache.currentSizeBytes, 4);
  });

  test('oversized replacement removes the stale same-key value', () {
    final cache = BoundedByteCache(maximumSizeBytes: 10, maximumEntries: 4);

    cache['item'] = bytes(4, 1);
    cache['item'] = bytes(11, 2);

    expect(cache['item'], isNull);
    expect(cache.currentSizeBytes, 0);
  });
}
