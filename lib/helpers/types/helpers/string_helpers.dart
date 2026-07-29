import 'dart:math';

import 'package:bluebubbles/helpers/helpers.dart';

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

String randomString(int length) =>
    String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(Random().nextInt(_chars.length))));

/// Failed messages stash their error inside the GUID as `error-<error>-<random suffix>`
/// (the suffix is left over from the original `temp-<random>` GUID), so strip the
/// leftovers back off before showing the error to the user.
final RegExp _errorGuidRegex = RegExp(r'^error-(.*?)(?:-[A-Za-z0-9]{8})?$', dotAll: true);

String errorFromGuid(String guid) =>
    _errorGuidRegex.firstMatch(guid)?.group(1) ?? guid.substring(guid.indexOf('-') + 1);

String sanitizeString(String? input) {
  return input?.replaceAll(String.fromCharCode(65532), '') ?? "";
}

bool isNullOrEmptyString(String? input) {
  return sanitizeString(input).isEmpty;
}

List<RegExpMatch> parseLinks(String text) {
  return urlRegex.allMatches(text).toList();
}
