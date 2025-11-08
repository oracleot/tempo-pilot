import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_event.dart';

/// Service for reading calendar events from the device.
///
/// Fetches events for specified calendars within a time window and maps them
/// to our privacy-first CalendarEvent model (no titles/descriptions stored).
class CalendarEventsService {
  CalendarEventsService({DeviceCalendarPlugin? plugin})
    : _plugin = plugin ?? DeviceCalendarPlugin();

  final DeviceCalendarPlugin _plugin;

  /// Fetch events from specified calendars within a time window.
  ///
  /// [calendarIds] - List of calendar IDs to fetch from
  /// [start] - Start of time window (inclusive)
  /// [end] - End of time window (inclusive)
  ///
  /// Returns list of events with privacy-safe fields only.
  /// Recurring events are returned as expanded instances.
  Future<List<CalendarEvent>> fetchEvents({
    required List<String> calendarIds,
    required DateTime start,
    required DateTime end,
  }) async {
    if (calendarIds.isEmpty) {
      return [];
    }

    final events = <CalendarEvent>[];

    for (final calendarId in calendarIds) {
      try {
        final params = RetrieveEventsParams(startDate: start, endDate: end);

        // Attempt to enable recurrence expansion when supported by the plugin.
        try {
          // ignore: avoid_dynamic_calls
          (params as dynamic).includeOccurrences = true;
        } catch (error) {
          if (kDebugMode) {
            debugPrint(
              '[CalendarEventsService] includeOccurrences not supported by '
              'current device_calendar version: $error',
            );
          }
        }

        final result = await _plugin.retrieveEvents(calendarId, params);

        if (result.isSuccess && result.data != null) {
          for (final event in result.data!) {
            final mapped = _mapEventToModel(event, calendarId);
            if (mapped != null) {
              events.add(mapped);
            }
          }
        } else if (!result.isSuccess) {
          if (kDebugMode) {
            debugPrint(
              '[CalendarEventsService] Failed to retrieve events from '
              'calendar $calendarId: ${result.errors}',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[CalendarEventsService] Error fetching events from '
            'calendar $calendarId: $e',
          );
        }
        // Continue with other calendars even if one fails
      }
    }

    return events;
  }

  /// Map device calendar Event to our privacy-first CalendarEvent model.
  ///
  /// Privacy: Does NOT store title, description, location, or attendees.
  /// Only timing information needed for free/busy calculation.
  CalendarEvent? _mapEventToModel(Event event, String calendarId) {
    // Skip events without required fields
    if (event.eventId == null || event.start == null || event.end == null) {
      if (kDebugMode) {
        debugPrint(
          '[CalendarEventsService] Skipping event with missing required fields',
        );
      }
      return null;
    }

    // Normalize all-day events
    final start = event.start!;
    final end = event.end!;
    final isAllDay = event.allDay ?? false;

    // Map availability to tri-state: true (busy), false (free), null (unknown)
    final busyHint = _availabilityToBusy(event.availability);

    return CalendarEvent(
      eventId: event.eventId!,
      calendarId: calendarId,
      start: start,
      end: end,
      isAllDay: isAllDay,
      busyHint: busyHint,
    );
  }

  /// Visible for tests to guard the availability mapping contract.
  @visibleForTesting
  bool? availabilityToBusyForTesting(Availability? availability) =>
      _availabilityToBusy(availability);

  /// Map platform availability to busy/free hint.
  ///
  /// Returns:
  /// - true: busy, tentative, unavailable
  /// - false: free
  /// - null: null (not provided by platform)
  bool? _availabilityToBusy(Availability? availability) {
    if (availability == null) {
      return null;
    }

    switch (availability) {
      case Availability.Busy:
      case Availability.Tentative:
      case Availability.Unavailable:
        return true;
      case Availability.Free:
        return false;
    }
  }
}
