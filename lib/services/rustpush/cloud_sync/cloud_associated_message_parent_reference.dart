/// A validated CloudKit reference to the local parent of an associated message.
///
/// Apple uses `p:<part>/<message-guid>` for a specific message part,
/// `bp:<part>/<message-guid>` for a bubble or tapback message, and a bare
/// `<message-guid>` when the reaction targets the whole message. The raw value
/// is accepted only at this parsing boundary and is never retained in errors.
final class CloudAssociatedMessageParentReference {
  const CloudAssociatedMessageParentReference._({
    required this.part,
    required this.localMessageGuid,
  });

  static const int maximumGuidCodeUnits = 512;
  static const int _maximumPartDigits = 19;

  /// Null when Apple sent a bare GUID for a whole-message reaction.
  final int? part;
  final String localMessageGuid;

  /// Encodes the legacy CloudKit parent form used by uploads.
  static String? encode({String? localMessageGuid, int? part}) {
    if (localMessageGuid == null) return null;
    return part == null ? localMessageGuid : 'p:$part/$localMessageGuid';
  }

  static CloudAssociatedMessageParentReference parse(String encoded) {
    const prefix = 'p:';
    const bubblePrefix = 'bp:';
    const separatorLength = 1;
    const maximumEncodedCodeUnits =
        bubblePrefix.length +
        _maximumPartDigits +
        separatorLength +
        maximumGuidCodeUnits;
    if (encoded.length > maximumEncodedCodeUnits) {
      throw const CloudAssociatedMessageParentReferenceFormatException();
    }

    final matchedPrefix = encoded.startsWith(prefix)
        ? prefix
        : (encoded.startsWith(bubblePrefix) ? bubblePrefix : null);
    if (matchedPrefix == null) {
      if (encoded.contains('/') ||
          encoded.contains(':') ||
          !_isValidGuid(encoded)) {
        throw const CloudAssociatedMessageParentReferenceFormatException();
      }
      return CloudAssociatedMessageParentReference._(
        part: null,
        localMessageGuid: encoded,
      );
    }

    final separator = encoded.indexOf('/', matchedPrefix.length);
    if (separator == -1 ||
        encoded.indexOf('/', separator + 1) != -1 ||
        separator == matchedPrefix.length) {
      throw const CloudAssociatedMessageParentReferenceFormatException();
    }

    final encodedPart = encoded.substring(matchedPrefix.length, separator);
    if (encodedPart.length > _maximumPartDigits ||
        !_isAsciiDecimal(encodedPart) ||
        (encodedPart.length > 1 && encodedPart.startsWith('0'))) {
      throw const CloudAssociatedMessageParentReferenceFormatException();
    }
    final part = int.tryParse(encodedPart);
    if (part == null || part < 0) {
      throw const CloudAssociatedMessageParentReferenceFormatException();
    }

    final guid = encoded.substring(separator + 1);
    if (!_isValidGuid(guid)) {
      throw const CloudAssociatedMessageParentReferenceFormatException();
    }

    return CloudAssociatedMessageParentReference._(
      part: part,
      localMessageGuid: guid,
    );
  }

  static bool _isAsciiDecimal(String value) {
    for (final codeUnit in value.codeUnits) {
      if (codeUnit < 0x30 || codeUnit > 0x39) return false;
    }
    return value.isNotEmpty;
  }

  static bool _isValidGuid(String value) {
    if (value.isEmpty || value.length > maximumGuidCodeUnits) return false;
    for (final codeUnit in value.codeUnits) {
      if (codeUnit <= 0x20 ||
          (codeUnit >= 0x7f && codeUnit <= 0x9f) ||
          codeUnit == 0x2028 ||
          codeUnit == 0x2029) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is CloudAssociatedMessageParentReference &&
      other.part == part &&
      other.localMessageGuid == localMessageGuid;

  @override
  int get hashCode => Object.hash(part, localMessageGuid);

  @override
  String toString() => 'CloudAssociatedMessageParentReference(redacted)';
}

/// A deliberately redacted parse failure.
final class CloudAssociatedMessageParentReferenceFormatException
    implements FormatException {
  const CloudAssociatedMessageParentReferenceFormatException();

  static const String safeCode = 'invalid_associated_message_parent_reference';

  @override
  String get message => safeCode;

  @override
  int? get offset => null;

  @override
  Object? get source => null;

  @override
  String toString() =>
      'CloudAssociatedMessageParentReferenceFormatException($safeCode)';
}
