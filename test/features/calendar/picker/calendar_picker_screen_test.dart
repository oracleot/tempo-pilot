import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/data/local/app_database.dart';
import 'package:tempo_pilot/features/calendar/picker/calendar_picker_screen.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_providers.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';
import 'package:tempo_pilot/providers/database_provider.dart';

class _StubCalendarPermissionService extends CalendarPermissionService {
  _StubCalendarPermissionService(this._status);

  final CalendarPermissionStatus _status;

  @override
  Future<CalendarPermissionStatus> getStatus() async => _status;

  @override
  Future<CalendarPermissionStatus> requestPermission() async => _status;

  @override
  Future<bool> openSettings() async => true;
}

class _TestAnalyticsService extends AnalyticsService {}

void main() {
  group('CalendarPickerScreen', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.inMemory();
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('toggle persists include state to database', (tester) async {
      await database.calendarSourceDao.upsertCalendarSource(
        LocalCalendarSourcesCompanion.insert(
          id: 'primary',
          name: 'Primary Calendar',
          accountName: const Value('user@example.com'),
          accountType: const Value('com.google'),
          included: const Value(false),
          isPrimary: const Value(true),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            calendarPermissionServiceProvider.overrideWithValue(
              _StubCalendarPermissionService(CalendarPermissionStatus.granted),
            ),
            analyticsServiceProvider.overrideWithValue(_TestAnalyticsService()),
          ],
          child: const MaterialApp(home: CalendarPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final stored = await database.calendarSourceDao.getById('primary');
      expect(stored, isNotNull);
      expect(stored!.included, isTrue);
    });

    testWidgets('shows empty state when no calendars are stored', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            calendarPermissionServiceProvider.overrideWithValue(
              _StubCalendarPermissionService(CalendarPermissionStatus.granted),
            ),
            analyticsServiceProvider.overrideWithValue(_TestAnalyticsService()),
          ],
          child: const MaterialApp(home: CalendarPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No calendars discovered yet'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('shows permission required view when permission is denied', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            calendarPermissionServiceProvider.overrideWithValue(
              _StubCalendarPermissionService(CalendarPermissionStatus.denied),
            ),
            analyticsServiceProvider.overrideWithValue(_TestAnalyticsService()),
          ],
          child: const MaterialApp(home: CalendarPickerScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Calendar access is required'), findsOneWidget);
      expect(find.text('Allow Access'), findsOneWidget);
    });
  });
}
