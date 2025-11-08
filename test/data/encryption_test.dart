import 'package:drift/drift.dart' show Value;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo_pilot/data/local/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock flutter_secure_storage for tests
  FlutterSecureStorage.setMockInitialValues({});

  group('Database Encryption', () {
    test('in-memory database does not use encryption', () {
      final db = AppDatabase.inMemory();

      expect(
        db.encryptionEnabled,
        isFalse,
        reason: 'In-memory databases should not use encryption',
      );

      db.close();
    });

    test('database can store and retrieve data', () async {
      final db = AppDatabase.inMemory();

      // Insert test profile
      await db
          .into(db.localProfiles)
          .insert(
            LocalProfilesCompanion.insert(
              id: 'test-user-encrypted',
              email: Value('test@example.com'),
            ),
          );

      // Insert test session
      await db.focusSessionDao.insertSession(
        LocalFocusSessionsCompanion.insert(
          id: 'session-encrypted-1',
          userId: 'test-user-encrypted',
          plannedDurationMinutes: 25,
        ),
      );

      // Verify data can be retrieved
      final session = await db.focusSessionDao.getById('session-encrypted-1');
      expect(session, isNotNull);
      expect(session!.userId, 'test-user-encrypted');
      expect(session.plannedDurationMinutes, 25);

      await db.close();
    });

    test('encryption key is persisted and reused', () async {
      final keyManager = DatabaseEncryptionKeyManager();

      // Get key first time
      final key1 = await keyManager.obtainKey();
      expect(key1, isNotEmpty);

      // Get key second time - should be the same
      final key2 = await keyManager.obtainKey();
      expect(
        key2,
        key1,
        reason: 'Encryption key should be persisted and reused',
      );

      // Clean up
      await keyManager.clearKey();
    });

    test('encryption key converts to valid SQLCipher PRAGMA format', () async {
      final keyManager = DatabaseEncryptionKeyManager();
      final base64Key = await keyManager.obtainKey();

      final pragmaValue = keyManager.toSqlCipherPragma(base64Key);

      expect(pragmaValue, startsWith("x'"));
      expect(pragmaValue, endsWith("'"));
      expect(
        pragmaValue.length,
        greaterThan(2),
        reason: 'PRAGMA key should have hex content',
      );

      // Clean up
      await keyManager.clearKey();
    });

    test('foreign key cascade delete works', () async {
      final db = AppDatabase.inMemory();

      // Insert profile
      final profile = LocalProfilesCompanion.insert(
        id: 'user-cascade-test',
        email: Value('cascade@example.com'),
      );
      await db.into(db.localProfiles).insert(profile);

      // Insert session referencing the profile
      await db.focusSessionDao.insertSession(
        LocalFocusSessionsCompanion.insert(
          id: 'session-cascade-1',
          userId: 'user-cascade-test',
          plannedDurationMinutes: 25,
        ),
      );

      // Verify session exists
      var session = await db.focusSessionDao.getById('session-cascade-1');
      expect(session, isNotNull);

      // Delete profile (should cascade to sessions due to onDelete: KeyAction.cascade)
      await (db.delete(
        db.localProfiles,
      )..where((tbl) => tbl.id.equals('user-cascade-test'))).go();

      // Verify session was deleted via cascade
      session = await db.focusSessionDao.getById('session-cascade-1');
      expect(
        session,
        isNull,
        reason: 'Session should be deleted when profile is deleted',
      );

      await db.close();
    });
  });
}
