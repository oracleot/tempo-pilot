import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tempo_pilot/data/local/app_database.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_source.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_providers.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_discovery_service.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';
import 'package:tempo_pilot/providers/database_provider.dart';

// Mocks
class MockCalendarPermissionService extends Mock
    implements CalendarPermissionService {}

class MockCalendarDiscoveryService extends Mock
    implements CalendarDiscoveryService {}

void main() {
  group('Calendar Providers', () {
    late MockCalendarPermissionService mockPermissionService;
    late MockCalendarDiscoveryService mockDiscoveryService;
    late ProviderContainer container;

    setUp(() {
      mockPermissionService = MockCalendarPermissionService();
      mockDiscoveryService = MockCalendarDiscoveryService();

      container = ProviderContainer(
        overrides: [
          calendarPermissionServiceProvider.overrideWithValue(
            mockPermissionService,
          ),
          calendarDiscoveryServiceProvider.overrideWithValue(
            mockDiscoveryService,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('calendarPermissionStatusProvider', () {
      test('returns granted status when permission is granted', () async {
        when(
          () => mockPermissionService.getStatus(),
        ).thenAnswer((_) async => CalendarPermissionStatus.granted);

        final status = await container.read(
          calendarPermissionStatusProvider.future,
        );

        expect(status, CalendarPermissionStatus.granted);
        verify(() => mockPermissionService.getStatus()).called(1);
      });

      test('returns denied status when permission is denied', () async {
        when(
          () => mockPermissionService.getStatus(),
        ).thenAnswer((_) async => CalendarPermissionStatus.denied);

        final status = await container.read(
          calendarPermissionStatusProvider.future,
        );

        expect(status, CalendarPermissionStatus.denied);
        verify(() => mockPermissionService.getStatus()).called(1);
      });

      test(
        'returns permanentlyDenied status when permanently denied',
        () async {
          when(
            () => mockPermissionService.getStatus(),
          ).thenAnswer((_) async => CalendarPermissionStatus.permanentlyDenied);

          final status = await container.read(
            calendarPermissionStatusProvider.future,
          );

          expect(status, CalendarPermissionStatus.permanentlyDenied);
          verify(() => mockPermissionService.getStatus()).called(1);
        },
      );

      test('returns unknown status on error', () async {
        when(
          () => mockPermissionService.getStatus(),
        ).thenAnswer((_) async => CalendarPermissionStatus.unknown);

        final status = await container.read(
          calendarPermissionStatusProvider.future,
        );

        expect(status, CalendarPermissionStatus.unknown);
      });
    });

    group('discoveredCalendarSourcesProvider', () {
      test('returns empty list when permission is not granted', () async {
        when(
          () => mockPermissionService.getStatus(),
        ).thenAnswer((_) async => CalendarPermissionStatus.denied);

        final sources = await container.read(
          discoveredCalendarSourcesProvider.future,
        );

        expect(sources, isEmpty);
        verifyNever(() => mockDiscoveryService.listCalendars());
      });

      test('returns calendar sources when permission is granted', () async {
        when(
          () => mockPermissionService.getStatus(),
        ).thenAnswer((_) async => CalendarPermissionStatus.granted);

        final mockSources = [
          const CalendarSource(
            id: '1',
            name: 'Work',
            accountName: 'work@example.com',
            isPrimary: true,
            included: true,
          ),
          const CalendarSource(
            id: '2',
            name: 'Personal',
            accountName: 'personal@example.com',
            isPrimary: false,
            included: false,
          ),
        ];

        when(
          () => mockDiscoveryService.listCalendars(),
        ).thenAnswer((_) async => mockSources);

        final sources = await container.read(
          discoveredCalendarSourcesProvider.future,
        );

        expect(sources, hasLength(2));
        expect(sources[0].name, 'Work');
        expect(sources[0].isPrimary, true);
        expect(sources[1].name, 'Personal');
        verify(() => mockDiscoveryService.listCalendars()).called(1);
      });

      test('marks primary calendars as included by default', () async {
        when(
          () => mockPermissionService.getStatus(),
        ).thenAnswer((_) async => CalendarPermissionStatus.granted);

        final mockSources = [
          const CalendarSource(
            id: '1',
            name: 'Primary',
            isPrimary: true,
            included: true,
          ),
        ];

        when(
          () => mockDiscoveryService.listCalendars(),
        ).thenAnswer((_) async => mockSources);

        final sources = await container.read(
          discoveredCalendarSourcesProvider.future,
        );

        expect(sources.first.isPrimary, true);
        expect(sources.first.included, true);
      });
    });
  });

  group('persistCalendarSourcesProvider', () {
    late AppDatabase database;
    late ProviderContainer dbContainer;

    setUp(() async {
      database = AppDatabase.inMemory();
      dbContainer = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
    });

    tearDown(() async {
      await database.close();
      dbContainer.dispose();
    });

    test(
      'preserves existing included toggles when rediscovering calendars',
      () async {
        final dao = database.calendarSourceDao;
        await dao.upsertCalendarSource(
          LocalCalendarSourcesCompanion.insert(
            id: 'primary',
            name: 'Primary Calendar',
            accountName: const Value('user@example.com'),
            accountType: const Value('com.google'),
            isPrimary: const Value(true),
            included: const Value(false),
          ),
        );

        final persistAction = dbContainer.read(persistCalendarSourcesProvider);

        await persistAction([
          const CalendarSource(
            id: 'primary',
            name: 'Primary Calendar',
            accountName: 'user@example.com',
            accountType: 'com.google',
            isPrimary: true,
            included: true,
          ),
        ]);

        final stored = await dao.getById('primary');
        expect(stored, isNotNull);
        expect(stored!.included, isFalse, reason: 'Should keep user override');
      },
    );

    test('removes stale calendars that disappear from discovery', () async {
      final dao = database.calendarSourceDao;
      await dao.upsertCalendarSource(
        LocalCalendarSourcesCompanion.insert(
          id: 'stale',
          name: 'Old Calendar',
          accountName: const Value('old@example.com'),
          accountType: const Value('com.google'),
          isPrimary: const Value(false),
          included: const Value(true),
        ),
      );

      final persistAction = dbContainer.read(persistCalendarSourcesProvider);

      await persistAction([
        const CalendarSource(
          id: 'fresh',
          name: 'New Calendar',
          accountName: 'new@example.com',
          accountType: 'com.google',
          isPrimary: true,
          included: true,
        ),
      ]);

      final stale = await dao.getById('stale');
      final fresh = await dao.getById('fresh');

      expect(stale, isNull, reason: 'Stale calendars should be pruned');
      expect(fresh, isNotNull);
      expect(fresh!.included, isTrue);
    });
  });
}
