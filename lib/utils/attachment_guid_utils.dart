// Apple represents an attachment owned by a message as `at_<part>_<message
// guid>`, and OpenBubbles stores the same identity locally as
// `<message guid>_<part>`.
//
// A message GUID can contain underscores, so conversion must split only at the
// separator adjacent to the part number. Invalid identifiers are returned
// unchanged because they are parsed on the CloudKit download path.

class AppleOwnedAttachmentGuid {
  const AppleOwnedAttachmentGuid({
    required this.part,
    required this.messageGuid,
  });

  final String part;
  final String messageGuid;
}

AppleOwnedAttachmentGuid? parseAppleOwnedAttachmentGuid(String guid) {
  const prefix = 'at_';
  if (!guid.startsWith(prefix)) return null;
  final remainder = guid.substring(prefix.length);
  final separator = remainder.indexOf('_');
  if (separator <= 0 || separator >= remainder.length - 1) return null;
  final part = remainder.substring(0, separator);
  if (!_isCanonicalDecimal(part)) return null;
  return AppleOwnedAttachmentGuid(
    part: part,
    messageGuid: remainder.substring(separator + 1),
  );
}

bool _isCanonicalDecimal(String value) {
  if (value.isEmpty) return false;
  for (final unit in value.codeUnits) {
    if (unit < 0x30 || unit > 0x39) return false;
  }
  return value == '0' || value.codeUnitAt(0) != 0x30;
}

String convertAppleAttachmentGuid(String guid) {
  final owned = parseAppleOwnedAttachmentGuid(guid);
  if (owned == null) return guid;
  return '${owned.messageGuid}_${owned.part}';
}

String unconvertAppleAttachmentGuid(String guid) {
  final separator = guid.lastIndexOf('_');
  if (separator <= 0 || separator >= guid.length - 1) return guid;
  final part = guid.substring(separator + 1);
  if (!_isCanonicalDecimal(part)) return guid;
  return 'at_${part}_${guid.substring(0, separator)}';
}
