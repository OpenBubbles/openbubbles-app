import 'package:bluebubbles/app/components/custom_text_editing_controllers.dart';
import 'package:bluebubbles/database/global/message_part.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeComposerAnnotationCoverage', () {
    test('fills a transient gap without discarding valid formatting', () {
      final annotations = [
        Annotation(range: [0, 3], bold: true),
        Annotation(range: [5, 8], italic: true),
      ];

      normalizeComposerAnnotationCoverage(annotations, 10);

      expect(annotations.map((annotation) => annotation.range), [
        [0, 3],
        [3, 5],
        [5, 8],
        [8, 10],
      ]);
      expect(annotations.first.bold, isTrue);
      expect(annotations[2].italic, isTrue);
    });

    test('clips overlaps into a single complete partition', () {
      final annotations = [
        Annotation(range: [-2, 4], bold: true),
        Annotation(range: [2, 8], italic: true),
        Annotation(range: [8, 20]),
      ];

      normalizeComposerAnnotationCoverage(annotations, 10);

      expect(annotations.map((annotation) => annotation.range), [
        [0, 4],
        [4, 8],
        [8, 10],
      ]);
      expect(annotations.first.bold, isTrue);
      expect(annotations[1].italic, isTrue);
    });

    test('merges adjacent plain ranges and clears empty text', () {
      final annotations = [
        Annotation(range: [0, 2]),
        Annotation(range: [2, 4]),
      ];

      normalizeComposerAnnotationCoverage(annotations, 4);
      expect(annotations.map((annotation) => annotation.range), [
        [0, 4],
      ]);

      normalizeComposerAnnotationCoverage(annotations, 0);
      expect(annotations, isEmpty);
    });
  });
}
