import 'dart:async';
import 'dart:io';

import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

class Database {
  static int version = 5;

  static late final Store store;
  static late final Box<Attachment> attachments;
  static late final Box<Chat> chats;
  static late final Box<Contact> contacts;
  static late final Box<FCMData> fcmData;
  static late final Box<Handle> handles;
  static late final Box<Message> messages;
  static late final Box<ScheduledMessage> scheduledMessages;
  static late final Box<ThemeStruct> themes;
  static late final Box<ThemeEntry> themeEntries;

  // ignore: deprecated_member_use_from_same_package
  static late final Box<ThemeObject> themeObjects;

  static final Completer<void> initComplete = Completer();

  static Future<void> init() async {
    // Web doesn't use a database currently, so do not do anything
    if (kIsWeb) return;

    if (!kIsDesktop) {
      await _initDatabaseMobile();
    } else {
      await _initDatabaseDesktop();
    }

    try {
      Database.attachments = store.box<Attachment>();
      Database.chats = store.box<Chat>();
      Database.contacts = store.box<Contact>();
      Database.fcmData = store.box<FCMData>();
      Database.handles = store.box<Handle>();
      Database.messages = store.box<Message>();
      Database.themes = store.box<ThemeStruct>();
      Database.themeEntries = store.box<ThemeEntry>();
      // ignore: deprecated_member_use_from_same_package
      themeObjects = store.box<ThemeObject>();

      // we reset when apple logs out; don't wipe chats
      // this was supposed to ensure chats are deleted after reset.
      // if (!ss.settings.finishedSetup.value) {
      //   Database.attachments.removeAll();
      //   Database.chats.removeAll();
      //   Database.contacts.removeAll();
      //   Database.fcmData.removeAll();
      //   Database.handles.removeAll();
      //   Database.messages.removeAll();
      //   Database.themes.removeAll();
      //   Database.themeEntries.removeAll();
      //   themeObjects.removeAll();
      // }
    } catch (e, s) {
      Logger.error("Failed to setup ObjectBox boxes!", error: e, trace: s);
    }

    try {
      if (Database.themes.isEmpty()) {
        await ss.prefs.setString("selected-dark", "OLED Dark");
        await ss.prefs.setString("selected-light", "Bright White");
        Database.themes.putMany(ts.defaultThemes);
      }
    } catch (e, s) {
      Logger.error("Failed to seed themes!", error: e, trace: s);
    }

    try {
      _performDatabaseMigrations();

      // So long as migrations succeed, we can update the database version
      await ss.prefs.setInt('dbVersion', version);
    } catch (e, s) {
      Logger.error("Failed to perform database migrations!", error: e, trace: s);
    }

    initComplete.complete();
  }

  static Future<void> waitForInit() async {
    await initComplete.future;
  }

  /// Timeout for database open/attach operations to prevent indefinite blocking.
  static const Duration _dbOpenTimeout = Duration(seconds: 10);

  /// Maximum number of retry attempts for database initialization.
  static const int _maxRetries = 3;

  static bool _isDbLockError(String errorMsg) {
    final lower = errorMsg.toLowerCase();
    return lower.contains("another store is still open using the same path") ||
        lower.contains("lock") ||
        lower.contains("already in use") ||
        lower.contains("busy");
  }

  static bool _isDbCorruptionError(String errorMsg) {
    final lower = errorMsg.toLowerCase();
    return lower.contains("corrupt") ||
        lower.contains("invalid database") ||
        lower.contains("schema version mismatch") ||
        lower.contains("storageexception");
  }

  static Future<void> _initDatabaseMobile({bool? storeOpenStatus, int retryCount = 0}) async {
    final Stopwatch sw = Stopwatch()..start();
    Directory objectBoxDirectory = Directory(join(fs.appDocDir.path, 'objectbox'));
    final isStoreOpen = storeOpenStatus ?? Store.isOpen(objectBoxDirectory.path);

    try {
      if (isStoreOpen) {
        Logger.info("Attempting to attach to an existing ObjectBox store (attempt ${retryCount + 1})...", tag: "DB-Init");
        store = await Future(() => Store.attach(getObjectBoxModel(), objectBoxDirectory.path))
            .timeout(_dbOpenTimeout, onTimeout: () {
          throw TimeoutException("Store.attach() timed out after ${_dbOpenTimeout.inSeconds}s — another process may hold the lock");
        });
        Logger.info("Successfully attached to an existing ObjectBox store in ${sw.elapsedMilliseconds}ms", tag: "DB-Init");
      } else {
        Logger.info("Opening new ObjectBox store from path: ${objectBoxDirectory.path}", tag: "DB-Init");
        store = await openStore(directory: objectBoxDirectory.path, maxDBSizeInKB: 5 * 1024 * 1024)
            .timeout(_dbOpenTimeout, onTimeout: () {
          throw TimeoutException("openStore() timed out after ${_dbOpenTimeout.inSeconds}s — database may be locked");
        });
        Logger.info("Opened ObjectBox store in ${sw.elapsedMilliseconds}ms", tag: "DB-Init");
      }
    } on TimeoutException catch (e) {
      sw.stop();
      Logger.error("Database open timed out after ${sw.elapsedMilliseconds}ms", error: e, tag: "DB-Init");
      if (retryCount < _maxRetries) {
        Logger.info("Retrying database init (attempt ${retryCount + 2}/${_maxRetries + 1})...", tag: "DB-Init");
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
        await _initDatabaseMobile(storeOpenStatus: storeOpenStatus, retryCount: retryCount + 1);
      } else {
        Logger.error("All database open attempts exhausted. The database may be locked by another process.", tag: "DB-Init");
        rethrow;
      }
    } catch (e, s) {
      sw.stop();
      Logger.error("Failed to open ObjectBox store after ${sw.elapsedMilliseconds}ms!", error: e, trace: s, tag: "DB-Init");
      final errorMsg = e.toString();

      if (_isDbCorruptionError(errorMsg)) {
        Logger.error("Database appears corrupted. Backing up and recreating...", tag: "DB-Init");
        try {
          if (objectBoxDirectory.existsSync()) {
            final backupDir = Directory("${objectBoxDirectory.path}.backup");
            if (backupDir.existsSync()) {
              backupDir.deleteSync(recursive: true);
            }
            objectBoxDirectory.renameSync(backupDir.path);
            Logger.info("Corrupted database backed up to ${backupDir.path}", tag: "DB-Init");
          }
          objectBoxDirectory.createSync(recursive: true);
          store = await openStore(directory: objectBoxDirectory.path, maxDBSizeInKB: 5 * 1024 * 1024)
              .timeout(_dbOpenTimeout, onTimeout: () {
            throw TimeoutException("openStore() timed out during corruption recovery");
          });
          Logger.info("Successfully recreated ObjectBox store after corruption recovery. Old data backed up.", tag: "DB-Init");
          return;
        } catch (recoveryError, recoveryTrace) {
          Logger.error("Database corruption recovery failed!", error: recoveryError, trace: recoveryTrace, tag: "DB-Init");
          rethrow;
        }
      }

      if (_isDbLockError(errorMsg) && retryCount < _maxRetries) {
        Logger.info("Database locked. Retrying with attach (attempt ${retryCount + 2}/${_maxRetries + 1})...", tag: "DB-Init");
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
        await _initDatabaseMobile(storeOpenStatus: true, retryCount: retryCount + 1);
      } else if (retryCount >= _maxRetries) {
        Logger.error("All database open attempts exhausted.", tag: "DB-Init");
        rethrow;
      }
    }
  }

  static Future<void> _initDatabaseDesktop() async {
    final Stopwatch sw = Stopwatch()..start();
    Directory objectBoxDirectory = Directory(join(fs.appDocDir.path, 'objectbox'));

    try {
      objectBoxDirectory.createSync(recursive: true);
      if (ss.prefs.getBool('use-custom-path') == true && ss.prefs.getString('custom-path') != null) {
        Directory oldCustom = Directory(join(ss.prefs.getString('custom-path')!, 'objectbox'));
        if (oldCustom.existsSync()) {
          Logger.info("Detected prior use of custom path option. Migrating...", tag: "DB-Init");
          fs.copyDirectory(oldCustom, objectBoxDirectory);
        }
        await ss.prefs.remove('use-custom-path');
        await ss.prefs.remove('custom-path');
      }

      Logger.info("Opening ObjectBox store from path: ${objectBoxDirectory.path}", tag: "DB-Init");
      store = await openStore(directory: objectBoxDirectory.path)
          .timeout(_dbOpenTimeout, onTimeout: () {
        throw TimeoutException("Desktop openStore() timed out after ${_dbOpenTimeout.inSeconds}s");
      });
      Logger.info("Opened desktop ObjectBox store in ${sw.elapsedMilliseconds}ms", tag: "DB-Init");
    } catch (e, s) {
      sw.stop();
      final errorMsg = e.toString();

      if (Platform.isLinux && _isDbLockError(errorMsg)) {
        Logger.debug("Another instance is probably running. Sending foreground signal", tag: "DB-Init");
        final instanceFile = File(join(fs.appDocDir.path, '.instance'));
        instanceFile.openSync(mode: FileMode.write).closeSync();
        exit(0);
      }

      if (_isDbCorruptionError(errorMsg)) {
        Logger.error("Desktop database appears corrupted. Backing up and recreating...", error: e, trace: s, tag: "DB-Init");
        try {
          if (objectBoxDirectory.existsSync()) {
            final backupDir = Directory("${objectBoxDirectory.path}.backup");
            if (backupDir.existsSync()) {
              backupDir.deleteSync(recursive: true);
            }
            objectBoxDirectory.renameSync(backupDir.path);
            Logger.info("Corrupted database backed up to ${backupDir.path}", tag: "DB-Init");
          }
          objectBoxDirectory.createSync(recursive: true);
          store = await openStore(directory: objectBoxDirectory.path)
              .timeout(_dbOpenTimeout, onTimeout: () {
            throw TimeoutException("Desktop openStore() timed out during corruption recovery");
          });
          Logger.info("Successfully recreated desktop ObjectBox store after corruption recovery. Old data backed up.", tag: "DB-Init");
          return;
        } catch (recoveryError, recoveryTrace) {
          Logger.error("Desktop database corruption recovery failed!", error: recoveryError, trace: recoveryTrace, tag: "DB-Init");
        }
      }

      Logger.error("Failed to initialize desktop database after ${sw.elapsedMilliseconds}ms!", error: e, trace: s, tag: "DB-Init");
    }
  }

  static void _performDatabaseMigrations({int? versionOverride}) {
    int version = versionOverride ?? ss.prefs.getInt('dbVersion') ?? (ss.settings.finishedSetup.value ? 1 : Database.version);
    if (version <= Database.version) return;

    final Stopwatch s = Stopwatch();
    s.start();

    int nextVersion = version;
    Logger.debug("Performing database migration from version $version to ${Database.version}", tag: "DB-Migration");
    switch (Database.version) {
      // Version 2 changed handleId to match the server side ROWID, rather than client side ROWID
      case 2:
        Logger.info("Fetching all messages and handles...", tag: "DB-Migration");
        final messages = Database.messages.getAll();
        if (messages.isNotEmpty) {
          final handles = Database.handles.getAll();
          Logger.info("Replacing handleIds for messages...", tag: "DB-Migration");
          for (Message m in messages) {
            if (m.isFromMe! || m.handleId == 0 || m.handleId == null) continue;
            m.handleId = handles.firstWhereOrNull((e) => e.id == m.handleId)?.originalROWID ?? m.handleId;
          }
          Logger.info("Final save...", tag: "DB-Migration");
          Database.messages.putMany(messages);
        }

        nextVersion = 2;
      // Version 3 modifies chat typing indicators and read receipts values to follow global setting initially
      case 3:
        final chats = Database.chats.getAll();
        final papi = ss.settings.enablePrivateAPI.value;
        final typeGlobal = ss.settings.privateSendTypingIndicators.value;
        final readGlobal = ss.settings.privateMarkChatAsRead.value;
        for (Chat c in chats) {
          if (papi && readGlobal && !(c.autoSendReadReceipts ?? true)) {
            // dont do anything
          } else {
            c.autoSendReadReceipts = null;
          }
          if (papi && typeGlobal && !(c.autoSendTypingIndicators ?? true)) {
            // dont do anything
          } else {
            c.autoSendTypingIndicators = null;
          }
        }

        Database.chats.putMany(chats);
        nextVersion = 3;
      // Version 4 saves FCM Data to the shared preferences for use in Tasker integration
      case 4:
        ss.getFcmData();
        ss.fcmData.save();
        nextVersion = 4;
      case 5:
        // Find the Bright White theme and reset it back to the default (new colors)
        final brightWhite = Database.themes.query(ThemeStruct_.name.equals("Bright White")).build().findFirst();
        if (brightWhite != null) {
          brightWhite.data = ts.whiteLightTheme;
          Database.themes.put(brightWhite, mode: PutMode.update);
        }

        // Find the OLED theme and reset it back to the default (new colors)
        final oled = Database.themes.query(ThemeStruct_.name.equals("OLED Dark")).build().findFirst();
        if (oled != null) {
          oled.data = ts.oledDarkTheme;
          Database.themes.put(oled, mode: PutMode.update);
        }
    }

    if (nextVersion != version) {
      _performDatabaseMigrations(versionOverride: nextVersion);
    }

    s.stop();
    Logger.info("Completed database migration in ${s.elapsedMilliseconds}ms", tag: "DB-Migration");
  }

  /// Wrapper for store.runInTransaction
  static R runInTransaction<R>(TxMode mode, R Function() fn) {
    return store.runInTransaction(mode, fn);
  }

  static reset() {
    Database.attachments.removeAll();
    Database.chats.removeAll();
    Database.fcmData.removeAll();
    Database.contacts.removeAll();
    Database.handles.removeAll();
    Database.messages.removeAll();
    Database.themes.removeAll();
  }
}