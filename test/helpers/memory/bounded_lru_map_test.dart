import 'package:bluebubbles/helpers/memory/bounded_lru_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads update recency before entry-count eviction', () {
    final cache = BoundedLruMap<String, String>(maximumEntries: 2);

    cache['first'] = 'one';
    cache['second'] = 'two';
    expect(cache['first'], 'one');
    cache['third'] = 'three';

    expect(cache['first'], 'one');
    expect(cache['second'], isNull);
    expect(cache['third'], 'three');
  });

  test('weight budget evicts the least recently used values', () {
    final cache = BoundedLruMap<String, String>(
      maximumEntries: 10,
      maximumWeight: 8,
      weightOf: (value) => value.length,
    );

    cache['first'] = '1234';
    cache['second'] = '5678';
    cache['third'] = 'abc';

    expect(cache['first'], isNull);
    expect(cache['second'], '5678');
    expect(cache['third'], 'abc');
    expect(cache.currentWeight, 7);
  });

  test('replacement, removal, and clear maintain weight accounting', () {
    final cache = BoundedLruMap<String, String>(
      maximumEntries: 4,
      maximumWeight: 20,
      weightOf: (value) => value.length,
    );

    cache['item'] = '12345678';
    cache['item'] = '123';
    expect(cache.currentWeight, 3);

    expect(cache.remove('item'), '123');
    expect(cache.currentWeight, 0);

    cache['first'] = '1';
    cache['second'] = '22';
    cache.clear();
    expect(cache.length, 0);
    expect(cache.currentWeight, 0);
  });

  test('does not retain a value larger than the entire weight budget', () {
    final cache = BoundedLruMap<String, String>(
      maximumEntries: 4,
      maximumWeight: 5,
      weightOf: (value) => value.length,
    );

    cache['small'] = '123';
    cache['oversized'] = '123456';

    expect(cache['small'], '123');
    expect(cache['oversized'], isNull);
    expect(cache.currentWeight, 3);
  });

  test('copy-on-write replacement keeps nested weight accurate', () {
    final cache = BoundedLruMap<String, Map<String, String>>(
      maximumEntries: 4,
      maximumWeight: 10,
      weightOf: (value) =>
          value.values.fold(0, (total, item) => total + item.length),
    );

    cache['message'] = {'first': '1234'};
    final replacement = Map<String, String>.from(cache['message'] ?? const {});
    replacement['second'] = '567';
    cache['message'] = replacement;

    expect(cache['message'], containsPair('first', '1234'));
    expect(cache['message'], containsPair('second', '567'));
    expect(cache.currentWeight, 7);
  });

  test('oversized replacement removes the stale same-key value', () {
    final cache = BoundedLruMap<String, String>(
      maximumEntries: 4,
      maximumWeight: 5,
      weightOf: (value) => value.length,
    );

    cache['item'] = '123';
    cache['item'] = '123456';

    expect(cache['item'], isNull);
    expect(cache.currentWeight, 0);
  });
}
