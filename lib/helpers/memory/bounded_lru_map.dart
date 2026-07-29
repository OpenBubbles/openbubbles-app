import 'dart:collection';

/// A least-recently-used map bounded by entry count and optional weight.
class BoundedLruMap<K, V> {
  BoundedLruMap({
    required this.maximumEntries,
    this.maximumWeight,
    int Function(V value)? weightOf,
  })  : assert(maximumEntries > 0),
        assert(maximumWeight == null || maximumWeight > 0),
        _weightOf = weightOf ?? ((_) => 1);

  final int maximumEntries;
  final int? maximumWeight;
  final int Function(V value) _weightOf;
  final LinkedHashMap<K, V> _entries = LinkedHashMap();
  int _currentWeight = 0;

  int get length => _entries.length;
  int get currentWeight => _currentWeight;
  Iterable<K> get keys => _entries.keys;
  Iterable<MapEntry<K, V>> get entries => _entries.entries;

  bool containsKey(Object? key) => _entries.containsKey(key);

  V? operator [](Object? key) {
    final value = _entries.remove(key);
    if (value == null) return null;
    _entries[key as K] = value;
    return value;
  }

  void operator []=(K key, V value) {
    final previous = _entries.remove(key);
    if (previous != null) {
      _currentWeight -= _weightOf(previous);
    }

    final weight = _weightOf(value);
    if (maximumWeight != null && weight > maximumWeight!) {
      return;
    }

    _entries[key] = value;
    _currentWeight += weight;
    _evictToBudget();
  }

  V? remove(Object? key) {
    final removed = _entries.remove(key);
    if (removed != null) {
      _currentWeight -= _weightOf(removed);
    }
    return removed;
  }

  void clear() {
    _entries.clear();
    _currentWeight = 0;
  }

  void _evictToBudget() {
    while (_entries.isNotEmpty &&
        (_entries.length > maximumEntries ||
            (maximumWeight != null && _currentWeight > maximumWeight!))) {
      final oldestKey = _entries.keys.first;
      final oldest = _entries.remove(oldestKey) as V;
      _currentWeight -= _weightOf(oldest);
    }
  }
}
