part of 'package:tempo_pilot/data/local/app_database.dart';

DateTime _nowUtc() => DateTime.now().toUtc();

@DriftAccessor(tables: [LocalFocusSessions])
class FocusSessionDao extends DatabaseAccessor<AppDatabase>
    with _$FocusSessionDaoMixin {
  FocusSessionDao(super.db);

  Future<void> insertSession(LocalFocusSessionsCompanion entry) async {
    final now = _nowUtc();
    final payload = entry.copyWith(
      createdAt: entry.createdAt.present ? entry.createdAt : Value(now),
      updatedAt: entry.updatedAt.present ? entry.updatedAt : Value(now),
      synced: const Value(false),
    );

    await into(
      localFocusSessions,
    ).insert(payload, mode: InsertMode.insertOrReplace);
  }

  Future<int> updateSession(String id, LocalFocusSessionsCompanion updates) {
    return transaction(() async {
      final existing =
          await (select(localFocusSessions)
                ..where((tbl) => tbl.id.equals(id))
                ..limit(1))
              .getSingleOrNull();

      final now = _nowUtc();
      final previous = existing?.updatedAt.toUtc();
      final nextUpdatedAt = previous == null
          ? now
          : now.isAfter(previous)
          ? now
          : previous.add(const Duration(microseconds: 1));

      final payload = updates.copyWith(
        updatedAt: Value(nextUpdatedAt),
        synced: const Value(false),
      );

      return (update(
        localFocusSessions,
      )..where((tbl) => tbl.id.equals(id))).write(payload);
    });
  }

  Future<int> completeSession({
    required String id,
    required DateTime endedAt,
    required int actualDurationMinutes,
  }) {
    return updateSession(
      id,
      LocalFocusSessionsCompanion(
        endedAt: Value(endedAt.toUtc()),
        actualDurationMinutes: Value(actualDurationMinutes),
        completed: const Value(true),
      ),
    );
  }

  Future<int> softDeleteSession(String id) {
    return updateSession(
      id,
      LocalFocusSessionsCompanion(deletedAt: Value(_nowUtc())),
    );
  }

  Future<int> markAsSynced({
    required String id,
    required DateTime serverUpdatedAt,
  }) {
    final serverUtc = serverUpdatedAt.toUtc();

    return (update(
      localFocusSessions,
    )..where((tbl) => tbl.id.equals(id))).write(
      LocalFocusSessionsCompanion(
        synced: const Value(true),
        updatedAt: Value(serverUtc),
      ),
    );
  }

  Future<List<LocalFocusSession>> getUnsyncedSessions() {
    return (select(
      localFocusSessions,
    )..where((tbl) => tbl.synced.equals(false))).get();
  }

  Stream<List<LocalFocusSession>> watchActiveSessions(String userId) {
    return (select(localFocusSessions)
          ..where((tbl) => tbl.userId.equals(userId))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .watch();
  }

  Future<LocalFocusSession?> getById(String id) {
    return (select(
      localFocusSessions,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Gets the most recent running session for a user.
  /// Returns null if no running session exists.
  /// A running session is one where completed=false and deletedAt=null.
  Future<LocalFocusSession?> getRunningSession(String userId) {
    return (select(localFocusSessions)
          ..where((tbl) => tbl.userId.equals(userId))
          ..where((tbl) => tbl.completed.equals(false))
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}
