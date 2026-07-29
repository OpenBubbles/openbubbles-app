import 'dart:collection';
import 'dart:typed_data';

/// A byte-aware least-recently-used cache.
///
/// Flutter's global [ImageCache] limits decoded images, but OpenBubbles also
/// retains encoded attachment bytes in conversation state. This cache bounds
/// that separate allocation and evicts the least recently accessed entries.
class BoundedByteCache {
  BoundedByteCache({
    required this.maximumSizeBytes,
    required this.maximumEntries,
  })  : assert(maximumSizeBytes > 0),
        assert(maximumEntries > 0);

  final int maximumSizeBytes;
  final int maximumEntries;
  final LinkedHashMap<String, Uint8List> _entries = LinkedHashMap();
  int _currentSizeBytes = 0;

  int get currentSizeBytes => _currentSizeBytes;
  int get length => _entries.length;
  bool get isEmpty => _entries.isEmpty;

  bool containsKey(String? key) => key != null && _entries.containsKey(key);

  Uint8List? operator [](String? key) {
    if (key == null) return null;
    final value = _entries.remove(key);
    if (value == null) return null;
    _entries[key] = value;
    return value;
  }

  void operator []=(String key, Uint8List value) {
    final previous = _entries.remove(key);
    if (previous != null) {
      _currentSizeBytes -= previous.lengthInBytes;
    }

    // An entry larger than the full budget is useful to the active widget but
    // must not evict the entire cache and then remain resident indefinitely.
    if (value.lengthInBytes > maximumSizeBytes) {
      return;
    }

    _entries[key] = value;
    _currentSizeBytes += value.lengthInBytes;
    _evictToBudget();
  }

  Uint8List? remove(String? key) {
    if (key == null) return null;
    final removed = _entries.remove(key);
    if (removed != null) {
      _currentSizeBytes -= removed.lengthInBytes;
    }
    return removed;
  }

  void clear() {
    _entries.clear();
    _currentSizeBytes = 0;
  }

  void _evictToBudget() {
    while (_entries.isNotEmpty &&
        (_entries.length > maximumEntries ||
            _currentSizeBytes > maximumSizeBytes)) {
      final oldestKey = _entries.keys.first;
      final oldest = _entries.remove(oldestKey)!;
      _currentSizeBytes -= oldest.lengthInBytes;
    }
  }
}
