import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';

/// Formats free time intervals for injection into AI chat system prompts.
///
/// Privacy-first: coarsens data to 5-minute boundaries and limits the number
/// of intervals shared to prevent inference of exact meeting density.
class AiAvailabilityFormatter {
  const AiAvailabilityFormatter();

  /// Filters and coarsens raw free intervals for AI consumption.
  ///
  /// - Keeps only intervals that still have time remaining after [now]
  /// - Clamps the start to the later of the interval start and [now]
  /// - Keeps only intervals with duration >= [minDuration] after coarsening
  /// - Rounds start/end to nearest 5-minute boundaries
  /// - Sorts by start time ascending
  /// - Limits to first [maxCount] intervals
  List<TimeInterval> formatForAi(
    List<TimeInterval> raw, {
    DateTime? now,
    int maxCount = 12,
    Duration minDuration = const Duration(minutes: 15),
  }) {
    final effectiveNow = now ?? DateTime.now();
    final filtered = <TimeInterval>[];

    for (final interval in raw) {
      // Skip intervals that have already ended
      if (!interval.end.isAfter(effectiveNow)) {
        continue;
      }

      final clampedStart = interval.start.isBefore(effectiveNow)
          ? effectiveNow
          : interval.start;

      // Round to 5-minute boundaries (coarsen data for privacy).
      // Ceil the start so we never over-promise availability before it begins,
      // and floor the end so we never extend beyond the true busy boundary.
      final roundedStart = _ceilToFiveMinutes(clampedStart);
      final roundedEnd = _floorToFiveMinutes(interval.end);

      // Ensure rounding didn't eliminate the interval
      if (!roundedEnd.isAfter(roundedStart)) {
        continue;
      }

      // Ensure the interval is long enough after rounding
      if (roundedEnd.difference(roundedStart) < minDuration) {
        continue;
      }

      filtered.add(TimeInterval(start: roundedStart, end: roundedEnd));
    }

    // Sort by start time
    filtered.sort((a, b) => a.start.compareTo(b.start));

    // Limit to maxCount
    return filtered.length > maxCount
        ? filtered.sublist(0, maxCount)
        : filtered;
  }

  /// Converts formatted intervals to JSON for system prompt injection.
  ///
  /// Returns a structured object with timezone, generation timestamp, and interval list.
  Map<String, dynamic> toJson(
    List<TimeInterval> intervals,
    String timezone,
    DateTime generatedAt,
  ) {
    final offsetMinutes = generatedAt.timeZoneOffset.inMinutes;
    final offsetLabel = _formatOffset(offsetMinutes);
    final generatedAtUtc = generatedAt.toUtc();
    
    return {
      'tz': timezone,
      'tz_offset_minutes': offsetMinutes,
      'tz_offset': offsetLabel,
      'generated_at': generatedAt.toIso8601String(),
      'generated_at_utc': generatedAtUtc.toIso8601String(),
      'day': 'today',
      'day_iso': _formatDate(generatedAt),
      'intervals': intervals.map((interval) {
        return {
          'start': _formatTime(interval.start),
          'end': _formatTime(interval.end),
          'minutes': interval.duration.inMinutes,
        };
      }).toList(),
    };
  }

  /// Generates a system prompt string from the availability JSON.
  ///
  /// Explicitly instructs the AI to only use provided intervals and not invent others.
  String toSystemPrompt(Map<String, dynamic> json) {
    final intervals = json['intervals'] as List<dynamic>;
    final tz = json['tz'] as String? ?? 'local time';
    final offsetLabel = json['tz_offset'] as String?;
    final dayIso = json['day_iso'] as String?;
    final tzDescription = offsetLabel != null
        ? '$tz (UTC$offsetLabel)'
        : tz;
    final dayDescription = dayIso != null ? 'on $dayIso' : 'today';

    if (intervals.isEmpty) {
      return 'CALENDAR ACCESS: I have checked your calendar $dayDescription in $tzDescription and you have no free time available. Suggest the user review their schedule or consider another day.';
    }

    final formattedList = intervals
        .map((interval) {
          final start = interval['start'] as String;
          final end = interval['end'] as String;
          final minutes = interval['minutes'] as int;
          return '$start–$end ($minutes min)';
        })
        .join(', ');

    return 'CALENDAR ACCESS: I can see your free time $dayDescription in $tzDescription: $formattedList. IMPORTANT: Only use these exact time slots for suggestions. Do not invent or suggest times outside these intervals. When users ask about availability, refer to these specific times.';
  }

  /// Ceil a DateTime to the next 5-minute boundary (inclusive).
  DateTime _ceilToFiveMinutes(DateTime dt) {
    final totalMinutes = dt.hour * 60 + dt.minute;
    final roundedMinutes = ((totalMinutes + 4) ~/ 5) * 5;
    final hours = roundedMinutes ~/ 60;
    final minutes = roundedMinutes % 60;
    return DateTime(dt.year, dt.month, dt.day, hours, minutes);
  }

  /// Floor a DateTime to the previous 5-minute boundary (inclusive).
  DateTime _floorToFiveMinutes(DateTime dt) {
    final totalMinutes = dt.hour * 60 + dt.minute;
    final roundedMinutes = (totalMinutes ~/ 5) * 5;
    final hours = roundedMinutes ~/ 60;
    final minutes = roundedMinutes % 60;
    return DateTime(dt.year, dt.month, dt.day, hours, minutes);
  }

  /// Formats a DateTime as HH:mm.
  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatOffset(int offsetMinutes) {
    final sign = offsetMinutes >= 0 ? '+' : '-';
    final absMinutes = offsetMinutes.abs();
    final hours = (absMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (absMinutes % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  String _formatDate(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
