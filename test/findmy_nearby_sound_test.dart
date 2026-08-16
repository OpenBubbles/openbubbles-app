import 'package:bluebubbles/app/layouts/findmy/findmy_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nearby Find My sound', () {
    test('is limited to Android accessory rows', () {
      expect(canPlayNearbyFindMySound(isAccessory: true, isAndroid: true), isTrue);
      expect(canPlayNearbyFindMySound(isAccessory: true, isAndroid: false), isFalse);
      expect(canPlayNearbyFindMySound(isAccessory: false, isAndroid: true), isFalse);
    });

    test('shows RSSI when the scan provides it', () {
      expect(
        nearbyTrackerSignalLabel({'signal': 'strong', 'rssi': -47}),
        'Strong signal (-47 dBm)',
      );
      expect(nearbyTrackerSignalLabel({'signal': 'weak'}), 'Weak signal');
    });
  });
}
