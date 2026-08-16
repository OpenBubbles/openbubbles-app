import 'package:mime_type/mime_type.dart';

String? resolveAttachmentMimeType(String name, String? path) {
  return mime(name) ?? (path == null ? null : mime(path));
}
