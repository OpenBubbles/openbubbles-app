import 'dart:async';

import 'package:bluebubbles/app/layouts/findmy/findmy_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('relay offline errors provide recovery guidance', () {
    expect(
      findMyCloudFailureMessage(Exception('Relay device offline')),
      contains('relay device is offline'),
    );
  });

  test('timeouts provide retry guidance', () {
    expect(
      findMyCloudFailureMessage(TimeoutException('request')),
      contains('timed out'),
    );
  });

  test('unknown failures do not expose exception details', () {
    expect(
      findMyCloudFailureMessage(Exception('private relay detail')),
      'Cloud Find My is unavailable right now.',
    );
  });
}
