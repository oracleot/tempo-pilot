import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_source.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_providers.dart';

/// State for the calendar picker screen.
class CalendarPickerState {
  const CalendarPickerState({
    required this.query,
    required this.allSources,
    required this.filteredSources,
  });

  final String query;
  final List<CalendarSource> allSources;
  final List<CalendarSource> filteredSources;

  int get totalCount => allSources.length;

  int get includedCount => allSources.where((source) => source.included).length;

  bool get isSearching => query.trim().isNotEmpty;

  bool get hasResults => filteredSources.isNotEmpty;
}

/// Holds the current search query for the picker UI.
final calendarPickerSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Computes the picker state by combining the persisted sources with the
/// current search query.
final calendarPickerStateProvider =
    Provider.autoDispose<AsyncValue<CalendarPickerState>>((ref) {
      final query = ref.watch(calendarPickerSearchQueryProvider);
      final sourcesAsync = ref.watch(persistedCalendarSourcesProvider);

      return sourcesAsync.whenData((sources) {
        final filtered = filterCalendars(sources, query);
        return CalendarPickerState(
          query: query,
          allSources: List<CalendarSource>.unmodifiable(sources),
          filteredSources: filtered,
        );
      });
    });

/// Filters calendars by name, account name, or account type using a
/// case-insensitive contains check.
List<CalendarSource> filterCalendars(
  List<CalendarSource> sources,
  String query,
) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return List<CalendarSource>.unmodifiable(sources);
  }

  final normalizedQuery = trimmed.toLowerCase();

  final filtered = sources
      .where((source) {
        final name = source.name.toLowerCase();
        final accountName = source.accountName?.toLowerCase() ?? '';
        final accountType = source.accountType?.toLowerCase() ?? '';

        return name.contains(normalizedQuery) ||
            accountName.contains(normalizedQuery) ||
            accountType.contains(normalizedQuery);
      })
      .toList(growable: false);

  return List<CalendarSource>.unmodifiable(filtered);
}
