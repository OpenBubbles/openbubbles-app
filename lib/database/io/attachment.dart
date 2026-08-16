import 'dart:convert';

import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/network/backend_service.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/utils/attachment_guid_utils.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:mime_type/mime_type.dart';
// (needed when generating objectbox model code)
// ignore: unnecessary_import
import 'package:objectbox/objectbox.dart';
import 'package:path/path.dart';
import 'package:universal_io/io.dart';
import 'package:telephony_plus/src/models/attachment.dart' as TelephonyAttachment;
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

@Entity()
class Attachment {
  int? id;
  int? originalROWID;

  @Index(type: IndexType.value)
  @Unique()
  String? guid;

  String? uti;
  String? mimeType;
  bool? isOutgoing;
  String? transferName;
  int? totalBytes;
  int? height;
  int? width;
  @Transient()
  Uint8List? bytes;
  String? webUrl;
  bool hasLivePhoto;

  @Transient()
  String? sourcePath;

  String? ckRecordId;

  final message = ToOne<Message>();

  Map<String, dynamic>? metadata;

  String? get dbMetadata => metadata == null
      ? null : jsonEncode(metadata);
  set dbMetadata(String? json) => metadata = json == null
      ? null : jsonDecode(json) as Map<String, dynamic>;
  
  void applyFromCloud(api.CloudAttachment c, String ckRecordId) {
    this.ckRecordId = ckRecordId;
    var decoded = api.decodeAttachmentmeta(wrapped: c.cm);
    uti = decoded.uti;
    mimeType = decoded.mimeType;
    isOutgoing = decoded.isOutgoing;
    transferName = decoded.transferName;
    totalBytes = decoded.totalBytes;
    metadata ??= {};
    metadata!["cloud"] = ckRecordId;
    final owned = parseAppleOwnedAttachmentGuid(decoded.guid);
    if (owned != null) {
      // format defined in indexedPartsToAttributedBodyDyn
      var message = Message.findOne(guid: owned.messageGuid);
      guid = "${owned.messageGuid}_${owned.part}";
      save(message);
    } else {
      guid = decoded.guid;
      save(null);
    }
  }

  String unconvertAttachmentGuid(String guid) {
    return unconvertAppleAttachmentGuid(guid);
  }

  Future<api.AttachmentMeta> getAttachmentMeta() async {
    var sum = md5.convert(File(path).readAsBytesSync());
    return api.AttachmentMeta(
      mimeType: mimeType,
      startDate: RustPushBBUtils.nsSinceAppleEpoch(DateTime.now()), 
      totalBytes: totalBytes ?? File(path).lengthSync(), 
      transferState: 5, 
      isSticker: false, 
      guid: unconvertAttachmentGuid(guid!), 
      hideAttachment: false, 
      userInfo: metadata!["rustpush"] != null ? api.attachmentToCloud(att: api.restoreAttachment(data: metadata!["rustpush"])) : null,
      filename: "~/Library/Messages/Attachments/24/04/${unconvertAttachmentGuid(guid!)}/test.png", 
      extras: const api.AttachmentMetaExtra(previewGenerationState: api.NumOrString.num(1)),
      isOutgoing: message.target?.isFromMe ?? true, 
      transferName: transferName ?? "unknown", 
      version: 1, 
      uti: uti,
      pathc: transferName ?? "unknown",
      createdDate: RustPushBBUtils.nsSinceAppleEpoch(DateTime.now()),
      md5: hex.encode(sum.bytes.slice(0, 8)),
    );
  }

  Attachment({
    this.id,
    this.originalROWID,
    this.guid,
    this.uti,
    this.mimeType,
    this.isOutgoing,
    this.transferName,
    this.totalBytes,
    this.height,
    this.width,
    this.metadata,
    this.bytes,
    this.webUrl,
    this.sourcePath,
    this.hasLivePhoto = false,
  });

  /// Convert JSON to [Attachment]
  factory Attachment.fromMap(Map<String, dynamic> json) {
    String? mimeType = json["mimeType"];
    if (json["uti"] == "com.apple.coreaudio_format" || json['transferName'].toString().endsWith(".caf")) {
      mimeType = "audio/caf";
    }

    // Load the metadata
    var metadata = json["metadata"];
    if (metadata is String && metadata.isNotEmpty) {
      try {
        metadata = jsonDecode(metadata);
      } catch (_) {}
    }

    return Attachment(
      id: json["ROWID"] ?? json["id"],
      originalROWID: json["originalROWID"],
      guid: json["guid"],
      uti: json["uti"],
      mimeType: mimeType ?? mime(json['transferName']),
      isOutgoing: json["isOutgoing"] == true,
      transferName: json['transferName'],
      totalBytes: json['totalBytes'] is int ? json['totalBytes'] : 0,
      height: json["height"] ?? 0,
      width: json["width"] ?? 0,
      metadata: metadata is String ? null : metadata,
      hasLivePhoto: json["hasLivePhoto"] ?? false,
    );
  }

  PlatformFile getFile() {
    return PlatformFile(name: transferName!, bytes: bytes, path: kIsWeb ? null : path, size: totalBytes ?? 0);
  }

  Future<void> writeToDisk() async {
    var file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes!);
  }

  Future<TelephonyAttachment.Attachment> toTelephony() async {
    PlatformFile file;
    if (getFile().exists()) {
      file = getFile();
    } else {
      file = await backend.downloadAttachment(this,
            original: true, onReceiveProgress: (count, total) => {});
    }
    final bytes = await file.getBytes();
    return TelephonyAttachment.Attachment(bytes: bytes, mimeType: mimeType!, filename: transferName!);
  }

  /// Save a new attachment or update an existing attachment on disk
  /// [message] is used to create a link between the attachment and message,
  /// when provided
  Attachment save(Message? message) {
    if (kIsWeb) return this;
    Database.runInTransaction(TxMode.write, () {
      /// Find an existing attachment and update the attachment ID if applicable
      Attachment? existing = Attachment.findOne(guid!);
      if (existing != null) {
        id = existing.id;
      }
      try {
        /// store the attachment and add the link between the message and
        /// attachment
        if (message?.id != null) {
          this.message.target = message;
        }

        id = Database.attachments.put(this);
      } on UniqueViolationException catch (_) {}
    });
    return this;
  }

  /// Save many attachments at once. [map] is used to establish a link between
  /// the message and its attachments.
  static void bulkSave(Map<Message, List<Attachment>> map) {
    return Database.runInTransaction(TxMode.write, () {
      /// convert List<List<Attachment>> into just List<Attachment> (flatten it)
      final attachments = map.values.flattened.toList();
      /// find existing attachments
      List<Attachment> existingAttachments =
          Attachment.find(cond: Attachment_.guid.oneOf(attachments.map((e) => e.guid!).toList()));
      /// map existing attachment IDs to the attachments to save, if applicable
      for (Attachment a in attachments) {
        final existing = existingAttachments.firstWhereOrNull((e) => e.guid == a.guid);
        if (existing != null) {
          a.id = existing.id;
        }
      }
      try {
        /// store the attachments and update their ids
        final ids = Database.attachments.putMany(attachments);
        for (int i = 0; i < attachments.length; i++) {
          attachments[i].id = ids[i];
        }
      } on UniqueViolationException catch (_) {}
    });
  }

  /// replaces a temporary attachment with the new one from the server
  static Future<Attachment> replaceAttachment(String? oldGuid, Attachment newAttachment) async {
    if (kIsWeb) return newAttachment;
    Attachment? existing = Attachment.findOne(oldGuid!);
    if (existing == null) {
      return Future.error("Old GUID ($oldGuid) does not exist!");
    }
    // update current chat image data to prevent the image or video thumbnail from reloading
    if (cm.activeChat != null) {
      final data = cvc(cm.activeChat!.chat).imageData[oldGuid];
      if (data != null) {
        cvc(cm.activeChat!.chat).imageData.remove(oldGuid);
        cvc(cm.activeChat!.chat).imageData[newAttachment.guid!] = data;
      }
    }

    // update values and save
    existing.guid = newAttachment.guid;
    existing.originalROWID = newAttachment.originalROWID;
    existing.uti = newAttachment.uti;
    existing.mimeType = newAttachment.mimeType ?? existing.mimeType;
    existing.isOutgoing = newAttachment.isOutgoing;
    existing.transferName = newAttachment.transferName;
    existing.totalBytes = newAttachment.totalBytes;
    existing.bytes = newAttachment.bytes;
    existing.webUrl = newAttachment.webUrl;
    existing.hasLivePhoto = newAttachment.hasLivePhoto;
    existing.save(null);

    // change the directory path
    String appDocPath = fs.appDocDir.path;
    String pathName = "$appDocPath/attachments/$oldGuid";
    Directory directory = Directory(pathName);

    if (directory.existsSync()) {
      await directory.rename("$appDocPath/attachments/${newAttachment.guid}");
    }

    // grab values from existing
    newAttachment.id = existing.id;
    newAttachment.width = existing.width;
    newAttachment.height = existing.height;
    newAttachment.metadata = existing.metadata;
    return newAttachment;
  }

  /// find an attachment by its guid
  static Attachment? findOne(String guid) {
    if (kIsWeb) return null;
    final query = Database.attachments.query(Attachment_.guid.equals(guid)).build();
    query.limit = 1;
    final result = query.findFirst();
    query.close();
    return result;
  }

  /// Find all attachments matching a specified condition, or all attachments
  /// if no condition is provided
  static List<Attachment> find({Condition<Attachment>? cond}) {
    final query = Database.attachments.query(cond).build();
    return query.find();
  }

  /// Delete an attachment and remove all instances of that attachment in the DB
  static void delete(String guid) {
    if (kIsWeb) return;
    Database.runInTransaction(TxMode.write, () {
      final query = Database.attachments.query(Attachment_.guid.equals(guid)).build();
      final result = query.findFirst();
      query.close();
      if (result?.id != null) {
        if (result?.ckRecordId != null && !pushService.syncStopDelete) {
          var list = ss.prefs.getStringList("attachmentDeletionIds-1") ?? [];
          list.add(result!.ckRecordId!);
          ss.prefs.setStringList("attachmentDeletionIds-1", list);
        }
        Database.attachments.remove(result!.id!);
      }
    });
  }

  String getFriendlySize({decimals = 2}) {
    return (totalBytes ?? 0.0).toDouble().getFriendlySize();
  }

  bool get hasValidSize => (width ?? 0) > 0 && (height ?? 0) > 0;

  double get aspectRatio => hasValidSize ? (_isPortrait && height! < width! ?  (height! / width!).abs() : (width! / height!).abs()) : 0.78;

  String? get mimeStart => mimeType?.split("/").first;

  static String get baseDirectory => "${fs.appDocDir.path}/attachments";

  String get directory => "$baseDirectory/$guid";

  String get path {
    String file;
    switch (Platform.operatingSystem) {
      case "windows":
        file = "$directory/${"$transferName".replaceAll(RegExp(r'[<>:"/\|?*]'), "_")}";
      case "linux":
      case "macos":
        file = "$directory/${"$transferName".replaceAll(RegExp(r'/'), "_")}";
      default:
        file = "$directory/${"$transferName".replaceAll(RegExp(r'/'), "_")}";
    }

    if (!canonicalize(file).startsWith(canonicalize(directory))) {
      throw Exception("Path traversal detected, are we under attack??");
    }

    return file;
  }

  String get convertedPath => "$path.png";

  bool get existsOnDisk => File(path).existsSync();

  Future<bool> get existsOnDiskAsync async => await File(path).exists();

  bool get canCompress => mimeStart == "image" && !mimeType!.contains("gif");

  static Attachment merge(Attachment attachment1, Attachment attachment2) {
    attachment1.id ??= attachment2.id;
    attachment1.bytes ??= attachment2.bytes;
    attachment1.guid ??= attachment2.guid;
    attachment1.height ??= attachment2.height;
    attachment1.width ??= attachment2.width;
    attachment1.isOutgoing ??= attachment2.isOutgoing;
    attachment1.mimeType ??= attachment2.mimeType;
    attachment1.totalBytes ??= attachment2.totalBytes;
    attachment1.transferName ??= attachment2.transferName;
    attachment1.uti ??= attachment2.uti;
    attachment1.webUrl ??= attachment2.webUrl;
    attachment1.metadata = mergeTopLevelDicts(attachment1.metadata, attachment2.metadata);
    if (attachment2.hasLivePhoto) {
      attachment1.hasLivePhoto = attachment2.hasLivePhoto;
    }
    if (!attachment1.message.hasValue) {
      attachment1.message.target = attachment2.message.target;
    }
    return attachment1;
  }

  Map<String, dynamic> toMap() => {
    "ROWID": id,
    "originalROWID": originalROWID,
    "guid": guid,
    "uti": uti,
    "mimeType": mimeType,
    "isOutgoing": isOutgoing!,
    "transferName": transferName,
    "totalBytes": totalBytes,
    "height": height,
    "width": width,
    "metadata": jsonEncode(metadata),
    "hasLivePhoto": hasLivePhoto,
  };

  bool  get _isPortrait {
    if (metadata?['orientation'] == '1') return true;
    if (metadata?['orientation'] == 1) return true;
    if (metadata?['orientation'] == 'portrait') return true;
    if (metadata?['Image Orientation']?.contains("90") ?? false) return true;
    return false;
  }
}
