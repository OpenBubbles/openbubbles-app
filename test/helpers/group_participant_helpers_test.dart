import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/group_participant_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reconcileGroupParticipants', () {
    test('replaces a participant when group size is unchanged', () {
      final existing = Handle(address: 'old@example.com');
      final retained = Handle(address: 'kept@example.com');
      final replacement = Handle(address: 'new@example.com');

      final result = reconcileGroupParticipants(
        [existing, retained],
        [replacement, Handle(address: 'kept@example.com')],
      );

      expect(result, hasLength(2));
      expect(result[0], same(replacement));
      expect(result[1], same(retained));
    });

    test('keeps every new participant and removes duplicate identities', () {
      final result = reconcileGroupParticipants(
        [],
        [
          Handle(address: 'one@example.com'),
          Handle(address: 'two@example.com'),
          Handle(address: 'two@example.com'),
          Handle(address: 'three@example.com'),
        ],
      );

      expect(result.map((handle) => handle.address),
          ['one@example.com', 'two@example.com', 'three@example.com']);
    });

    test('distinguishes the same address on different services', () {
      final sms = Handle(address: '+15550000001', service: 'SMS');
      final imessage = Handle(address: '+15550000001', service: 'iMessage');

      final result = reconcileGroupParticipants([sms], [imessage]);

      expect(result, hasLength(1));
      expect(result.single, same(imessage));
    });
  });
}
