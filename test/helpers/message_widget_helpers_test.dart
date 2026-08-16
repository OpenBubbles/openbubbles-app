import 'package:bluebubbles/database/global/message_part.dart';
import 'package:bluebubbles/helpers/ui/message_widget_helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuple/tuple.dart';

void main() {
  group('messageUrlMatches', () {
    test('finds separate same-host URLs with different paths', () {
      const first = 'https://example.com/one';
      const second = 'https://example.com/two';

      final matches = messageUrlMatches('$first and $second');

      expect(matches.map((match) => match.group(0)), [first, second]);
    });

    test(
      'keeps query, plus, percent, fragment, and parentheses characters',
      () {
        const url =
            r'https://example.com/path/(part)?q=alpha+beta%2Bgamma#section-1';

        final matches = messageUrlMatches('Open $url please');

        expect(matches, hasLength(1));
        expect(matches.single.group(0), url);
      },
    );

    test('does not include sentence punctuation after a URL', () {
      const url = 'https://example.com/path?value=one+two';

      final matches = messageUrlMatches('Read $url. Then continue.');

      expect(matches, hasLength(1));
      expect(matches.single.group(0), url);
    });

    test('accepts modern top-level domains longer than six characters', () {
      const url = 'https://example.technology/path';

      final matches = messageUrlMatches(url);

      expect(matches, hasLength(1));
      expect(matches.single.group(0), url);
    });
  });

  test('preserves the complete URL when another annotation ends at a plus', () {
    const url = 'https://example.com/path?query=alpha+beta&next=1';
    final plusIndex = url.indexOf('+');
    final annotations = [
      Annotation(range: [0, url.length]),
    ];

    markEnrichedMessageRange(
      annotations,
      const Tuple3('link', [0, url.length], null),
    );
    markEnrichedMessageRange(annotations, Tuple3('link', [0, plusIndex], null));
    annotations.sort((a, b) => a.range[0].compareTo(b.range[0]));

    expect(annotations.map((annotation) => annotation.range), [
      [0, plusIndex],
      [plusIndex, url.length],
    ]);
    expect(
      annotations.every(
        (annotation) => annotation.renderExtras.first.item1 == 'link',
      ),
      isTrue,
    );
  });
}
