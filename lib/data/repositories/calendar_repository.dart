import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/data/local/app_database.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_event.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_events_service.dart';

/// Repository for calendar event operations.
///
/// Orchestrates fetching events from the device and persisting them locally.
/// Implements incremental refresh with clock skew tolerance and retry logic.
class CalendarRepository {
  CalendarRepository({
    required CalendarEventsDao dao,
    required CalendarEventsService eventsService,
    required AnalyticsService analytics,
  }) : _dao = dao,
       _eventsService = eventsService,
       _analytics = analytics;

  final CalendarEventsDao _dao;
  final CalendarEventsService _eventsService;
  final AnalyticsService _analytics;

  /// Fetch events for the next 7 days from included calendars and persist locally.
  ///
  /// Uses an overlap window of 1 hour to handle clock skew.
  /// Implements exponential backoff retry (1s, 2s, 4s; max 3 attempts).
  ///
  /// [calendarIds] - List of calendar IDs to fetch from (typically included calendars)
  /// [fromTime] - Start of fetch window (defaults to now minus 1 hour for overlap)
  /// [toTime] - End of fetch window (defaults to now plus 7 days plus 1 hour)
  ///
  /// Returns the number of events fetched and persisted.
  Future<int> fetchEvents7d({
    required List<String> calendarIds,
    DateTime? fromTime,
    DateTime? toTime,
  }) async {
    if (calendarIds.isEmpty) {
      if (kDebugMode) {
        debugPrint('[CalendarRepository] No calendars to fetch from');
      }
      return 0;
    }

    final now = DateTime.now().toUtc();
    final start = fromTime ?? now.subtract(const Duration(hours: 1));
    final end = toTime ?? now.add(const Duration(days: 7, hours: 1));

    _analytics.logEvent('calendar_events_fetch_started', {
      'calendar_count': calendarIds.length,
      'window_start': start.toIso8601String(),
      'window_end': end.toIso8601String(),
    });

    // Retry with exponential backoff
    const maxAttempts = 3;
    const backoffDurations = [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];

    List<CalendarEvent>? events;
    Exception? lastError;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        events = await _eventsService.fetchEvents(
          calendarIds: calendarIds,
          start: start,
          end: end,
        );
        break; // Success, exit retry loop
      } on Exception catch (e) {
        lastError = e;
        if (kDebugMode) {
          debugPrint(
            '[CalendarRepository] Fetch attempt ${attempt + 1} failed: $e',
          );
        }

        if (attempt < maxAttempts - 1) {
          await Future.delayed(backoffDurations[attempt]);
        }
      }
    }

    // If all retries failed, throw the last error
    if (events == null) {
      if (kDebugMode) {
        debugPrint(
          '[CalendarRepository] All fetch attempts failed. Last error: $lastError',
        );
      }
      _analytics.logEvent('calendar_events_fetch_failed', {
        'calendar_count': calendarIds.length,
        'error': lastError?.toString() ?? 'unknown',
      });
      throw lastError ??
          Exception('Failed to fetch events after $maxAttempts attempts');
    }

    // Perform tombstone diffing: find events that disappeared from the device source
    final startMs = BigInt.from(start.millisecondsSinceEpoch);
    final endMs = BigInt.from(end.millisecondsSinceEpoch);

    final existing = await _dao.getEventKeysInWindow(
      startMs: startMs,
      endMs: endMs,
      calendarIds: calendarIds,
    );

    final fetchedKeys = events.map((e) {
      return (
        e.eventId,
        e.calendarId,
        BigInt.from(e.start.millisecondsSinceEpoch),
      );
    }).toSet();

    final deleted = existing.difference(fetchedKeys);
    if (deleted.isNotEmpty) {
      await _dao.markEventsDeleted(deleted.toList(), now);
      if (kDebugMode) {
        debugPrint(
          '[CalendarRepository] Tombstoned ${deleted.length} deleted events',
        );
      }
    }

    // Persist to local database
    if (events.isNotEmpty) {
      await _upsertEvents(events);
    }

    if (kDebugMode) {
      debugPrint(
        '[CalendarRepository] Fetched and persisted ${events.length} events',
      );
    }

    _analytics.logEvent('calendar_events_fetch_succeeded', {
      'calendar_count': calendarIds.length,
      'event_count': events.length,
    });

    return events.length;
  }

  /// Upsert events into local database.
  ///
  /// Uses batch insert for performance with large event sets.
  Future<void> _upsertEvents(List<CalendarEvent> events) async {
    final companions = events.map((event) {
      final startMs = BigInt.from(event.start.millisecondsSinceEpoch);
      return LocalCalendarEventsCompanion(
        eventId: Value(event.eventId),
        calendarId: Value(event.calendarId),
        instanceStartTs: Value(
          startMs,
        ), // Use start time as instance discriminator
        startTs: Value(startMs),
        endTs: Value(BigInt.from(event.end.millisecondsSinceEpoch)),
        isAllDay: Value(event.isAllDay),
        busyHint: Value(event.busyHint),
      );
    }).toList();

    await _dao.upsertEvents(companions);
  }

  /// Get events in a time window from local storage.
  ///
  /// [start] - Start of time window
  /// [end] - End of time window
  /// [calendarIds] - Optional list of calendar IDs to filter by
  ///
  /// Returns list of events sorted by start time.
  Future<List<CalendarEvent>> getEventsInWindow({
    required DateTime start,
    required DateTime end,
    List<String>? calendarIds,
  }) async {
    final startMs = BigInt.from(start.millisecondsSinceEpoch);
    final endMs = BigInt.from(end.millisecondsSinceEpoch);

    final localEvents = await _dao.getEventsInWindow(
      startMs: startMs,
      endMs: endMs,
      calendarIds: calendarIds,
    );

    return localEvents.map(_mapLocalEventToModel).toList();
  }

  /// Watch events in a time window for reactive UI updates.
  Stream<List<CalendarEvent>> watchEventsInWindow({
    required DateTime start,
    required DateTime end,
    List<String>? calendarIds,
  }) {
    final startMs = BigInt.from(start.millisecondsSinceEpoch);
    final endMs = BigInt.from(end.millisecondsSinceEpoch);

    return _dao
        .watchEventsInWindow(
          startMs: startMs,
          endMs: endMs,
          calendarIds: calendarIds,
        )
        .map((localEvents) => localEvents.map(_mapLocalEventToModel).toList());
  }

  /// Delete events for a specific calendar.
  ///
  /// Used when a calendar is removed from the included list.
  Future<void> deleteEventsForCalendar(String calendarId) async {
    final deleted = await _dao.deleteEventsForCalendar(calendarId);
    if (kDebugMode) {
      debugPrint(
        '[CalendarRepository] Deleted $deleted events for calendar $calendarId',
      );
    }
  }

  /// Clean up events older than a given date.
  ///
  /// Used to prevent unbounded database growth.
  /// Typically called to remove events older than 30 days.
  Future<void> cleanupOldEvents(DateTime olderThan) async {
    final timestampMs = BigInt.from(olderThan.millisecondsSinceEpoch);
    final deleted = await _dao.deleteEventsOlderThan(timestampMs);
    if (kDebugMode) {
      debugPrint('[CalendarRepository] Cleaned up $deleted old events');
    }
  }

  /// Get count of events in the database (for debugging/stats).
  Future<int> getEventCount() => _dao.getEventCount();

  /// Map local Drift entity to domain model.
  CalendarEvent _mapLocalEventToModel(LocalCalendarEvent local) {
    return CalendarEvent(
      eventId: local.eventId,
      calendarId: local.calendarId,
      start: DateTime.fromMillisecondsSinceEpoch(local.startTs.toInt()),
      end: DateTime.fromMillisecondsSinceEpoch(local.endTs.toInt()),
      isAllDay: local.isAllDay,
      busyHint: local.busyHint,
    );
  }
}
