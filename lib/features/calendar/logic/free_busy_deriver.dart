import 'package:tempo_pilot/features/calendar/models/calendar_event.dart';

/// Represents a contiguous time interval in local time.
class TimeInterval {
  TimeInterval({required this.start, required this.end})
    : assert(!end.isBefore(start), 'Interval end must be after start');

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  TimeInterval copyWith({DateTime? start, DateTime? end}) {
    return TimeInterval(start: start ?? this.start, end: end ?? this.end);
  }
}

/// Derives busy and free intervals from calendar events within a window.
class FreeBusyDeriver {
  const FreeBusyDeriver();

  /// Builds merged busy intervals for the provided events.
  List<TimeInterval> deriveBusyIntervals({
    required List<CalendarEvent> events,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    if (!windowEnd.isAfter(windowStart) || events.isEmpty) {
      return const <TimeInterval>[];
    }

    final candidates = <TimeInterval>[];

    for (final event in events) {
      if (event.busyHint == false) {
        // Explicitly marked as free — skip.
        continue;
      }

      if (event.isAllDay) {
        _expandAllDayEvent(
          event: event,
          windowStart: windowStart,
          windowEnd: windowEnd,
          out: candidates,
        );
      } else {
        // Events are already in local time, no conversion needed
        final localStart = event.start;
        final localEnd = event.end;

        final clampedStart = localStart.isBefore(windowStart)
            ? windowStart
            : localStart;
        final clampedEnd = localEnd.isAfter(windowEnd) ? windowEnd : localEnd;

        if (clampedEnd.isAfter(clampedStart)) {
          candidates.add(TimeInterval(start: clampedStart, end: clampedEnd));
        }
      }
    }

    if (candidates.isEmpty) {
      return const <TimeInterval>[];
    }

    candidates.sort((a, b) => a.start.compareTo(b.start));
    return _mergeIntervals(candidates);
  }

  /// Builds free intervals as the complement of [busyIntervals] within the window.
  List<TimeInterval> deriveFreeFromBusy({
    required List<TimeInterval> busyIntervals,
    required DateTime windowStart,
    required DateTime windowEnd,
    Duration minimumGap = Duration.zero,
  }) {
    if (!windowEnd.isAfter(windowStart)) {
      return const <TimeInterval>[];
    }

    final free = <TimeInterval>[];
    var cursor = windowStart;

    for (final busy in busyIntervals) {
      if (busy.start.isAfter(cursor)) {
        final candidate = TimeInterval(start: cursor, end: busy.start);
        if (candidate.duration >= minimumGap) {
          free.add(candidate);
        }
      }
      if (busy.end.isAfter(cursor)) {
        cursor = busy.end.isAfter(windowEnd) ? windowEnd : busy.end;
      }
      if (!cursor.isBefore(windowEnd)) {
        break;
      }
    }

    if (cursor.isBefore(windowEnd)) {
      final tail = TimeInterval(start: cursor, end: windowEnd);
      if (tail.duration >= minimumGap) {
        free.add(tail);
      }
    }

    return free;
  }

  /// Convenience helper that derives busy intervals and converts them to free blocks.
  List<TimeInterval> deriveFreeIntervals({
    required List<CalendarEvent> events,
    required DateTime windowStart,
    required DateTime windowEnd,
    Duration minimumGap = Duration.zero,
  }) {
    final busy = deriveBusyIntervals(
      events: events,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );

    return deriveFreeFromBusy(
      busyIntervals: busy,
      windowStart: windowStart,
      windowEnd: windowEnd,
      minimumGap: minimumGap,
    );
  }

  void _expandAllDayEvent({
    required CalendarEvent event,
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<TimeInterval> out,
  }) {
    // Events are already in local time
    final localStart = event.start;
    final localEnd = event.end;

    final eventStartDay = DateTime(
      localStart.year,
      localStart.month,
      localStart.day,
    );
    final eventEndDayExclusive = DateTime(
      localEnd.year,
      localEnd.month,
      localEnd.day,
    );

    final windowStartDay = DateTime(
      windowStart.year,
      windowStart.month,
      windowStart.day,
    );
    final windowEndDayExclusive = DateTime(
      windowEnd.year,
      windowEnd.month,
      windowEnd.day,
    );

    final boundedStartDay = eventStartDay.isBefore(windowStartDay)
        ? windowStartDay
        : eventStartDay;
    final boundedEndExclusive =
        eventEndDayExclusive.isAfter(windowEndDayExclusive)
        ? windowEndDayExclusive
        : eventEndDayExclusive;

    var cursorDay = boundedStartDay;
    while (cursorDay.isBefore(boundedEndExclusive)) {
      final dayStart = cursorDay.isBefore(windowStart)
          ? windowStart
          : cursorDay;
      final nextDay = cursorDay.add(const Duration(days: 1));
      final dayEnd = nextDay.isAfter(windowEnd) ? windowEnd : nextDay;

      if (dayEnd.isAfter(dayStart)) {
        out.add(TimeInterval(start: dayStart, end: dayEnd));
      }

      cursorDay = nextDay;
      if (!cursorDay.isBefore(windowEnd)) {
        break;
      }
    }
  }

  List<TimeInterval> _mergeIntervals(List<TimeInterval> intervals) {
    if (intervals.isEmpty) {
      return const <TimeInterval>[];
    }

    final merged = <TimeInterval>[];
    var current = intervals.first;

    for (var i = 1; i < intervals.length; i++) {
      final candidate = intervals[i];
      if (candidate.start.isBefore(current.end) ||
          candidate.start.isAtSameMomentAs(current.end)) {
        final newEnd = candidate.end.isAfter(current.end)
            ? candidate.end
            : current.end;
        current = current.copyWith(end: newEnd);
      } else {
        merged.add(current);
        current = candidate;
      }
    }

    merged.add(current);
    return merged;
  }
}
