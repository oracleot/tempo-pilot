part of 'package:tempo_pilot/data/local/app_database.dart';

@DriftAccessor(tables: [LocalCalendarSources])
class CalendarSourceDao extends DatabaseAccessor<AppDatabase>
    with _$CalendarSourceDaoMixin {
  CalendarSourceDao(super.db);

  /// Insert or replace a calendar source.
  Future<void> upsertCalendarSource(LocalCalendarSourcesCompanion entry) async {
    final now = _nowUtc();
    final payload = entry.copyWith(
      createdAt: entry.createdAt.present ? entry.createdAt : Value(now),
      updatedAt: Value(now),
    );

    await into(
      localCalendarSources,
    ).insert(payload, mode: InsertMode.insertOrReplace);
  }

  /// Batch insert/replace multiple calendar sources.
  Future<void> upsertCalendarSources(
    List<LocalCalendarSourcesCompanion> entries,
  ) async {
    await batch((batch) {
      for (final entry in entries) {
        final now = _nowUtc();
        final payload = entry.copyWith(
          createdAt: entry.createdAt.present ? entry.createdAt : Value(now),
          updatedAt: Value(now),
        );
        batch.insert(
          localCalendarSources,
          payload,
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Update a calendar source's included status.
  Future<int> updateIncluded(String id, bool included) {
    final now = _nowUtc();
    return (update(
      localCalendarSources,
    )..where((tbl) => tbl.id.equals(id))).write(
      LocalCalendarSourcesCompanion(
        included: Value(included),
        updatedAt: Value(now),
      ),
    );
  }

  /// Get all calendar sources.
  Future<List<LocalCalendarSource>> getAllCalendarSources() {
    return select(localCalendarSources).get();
  }

  /// Get all included calendar sources.
  Future<List<LocalCalendarSource>> getIncludedCalendarSources() {
    return (select(
      localCalendarSources,
    )..where((tbl) => tbl.included.equals(true))).get();
  }

  /// Watch all calendar sources.
  Stream<List<LocalCalendarSource>> watchAllCalendarSources() {
    return select(localCalendarSources).watch();
  }

  /// Watch included calendar sources.
  Stream<List<LocalCalendarSource>> watchIncludedCalendarSources() {
    return (select(
      localCalendarSources,
    )..where((tbl) => tbl.included.equals(true))).watch();
  }

  /// Get a calendar source by ID.
  Future<LocalCalendarSource?> getById(String id) {
    return (select(
      localCalendarSources,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Clear all calendar sources (useful for re-discovery).
  Future<int> clearAll() {
    return delete(localCalendarSources).go();
  }

  /// Remove calendar sources whose identifiers are no longer discovered.
  Future<int> deleteByIds(Iterable<String> ids) {
    final idList = ids.toList();
    if (idList.isEmpty) {
      return Future.value(0);
    }
    return (delete(
      localCalendarSources,
    )..where((tbl) => tbl.id.isIn(idList))).go();
  }
}
