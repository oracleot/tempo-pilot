import 'package:flutter_test/flutter_test.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_source.dart';
import 'package:tempo_pilot/features/calendar/picker/calendar_picker_view_model.dart';

void main() {
  group('filterCalendars', () {
    final sources = [
      const CalendarSource(
        id: '1',
        name: 'Work Calendar',
        accountName: 'work@example.com',
        accountType: 'com.google',
        included: true,
        isPrimary: true,
      ),
      const CalendarSource(
        id: '2',
        name: 'Personal',
        accountName: 'personal@example.com',
        accountType: 'com.google',
      ),
      const CalendarSource(
        id: '3',
        name: 'Family Schedule',
        accountName: 'shared@example.com',
        accountType: 'exchange',
      ),
    ];

    test('returns all calendars when query is empty', () {
      final filtered = filterCalendars(sources, '');

      expect(filtered, hasLength(3));
      expect(filtered.first.name, 'Work Calendar');
    });

    test('matches by name case-insensitively', () {
      final filtered = filterCalendars(sources, 'family');

      expect(filtered, hasLength(1));
      expect(filtered.single.id, '3');
    });

    test('matches by account name', () {
      final filtered = filterCalendars(sources, 'PERSONAL@EXAMPLE.COM');

      expect(filtered, hasLength(1));
      expect(filtered.single.id, '2');
    });

    test('matches by account type', () {
      final filtered = filterCalendars(sources, 'exchange');

      expect(filtered, hasLength(1));
      expect(filtered.single.id, '3');
    });

    test('returns empty list when no match found', () {
      final filtered = filterCalendars(sources, 'zzz');

      expect(filtered, isEmpty);
    });
  });
}
