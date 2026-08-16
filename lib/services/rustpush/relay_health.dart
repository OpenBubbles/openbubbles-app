enum RelayHealthStatus { unknown, healthy, stale, offline }

const relayHealthStaleAfter = Duration(minutes: 30);

bool isUserManagedIPhoneRelay({
  required String deviceName,
  required bool hosted,
}) {
  if (hosted) return false;

  final normalizedName = deviceName.toLowerCase();
  return normalizedName.contains("iphone") ||
      normalizedName.contains("ipad") ||
      normalizedName.contains("ipod");
}

class RelayHealthSnapshot {
  final bool? reachable;
  final DateTime? lastChecked;
  final DateTime? lastSuccess;

  const RelayHealthSnapshot({
    this.reachable,
    this.lastChecked,
    this.lastSuccess,
  });

  RelayHealthStatus statusAt(
    DateTime now, {
    Duration staleAfter = relayHealthStaleAfter,
  }) {
    if (reachable == false) return RelayHealthStatus.offline;
    if (reachable != true || lastChecked == null) {
      return RelayHealthStatus.unknown;
    }

    final age = now.toUtc().difference(lastChecked!.toUtc());
    return age <= staleAfter
        ? RelayHealthStatus.healthy
        : RelayHealthStatus.stale;
  }

  RelayHealthTransition afterProbe({
    required bool isReachable,
    required DateTime checkedAt,
  }) {
    final next = RelayHealthSnapshot(
      reachable: isReachable,
      lastChecked: checkedAt,
      lastSuccess: isReachable ? checkedAt : lastSuccess,
    );
    return RelayHealthTransition(
      snapshot: next,
      recovered: reachable == false && isReachable,
    );
  }
}

class RelayHealthTransition {
  final RelayHealthSnapshot snapshot;
  final bool recovered;

  const RelayHealthTransition({
    required this.snapshot,
    required this.recovered,
  });
}
