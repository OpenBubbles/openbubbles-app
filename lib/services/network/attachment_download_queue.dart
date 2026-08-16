class AttachmentDownloadQueue<T> {
  final Map<String, List<T>> _queues = <String, List<T>>{};

  Iterable<T> get all => _queues.values.expand((items) => items);

  List<T> forChat(String chatGuid) =>
      List<T>.unmodifiable(_queues[chatGuid] ?? <T>[]);

  void add(String chatGuid, T item, {bool prioritized = false}) {
    final queue = _queues.putIfAbsent(chatGuid, () => <T>[]);
    if (queue.contains(item)) {
      if (prioritized) prioritize(chatGuid, item);
      return;
    }
    if (prioritized) {
      queue.insert(0, item);
    } else {
      queue.add(item);
    }
  }

  bool remove(String chatGuid, T item) {
    final queue = _queues[chatGuid];
    if (queue == null || !queue.remove(item)) return false;
    if (queue.isEmpty) _queues.remove(chatGuid);
    return true;
  }

  bool prioritize(String chatGuid, T item) {
    final queue = _queues[chatGuid];
    if (queue == null || !queue.remove(item)) return false;
    queue.insert(0, item);
    return true;
  }

  T? next({String? activeChatGuid, required bool Function(T) isFetching}) {
    final activeQueue = activeChatGuid == null ? null : _queues[activeChatGuid];
    if (activeQueue != null) {
      for (final item in activeQueue) {
        if (!isFetching(item)) return item;
      }
    }

    for (final item in all) {
      if (!isFetching(item)) return item;
    }
    return null;
  }
}
