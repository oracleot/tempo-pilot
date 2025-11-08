import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo_pilot/data/local/app_database.dart';

void main() {
  late AppDatabase database;
  late FocusSessionDao dao;

  setUp(() async {
    database = AppDatabase.inMemory();
    dao = FocusSessionDao(database);

    await database
        .into(database.localProfiles)
        .insert(LocalProfilesCompanion.insert(id: 'user-1'));
  });

  tearDown(() async {
    await database.close();
  });

  test('insert session stores entry as unsynced', () async {
    final sessionId = 'session-1';
    final session = LocalFocusSessionsCompanion.insert(
      id: sessionId,
      userId: 'user-1',
      startedAt: Value(DateTime.utc(2025, 1, 1, 10)),
      plannedDurationMinutes: 25,
    );

    await dao.insertSession(session);

    final fetched = await dao.getById(sessionId);
    expect(fetched, isNotNull);
    expect(fetched!.synced, isFalse);
    expect(fetched.completed, isFalse);
  });

  test('markAsSynced persists server timestamp', () async {
    const sessionId = 'session-2';
    final insertedAt = DateTime.utc(2025, 1, 1, 12);
    await dao.insertSession(
      LocalFocusSessionsCompanion.insert(
        id: sessionId,
        userId: 'user-1',
        startedAt: Value(insertedAt),
        plannedDurationMinutes: 50,
        createdAt: Value(insertedAt),
        updatedAt: Value(insertedAt),
      ),
    );

    final remoteUpdatedAt = insertedAt.add(const Duration(hours: 2));
    await dao.markAsSynced(id: sessionId, serverUpdatedAt: remoteUpdatedAt);

    final fetched = await dao.getById(sessionId);
    expect(fetched, isNotNull);
    expect(fetched!.synced, isTrue);
    expect(fetched.updatedAt.toUtc(), remoteUpdatedAt);
  });

  test('completing a session resets synced flag', () async {
    const sessionId = 'session-3';
    await dao.insertSession(
      LocalFocusSessionsCompanion.insert(
        id: sessionId,
        userId: 'user-1',
        startedAt: Value(DateTime.utc(2025, 1, 1, 14)),
        plannedDurationMinutes: 45,
      ),
    );
    await dao.markAsSynced(
      id: sessionId,
      serverUpdatedAt: DateTime.utc(2025, 1, 1, 16),
    );

    await dao.completeSession(
      id: sessionId,
      endedAt: DateTime.utc(2025, 1, 1, 14, 45),
      actualDurationMinutes: 45,
    );

    final fetched = await dao.getById(sessionId);
    expect(fetched, isNotNull);
    expect(fetched!.completed, isTrue);
    expect(fetched.synced, isFalse);
  });

  test('local updates never regress updatedAt and mark as unsynced', () async {
    const sessionId = 'session-5';
    final base = DateTime.utc(2025, 1, 3, 9);
    await dao.insertSession(
      LocalFocusSessionsCompanion.insert(
        id: sessionId,
        userId: 'user-1',
        startedAt: Value(base),
        plannedDurationMinutes: 25,
        createdAt: Value(base),
        updatedAt: Value(base),
      ),
    );

    final initial = await dao.getById(sessionId);
    expect(initial, isNotNull);
    expect(initial!.synced, isFalse);
    expect(initial.updatedAt.toUtc(), base);

    await dao.markAsSynced(
      id: sessionId,
      serverUpdatedAt: base.add(const Duration(minutes: 10)),
    );

    final synced = await dao.getById(sessionId);
    expect(synced, isNotNull);
    expect(synced!.synced, isTrue);
    expect(synced.updatedAt.toUtc(), base.add(const Duration(minutes: 10)));

    await dao.updateSession(
      sessionId,
      LocalFocusSessionsCompanion(plannedDurationMinutes: const Value(30)),
    );

    final updated = await dao.getById(sessionId);
    expect(updated, isNotNull);
    expect(updated!.synced, isFalse);
    expect(updated.updatedAt.toUtc().isAfter(synced.updatedAt.toUtc()), isTrue);
  });

  test(
    'markAsSynced stores server timestamp even when earlier than local',
    () async {
      const sessionId = 'session-6';
      final base = DateTime.utc(2025, 1, 4, 10);
      await dao.insertSession(
        LocalFocusSessionsCompanion.insert(
          id: sessionId,
          userId: 'user-1',
          startedAt: Value(base),
          plannedDurationMinutes: 40,
          createdAt: Value(base),
          updatedAt: Value(base),
        ),
      );

      await dao.updateSession(
        sessionId,
        LocalFocusSessionsCompanion(plannedDurationMinutes: const Value(45)),
      );

      final locallyUpdated = await dao.getById(sessionId);
      expect(locallyUpdated, isNotNull);
      expect(locallyUpdated!.synced, isFalse);

      await dao.markAsSynced(id: sessionId, serverUpdatedAt: base);

      final after = await dao.getById(sessionId);
      expect(after, isNotNull);
      expect(after!.synced, isTrue);
      expect(after.updatedAt.toUtc(), base);
    },
  );

  test('soft delete keeps row pending sync', () async {
    const sessionId = 'session-4';
    await dao.insertSession(
      LocalFocusSessionsCompanion.insert(
        id: sessionId,
        userId: 'user-1',
        startedAt: Value(DateTime.utc(2025, 1, 2, 9)),
        plannedDurationMinutes: 30,
      ),
    );
    await dao.markAsSynced(
      id: sessionId,
      serverUpdatedAt: DateTime.utc(2025, 1, 2, 10),
    );

    await dao.softDeleteSession(sessionId);

    final unsynced = await dao.getUnsyncedSessions();
    expect(unsynced.map((s) => s.id), contains(sessionId));
  });
}
