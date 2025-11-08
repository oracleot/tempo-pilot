import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_source.dart';
import 'package:tempo_pilot/features/calendar/permissions/calendar_permission_provider.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_discovery_service.dart';
import 'package:tempo_pilot/providers/database_provider.dart';
import 'package:tempo_pilot/data/local/app_database.dart';
import 'package:drift/drift.dart';

export 'package:tempo_pilot/features/calendar/permissions/calendar_permission_provider.dart'
    show
        CalendarPermissionController,
        calendarPermissionServiceProvider,
        calendarPermissionStatusProvider;

/// Provider for the calendar discovery service.
final calendarDiscoveryServiceProvider = Provider<CalendarDiscoveryService>(
  (ref) => CalendarDiscoveryService(),
);

/// Provider for the CalendarSourceDao.
final calendarSourceDaoProvider = Provider((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.calendarSourceDao;
});

/// Provider for discovered calendar sources.
final discoveredCalendarSourcesProvider = FutureProvider<List<CalendarSource>>((
  ref,
) async {
  // Only discover calendars if permission is granted
  final permissionStatus = await ref.watch(
    calendarPermissionStatusProvider.future,
  );

  if (permissionStatus != CalendarPermissionStatus.granted) {
    return [];
  }

  final service = ref.watch(calendarDiscoveryServiceProvider);
  return service.listCalendars();
});

/// Provider for persisted calendar sources from the database.
final persistedCalendarSourcesProvider = StreamProvider<List<CalendarSource>>((
  ref,
) {
  final dao = ref.watch(calendarSourceDaoProvider);
  return dao.watchAllCalendarSources().map(
    (sources) => sources
        .map(
          (s) => CalendarSource(
            id: s.id,
            name: s.name,
            accountName: s.accountName,
            accountType: s.accountType,
            isPrimary: s.isPrimary,
            included: s.included,
          ),
        )
        .toList(),
  );
});

/// Provider for included (enabled) calendar sources.
/// Filters to only show included calendars that are also primary.
final includedCalendarSourcesProvider = StreamProvider<List<CalendarSource>>((
  ref,
) {
  final dao = ref.watch(calendarSourceDaoProvider);
  return dao.watchIncludedCalendarSources().map(
    (sources) => sources
        .where((s) => s.isPrimary) // Only include primary calendars
        .map(
          (s) => CalendarSource(
            id: s.id,
            name: s.name,
            accountName: s.accountName,
            accountType: s.accountType,
            isPrimary: s.isPrimary,
            included: s.included,
          ),
        )
        .toList(),
  );
});

/// Action provider for persisting discovered calendars.
final persistCalendarSourcesProvider = Provider((ref) {
  return (List<CalendarSource> sources) async {
    final dao = ref.read(calendarSourceDaoProvider);
    final existing = await dao.getAllCalendarSources();
    final existingMap = {for (final entry in existing) entry.id: entry};
    final discoveredIds = sources.map((s) => s.id).toSet();

    final companions = sources.map((source) {
      final current = existingMap[source.id];
      final includeFlag = current?.included ?? source.included;

      return LocalCalendarSourcesCompanion.insert(
        id: source.id,
        name: source.name,
        accountName: Value(source.accountName),
        accountType: Value(source.accountType),
        isPrimary: Value(source.isPrimary),
        included: Value(includeFlag),
      );
    }).toList();

    await dao.upsertCalendarSources(companions);

    final staleIds = existingMap.keys.where(
      (id) => !discoveredIds.contains(id),
    );
    if (staleIds.isNotEmpty) {
      await dao.deleteByIds(staleIds);
    }
  };
});

/// Action provider for updating a calendar source's included status.
final updateCalendarIncludedProvider = Provider((ref) {
  return (String id, bool included) async {
    final dao = ref.read(calendarSourceDaoProvider);
    await dao.updateIncluded(id, included);
  };
});
