/// Domain model representing a calendar event.
///
/// Privacy-first design: stores only timing information needed for free/busy
/// calculation. No titles, descriptions, locations, or attendee information.
class CalendarEvent {
  const CalendarEvent({
    required this.eventId,
    required this.calendarId,
    required this.start,
    required this.end,
    required this.isAllDay,
    this.busyHint,
  });

  /// Platform-specific event identifier
  final String eventId;

  /// Calendar this event belongs to
  final String calendarId;

  /// Event start time (local timezone)
  final DateTime start;

  /// Event end time (local timezone)
  final DateTime end;

  /// Whether this is an all-day event
  final bool isAllDay;

  /// Hint whether this event marks time as busy (null if unavailable)
  final bool? busyHint;

  /// Duration of the event
  Duration get duration => end.difference(start);

  CalendarEvent copyWith({
    String? eventId,
    String? calendarId,
    DateTime? start,
    DateTime? end,
    bool? isAllDay,
    bool? busyHint,
  }) {
    return CalendarEvent(
      eventId: eventId ?? this.eventId,
      calendarId: calendarId ?? this.calendarId,
      start: start ?? this.start,
      end: end ?? this.end,
      isAllDay: isAllDay ?? this.isAllDay,
      busyHint: busyHint ?? this.busyHint,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          calendarId == other.calendarId &&
          start == other.start &&
          end == other.end &&
          isAllDay == other.isAllDay &&
          busyHint == other.busyHint;

  @override
  int get hashCode =>
      eventId.hashCode ^
      calendarId.hashCode ^
      start.hashCode ^
      end.hashCode ^
      isAllDay.hashCode ^
      busyHint.hashCode;

  @override
  String toString() {
    return 'CalendarEvent('
        'eventId: $eventId, '
        'calendarId: $calendarId, '
        'start: $start, '
        'end: $end, '
        'isAllDay: $isAllDay, '
        'busyHint: $busyHint'
        ')';
  }
}
