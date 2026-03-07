import 'dart:convert';

import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/carddav_sync.dart';
import 'package:bluebubbles/main.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/utils/string_utils.dart';
import 'package:dio/dio.dart';
import 'package:fast_contacts/fast_contacts.dart' hide Contact, StructuredName;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;

ContactsService cs = Get.isRegistered<ContactsService>() ? Get.find<ContactsService>() : Get.put(ContactsService());

/// Compare two phone numbers ignoring formatting and country code differences.
/// Strips all non-digit characters, removes leading zeros, then checks if
/// the shorter number is a suffix of the longer one (minimum 7 digits).
bool phoneNumbersMatch(String a, String b) {
  final na = a.numericOnly();
  final nb = b.numericOnly();
  if (na.isEmpty || nb.isEmpty) return false;
  if (na == nb) return true;
  final sa = na.replaceFirst(RegExp(r'^0+'), '');
  final sb = nb.replaceFirst(RegExp(r'^0+'), '');
  if (sa.isEmpty || sb.isEmpty) return false;
  if (sa == sb) return true;
  final shorter = sa.length <= sb.length ? sa : sb;
  final longer = sa.length > sb.length ? sa : sb;
  return shorter.length >= 7 && longer.endsWith(shorter);
}

class ContactsService extends GetxService {
  final tag = "ContactsService";
  /// The master list of contact objects
  List<Contact> contacts = [];

  bool _hasContactAccess = false;

  Future<bool> get hasContactAccess async {
    if (_hasContactAccess) return true;

    _hasContactAccess = await canAccessContacts();
    return _hasContactAccess;
  }

  Future<void> init() async {
    // Load the contact access state
    await hasContactAccess;

    if (!kIsWeb) {
      contacts = Contact.getContacts();
      // Re-match handles against cached contacts on startup
      // (picks up matching improvements without needing a network fetch)
      await rematchContacts();
    } else {
      await fetchNetworkContacts();
    }
  }

  Future<bool> canAccessContacts() async {
    if (kIsWeb || kIsDesktop) {
      int versionCode = (await ss.getServerDetails()).item4;
      return versionCode >= 42 || usingRustPush;
    } else {
      return (await Permission.contacts.status).isGranted;
    }
  }

  Future<List<List<int>>> refreshContacts() async {
    if (!(await hasContactAccess)) return [];

    // Check if the user is on v1.5.2 or newer
    int serverVersion = (await ss.getServerDetails()).item4;
    // 100(major) + 21(minor) + 1(bug)
    bool isMin1_5_2 = serverVersion >= 207; // Server: v1.5.2

    final startTime = DateTime.now().millisecondsSinceEpoch;
    List<Contact> _contacts = [];
    final changedIds = <List<int>>[<int>[], <int>[]];

    _contacts = await fetchAllContacts();

    // compare loaded contacts to db contacts
    if (!kIsWeb) {
      final dbContacts = Database.contacts.getAll();
      // save any updated contacts
      for (Contact c in dbContacts) {
        final refreshedContact = _contacts.firstWhereOrNull((element) => element.id == c.id);
        if (refreshedContact != null) {
          refreshedContact.dbId = c.dbId;
          if (c != refreshedContact) {
            changedIds.first.add(c.dbId!);
            refreshedContact.save();
          }
        }
      }
      // save any new contacts
      final newContacts = _contacts.where((e) => !dbContacts.map((e2) => e2.id).contains(e.id)).toList();
      if (newContacts.isNotEmpty) {
        final ids = Database.contacts.putMany(newContacts);
        for (int i = 0; i < newContacts.length; i++) {
          newContacts[i].dbId = ids[i];
        }
      }
    }
    // load stored handles
    final List<Handle> handles = [];
    if (kIsWeb) {
      handles.addAll(chats.webCachedHandles);
    } else {
      handles.addAll(Database.handles.getAll());
    }
    // get formatted addresses
    for (Handle h in handles) {
      if (!h.address.contains("@") && h.formattedAddress == null) {
        h.formattedAddress = await formatPhoneNumber(h.address);
      }
    }
    // match handles to contacts and save match
    final handlesToSearch = List<Handle>.from(handles);
    for (Contact c in _contacts) {
      final handles = matchContactToHandles(c, handlesToSearch);
      final addressesAndServices = handles.map((e) => e.uniqueAddressAndService).toList();
      if (handles.isNotEmpty) {
        handlesToSearch.removeWhere((e) => addressesAndServices.contains(e.uniqueAddressAndService));

        // we have changes if the handle doesn't have an associated contact,
        // even if there were no contact changes in the first place
        final matches = handles.where((e) => addressesAndServices.contains(e.uniqueAddressAndService));
        for (Handle h in matches) {
          if (kIsWeb) {
            h.webContact = c;
            continue;
          }

          if (h.contactRelation.target == null) {
            changedIds.last.add(h.id!);
          } else if (c.isShared) {
            // we have an existing contact, and we're shared.
            continue;
          }

          h.contactRelation.target = c;
        }
      }
    }
    if (!kIsWeb) {
      Handle.bulkSave(handles, matchOnOriginalROWID: isMin1_5_2);
    } else {
      // dummy to make the full contacts UI refresh happen on web
      changedIds.last.add(handles.length);
      contacts = _contacts;
      for (Chat c in chats.chats) {
        c.webSyncParticipants();
      }
      chats.chats.refresh();
    }

    final endTime = DateTime.now().millisecondsSinceEpoch;
    Logger.debug("Contact refresh took ${endTime - startTime} ms");

    // only return contacts if things changed (or on web)
    return changedIds;
  }

  /// Re-match all handles to contacts using only cached database data.
  /// Does not fetch from network — useful when matching logic has changed.
  Future<void> rematchContacts() async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final dbContacts = Database.contacts.getAll();
    final handles = Database.handles.getAll();
    Logger.info("Rematch starting: ${dbContacts.length} contacts, ${handles.length} handles");
    if (dbContacts.isEmpty || handles.isEmpty) return;

    contacts = dbContacts;
    int matched = 0;
    int alreadyMatched = 0;
    int unmatched = 0;
    final handlesToSearch = List<Handle>.from(handles);
    for (Contact c in dbContacts) {
      final matchedHandles = matchContactToHandles(c, handlesToSearch);
      if (matchedHandles.isNotEmpty) {
        final addressesAndServices = matchedHandles.map((e) => e.uniqueAddressAndService).toList();
        handlesToSearch.removeWhere((e) => addressesAndServices.contains(e.uniqueAddressAndService));
        for (Handle h in matchedHandles) {
          if (h.contactRelation.target?.id != c.id) {
            h.contactRelation.target = c;
            matched++;
          } else {
            alreadyMatched++;
          }
        }
      }
    }
    unmatched = handlesToSearch.length;
    Logger.info("Rematch done: $matched new, $alreadyMatched already matched, $unmatched unmatched (${DateTime.now().millisecondsSinceEpoch - startTime} ms)");
    if (matched > 0) {
      Handle.bulkSave(handles);
    }
    // Log unmatched handles for debugging
    for (Handle h in handlesToSearch.take(20)) {
      if (!h.address.contains("@")) {
        Logger.info("Unmatched handle: ${h.address}");
      }
    }
  }

  Future<List<Contact>> fetchAllContacts() async {
    final _contacts = <Contact>[];

    int startTime = DateTime.now().millisecondsSinceEpoch;
    if (kIsWeb || kIsDesktop) {
      _contacts.addAll(await fetchNetworkContacts());
      int endTime = DateTime.now().millisecondsSinceEpoch;
      Logger.debug("Contacts fetched in ${endTime - startTime} ms");
    } else {
      _contacts.addAll((await FastContacts.getAllContacts(
        fields: List<ContactField>.from(ContactField.values)
          ..removeWhere((e) => [ContactField.company, ContactField.department, ContactField.jobDescription, ContactField.emailLabels, ContactField.phoneLabels].contains(e))
      )).map((e) => Contact(
        displayName: e.displayName,
        emails: e.emails.map((e) => e.address).toList(),
        phones: e.phones.map((e) => e.number).toList(),
        structuredName: e.structuredName == null ? null : StructuredName(
          namePrefix: e.structuredName!.namePrefix,
          givenName: e.structuredName!.givenName,
          middleName: e.structuredName!.middleName,
          familyName: e.structuredName!.familyName,
          nameSuffix: e.structuredName!.nameSuffix,
        ),
        id: e.id,
      )));

      int endTime = DateTime.now().millisecondsSinceEpoch;
      Logger.debug("Contacts fetched in ${endTime - startTime} ms");

      // get avatars
      startTime = DateTime.now().millisecondsSinceEpoch;
      for (Contact c in _contacts) {
        c.avatar = await getContactAvatar(c.id);
      }

      endTime = DateTime.now().millisecondsSinceEpoch;
      Logger.debug("Avatars fetched in ${endTime - startTime} ms");
    }

    return _contacts;
  }

  Future<Uint8List?> getContactAvatar(String id) async {
    Uint8List? avatar;

    try {
      avatar = await FastContacts.getContactImage(id, size: ContactImageSize.fullSize);
    } catch (e) {
      Logger.warn("Failed to get full size avatar for ID, $id!", error: e);
    }

    if (avatar == null) {
      try {
        avatar = await FastContacts.getContactImage(id);
      } catch (e) {
        Logger.warn("Failed to get small size avatar for ID, $id!", error: e);
      }
    }

    return avatar;
  }

  void completeContactsRefresh(List<Contact> refreshedContacts, {List<List<int>>? reloadUI}) {
    if (refreshedContacts.isNotEmpty) {
      contacts = refreshedContacts;
      if (reloadUI != null) {
        eventDispatcher.emit('update-contacts', reloadUI);
      }
    }
  }

  List<Handle> matchContactToHandles(Contact c, List<Handle> handles) {
    List<Handle> handleMatches = [];
    // multiply phones by 3 because a phone can be matched to iMessage / SMS / Android SMS
    int maxResults = c.phones.length * 3 + c.emails.length;
    for (Handle h in handles) {
      // Match emails
      if (h.address.contains("@") && c.emails.contains(h.address)) {
        handleMatches.add(h);
        continue;
      }

      // Skip emails that didn't match above — don't try phone matching
      if (h.address.contains("@")) continue;

      // Match phone numbers with fuzzy comparison
      if (c.phones.any((p) => phoneNumbersMatch(h.address, p))) {
        handleMatches.add(h);
        continue;
      }

      if (handleMatches.length >= maxResults) break;
    }

    return handleMatches;
  }

  Contact? matchHandleToContact(Handle h) {
    if (!_hasContactAccess) return null;

    for (Contact c in contacts) {
      if (h.address.contains("@") && c.emails.contains(h.address)) {
        return c;
      }
      if (h.address.contains("@")) continue;
      if (c.phones.any((p) => phoneNumbersMatch(h.address, p))) {
        return c;
      }
    }
    return null;
  }

  Contact? getContact(String address) {
    final tempHandle = Handle(
      address: address
    );
    return matchHandleToContact(tempHandle);
  }

  Future<List<Contact>> fetchNetworkContacts({Function(String)? logger}) async {
    final networkContacts = <Contact>[];

    if (usingRustPush) {
      final CardDavClient client;

      if (ss.settings.contactSyncProvider.value == "Google") {
        var account = await pushService.googleSignIn.signInOffline();
        if (account == null) {
          Logger.warn("No google auth!");
          return [];
        }

        
        String accessToken;

        if (account.refreshToken != null) {
          final response = await http.dio.post(
            'https://oauth2.googleapis.com/token',
            data: {
              'client_id': clientId,
              'client_secret': clientSecret,
              'refresh_token': account.refreshToken,
              'grant_type': 'refresh_token',
            },
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              responseType: ResponseType.json,
            ),
          );

          if (response.statusCode != 200) {
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              message: 'Failed to refresh Google access token',
              type: DioExceptionType.badResponse,
            );
          }
          accessToken = response.data['access_token'] as String;
        } else {
          accessToken = account.accessToken;
        }

        client = CardDavClient(
          principalUrl: Uri.parse('https://www.googleapis.com/.well-known/carddav'),
          authHeadersProvider: () async {
            return {
              "Authorization": "Bearer $accessToken"
            };
          },
          state: MemoryStateStore(),
        );
      } else if (ss.settings.contactSyncProvider.value == "CardDav") {
        if (ss.settings.cardDavServer.value == "") return [];
        client = CardDavClient(
          principalUrl: Uri.parse(ss.settings.cardDavServer.value),
          username: ss.settings.cardDavUser.value,
          password: ss.settings.cardDavPass.value,
          state: MemoryStateStore(),
        );
      } else {
        if (pushService.state?.icloudServices == null) return [];
        client = CardDavClient(
          principalUrl: Uri.parse('https://contacts.icloud.com/'),
          authHeadersProvider: () async {
            return await api.getContactsHeaders(path: pushService.statePath, state: pushService.state!.anisette, tokenProvider: pushService.state!.icloudServices!.tokenProvider, config: pushService.state!.osConfig);
          },
          state: MemoryStateStore(),
        );
      }

      final synced = await client.syncAllAddressBooks();

      for (final entry in synced.entries) {
        final book = entry.key;
        final changes = entry.value;

        print('AddressBook: ${book.displayName ?? book.url}');
        print('Changes: ${changes.length}');
        for (final ch in changes) {
          if (ch.type == ChangeType.upsert) {
            if (ch.contact != null) networkContacts.add(ch.contact!);
            // Parse/store vCard as you like
            print(
                '  UPSERT ${ch.href} etag=${ch.etag} vcardLen=${ch.vcard?.length} contact=${ch.contact?.toMap()}');
          } else {
            print('  DELETE ${ch.href}');
          }
        }
      }
      return networkContacts;
    }

    // refresh UI on web without waiting for avatars
    if (kIsWeb) {
      logger?.call("Fetching contacts (no avatars)...");
      try {
        final response = await http.contacts();

        if (response.statusCode == 200 && !isNullOrEmpty(response.data['data'])) {
          logger?.call("Found contacts!");

          for (Map<String, dynamic> map in response.data['data']) {
            final displayName = getDisplayName(map['displayName'], map['firstName'], map['lastName']);
            final emails = (map['emails'] as List<dynamic>? ?? []).map((e) => e['address'].toString()).toList();
            final phones = (map['phoneNumbers'] as List<dynamic>? ?? []).map((e) => e['address'].toString()).toList();
            logger?.call("Parsing contact: $displayName");
            networkContacts.add(Contact(
              id: (map['id'] ?? (phones.isNotEmpty ? phones : emails)).toString(),
              displayName: displayName,
              emails: emails,
              phones: phones,
            ));
          }
        } else {
          logger?.call("No contacts found!");
        }
        logger?.call("Finished contacts sync (no avatars)");
      } catch (e, s) {
        logger?.call("Got exception: $e");
        logger?.call(s.toString());
      }
      final handlesToSearch = List<Handle>.from(chats.webCachedHandles);
      for (Contact c in contacts) {
        final handles = matchContactToHandles(c, handlesToSearch);
        final addressesAndServices = handles.map((e) => e.uniqueAddressAndService).toList();
        if (handles.isNotEmpty) {
          handlesToSearch.removeWhere((e) => addressesAndServices.contains(e.uniqueAddressAndService));
          for (Handle h in handles) {
            if (addressesAndServices.contains(h.uniqueAddressAndService)) {
              h.webContact = c;
            }
          }
        }
      }
      eventDispatcher.emit('update-contacts', null);
    }

    logger?.call("Fetching contacts (with avatars)...");
    try {
      if (kIsWeb) {
        final response = await http.contacts(withAvatars: true);

        if (!isNullOrEmpty(response.data['data'])) {
          logger?.call("Found contacts!");
          for (Map<String, dynamic> map in response.data['data'].where((e) => !isNullOrEmpty(e['avatar']))) {
            final displayName = getDisplayName(map['displayName'], map['firstName'], map['lastName']);
            logger?.call("Adding avatar for contact: $displayName");
            final emails = (map['emails'] as List<dynamic>? ?? []).map((e) => e['address'].toString()).toList();
            final phones = (map['phoneNumbers'] as List<dynamic>? ?? []).map((e) => e['address'].toString()).toList();
            for (Contact contact in networkContacts) {
              bool match = contact.id == (map['id'] ?? (phones.isNotEmpty ? phones : emails)).toString();

              // Ensure contact first name matches to avoid issues with shared numbers (landlines)
              if (!match && map['firstName'] != null && !contact.displayName.startsWith(map['firstName'])) continue;

              List<String> addresses = [...contact.phones, ...contact.emails];
              List<String> _addresses = [...phones, ...emails];
              for (String a in addresses) {
                if (match) {
                  break;
                }
                String? formatA = a.contains("@") ? a.toLowerCase() : await formatPhoneNumber(cleansePhoneNumber(a));
                if (formatA.isEmpty) continue;
                for (String _a in _addresses) {
                  String? _formatA = _a.contains("@") ? _a.toLowerCase() : await formatPhoneNumber(cleansePhoneNumber(_a));
                  if (formatA == _formatA) {
                    match = true;
                    break;
                  }
                }
              }

              if (match && contact.avatar == null) {
                contact.avatar = base64Decode(map['avatar'].toString());
              }
            }
          }
        } else {
          logger?.call("No contacts found!");
        }
        logger?.call("Finished contacts sync (with avatars)");
      } else {
        final response = await http.contacts(withAvatars: true);

        if (response.statusCode == 200 && !isNullOrEmpty(response.data['data'])) {
          logger?.call("Found contacts!");
          for (Map<String, dynamic> map in response.data['data']) {
            final displayName = getDisplayName(map['displayName'], map['firstName'], map['lastName']);
            final emails = (map['emails'] as List<dynamic>? ?? []).map((e) => e['address'].toString()).toList();
            final phones = (map['phoneNumbers'] as List<dynamic>? ?? []).map((e) => e['address'].toString()).toList();
            logger?.call("Parsing contact: $displayName");

            // Log when a contact has no saved addresses
            if (emails.isEmpty && phones.isEmpty) {
              logger?.call("Contact has no saved addresses: $displayName");
            }
            
            networkContacts.add(Contact(
              id: (map['id'] ?? (phones.isNotEmpty ? phones : emails)).toString(),
              displayName: displayName,
              emails: emails,
              phones: phones,
              avatar: !isNullOrEmpty(map['avatar']) ? base64Decode(map['avatar'].toString()) : null,
            ));
          }
        } else {
          logger?.call("No contacts found!");
        }
        logger?.call("Finished contacts sync (with avatars)");
      }
    } catch (e, s) {
      logger?.call("Got exception: $e");
      logger?.call(s.toString());
    }
    return networkContacts;
  }
}
