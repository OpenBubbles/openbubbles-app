import 'package:bluebubbles/services/rustpush/relay_health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final checkedAt = DateTime.utc(2026, 8, 15, 12);

  test('a recent successful probe is healthy', () {
    final snapshot = RelayHealthSnapshot(
      reachable: true,
      lastChecked: DateTime.utc(2026, 8, 15, 12),
    );

    expect(
      snapshot.statusAt(checkedAt.add(const Duration(minutes: 5))),
      RelayHealthStatus.healthy,
    );
  });

  test('an old successful probe is stale', () {
    final snapshot = RelayHealthSnapshot(
      reachable: true,
      lastChecked: DateTime.utc(2026, 8, 15, 11),
    );

    expect(snapshot.statusAt(checkedAt), RelayHealthStatus.stale);
  });

  test('a failed probe is offline and retains the last success', () {
    final snapshot = RelayHealthSnapshot(
      reachable: true,
      lastChecked: checkedAt,
      lastSuccess: checkedAt,
    );

    final transition = snapshot.afterProbe(
      isReachable: false,
      checkedAt: checkedAt.add(const Duration(minutes: 1)),
    );

    expect(
      transition.snapshot.statusAt(checkedAt.add(const Duration(minutes: 1))),
      RelayHealthStatus.offline,
    );
    expect(transition.snapshot.lastSuccess, checkedAt);
    expect(transition.recovered, isFalse);
  });

  test('a successful probe after offline is recovered and healthy', () {
    final offline = RelayHealthSnapshot(
      reachable: false,
      lastChecked: checkedAt,
    );

    final transition = offline.afterProbe(
      isReachable: true,
      checkedAt: checkedAt.add(const Duration(minutes: 2)),
    );

    expect(transition.recovered, isTrue);
    expect(
      transition.snapshot.statusAt(checkedAt.add(const Duration(minutes: 2))),
      RelayHealthStatus.healthy,
    );
    expect(
      transition.snapshot.lastSuccess,
      checkedAt.add(const Duration(minutes: 2)),
    );
  });

  test('only non-hosted Apple mobile relays are eligible', () {
    expect(
      isUserManagedIPhoneRelay(deviceName: "iPhone 15 Pro", hosted: false),
      isTrue,
    );
    expect(
      isUserManagedIPhoneRelay(deviceName: "MacBookPro18,3", hosted: false),
      isFalse,
    );
    expect(
      isUserManagedIPhoneRelay(deviceName: "iPhone 15 Pro", hosted: true),
      isFalse,
    );
  });
}
