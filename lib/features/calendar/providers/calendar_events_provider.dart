import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/data/repositories/calendar_repository.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_event.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_providers.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_events_service.dart';
import 'package:tempo_pilot/providers/database_provider.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';

/// Provider for CalendarEventsService
final calendarEventsServiceProvider = Provider<CalendarEventsService>((ref) {
  return CalendarEventsService();
});

/// Provider for CalendarRepository
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final eventsService = ref.watch(calendarEventsServiceProvider);
  final analytics = ref.watch(analyticsServiceProvider);

  return CalendarRepository(
    dao: db.calendarEventsDao,
    eventsService: eventsService,
    analytics: analytics,
  );
});

/// Provider for fetching events for the next 7 days.
///
/// Automatically fetches from all included calendars.
/// Returns AsyncValue with event count on success.
final fetchEvents7dProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(calendarRepositoryProvider);

  // Get included calendar IDs
  final includedCalendars = await ref.watch(
    includedCalendarSourcesProvider.future,
  );

  final calendarIds = includedCalendars.map((s) => s.id).toList();

  if (calendarIds.isEmpty) {
    return 0;
  }

  return repository.fetchEvents7d(calendarIds: calendarIds);
});

/// Provider for watching events in a time window.
///
/// [start] - Start of time window
/// [end] - End of time window
///
/// Returns a stream of events sorted by start time.
final eventsInWindowProvider = StreamProvider.autoDispose
    .family<List<CalendarEvent>, ({DateTime start, DateTime end})>((
      ref,
      params,
    ) {
      final repository = ref.watch(calendarRepositoryProvider);

      // Get included calendar IDs synchronously from state
      // We need the current value, not a future
      final includedCalendarsAsync = ref.watch(includedCalendarSourcesProvider);

      return includedCalendarsAsync.when(
        data: (calendars) {
          final calendarIds = calendars.map((s) => s.id).toList();

          if (calendarIds.isEmpty) {
            return Stream.value([]);
          }

          return repository.watchEventsInWindow(
            start: params.start,
            end: params.end,
            calendarIds: calendarIds,
          );
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
    });

/// Convenience provider for today's events.
final todaysEventsProvider = StreamProvider.autoDispose<List<CalendarEvent>>((
  ref,
) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return ref
      .watch(eventsInWindowProvider((start: startOfDay, end: endOfDay)))
      .when(
        data: (events) => Stream.value(events),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Convenience provider for this week's events.
final thisWeeksEventsProvider = StreamProvider.autoDispose<List<CalendarEvent>>(
  (ref) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));

    return ref
        .watch(eventsInWindowProvider((start: startOfWeekDay, end: endOfWeek)))
        .when(
          data: (events) => Stream.value(events),
          loading: () => Stream.value([]),
          error: (_, __) => Stream.value([]),
        );
  },
);
