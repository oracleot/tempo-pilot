import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo_pilot/data/local/app_database.dart';

void main() {
  late AppDatabase db;
  late CalendarEventsDao dao;

  setUp(() async {
    db = AppDatabase.inMemory();
    dao = db.calendarEventsDao;

    // Create test calendar sources to satisfy foreign key constraints
    await db.calendarSourceDao.upsertCalendarSources([
      LocalCalendarSourcesCompanion.insert(id: 'cal1', name: 'Test Calendar 1'),
      LocalCalendarSourcesCompanion.insert(id: 'cal2', name: 'Test Calendar 2'),
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  group('CalendarEventsDao', () {
    test('upsertEvent inserts a new event', () async {
      final event = LocalCalendarEventsCompanion.insert(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
        startTs: BigInt.from(1000),
        endTs: BigInt.from(2000),
      );

      await dao.upsertEvent(event);

      final result = await dao.getEvent(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
      );
      expect(result, isNotNull);
      expect(result!.eventId, 'event1');
      expect(result.calendarId, 'cal1');
      expect(result.startTs, BigInt.from(1000));
      expect(result.endTs, BigInt.from(2000));
      expect(result.isAllDay, false);
      expect(result.busyHint, isNull);
    });

    test('upsertEvent replaces existing event (idempotent)', () async {
      final event1 = LocalCalendarEventsCompanion.insert(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
        startTs: BigInt.from(1000),
        endTs: BigInt.from(2000),
      );

      await dao.upsertEvent(event1);

      // Upsert again with different times
      final event2 = LocalCalendarEventsCompanion.insert(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
        startTs: BigInt.from(1500),
        endTs: BigInt.from(2500),
      );

      await dao.upsertEvent(event2);

      final result = await dao.getEvent(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
      );
      expect(result, isNotNull);
      expect(result!.startTs, BigInt.from(1500));
      expect(result.endTs, BigInt.from(2500));
    });

    test('upsertEvents batch inserts multiple events', () async {
      final events = [
        LocalCalendarEventsCompanion.insert(
          eventId: 'event1',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(1000),
          startTs: BigInt.from(1000),
          endTs: BigInt.from(2000),
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'event2',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(3000),
          startTs: BigInt.from(3000),
          endTs: BigInt.from(4000),
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'event3',
          calendarId: 'cal2',
          instanceStartTs: BigInt.from(5000),
          startTs: BigInt.from(5000),
          endTs: BigInt.from(6000),
        ),
      ];

      await dao.upsertEvents(events);

      final count = await dao.getEventCount();
      expect(count, 3);
    });

    test('getEventsInWindow returns events overlapping time window', () async {
      // Event 1: [1000, 2000]
      // Event 2: [3000, 4000]
      // Event 3: [5000, 6000]
      final events = [
        LocalCalendarEventsCompanion.insert(
          eventId: 'event1',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(1000),
          startTs: BigInt.from(1000),
          endTs: BigInt.from(2000),
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'event2',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(3000),
          startTs: BigInt.from(3000),
          endTs: BigInt.from(4000),
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'event3',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(5000),
          startTs: BigInt.from(5000),
          endTs: BigInt.from(6000),
        ),
      ];

      await dao.upsertEvents(events);

      // Query window [2500, 4500] should return event2 only
      final result = await dao.getEventsInWindow(
        startMs: BigInt.from(2500),
        endMs: BigInt.from(4500),
      );

      expect(result.length, 1);
      expect(result[0].eventId, 'event2');
    });

    test('getEventsInWindow filters by calendar IDs', () async {
      final events = [
        LocalCalendarEventsCompanion.insert(
          eventId: 'event1',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(1000),
          startTs: BigInt.from(1000),
          endTs: BigInt.from(2000),
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'event2',
          calendarId: 'cal2',
          instanceStartTs: BigInt.from(1000),
          startTs: BigInt.from(1000),
          endTs: BigInt.from(2000),
        ),
      ];

      await dao.upsertEvents(events);

      final result = await dao.getEventsInWindow(
        startMs: BigInt.from(0),
        endMs: BigInt.from(3000),
        calendarIds: ['cal1'],
      );

      expect(result.length, 1);
      expect(result[0].calendarId, 'cal1');
    });

    test('softDeleteEvent marks event as deleted', () async {
      final event = LocalCalendarEventsCompanion.insert(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
        startTs: BigInt.from(1000),
        endTs: BigInt.from(2000),
      );

      await dao.upsertEvent(event);

      await dao.softDeleteEvent(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
      );

      // Soft-deleted events are excluded from normal queries
      final result = await dao.getEvent(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
      );
      expect(result, isNull);

      // But the event still exists in the database
      final count = await dao.getEventCount();
      expect(count, 0); // Excludes soft-deleted
    });

    test('deleteEventsForCalendar removes all events for a calendar', () async {
      final events = [
        LocalCalendarEventsCompanion.insert(
          eventId: 'event1',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(1000),
          startTs: BigInt.from(1000),
          endTs: BigInt.from(2000),
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'event2',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(3000),
          startTs: BigInt.from(3000),
          endTs: BigInt.from(4000),
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'event3',
          calendarId: 'cal2',
          instanceStartTs: BigInt.from(5000),
          startTs: BigInt.from(5000),
          endTs: BigInt.from(6000),
        ),
      ];

      await dao.upsertEvents(events);

      await dao.deleteEventsForCalendar('cal1');

      final remaining = await dao.getEventCount();
      expect(remaining, 1);

      final result = await dao.getEvent(
        eventId: 'event3',
        calendarId: 'cal2',
        instanceStartTs: BigInt.from(5000),
      );
      expect(result, isNotNull);
    });

    test('deleteEventsOlderThan removes old events', () async {
      final events = [
        LocalCalendarEventsCompanion.insert(
          eventId: 'event1',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(1000),
          startTs: BigInt.from(1000),
          endTs: BigInt.from(2000), // ends at 2000
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'event2',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(3000),
          startTs: BigInt.from(3000),
          endTs: BigInt.from(4000), // ends at 4000
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'event3',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(5000),
          startTs: BigInt.from(5000),
          endTs: BigInt.from(6000), // ends at 6000
        ),
      ];

      await dao.upsertEvents(events);

      // Delete events ending before 4500
      await dao.deleteEventsOlderThan(BigInt.from(4500));

      final remaining = await dao.getEventCount();
      expect(remaining, 1);

      final result = await dao.getEvent(
        eventId: 'event3',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(5000),
      );
      expect(result, isNotNull);
    });

    test('watchEventsInWindow emits updates', () async {
      final event = LocalCalendarEventsCompanion.insert(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
        startTs: BigInt.from(1000),
        endTs: BigInt.from(2000),
      );

      await dao.upsertEvent(event);

      final stream = dao.watchEventsInWindow(
        startMs: BigInt.from(0),
        endMs: BigInt.from(3000),
      );

      // First emission should have 1 event
      final first = await stream.first;
      expect(first.length, 1);

      // Add another event
      final event2 = LocalCalendarEventsCompanion.insert(
        eventId: 'event2',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1500),
        startTs: BigInt.from(1500),
        endTs: BigInt.from(2500),
      );
      await dao.upsertEvent(event2);

      // Stream should emit again with 2 events
      final second = await stream.first;
      expect(second.length, 2);
    });

    test('stores all-day events', () async {
      final event = LocalCalendarEventsCompanion.insert(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
        startTs: BigInt.from(1000),
        endTs: BigInt.from(2000),
        isAllDay: const Value(true),
      );

      await dao.upsertEvent(event);

      final result = await dao.getEvent(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
      );
      expect(result!.isAllDay, true);
    });

    test('stores busy hint', () async {
      final event = LocalCalendarEventsCompanion.insert(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
        startTs: BigInt.from(1000),
        endTs: BigInt.from(2000),
        busyHint: const Value(true),
      );

      await dao.upsertEvent(event);

      final result = await dao.getEvent(
        eventId: 'event1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
      );
      expect(result!.busyHint, true);
    });

    test(
      'getEventKeysInWindow returns event keys for tombstone diffing',
      () async {
        final events = [
          LocalCalendarEventsCompanion.insert(
            eventId: 'event1',
            calendarId: 'cal1',
            instanceStartTs: BigInt.from(1000),
            startTs: BigInt.from(1000),
            endTs: BigInt.from(2000),
          ),
          LocalCalendarEventsCompanion.insert(
            eventId: 'event2',
            calendarId: 'cal1',
            instanceStartTs: BigInt.from(3000),
            startTs: BigInt.from(3000),
            endTs: BigInt.from(4000),
          ),
        ];

        await dao.upsertEvents(events);

        final keys = await dao.getEventKeysInWindow(
          startMs: BigInt.from(0),
          endMs: BigInt.from(5000),
        );

        expect(keys.length, 2);
        expect(keys.contains(('event1', 'cal1', BigInt.from(1000))), true);
        expect(keys.contains(('event2', 'cal1', BigInt.from(3000))), true);
      },
    );

    test('markEventsDeleted tombstones multiple events', () async {
      final events = [
        LocalCalendarEventsCompanion.insert(
          eventId: 'event1',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(1000),
          startTs: BigInt.from(1000),
          endTs: BigInt.from(2000),
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'event2',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(3000),
          startTs: BigInt.from(3000),
          endTs: BigInt.from(4000),
        ),
      ];

      await dao.upsertEvents(events);

      // Mark event1 as deleted
      await dao.markEventsDeleted([
        ('event1', 'cal1', BigInt.from(1000)),
      ], DateTime.now().toUtc());

      // Only event2 should remain visible
      final count = await dao.getEventCount();
      expect(count, 1);

      final remaining = await dao.getEventsInWindow(
        startMs: BigInt.from(0),
        endMs: BigInt.from(5000),
      );
      expect(remaining.length, 1);
      expect(remaining[0].eventId, 'event2');
    });

    test('markEventsDeleted chunks large batches under SQLite limit', () async {
      const total = 400;
      final events = <LocalCalendarEventsCompanion>[];
      final keys = <(String, String, BigInt)>[];

      for (var i = 0; i < total; i++) {
        final start = BigInt.from(i * 1000);
        events.add(
          LocalCalendarEventsCompanion.insert(
            eventId: 'bulk_$i',
            calendarId: 'cal1',
            instanceStartTs: start,
            startTs: start,
            endTs: BigInt.from(i * 1000 + 500),
          ),
        );
        keys.add(('bulk_$i', 'cal1', start));
      }

      await dao.upsertEvents(events);

      expect(await dao.getEventCount(), total);

      await dao.markEventsDeleted(keys, DateTime.now().toUtc());

      expect(await dao.getEventCount(), 0);
    });

    test('supports recurring event instances with same eventId', () async {
      // Simulate recurring event: same eventId, different instance start times
      final events = [
        LocalCalendarEventsCompanion.insert(
          eventId: 'recurring1',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(1000), // First occurrence
          startTs: BigInt.from(1000),
          endTs: BigInt.from(2000),
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'recurring1',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(3000), // Second occurrence
          startTs: BigInt.from(3000),
          endTs: BigInt.from(4000),
        ),
        LocalCalendarEventsCompanion.insert(
          eventId: 'recurring1',
          calendarId: 'cal1',
          instanceStartTs: BigInt.from(5000), // Third occurrence
          startTs: BigInt.from(5000),
          endTs: BigInt.from(6000),
        ),
      ];

      await dao.upsertEvents(events);

      // All three instances should persist independently
      final count = await dao.getEventCount();
      expect(count, 3);

      // Each instance is retrievable by its unique key
      final first = await dao.getEvent(
        eventId: 'recurring1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(1000),
      );
      expect(first, isNotNull);
      expect(first!.startTs, BigInt.from(1000));

      final second = await dao.getEvent(
        eventId: 'recurring1',
        calendarId: 'cal1',
        instanceStartTs: BigInt.from(3000),
      );
      expect(second, isNotNull);
      expect(second!.startTs, BigInt.from(3000));
    });
  });
}
