import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bluebubbles/services/services.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:dio/io.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:bluebubbles/database/io/contact.dart' as contacts;
import 'package:bluebubbles/database/global/structured_name.dart' as structured;

// 690 lines of beautiful AI slop. It works great!

/// ===== Models =====

class AddressBook {
  final Uri url;
  final String? displayName;
  final String? ctag;
  final String? syncToken;

  AddressBook({
    required this.url,
    this.displayName,
    this.ctag,
    this.syncToken,
  });

  AddressBook copyWith({String? ctag, String? syncToken, String? displayName}) {
    return AddressBook(
      url: url,
      displayName: displayName ?? this.displayName,
      ctag: ctag ?? this.ctag,
      syncToken: syncToken ?? this.syncToken,
    );
  }

  @override
  String toString() => 'AddressBook(url=$url, name=$displayName, ctag=$ctag, token=$syncToken)';
}

enum ChangeType { upsert, deleted }

class ContactChange {
  final ChangeType type;
  final Uri href;
  final contacts.Contact? contact; // present for upsert
  final String? vcard; // present for upsert
  final String? etag;

  ContactChange.upsert({required this.href, required this.vcard, required this.contact, this.etag})
      : type = ChangeType.upsert;
  ContactChange.deleted({required this.href})
      : type = ChangeType.deleted,
        vcard = null,
        contact = null,
        etag = null;

  @override
  String toString() =>
      'ContactChange($type, href=$href, etag=$etag, vcardLen=${vcard?.length}, contact=${contact?.displayName})';
}

/// ===== Persistence hooks (you implement) =====
/// Store per-addressbook CTag and sync-token somewhere (db/shared_prefs/etc).
abstract class CardDavStateStore {
  Future<String?> getCtag(Uri addressBookUrl);
  Future<void> setCtag(Uri addressBookUrl, String? ctag);

  Future<String?> getSyncToken(Uri addressBookUrl);
  Future<void> setSyncToken(Uri addressBookUrl, String? syncToken);
}

/// Simple in-memory store (for demo/testing).
class MemoryStateStore implements CardDavStateStore {
  String _k(Uri u) => u.toString();

  @override
  Future<String?> getCtag(Uri addressBookUrl) async => ss.settings.ctags[_k(addressBookUrl)];

  @override
  Future<void> setCtag(Uri addressBookUrl, String? ctag) async {
    ss.settings.ctags[_k(addressBookUrl)] = ctag;
    ss.saveSettings();
  }

  @override
  Future<String?> getSyncToken(Uri addressBookUrl) async => ss.settings.tokens[_k(addressBookUrl)];

  @override
  Future<void> setSyncToken(Uri addressBookUrl, String? syncToken) async {
    ss.settings.tokens[_k(addressBookUrl)] = syncToken;
    ss.saveSettings();
  }
}

List<int> gzipEncoder(String request, RequestOptions options) {
  options.headers.putIfAbsent("Content-Encoding", () => "gzip");
  return gzip.encode(utf8.encode(request));
}

/// ===== Client =====

typedef AuthHeadersProvider = Future<Map<String, String>> Function();

class CardDavClient {
  final Dio _dio;
  final Uri principalUrl; // e.g. https://host/dav/principals/users/alice/  OR the user-provided principal endpoint
  final CardDavStateStore state;
  final AuthHeadersProvider _authHeadersProvider;
  final int maxConcurrentVCardDownloads;

  CardDavClient({
    required this.principalUrl,
    required this.state,
    // If provided, called per request to supply auth headers (e.g., OAuth token refresh).
    AuthHeadersProvider? authHeadersProvider,
    String? username,
    String? password,
    this.maxConcurrentVCardDownloads = 6,
    Dio? dio,
  })  : _authHeadersProvider = authHeadersProvider ??
            (() async {
              if (username == null || password == null) {
                throw StateError('Auth headers provider not set and username/password not provided');
              }
              return {
                'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
              };
            }),
        _dio = dio ??
            Dio(
              BaseOptions(
                // You can set baseUrl to principalUrl.origin if you like.
                followRedirects: true,
                validateStatus: (s) => s != null && s >= 200 && s < 500,
                headers: {
                  'User-Agent': 'macOS/15.5 (24F74) AddressBookCore/2695.500.71',
                  'Cache-Control': 'no-transform',
                  'Accept-Language': 'en-US,en;q=0.9',
                },
                responseType: ResponseType.plain,
                requestEncoder: gzipEncoder
              ),
            ) {
    final adapter = _dio.httpClientAdapter;
    if (adapter is DefaultHttpClientAdapter) {
      adapter.onHttpClientCreate = (client) {
        client.findProxy = (uri) => 'PROXY 192.168.99.71:8080';
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final headers = await _authHeadersProvider();
    if (headers.isEmpty) return const {};
    return headers;
  }

  /// Public entry point:
  /// - discover address books
  /// - for each address book: compare CTag, and if changed run incremental sync and download vcards
  Future<Map<AddressBook, List<ContactChange>>> syncAllAddressBooks() async {
    final books = await discoverAddressBooks();
    final result = <AddressBook, List<ContactChange>>{};

    for (final book in books) {
      final changes = await syncAddressBook(book);
      result[book] = changes;
    }
    return result;
  }

  /// Discover address books for this principal:
  /// 1) PROPFIND principalUrl for addressbook-home-set
  /// 2) PROPFIND home-set Depth:1 to list address books and props (displayname, getctag, sync-token)
  Future<List<AddressBook>> discoverAddressBooks() async {
    var homeSet = await _tryDiscoverAddressBookHomeSet(principalUrl);
    if (homeSet == null) {
      final principal = await _discoverCurrentUserPrincipal(principalUrl);
      if (principal != null) {
        homeSet = await _tryDiscoverAddressBookHomeSet(principal);
      }
    }
    if (homeSet == null) {
      throw StateError('Could not discover addressbook-home-set from principal: $principalUrl');
    }
    final books = await _listAddressBooks(homeSet);
    return books;
  }

  /// Sync one address book:
  /// - PROPFIND for current CTag + current sync-token (optional)
  /// - if CTag unchanged: return []
  /// - else: REPORT sync-collection using stored sync-token (if any)
  /// - download changed/new vcards via GET
  /// - update stored CTag + sync-token
  Future<List<ContactChange>> syncAddressBook(AddressBook book) async {
    // Refresh CTag and (optionally) a sync-token property.
    final refreshed = await _fetchAddressBookProps(book.url);
    final currentCtag = refreshed.ctag;
    final storedCtag = await state.getCtag(book.url);

    // If server provides CTag and it’s unchanged, nothing to do.
    if (currentCtag != null && storedCtag != null && currentCtag == storedCtag) {
      return const <ContactChange>[];
    }

    // Run incremental sync via sync-collection (RFC 6578)
    final lastToken = await state.getSyncToken(book.url);
    final syncResult = await _syncCollection(book.url, syncToken: lastToken);

    // Download vCards for upserts
    final changes = <ContactChange>[];
    final upserts = <_SyncItem>[];
    for (final item in syncResult.items) {
      if (item.deleted) {
        changes.add(ContactChange.deleted(href: item.href));
      } else {
        upserts.add(item);
      }
    }

    if (upserts.isNotEmpty) {
      final upsertChanges = await _mapWithConcurrency<ContactChange?>(
        upserts,
        maxConcurrentVCardDownloads,
        (item) async {
          final vcard = await _downloadVCard(item.href);
          if (vcard == null) {
            // If GET fails with 404, treat as deleted.
            return ContactChange.deleted(href: item.href);
          }
          final contact = await _myContactFromVCard(vcard, item.href);
          return ContactChange.upsert(href: item.href, vcard: vcard, contact: contact, etag: item.etag);
        },
      );
      changes.addAll(upsertChanges.whereType<ContactChange>());
    }

    // Persist new token + ctag
    await state.setSyncToken(book.url, syncResult.newSyncToken);
    await state.setCtag(book.url, currentCtag);

    return changes;
  }

  /// ===== Discovery helpers =====

  Future<Uri?> _tryDiscoverAddressBookHomeSet(Uri principal) async {
    final body = _xmlDoc('d:propfind', {
      'DAV:': 'd',
      'urn:ietf:params:xml:ns:carddav': 'card',
    }, [
      XmlElement(XmlName('d:prop'), [], [
        XmlElement(XmlName('card:addressbook-home-set')),
      ]),
    ]);

    final res = await _requestXml(
      'PROPFIND',
      principal,
      body: body,
      headers: {'Depth': '0'},
    );

    final doc = XmlDocument.parse(res);
    final href = _firstPropHref(doc, ['urn:ietf:params:xml:ns:carddav', 'addressbook-home-set']);
    if (href == null) return null;
    return _resolve(principal, href);
  }

  Future<Uri?> _discoverCurrentUserPrincipal(Uri baseUrl) async {
    final body = _xmlDoc('d:propfind', {
      'DAV:': 'd',
    }, [
      XmlElement(XmlName('d:prop'), [], [
        XmlElement(XmlName('d:current-user-principal')),
        XmlElement(XmlName('d:principal-URL')),
      ]),
    ]);

    final res = await _requestXml(
      'PROPFIND',
      baseUrl,
      body: body,
      headers: {'Depth': '0'},
    );

    final doc = XmlDocument.parse(res);
    final href = _firstPropHref(doc, ['DAV:', 'current-user-principal']) ??
        _firstPropHref(doc, ['DAV:', 'principal-URL']);
    if (href == null) return null;
    return _resolve(baseUrl, href);
  }

  Future<List<AddressBook>> _listAddressBooks(Uri homeSet) async {
    // Ask for:
    // - displayname
    // - resourcetype (so we can filter addressbook collections)
    // - getctag (calendarserver/apple extension)
    // - sync-token (RFC 6578)
    final body = _xmlDoc('d:propfind', {
      'DAV:': 'd',
      'urn:ietf:params:xml:ns:carddav': 'card',
      'http://calendarserver.org/ns/': 'cs', // getctag often here
      'http://apple.com/ns/ical/': 'apple',  // some servers put it here
    }, [
      XmlElement(XmlName('d:prop'), [], [
        XmlElement(XmlName('d:displayname')),
        XmlElement(XmlName('d:resourcetype')),
        XmlElement(XmlName('cs:getctag')),
        XmlElement(XmlName('apple:getctag')),
        XmlElement(XmlName('d:sync-token')),
      ]),
    ]);

    final res = await _requestXml(
      'PROPFIND',
      homeSet,
      body: body,
      headers: {'Depth': '1'},
    );

    final doc = XmlDocument.parse(res);

    // Parse each <d:response>
    final responses = doc.findAllElements('response', namespace: 'DAV:');
    final books = <AddressBook>[];

    for (final r in responses) {
      final hrefText = r.getElement('href', namespace: 'DAV:')?.innerText.trim();
      if (hrefText == null || hrefText.isEmpty) continue;

      final url = _resolve(homeSet, hrefText);

      // Check resourcetype includes <card:addressbook/>
      final isAddressBook = r
          .findAllElements('resourcetype', namespace: 'DAV:')
          .expand((e) => e.children.whereType<XmlElement>())
          .any((e) => (e.name.namespaceUri == 'urn:ietf:params:xml:ns:carddav' && e.name.local == 'addressbook'));

      if (!isAddressBook) continue;

      final displayName = _firstPropText(r, [
        ['DAV:', 'displayname']
      ]);

      final ctag = _firstPropText(r, [
        ['http://calendarserver.org/ns/', 'getctag'],
        ['http://apple.com/ns/ical/', 'getctag'],
      ]);

      final syncToken = _firstPropText(r, [
        ['DAV:', 'sync-token']
      ]);

      books.add(AddressBook(url: url, displayName: displayName, ctag: ctag, syncToken: syncToken));
    }

    return books;
  }

  Future<AddressBook> _fetchAddressBookProps(Uri addressBookUrl) async {
    final body = _xmlDoc('d:propfind', {
      'DAV:': 'd',
      'http://calendarserver.org/ns/': 'cs',
      'http://apple.com/ns/ical/': 'apple',
    }, [
      XmlElement(XmlName('d:prop'), [], [
        XmlElement(XmlName('cs:getctag')),
        XmlElement(XmlName('apple:getctag')),
        XmlElement(XmlName('d:sync-token')),
      ]),
    ]);

    final res = await _requestXml(
      'PROPFIND',
      addressBookUrl,
      body: body,
      headers: {'Depth': '0'},
    );

    final doc = XmlDocument.parse(res);

    final ctag = _firstPropText(doc, [
      ['http://calendarserver.org/ns/', 'getctag'],
      ['http://apple.com/ns/ical/', 'getctag'],
    ]);

    final syncToken = _firstPropText(doc, [
      ['DAV:', 'sync-token'],
    ]);

    return AddressBook(url: addressBookUrl, ctag: ctag, syncToken: syncToken);
  }

  /// ===== Incremental sync (RFC 6578) =====

  Future<_SyncCollectionResult> _syncCollection(Uri addressBookUrl, {String? syncToken}) async {
    if (syncToken == null && _isGoogleCardDav(addressBookUrl)) {
      return _propfindAllItems(addressBookUrl);
    }
    // Depth: 1 is typical for sync-collection
    // We request:
    // - getetag for changed resources
    //
    // Note: Some servers accept <d:sync-token/> for initial sync, others want "0",
    // others want it omitted. We’ll do:
    // - if no token: send empty <d:sync-token/>
    // - else include the saved token
    final tokenElement = (syncToken == null)
        ? XmlElement(XmlName('d:sync-token'))
        : XmlElement(XmlName('d:sync-token'), [], [XmlText(syncToken)]);

    final body = _xmlDoc('d:sync-collection', {
      'DAV:': 'd',
    }, [
      tokenElement,
      XmlElement(XmlName('d:sync-level'), [], [XmlText('1')]),
      XmlElement(XmlName('d:prop'), [], [
        XmlElement(XmlName('d:getetag')),
      ]),
    ]);

    final res = await _requestXml(
      'REPORT',
      addressBookUrl,
      body: body,
      headers: {
        'Depth': '1',
        'Content-Type': 'text/xml',
      },
    );

    final doc = XmlDocument.parse(res);

    final newToken = doc
        .findAllElements('sync-token', namespace: 'DAV:')
        .map((e) => e.innerText.trim())
        .firstWhere((t) => t.isNotEmpty, orElse: () => syncToken ?? '');

    final items = <_SyncItem>[];

    final responses = doc.findAllElements('response', namespace: 'DAV:');
    for (final r in responses) {
      final hrefText = r.getElement('href', namespace: 'DAV:')?.innerText.trim();
      if (hrefText == null || hrefText.isEmpty) continue;

      final href = _resolve(addressBookUrl, hrefText);

      // Detect deletion via <d:status>HTTP/1.1 404 Not Found</d:status>
      // Some servers use 410, or put status inside propstat.
      final statuses = r.findAllElements('status', namespace: 'DAV:').map((e) => e.innerText).toList();
      final deleted = statuses.any((s) => s.contains(' 404 ') || s.contains(' 410 '));

      String? etag;
      if (!deleted) {
        etag = r
            .findAllElements('getetag', namespace: 'DAV:')
            .map((e) => e.innerText.trim())
            .firstWhere((t) => t.isNotEmpty, orElse: () => '');
        if (etag != null && etag.isEmpty) etag = null;
      }

      items.add(_SyncItem(href: href, etag: etag, deleted: deleted));
    }

    return _SyncCollectionResult(newSyncToken: newToken.isEmpty ? null : newToken, items: items);
  }

  bool _isGoogleCardDav(Uri addressBookUrl) {
    return addressBookUrl.host == 'www.googleapis.com' && addressBookUrl.path.contains('/carddav/');
  }

  Future<_SyncCollectionResult> _propfindAllItems(Uri addressBookUrl) async {
    final body = _xmlDoc('d:propfind', {
      'DAV:': 'd',
    }, [
      XmlElement(XmlName('d:prop'), [], [
        XmlElement(XmlName('d:getetag')),
      ]),
    ]);

    final res = await _requestXml(
      'PROPFIND',
      addressBookUrl,
      body: body,
      headers: {
        'Depth': '1',
      },
    );

    final doc = XmlDocument.parse(res);
    final items = <_SyncItem>[];
    final responses = doc.findAllElements('response', namespace: 'DAV:');
    for (final r in responses) {
      final hrefText = r.getElement('href', namespace: 'DAV:')?.innerText.trim();
      if (hrefText == null || hrefText.isEmpty) continue;
      final href = _resolve(addressBookUrl, hrefText);
      final etag = r
          .findAllElements('getetag', namespace: 'DAV:')
          .map((e) => e.innerText.trim())
          .firstWhere((t) => t.isNotEmpty, orElse: () => '');
      items.add(_SyncItem(href: href, etag: etag.isEmpty ? null : etag, deleted: false));
    }

    return _SyncCollectionResult(newSyncToken: null, items: items);
  }

  /// ===== vCard download =====

  Future<String?> _downloadVCard(Uri href) async {
    final authHeaders = await _authHeaders();
    final res = await _dio.getUri(
      href,
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'Accept': 'text/vcard, text/x-vcard, text/plain',
          ...authHeaders,
        },
      ),
    );

    // Treat 2xx as success; 404/410 as missing/deleted.
    if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
      final data = res.data;
      if (data is String) return data;
      return data?.toString();
    }
    return null;
  }

  Future<contacts.Contact> _myContactFromVCard(String vcard, Uri href) async {
    final contact = Contact.fromVCard(vcard);
    final inlinePhoto = _extractInlinePhotoBytes(vcard);
    if (inlinePhoto != null && inlinePhoto.isNotEmpty) {
      contact.photo = inlinePhoto;
      return _toMyContact(contact);
    }
    final photoUri = _extractPhotoUri(vcard, href);
    if (photoUri != null && (contact.photo == null || contact.photo!.isEmpty)) {
      final photoBytes = await _downloadPhoto(photoUri);
      if (photoBytes != null && photoBytes.isNotEmpty) {
        contact.photo = photoBytes;
      }
    }
    return _toMyContact(contact);
  }

  Uint8List? _extractInlinePhotoBytes(String vcard) {
    final unfolded = vcard.replaceAll(RegExp(r'\r?\n[ \t]'), '');
    final lines = unfolded.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      if (!line.toUpperCase().startsWith('PHOTO')) continue;
      final parts = line.split(':');
      if (parts.length < 2) continue;
      final params = parts.first.toUpperCase();
      final value = parts.sublist(1).join(':').trim();
      if (value.isEmpty) continue;
      if (!params.contains('ENCODING=B') &&
          !params.contains('VALUE=BINARY') &&
          !params.contains('BASE64')) {
        continue;
      }
      final cleaned = value.replaceAll(RegExp(r'\s'), '');
      try {
        return base64Decode(cleaned);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Uri? _extractPhotoUri(String vcard, Uri baseUrl) {
    final unfolded = vcard.replaceAll(RegExp(r'\r?\n[ \t]'), '');
    final lines = unfolded.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      if (!line.toUpperCase().startsWith('PHOTO')) continue;
      final parts = line.split(':');
      if (parts.length < 2) continue;
      final params = parts.first.toUpperCase();
      final value = parts.sublist(1).join(':').trim();
      if (value.isEmpty) continue;
      if (params.contains('ENCODING=B') || params.contains('VALUE=BINARY')) continue;

      final uri = Uri.tryParse(value);
      if (uri == null) continue;
      return uri.isAbsolute ? uri : _resolve(baseUrl, value);
    }
    return null;
  }

  Future<Uint8List?> _downloadPhoto(Uri href) async {
    final authHeaders = await _authHeaders();
    final res = await _dio.getUri(
      href,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Accept': 'image/*',
          ...authHeaders,
        },
      ),
    );

    if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
      final data = res.data;
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
    }
    return null;
  }

  Future<List<T>> _mapWithConcurrency<T>(
    List<dynamic> items,
    int concurrency,
    Future<T> Function(dynamic) task,
  ) async {
    if (items.isEmpty) return const [];
    final max = concurrency < 1 ? 1 : concurrency;
    final results = List<T?>.filled(items.length, null);
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final i = nextIndex++;
        if (i >= items.length) return;
        results[i] = await task(items[i]);
      }
    }

    await Future.wait(List.generate(max, (_) => worker()));
    return results.whereType<T>().toList();
  }

  contacts.Contact _toMyContact(Contact contact) {
    final name = contact.name;
    final phones = contact.phones
        .map((p) => p.number.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final emails = contact.emails
        .map((e) => e.address.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    var displayName = contact.displayName;
    if (displayName.isEmpty) {
      final parts = [name.first, name.middle, name.last].where((s) => s.isNotEmpty);
      displayName = parts.join(' ');
    }
    return contacts.Contact(
      id: contact.id,
      displayName: displayName,
      phones: phones,
      emails: emails,
      structuredName: structured.StructuredName(
        namePrefix: name.prefix,
        givenName: name.first,
        middleName: name.middle,
        familyName: name.last,
        nameSuffix: name.suffix,
      ),
      avatar: contact.photoOrThumbnail,
    );
  }

  /// ===== HTTP/XML helpers =====

  Future<String> _requestXml(
    String method,
    Uri url, {
    required String body,
    Map<String, String>? headers,
    int redirectCount = 0,
  }) async {
    final authHeaders = await _authHeaders();
    final res = await _dio.requestUri(
      url,
      data: body,
      options: Options(
        method: method,
        responseType: ResponseType.plain,
        headers: {
          'Content-Type': 'text/xml',
          'Accept': '*/*',
          ...(headers ?? const {}),
          ...authHeaders,
        },
      ),
    );

    final status = res.statusCode ?? 0;
    if (status >= 300 && status < 400) {
      if (redirectCount >= 5) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          message: 'CardDAV $method $url failed: HTTP $status (too many redirects)',
          type: DioExceptionType.badResponse,
        );
      }
      final location = res.headers.value('location');
      if (location != null && location.isNotEmpty) {
        final nextUrl = url.resolve(location);
        return _requestXml(
          method,
          nextUrl,
          body: body,
          headers: headers,
          redirectCount: redirectCount + 1,
        );
      }
    }
    if (status < 200 || status >= 300) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: 'CardDAV $method $url failed: HTTP $status\n${res.data}',
        type: DioExceptionType.badResponse,
      );
    }

    final data = res.data;
    if (data is! String) return data.toString();
    return data;
  }

  /// Build an XML doc as string with declaration.
  String _xmlDoc(String rootName, Map<String, String> xmlns, List<XmlNode> children) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8"');
    builder.element(rootName, namespaces: xmlns, nest: () {
      for (final c in children) {
        builder.xml(c.toXmlString());
      }
    });
    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Resolve relative hrefs against base.
  Uri _resolve(Uri base, String href) {
    // CardDAV hrefs often start with '/', which Uri.resolve handles against full base.
    return base.resolve(href);
  }

  /// Extract the first href inside a given prop (by namespace/localName).
  String? _firstPropHref(XmlNode node, List<dynamic> nsAndLocal) {
    // nsAndLocal = [namespaceUri, localName]
    final ns = nsAndLocal[0] as String;
    final local = nsAndLocal[1] as String;

    final el = node
        .findAllElements(local, namespace: ns)
        .expand((e) => e.findAllElements('href', namespace: 'DAV:'))
        .map((e) => e.innerText.trim())
        .firstWhere((t) => t.isNotEmpty, orElse: () => '');

    return el.isEmpty ? null : el;
  }

  /// Read first matching property text among candidates.
  /// candidates: [ [namespaceUri, localName], ... ]
  String? _firstPropText(XmlNode node, List<List<String>> candidates) {
    for (final c in candidates) {
      final ns = c[0];
      final local = c[1];
      final txt = node
          .findAllElements(local, namespace: ns)
          .map((e) => e.innerText.trim())
          .firstWhere((t) => t.isNotEmpty, orElse: () => '');
      if (txt.isNotEmpty) return txt;
    }
    return null;
  }
}

/// Internal sync item
class _SyncItem {
  final Uri href;
  final String? etag;
  final bool deleted;

  _SyncItem({required this.href, required this.etag, required this.deleted});
}

class _SyncCollectionResult {
  final String? newSyncToken;
  final List<_SyncItem> items;

  _SyncCollectionResult({required this.newSyncToken, required this.items});
}
