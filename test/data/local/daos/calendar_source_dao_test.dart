import 'package:flutter_test/flutter_test.dart' hide isNotNull;
import 'package:drift/drift.dart';
import 'package:tempo_pilot/data/local/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.inMemory();
  });

  tearDown(() async {
    await database.close();
  });

  group('CalendarSourceDao', () {
    test('upsertCalendarSource inserts a new calendar source', () async {
      final companion = LocalCalendarSourcesCompanion.insert(
        id: 'cal_1',
        name: 'Work Calendar',
        accountName: const Value('work@example.com'),
        accountType: const Value('com.google'),
        isPrimary: const Value(true),
        included: const Value(true),
      );

      await database.calendarSourceDao.upsertCalendarSource(companion);

      final result = await database.calendarSourceDao.getById('cal_1');
      expect(result, isA<LocalCalendarSource>());
      expect(result!.id, 'cal_1');
      expect(result.name, 'Work Calendar');
      expect(result.accountName, 'work@example.com');
      expect(result.isPrimary, true);
      expect(result.included, true);
    });

    test('upsertCalendarSource updates an existing calendar source', () async {
      final companion1 = LocalCalendarSourcesCompanion.insert(
        id: 'cal_1',
        name: 'Work Calendar',
        included: const Value(true),
      );

      await database.calendarSourceDao.upsertCalendarSource(companion1);

      final companion2 = LocalCalendarSourcesCompanion.insert(
        id: 'cal_1',
        name: 'Updated Work Calendar',
        included: const Value(false),
      );

      await database.calendarSourceDao.upsertCalendarSource(companion2);

      final result = await database.calendarSourceDao.getById('cal_1');
      expect(result, isA<LocalCalendarSource>());
      expect(result!.name, 'Updated Work Calendar');
      expect(result.included, false);
    });

    test('updateIncluded changes the included status', () async {
      final companion = LocalCalendarSourcesCompanion.insert(
        id: 'cal_1',
        name: 'Work Calendar',
        included: const Value(true),
      );

      await database.calendarSourceDao.upsertCalendarSource(companion);
      await database.calendarSourceDao.updateIncluded('cal_1', false);

      final result = await database.calendarSourceDao.getById('cal_1');
      expect(result!.included, false);
    });

    test('getIncludedCalendarSources returns only included sources', () async {
      final companion1 = LocalCalendarSourcesCompanion.insert(
        id: 'cal_1',
        name: 'Work Calendar',
        included: const Value(true),
      );

      final companion2 = LocalCalendarSourcesCompanion.insert(
        id: 'cal_2',
        name: 'Personal Calendar',
        included: const Value(false),
      );

      final companion3 = LocalCalendarSourcesCompanion.insert(
        id: 'cal_3',
        name: 'Family Calendar',
        included: const Value(true),
      );

      await database.calendarSourceDao.upsertCalendarSources([
        companion1,
        companion2,
        companion3,
      ]);

      final included = await database.calendarSourceDao
          .getIncludedCalendarSources();
      expect(included.length, 2);
      expect(included.map((s) => s.id), containsAll(['cal_1', 'cal_3']));
    });

    test('watchAllCalendarSources emits updates', () async {
      final stream = database.calendarSourceDao.watchAllCalendarSources();

      // Initial empty state
      expect(await stream.first, isEmpty);

      // Insert a source
      final companion = LocalCalendarSourcesCompanion.insert(
        id: 'cal_1',
        name: 'Work Calendar',
      );
      await database.calendarSourceDao.upsertCalendarSource(companion);

      // Wait for the stream to emit the new state
      final sources = await stream.first;
      expect(sources.length, 1);
      expect(sources.first.id, 'cal_1');
    });

    test('clearAll removes all calendar sources', () async {
      final companion1 = LocalCalendarSourcesCompanion.insert(
        id: 'cal_1',
        name: 'Work Calendar',
      );

      final companion2 = LocalCalendarSourcesCompanion.insert(
        id: 'cal_2',
        name: 'Personal Calendar',
      );

      await database.calendarSourceDao.upsertCalendarSources([
        companion1,
        companion2,
      ]);

      final beforeClear = await database.calendarSourceDao
          .getAllCalendarSources();
      expect(beforeClear.length, 2);

      await database.calendarSourceDao.clearAll();

      final afterClear = await database.calendarSourceDao
          .getAllCalendarSources();
      expect(afterClear, isEmpty);
    });
  });
}
