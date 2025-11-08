import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/data/local/app_database.dart';
import 'package:tempo_pilot/data/repositories/calendar_repository.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_event.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_events_service.dart';

class MockCalendarEventsDao extends Mock implements CalendarEventsDao {}

class MockCalendarEventsService extends Mock implements CalendarEventsService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late CalendarEventsDao dao;
  late CalendarEventsService eventsService;
  late AnalyticsService analytics;
  late CalendarRepository repository;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(BigInt.zero);
    registerFallbackValue(DateTime.now().toUtc());
  });

  setUp(() {
    dao = MockCalendarEventsDao();
    eventsService = MockCalendarEventsService();
    analytics = MockAnalyticsService();

    when(() => analytics.logEvent(any(), any())).thenReturn(null);

    repository = CalendarRepository(
      dao: dao,
      eventsService: eventsService,
      analytics: analytics,
    );
  });

  group('CalendarRepository', () {
    test('fetchEvents7d fetches and persists events', () async {
      final now = DateTime.now().toUtc();
      final events = [
        CalendarEvent(
          eventId: 'event1',
          calendarId: 'cal1',
          start: now,
          end: now.add(const Duration(hours: 1)),
          isAllDay: false,
        ),
        CalendarEvent(
          eventId: 'event2',
          calendarId: 'cal1',
          start: now.add(const Duration(days: 1)),
          end: now.add(const Duration(days: 1, hours: 2)),
          isAllDay: false,
        ),
      ];

      when(
        () => eventsService.fetchEvents(
          calendarIds: any(named: 'calendarIds'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => events);

      when(
        () => dao.getEventKeysInWindow(
          startMs: any(named: 'startMs'),
          endMs: any(named: 'endMs'),
          calendarIds: any(named: 'calendarIds'),
        ),
      ).thenAnswer((_) async => <(String, String, BigInt)>{});

      when(() => dao.markEventsDeleted(any(), any())).thenAnswer((_) async {});

      when(() => dao.upsertEvents(any())).thenAnswer((_) async {});

      final count = await repository.fetchEvents7d(calendarIds: ['cal1']);

      expect(count, 2);

      verify(
        () => eventsService.fetchEvents(
          calendarIds: ['cal1'],
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).called(1);

      verify(() => dao.upsertEvents(any())).called(1);
      verify(
        () => analytics.logEvent('calendar_events_fetch_started', any()),
      ).called(1);
      verify(
        () => analytics.logEvent('calendar_events_fetch_succeeded', any()),
      ).called(1);
    });

    test('fetchEvents7d returns 0 for empty calendar list', () async {
      final count = await repository.fetchEvents7d(calendarIds: []);

      expect(count, 0);
      verifyNever(
        () => eventsService.fetchEvents(
          calendarIds: any(named: 'calendarIds'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      );
    });

    test('fetchEvents7d retries on failure with exponential backoff', () async {
      var attemptCount = 0;

      when(
        () => eventsService.fetchEvents(
          calendarIds: any(named: 'calendarIds'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async {
        attemptCount++;
        if (attemptCount < 3) {
          throw Exception('Network error');
        }
        return [
          CalendarEvent(
            eventId: 'event1',
            calendarId: 'cal1',
            start: DateTime.now().toUtc(),
            end: DateTime.now().toUtc().add(const Duration(hours: 1)),
            isAllDay: false,
          ),
        ];
      });

      when(
        () => dao.getEventKeysInWindow(
          startMs: any(named: 'startMs'),
          endMs: any(named: 'endMs'),
          calendarIds: any(named: 'calendarIds'),
        ),
      ).thenAnswer((_) async => <(String, String, BigInt)>{});

      when(() => dao.markEventsDeleted(any(), any())).thenAnswer((_) async {});

      when(() => dao.upsertEvents(any())).thenAnswer((_) async {});

      final count = await repository.fetchEvents7d(calendarIds: ['cal1']);

      expect(count, 1);
      expect(attemptCount, 3);

      verify(
        () => eventsService.fetchEvents(
          calendarIds: any(named: 'calendarIds'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).called(3);
      verify(
        () => analytics.logEvent('calendar_events_fetch_started', any()),
      ).called(1);
      verify(
        () => analytics.logEvent('calendar_events_fetch_succeeded', any()),
      ).called(1);
    });

    test('fetchEvents7d throws after max retries', () async {
      when(
        () => eventsService.fetchEvents(
          calendarIds: any(named: 'calendarIds'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenThrow(Exception('Network error'));

      await expectLater(
        repository.fetchEvents7d(calendarIds: ['cal1']),
        throwsException,
      );

      verify(
        () => eventsService.fetchEvents(
          calendarIds: any(named: 'calendarIds'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).called(3); // Max attempts
      verify(
        () => analytics.logEvent('calendar_events_fetch_failed', any()),
      ).called(1);
    });

    test('fetchEvents7d uses default time window', () async {
      when(
        () => eventsService.fetchEvents(
          calendarIds: any(named: 'calendarIds'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => []);

      when(
        () => dao.getEventKeysInWindow(
          startMs: any(named: 'startMs'),
          endMs: any(named: 'endMs'),
          calendarIds: any(named: 'calendarIds'),
        ),
      ).thenAnswer((_) async => <(String, String, BigInt)>{});

      when(() => dao.markEventsDeleted(any(), any())).thenAnswer((_) async {});

      when(() => dao.upsertEvents(any())).thenAnswer((_) async {});

      await repository.fetchEvents7d(calendarIds: ['cal1']);

      final captured = verify(
        () => eventsService.fetchEvents(
          calendarIds: any(named: 'calendarIds'),
          start: captureAny(named: 'start'),
          end: captureAny(named: 'end'),
        ),
      ).captured;

      final start = captured[0] as DateTime;
      final end = captured[1] as DateTime;

      // Check that window is approximately [now-1h, now+7d+1h]
      final now = DateTime.now().toUtc();
      expect(
        start.difference(now.subtract(const Duration(hours: 1))).abs(),
        lessThan(const Duration(seconds: 5)),
      );
      expect(
        end.difference(now.add(const Duration(days: 7, hours: 1))).abs(),
        lessThan(const Duration(seconds: 5)),
      );
    });

    test('fetchEvents7d uses custom time window when provided', () async {
      final customStart = DateTime(2025, 1, 1).toUtc();
      final customEnd = DateTime(2025, 1, 8).toUtc();

      when(
        () => eventsService.fetchEvents(
          calendarIds: any(named: 'calendarIds'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => []);

      when(
        () => dao.getEventKeysInWindow(
          startMs: any(named: 'startMs'),
          endMs: any(named: 'endMs'),
          calendarIds: any(named: 'calendarIds'),
        ),
      ).thenAnswer((_) async => <(String, String, BigInt)>{});

      when(() => dao.markEventsDeleted(any(), any())).thenAnswer((_) async {});

      when(() => dao.upsertEvents(any())).thenAnswer((_) async {});

      await repository.fetchEvents7d(
        calendarIds: ['cal1'],
        fromTime: customStart,
        toTime: customEnd,
      );

      verify(
        () => eventsService.fetchEvents(
          calendarIds: ['cal1'],
          start: customStart,
          end: customEnd,
        ),
      ).called(1);
    });

    test('fetchEvents7d tombstones deleted events', () async {
      // Existing events in DB
      final existingKeys = <(String, String, BigInt)>{
        ('event1', 'cal1', BigInt.from(1000)),
        ('event2', 'cal1', BigInt.from(2000)),
        ('event3', 'cal1', BigInt.from(3000)),
      };

      // Fetched events (event2 removed from device)
      final fetchedEvents = [
        CalendarEvent(
          eventId: 'event1',
          calendarId: 'cal1',
          start: DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
          end: DateTime.fromMillisecondsSinceEpoch(1500, isUtc: true),
          isAllDay: false,
        ),
        CalendarEvent(
          eventId: 'event3',
          calendarId: 'cal1',
          start: DateTime.fromMillisecondsSinceEpoch(3000, isUtc: true),
          end: DateTime.fromMillisecondsSinceEpoch(3500, isUtc: true),
          isAllDay: false,
        ),
      ];

      when(
        () => eventsService.fetchEvents(
          calendarIds: any(named: 'calendarIds'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => fetchedEvents);

      when(
        () => dao.getEventKeysInWindow(
          startMs: any(named: 'startMs'),
          endMs: any(named: 'endMs'),
          calendarIds: any(named: 'calendarIds'),
        ),
      ).thenAnswer((_) async => existingKeys);

      when(() => dao.markEventsDeleted(any(), any())).thenAnswer((_) async {});

      when(() => dao.upsertEvents(any())).thenAnswer((_) async {});

      await repository.fetchEvents7d(calendarIds: ['cal1']);

      // Verify event2 was tombstoned
      final captured =
          verify(
                () => dao.markEventsDeleted(captureAny(), any()),
              ).captured.first
              as List<(String, String, BigInt)>;

      expect(captured.length, 1);
      expect(captured[0], ('event2', 'cal1', BigInt.from(2000)));
    });

    test('deleteEventsForCalendar calls DAO', () async {
      when(() => dao.deleteEventsForCalendar(any())).thenAnswer((_) async => 5);

      await repository.deleteEventsForCalendar('cal1');

      verify(() => dao.deleteEventsForCalendar('cal1')).called(1);
    });

    test('cleanupOldEvents calls DAO with timestamp', () async {
      final olderThan = DateTime(2024, 1, 1).toUtc();

      when(() => dao.deleteEventsOlderThan(any())).thenAnswer((_) async => 10);

      await repository.cleanupOldEvents(olderThan);

      verify(
        () => dao.deleteEventsOlderThan(
          BigInt.from(olderThan.millisecondsSinceEpoch),
        ),
      ).called(1);
    });

    test('getEventCount calls DAO', () async {
      when(() => dao.getEventCount()).thenAnswer((_) async => 42);

      final count = await repository.getEventCount();

      expect(count, 42);
      verify(() => dao.getEventCount()).called(1);
    });
  });
}
