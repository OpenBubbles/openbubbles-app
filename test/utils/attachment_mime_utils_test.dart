import 'package:bluebubbles/utils/attachment_mime_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAttachmentMimeType', () {
    test('resolves PDF filenames', () {
      expect(resolveAttachmentMimeType('report.pdf', null), 'application/pdf');
    });

    test('resolves DOCX filenames', () {
      expect(
        resolveAttachmentMimeType('report.docx', null),
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    });

    test('resolves XLSX filenames', () {
      expect(
        resolveAttachmentMimeType('report.xlsx', null),
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    });

    test('resolves PPTX filenames', () {
      expect(
        resolveAttachmentMimeType('report.pptx', null),
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      );
    });

    test('resolves plain text filenames', () {
      expect(resolveAttachmentMimeType('notes.txt', null), 'text/plain');
    });

    test('leaves unknown binary filenames unresolved', () {
      expect(resolveAttachmentMimeType('payload.unknown', null), isNull);
    });

    test('falls back to a path extension when the filename has none', () {
      expect(
        resolveAttachmentMimeType('document', '/tmp/document.pdf'),
        'application/pdf',
      );
    });
  });
}
