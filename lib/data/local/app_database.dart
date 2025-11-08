import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';
part 'tables.dart';
part 'daos/focus_session_dao.dart';
part 'daos/calendar_source_dao.dart';
part 'daos/calendar_events_dao.dart';

/// Manages creation and persistence of the SQLCipher key in secure storage.
class DatabaseEncryptionKeyManager {
  DatabaseEncryptionKeyManager({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'tempo_pilot.db.encryption_key';
  final FlutterSecureStorage _storage;

  /// Retrieves an existing key or generates a fresh 256-bit key.
  Future<String> obtainKey() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final key = _generateBase64Key();
    await _storage.write(key: _storageKey, value: key);
    return key;
  }

  /// Converts the stored key into a SQLCipher-compatible PRAGMA value.
  String toSqlCipherPragma(String base64Key) {
    final bytes = base64Url.decode(base64Key);
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return "x'$hex'";
  }

  Future<void> clearKey() => _storage.delete(key: _storageKey);

  String _generateBase64Key() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}

/// Drift database configured for encrypted on-device storage.
@DriftDatabase(
  tables: [
    LocalProfiles,
    LocalFocusSessions,
    LocalCalendarSources,
    LocalCalendarEvents,
  ],
  daos: [FocusSessionDao, CalendarSourceDao, CalendarEventsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.executor, {required this.encryptionEnabled});

  static const _dbFileName = 'tempo_pilot.db';
  final bool encryptionEnabled;

  /// Opens the database on a background isolate.
  /// Note: Encryption with SQLCipher requires additional native library setup.
  /// Currently using sqlite3_flutter_libs without encryption for stability.
  static Future<AppDatabase> open({
    DatabaseEncryptionKeyManager? keyManager,
    bool enableEncryption =
        false, // Disabled until SQLCipher is properly configured
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('AppDatabase does not run on web targets.');
    }

    final directory = await getApplicationSupportDirectory();
    final dbFile = File(p.join(directory.path, _dbFileName));
    if (!await dbFile.parent.exists()) {
      await dbFile.parent.create(recursive: true);
    }

    // Encryption disabled for now - sqlite3_flutter_libs doesn't include SQLCipher
    const encryptionActive = false;

    final executor = NativeDatabase.createInBackground(dbFile);

    return AppDatabase._(executor, encryptionEnabled: encryptionActive);
  }

  /// Lightweight constructor for testing with an in-memory database.
  factory AppDatabase.inMemory() {
    final executor = NativeDatabase.memory(logStatements: false);
    return AppDatabase._(executor, encryptionEnabled: false);
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add calendar_sources table in v2
        await m.createTable(localCalendarSources);
      }
      if (from < 3) {
        // Add calendar_events table in v3
        await m.createTable(localCalendarEvents);
      }
      if (from >= 3 && from < 4) {
        await _migrateCalendarEventsToV4(m);
      }
      if (from < 5) {
        await _ensureFocusSessionIndexes(m);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      if (kDebugMode) {
        if (details.wasCreated) {
          debugPrint(
            '[Drift] Database created at version ${details.versionNow}',
          );
        } else if (details.hadUpgrade) {
          debugPrint(
            '[Drift] Database upgraded from v${details.versionBefore} '
            'to v${details.versionNow}',
          );
        }
      }
    },
  );

  Future<void> _migrateCalendarEventsToV4(Migrator m) async {
    await _dropCalendarEventIndexes();
    await customStatement(
      'ALTER TABLE local_calendar_events RENAME TO local_calendar_events_old',
    );
    await m.createTable(localCalendarEvents);
    await customStatement(
      'INSERT INTO local_calendar_events ('
      'event_id, calendar_id, instance_start_ts, start_ts, end_ts, '
      'is_all_day, busy_hint, created_at, updated_at, deleted_at'
      ') '
      'SELECT '
      'event_id, calendar_id, start_ts, start_ts, end_ts, '
      'is_all_day, busy_hint, created_at, updated_at, deleted_at '
      'FROM local_calendar_events_old',
    );
    await customStatement('DROP TABLE local_calendar_events_old');
  }

  Future<void> _dropCalendarEventIndexes() async {
    await customStatement('DROP INDEX IF EXISTS idx_calendar_event_window');
    await customStatement('DROP INDEX IF EXISTS idx_event_start');
    await customStatement('DROP INDEX IF EXISTS idx_event_deleted');
  }

  Future<void> _ensureFocusSessionIndexes(Migrator m) async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_user_sessions_by_updated_at '
      'ON local_focus_sessions (user_id, updated_at)',
    );
  }
}
