part of 'package:tempo_pilot/data/local/app_database.dart';

@DriftAccessor(tables: [LocalCalendarEvents])
class CalendarEventsDao extends DatabaseAccessor<AppDatabase>
    with _$CalendarEventsDaoMixin {
  CalendarEventsDao(super.db);

  /// Insert or replace a batch of events.
  /// Uses upsert semantics for idempotency.
  Future<void> upsertEvents(List<LocalCalendarEventsCompanion> events) async {
    if (events.isEmpty) return;

    final now = _nowUtc();
    final payload = events.map((event) {
      return event.copyWith(
        createdAt: event.createdAt.present ? event.createdAt : Value(now),
        updatedAt: Value(now),
      );
    }).toList();

    // Use batch insert for performance with large event sets
    await batch((batch) {
      batch.insertAll(
        localCalendarEvents,
        payload,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Insert or replace a single event.
  Future<void> upsertEvent(LocalCalendarEventsCompanion event) async {
    final now = _nowUtc();
    final payload = event.copyWith(
      createdAt: event.createdAt.present ? event.createdAt : Value(now),
      updatedAt: Value(now),
    );

    await into(
      localCalendarEvents,
    ).insert(payload, mode: InsertMode.insertOrReplace);
  }

  /// Soft delete an event by marking deletedAt.
  Future<int> softDeleteEvent({
    required String eventId,
    required String calendarId,
    required BigInt instanceStartTs,
  }) {
    final now = _nowUtc();
    return (update(localCalendarEvents)
          ..where((tbl) => tbl.eventId.equals(eventId))
          ..where((tbl) => tbl.calendarId.equals(calendarId))
          ..where((tbl) => tbl.instanceStartTs.equals(instanceStartTs)))
        .write(
          LocalCalendarEventsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  /// Get events in a time window [startMs, endMs] from included calendars.
  /// Excludes soft-deleted events.
  Future<List<LocalCalendarEvent>> getEventsInWindow({
    required BigInt startMs,
    required BigInt endMs,
    List<String>? calendarIds,
  }) {
    final query = select(localCalendarEvents)
      ..where((tbl) => tbl.deletedAt.isNull())
      ..where((tbl) => tbl.startTs.isSmallerThanValue(endMs))
      ..where((tbl) => tbl.endTs.isBiggerThanValue(startMs))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.startTs)]);

    if (calendarIds != null && calendarIds.isNotEmpty) {
      query.where((tbl) => tbl.calendarId.isIn(calendarIds));
    }

    return query.get();
  }

  /// Watch events in a time window for reactive UI updates.
  Stream<List<LocalCalendarEvent>> watchEventsInWindow({
    required BigInt startMs,
    required BigInt endMs,
    List<String>? calendarIds,
  }) {
    final query = select(localCalendarEvents)
      ..where((tbl) => tbl.deletedAt.isNull())
      ..where((tbl) => tbl.startTs.isSmallerThanValue(endMs))
      ..where((tbl) => tbl.endTs.isBiggerThanValue(startMs))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.startTs)]);

    if (calendarIds != null && calendarIds.isNotEmpty) {
      query.where((tbl) => tbl.calendarId.isIn(calendarIds));
    }

    return query.watch();
  }

  /// Get a specific event by its composite key.
  Future<LocalCalendarEvent?> getEvent({
    required String eventId,
    required String calendarId,
    required BigInt instanceStartTs,
  }) {
    return (select(localCalendarEvents)
          ..where((tbl) => tbl.eventId.equals(eventId))
          ..where((tbl) => tbl.calendarId.equals(calendarId))
          ..where((tbl) => tbl.instanceStartTs.equals(instanceStartTs))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Delete all events for a specific calendar.
  /// Used when a calendar is removed from included list.
  Future<int> deleteEventsForCalendar(String calendarId) {
    return (delete(
      localCalendarEvents,
    )..where((tbl) => tbl.calendarId.equals(calendarId))).go();
  }

  /// Hard delete events older than a certain timestamp.
  /// Used for cleanup to prevent unbounded growth.
  Future<int> deleteEventsOlderThan(BigInt timestampMs) {
    return (delete(
      localCalendarEvents,
    )..where((tbl) => tbl.endTs.isSmallerThanValue(timestampMs))).go();
  }

  /// Get count of events in the database (for debugging/stats).
  Future<int> getEventCount() async {
    final count = countAll();
    final query = selectOnly(localCalendarEvents)
      ..addColumns([count])
      ..where(localCalendarEvents.deletedAt.isNull());

    final result = await query.getSingleOrNull();
    return result?.read(count) ?? 0;
  }

  /// Get event keys (eventId, calendarId, instanceStartTs) in a time window.
  /// Used for tombstone diffing to detect deleted events.
  Future<Set<(String, String, BigInt)>> getEventKeysInWindow({
    required BigInt startMs,
    required BigInt endMs,
    List<String>? calendarIds,
  }) async {
    final query = selectOnly(localCalendarEvents)
      ..addColumns([
        localCalendarEvents.eventId,
        localCalendarEvents.calendarId,
        localCalendarEvents.instanceStartTs,
      ])
      ..where(localCalendarEvents.deletedAt.isNull())
      ..where(localCalendarEvents.startTs.isSmallerThanValue(endMs))
      ..where(localCalendarEvents.endTs.isBiggerThanValue(startMs));

    if (calendarIds != null && calendarIds.isNotEmpty) {
      query.where(localCalendarEvents.calendarId.isIn(calendarIds));
    }

    final results = await query.get();
    return results.map((row) {
      return (
        row.read(localCalendarEvents.eventId)!,
        row.read(localCalendarEvents.calendarId)!,
        row.read(localCalendarEvents.instanceStartTs)!,
      );
    }).toSet();
  }

  /// Mark events as deleted via tombstones.
  /// Used for incremental refresh to track events removed from device.
  Future<void> markEventsDeleted(
    List<(String, String, BigInt)> eventKeys,
    DateTime deletedAt,
  ) async {
    if (eventKeys.isEmpty) return;

    const chunkSize = 250; // 250 * 3 params = 750 < SQLite 999 limit
    final utcDeletedAt = deletedAt.toUtc().toIso8601String();

    for (var offset = 0; offset < eventKeys.length; offset += chunkSize) {
      final chunk = eventKeys.sublist(
        offset,
        offset + chunkSize > eventKeys.length
            ? eventKeys.length
            : offset + chunkSize,
      );

      final placeholders = List.filled(chunk.length, '(?, ?, ?)').join(', ');
      final args = <Object?>[utcDeletedAt, utcDeletedAt];

      for (final (eventId, calendarId, instanceStartTs) in chunk) {
        args
          ..add(eventId)
          ..add(calendarId)
          ..add(instanceStartTs.toInt());
      }

      await customStatement(
        'UPDATE local_calendar_events '
        'SET deleted_at = ?, updated_at = ? '
        'WHERE (event_id, calendar_id, instance_start_ts) IN ($placeholders)',
        args,
      );
    }
  }
}
