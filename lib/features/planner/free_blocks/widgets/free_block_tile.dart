import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';

/// Renders a single free block entry.
class FreeBlockTile extends StatelessWidget {
  const FreeBlockTile({
    super.key,
    required this.interval,
    this.showDayLabel = false,
  });

  final TimeInterval interval;
  final bool showDayLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final locale = Localizations.localeOf(context);
    final use24HourFormat = mediaQuery.alwaysUse24HourFormat;

    final duration = interval.duration;
    final bool isAllDay = _coversWholeDay(interval);
    final bool isFullWeek = _coversWholeWeek(interval);
    final bool isMultiDay = !_isSameDay(interval.start, interval.end);

    String title;
    String? subtitle;
    String? trailingLabel;

    if (!showDayLabel && isAllDay) {
      title = 'All day free';
      subtitle = 'No calendar conflicts today.';
      trailingLabel = null;
    } else if (isFullWeek) {
      title = 'All week free';
      subtitle = 'Clear schedule for the next 7 days.';
      trailingLabel = null;
    } else if (showDayLabel && isMultiDay) {
      // Multi-day free block
      title =
          '${_formatDayLabel(interval.start, locale)} – ${_formatDayLabel(interval.end, locale)}';
      subtitle = 'Continuous free time';
      trailingLabel = _formatDuration(duration);
    } else if (showDayLabel) {
      // Single day free block with day label
      final startTime = TimeOfDay.fromDateTime(interval.start);
      final endTime = TimeOfDay.fromDateTime(interval.end);
      final timeRange =
          '${localizations.formatTimeOfDay(startTime, alwaysUse24HourFormat: use24HourFormat)} – ${localizations.formatTimeOfDay(endTime, alwaysUse24HourFormat: use24HourFormat)}';

      title = _formatDayLabel(interval.start, locale);
      subtitle = timeRange;
      trailingLabel = _formatDuration(duration);
    } else {
      // Today view - just show times
      final startTime = TimeOfDay.fromDateTime(interval.start);
      final endTime = TimeOfDay.fromDateTime(interval.end);
      final timeRange =
          '${localizations.formatTimeOfDay(startTime, alwaysUse24HourFormat: use24HourFormat)} – ${localizations.formatTimeOfDay(endTime, alwaysUse24HourFormat: use24HourFormat)}';

      title = timeRange;
      subtitle = null;
      trailingLabel = _formatDuration(duration);
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.event_available,
          color: theme.colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : null,
      trailing: trailingLabel != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                trailingLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      onTap: () {
        // Future enhancement: show detailed view of free time
        // For now, provide visual feedback that it's tappable
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  bool _coversWholeDay(TimeInterval interval) {
    final start = interval.start;
    final end = interval.end;
    final dayStart = DateTime(start.year, start.month, start.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return start.isAtSameMomentAs(dayStart) && end.isAtSameMomentAs(dayEnd);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _coversWholeWeek(TimeInterval interval) {
    final start = interval.start;
    final end = interval.end;

    final startDay = DateTime(start.year, start.month, start.day);
    final isMonday = startDay.weekday == DateTime.monday;
    final endOfWeek = startDay.add(const Duration(days: 7));

    if (!isMonday) {
      return false;
    }

    return end.isAtSameMomentAs(endOfWeek);
  }

  String _formatDayLabel(DateTime start, Locale locale) {
    final languageTag = locale.toLanguageTag();
    final weekdayFormatter = DateFormat.EEEE(languageTag);
    final dateFormatter = DateFormat.MMMd(languageTag);
    return '${weekdayFormatter.format(start)} · ${dateFormatter.format(start)}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}m';
  }
}
