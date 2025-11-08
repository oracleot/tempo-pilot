import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_event.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('FreeBusyDeriver', () {
    const deriver = FreeBusyDeriver();
    final london = tz.getLocation('Europe/London');

    CalendarEvent buildEvent({
      required String id,
      required tz.TZDateTime start,
      required tz.TZDateTime end,
      bool isAllDay = false,
      bool? busyHint,
    }) {
      return CalendarEvent(
        eventId: id,
        calendarId: 'primary',
        start: start,
        end: end,
        isAllDay: isAllDay,
        busyHint: busyHint,
      );
    }

    test('handles DST spring forward events without truncating duration', () {
      final windowStart = tz.TZDateTime(london, 2024, 3, 31, 0);
      final windowEnd = tz.TZDateTime(london, 2024, 3, 31, 6);
      final events = [
        buildEvent(
          id: 'dst-spring',
          start: tz.TZDateTime(london, 2024, 3, 31, 0, 30),
          end: tz.TZDateTime(london, 2024, 3, 31, 3, 30),
        ),
      ];

      final busy = deriver.deriveBusyIntervals(
        events: events,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      expect(busy, hasLength(1));
      expect(busy.first.start, events.first.start);
      expect(busy.first.end, events.first.end);
      expect(
        busy.first.duration,
        const Duration(hours: 3),
        reason: 'Spring forward day should still reflect 3 hours of focus time',
      );
    });

    test('handles DST fall back events by keeping repeated hour', () {
      final windowStart = tz.TZDateTime(london, 2024, 10, 27, 0);
      final windowEnd = tz.TZDateTime(london, 2024, 10, 27, 6);
      final events = [
        buildEvent(
          id: 'dst-fall',
          start: tz.TZDateTime(london, 2024, 10, 27, 0, 30),
          end: tz.TZDateTime(london, 2024, 10, 27, 4, 30),
        ),
      ];

      final busy = deriver.deriveBusyIntervals(
        events: events,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      expect(busy, hasLength(1));
      expect(busy.first.duration, const Duration(hours: 4));
      expect(
        busy.first.end,
        events.first.end,
        reason: 'The extra hour after clocks roll back should be preserved',
      );
    });

    test('splits all-day events per local day across DST boundary', () {
      final windowStart = tz.TZDateTime(london, 2024, 3, 30);
      final windowEnd = tz.TZDateTime(london, 2024, 4, 2);
      final events = [
        buildEvent(
          id: 'all-day',
          start: tz.TZDateTime(london, 2024, 3, 30),
          end: tz.TZDateTime(london, 2024, 4, 2),
          isAllDay: true,
        ),
      ];

      final busy = deriver.deriveBusyIntervals(
        events: events,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      expect(busy, hasLength(3));
      expect(busy[0].start, windowStart);
      expect(busy[0].end, tz.TZDateTime(london, 2024, 3, 31));
      expect(busy[1].start, tz.TZDateTime(london, 2024, 3, 31));
      expect(busy[1].end, tz.TZDateTime(london, 2024, 4, 1));
      expect(busy[2].start, tz.TZDateTime(london, 2024, 4, 1));
      expect(busy[2].end, windowEnd);
    });

    test('clamps cross-midnight events to window and exposes free slots', () {
      final windowStart = tz.TZDateTime(london, 2024, 4, 2, 0);
      final windowEnd = tz.TZDateTime(london, 2024, 4, 2, 8);
      final events = [
        buildEvent(
          id: 'overnight',
          start: tz.TZDateTime(london, 2024, 4, 1, 23),
          end: tz.TZDateTime(london, 2024, 4, 2, 2),
        ),
        buildEvent(
          id: 'morning',
          start: tz.TZDateTime(london, 2024, 4, 2, 4),
          end: tz.TZDateTime(london, 2024, 4, 2, 6),
        ),
      ];

      final busy = deriver.deriveBusyIntervals(
        events: events,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      expect(busy, hasLength(2));
      expect(busy.first.start, windowStart);
      expect(busy.first.end, tz.TZDateTime(london, 2024, 4, 2, 2));
      expect(busy.last.start, tz.TZDateTime(london, 2024, 4, 2, 4));
      expect(busy.last.end, tz.TZDateTime(london, 2024, 4, 2, 6));

      final free = deriver.deriveFreeFromBusy(
        busyIntervals: busy,
        windowStart: windowStart,
        windowEnd: windowEnd,
        minimumGap: const Duration(minutes: 15),
      );

      expect(free, hasLength(2));
      expect(free.first.start, tz.TZDateTime(london, 2024, 4, 2, 2));
      expect(free.first.end, tz.TZDateTime(london, 2024, 4, 2, 4));
      expect(free.last.start, tz.TZDateTime(london, 2024, 4, 2, 6));
      expect(free.last.end, windowEnd);
    });

    test(
      'merges large contiguous datasets without performance regressions',
      () {
        final windowStart = tz.TZDateTime(london, 2024, 4, 1, 8);
        final events = List<CalendarEvent>.generate(1500, (index) {
          final start = windowStart.add(Duration(minutes: index * 30));
          final end = start.add(const Duration(minutes: 30));
          return buildEvent(id: 'event-$index', start: start, end: end);
        });
        final windowEnd = events.last.end;

        final busy = deriver.deriveBusyIntervals(
          events: events,
          windowStart: windowStart,
          windowEnd: windowEnd,
        );

        expect(busy, hasLength(1));
        expect(busy.first.start, windowStart);
        expect(busy.first.end, windowEnd);
      },
    );
  });
}
