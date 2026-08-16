import 'package:bluebubbles/helpers/ui/reaction_helpers.dart';
import 'package:bluebubbles/services/rustpush/cloud_sync/cloud_associated_message_parent_reference.dart';
import 'package:bluebubbles/utils/attachment_guid_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guid = 'ABCDEF12-3456-7890-ABCD-EF1234567890';

  test('accepts bare, p, and bp CloudKit parent forms', () {
    final bare = CloudAssociatedMessageParentReference.parse(guid);
    final part = CloudAssociatedMessageParentReference.parse('p:3/$guid');
    final bubble = CloudAssociatedMessageParentReference.parse('bp:4/$guid');

    expect(bare.localMessageGuid, guid);
    expect(bare.part, isNull);
    expect(part.localMessageGuid, guid);
    expect(part.part, 3);
    expect(bubble.localMessageGuid, guid);
    expect(bubble.part, 4);
  });

  test('encodes partless parents without a p:null wrapper', () {
    expect(
      CloudAssociatedMessageParentReference.encode(
        localMessageGuid: guid,
        part: null,
      ),
      guid,
    );
    expect(
      CloudAssociatedMessageParentReference.encode(
        localMessageGuid: guid,
        part: 0,
      ),
      'p:0/$guid',
    );
    final decoded = CloudAssociatedMessageParentReference.parse(
      CloudAssociatedMessageParentReference.encode(
        localMessageGuid: guid,
        part: null,
      )!,
    );
    expect(decoded.localMessageGuid, guid);
    expect(decoded.part, isNull);
  });

  test('rejects malformed parent forms without exposing the input', () {
    for (final value in [
      '',
      '0/$guid',
      'bpdi:0/$guid',
      'p:01/$guid',
      'p:x/$guid',
      'p:0/$guid/extra',
    ]) {
      Object? caught;
      try {
        CloudAssociatedMessageParentReference.parse(value);
      } catch (error) {
        caught = error;
      }

      expect(caught,
          isA<CloudAssociatedMessageParentReferenceFormatException>());
      if (value.isNotEmpty) {
        expect(caught.toString(), isNot(contains(value)));
      }
    }
  });

  test('maps known reaction types and ignores newer unknown types', () {
    expect(ReactionTypes.fromAssociatedMessageType(2000), 'love');
    expect(ReactionTypes.fromAssociatedMessageType(3001), '-like');
    expect(ReactionTypes.fromAssociatedMessageType(2008), isNull);
    expect(ReactionTypes.fromAssociatedMessageType(4000), isNull);
  });

  test('parses owned attachment GUIDs without losing underscores', () {
    final parsed = parseAppleOwnedAttachmentGuid('at_12/message_guid_42');
    expect(parsed, isNull);

    final owned = parseAppleOwnedAttachmentGuid('at_12_message_guid_42');
    expect(owned!.part, '12');
    expect(owned.messageGuid, 'message_guid_42');
    expect(convertAppleAttachmentGuid('at_12_message_guid_42'),
        'message_guid_42_12');
    expect(unconvertAppleAttachmentGuid('message_guid_42_12'),
        'at_12_message_guid_42');
    expect(convertAppleAttachmentGuid('at_01_message_guid'),
        'at_01_message_guid');
  });
}
