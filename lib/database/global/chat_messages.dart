import 'package:bluebubbles/database/models.dart';

class ChatMessages {
  static const int _maxPendingReactionsPerMessage = 32;
  static const int _maxPendingReactionParents = 128;
  final Map<String, Message> _messages = {};
  final Map<String, Message> _reactions = {};
  final Map<String, Map<String, Message>> _pendingReactions = {};
  final Map<String, Attachment> _attachments = {};
  final Map<String, Map<String, Message>> _threads = {};
  final Map<String, Map<String, Message>> _edits = {};

  bool get isEmpty => _messages.isEmpty;
  bool get isNotEmpty => _messages.isNotEmpty;
  List<Message> get messages => _messages.values.toList();
  List<Message> get reactions => _reactions.values.toList();
  List<Attachment> get attachments => _attachments.values.toList();
  List<Message> threads(String originatorGuid, int originatorPart, {bool returnOriginator = true}) =>
      _threads[originatorGuid]?.values.where((e) =>
      (e.normalizedThreadPart == originatorPart && e.guid != originatorGuid) || (returnOriginator ? e.guid == originatorGuid : false)).toList() ?? [];

  void addMessages(List<Message> __messages) {
    for (Message m in __messages) {
      if (m.associatedMessageGuid != null) {
        // add reactions
        _reactions[m.guid!] = m;
        final parent = getMessage(m.associatedMessageGuid!);
        if (parent != null) {
          _attachReaction(parent, m);
        } else {
          final parentGuid = m.associatedMessageGuid!;
          var pending = _pendingReactions[parentGuid];
          if (pending == null) {
            if (_pendingReactions.length >= _maxPendingReactionParents) {
              _pendingReactions.remove(_pendingReactions.keys.first);
            }
            pending = <String, Message>{};
            _pendingReactions[parentGuid] = pending;
          }
          // A malformed or delayed stream must not grow this cache forever.
          // The database sync remains the source of truth if an item is
          // evicted before its parent arrives.
          if (pending.length >= _maxPendingReactionsPerMessage &&
              !pending.containsKey(m.guid)) {
            pending.remove(pending.keys.first);
          }
          pending[m.guid!] = m;
        }
      } else {
        // add regular texts
        _messages[m.guid!] = m;
        final pending = _pendingReactions.remove(m.guid);
        if (pending != null) {
          for (final reaction in pending.values) {
            _attachReaction(m, reaction);
          }
        }
      }
      if (m.threadOriginatorGuid != null && !m.guid!.startsWith("temp") && m.associatedMessageGuid == null) {
        // add threaded messages
        _threads[m.threadOriginatorGuid!] ??= {};
        _threads[m.threadOriginatorGuid]![m.guid!] = m;
      }
      if (_threads.keys.contains(m.guid)) {
        // add thread 'originator'
        _threads[m.guid]![m.guid!] = m;
      }
      _attachments.addEntries(m.attachments.map((e) => MapEntry(e!.guid!, e)));
    }
  }

  void _attachReaction(Message parent, Message reaction) {
    if (!parent.associatedMessages.any((item) => item.guid == reaction.guid)) {
      parent.associatedMessages.add(reaction);
    }
    parent.hasReactions = true;
  }

  void removeMessage(String guid) {
    _messages.remove(guid);
    _reactions.remove(guid);
    _pendingReactions.remove(guid);
    final result = _threads.remove(guid);
    if (result == null) {
      for (Map element in _threads.values) {
        element.remove(guid);
      }
    }
    final result2 = _edits.remove(guid);
    if (result2 == null) {
      for (Map element in _edits.values) {
        element.remove(guid);
      }
    }
  }

  void removeAttachments(Iterable<String> guids) {
    for (String s in guids) {
      _attachments.remove(s);
    }
  }

  void addThreadOriginator(Message m) {
    _threads[m.guid!] ??= {};
    _threads[m.guid]![m.guid!] = m;
  }

  Message? getMessage(String guid) {
    return _messages[guid] ?? _reactions[guid];
  }

  Attachment? getAttachment(String guid) {
    return _attachments[guid];
  }

  // It isn't guaranteed that the thread originator will be in the regular
  // messages list, in case it is much older than the currently loaded messages.
  // Prefer to use this method to find originator.
  Message? getThreadOriginator(String guid) {
    final fromOriginatorList = _threads[guid]?[guid];
    if (fromOriginatorList == null) {
      final message = getMessage(guid);
      if (message != null) addThreadOriginator(message);
      return message;
    } else {
      return fromOriginatorList;
    }
  }

  Message? getPreviousReply(String threadGuid, int threadPart, String messageGuid) {
    final thread = threads(threadGuid, threadPart)..sort((a, b) => Message.sort(a, b, descending: false));
    final index = thread.indexWhere((element) => element.guid == messageGuid);
    if (index > 0) {
      return thread[index - 1];
    }
    return null;
  }

  flush() {
    _messages.clear();
    _reactions.clear();
    _pendingReactions.clear();
    _attachments.clear();
    _threads.clear();
    _edits.clear();
  }
}
