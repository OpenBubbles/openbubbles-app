enum ProfileFailureKind { transient, permanent }

class ProfileRetryPolicy {
  ProfileRetryPolicy({
    this.delays = const <Duration>[
      Duration(seconds: 5),
      Duration(seconds: 30),
      Duration(minutes: 2),
    ],
  });

  final List<Duration> delays;
  final Map<String, int> _attempts = <String, int>{};
  final Set<String> _scheduled = <String>{};

  ProfileFailureKind classify(Object error) {
    final description = error.toString().toLowerCase();
    if (description.contains("profile service unavailable") ||
        description.contains("timeout") ||
        description.contains("connection") ||
        description.contains("network") ||
        description.contains("socket") ||
        description.contains("dns")) {
      return ProfileFailureKind.transient;
    }
    return ProfileFailureKind.permanent;
  }

  bool get isEmpty => _attempts.isEmpty && _scheduled.isEmpty;

  bool isScheduled(String profileKey) => _scheduled.contains(profileKey);

  Duration? schedule(String profileKey) {
    if (!_scheduled.add(profileKey)) return null;
    final attempt = _attempts[profileKey] ?? 0;
    if (attempt >= delays.length) {
      _scheduled.remove(profileKey);
      _attempts.remove(profileKey);
      return null;
    }
    _attempts[profileKey] = attempt + 1;
    return delays[attempt];
  }

  void timerFired(String profileKey) {
    _scheduled.remove(profileKey);
  }

  void complete(String profileKey) {
    _scheduled.remove(profileKey);
    _attempts.remove(profileKey);
  }

  void clear() {
    _scheduled.clear();
    _attempts.clear();
  }
}
