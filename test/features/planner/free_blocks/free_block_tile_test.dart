import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';
import 'package:tempo_pilot/features/planner/free_blocks/widgets/free_block_tile.dart';

void main() {
  TimeInterval buildInterval({
    required int startHour,
    required int endHour,
    int endMinute = 0,
  }) {
    return TimeInterval(
      start: DateTime(2025, 1, 1, startHour),
      end: DateTime(2025, 1, 1, endHour, endMinute),
    );
  }

  Widget buildHost(Widget child) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(alwaysUse24HourFormat: true),
        child: Material(child: child),
      ),
    );
  }

  testWidgets('renders time range and duration without day label', (
    tester,
  ) async {
    final interval = buildInterval(startHour: 9, endHour: 11, endMinute: 30);

    await tester.pumpWidget(buildHost(FreeBlockTile(interval: interval)));

    expect(find.textContaining('09:00'), findsOneWidget);
    expect(find.textContaining('11:30'), findsOneWidget);

    final listTile = tester.widget<ListTile>(find.byType(ListTile));
    final trailing = listTile.trailing as Text;
    expect(trailing.data, '2h 30m');
  });

  testWidgets('includes weekday label when showDayLabel is true', (
    tester,
  ) async {
    final interval = buildInterval(startHour: 14, endHour: 15);

    await tester.pumpWidget(
      buildHost(FreeBlockTile(interval: interval, showDayLabel: true)),
    );

    expect(find.textContaining('Wednesday · Jan 1'), findsOneWidget);
    expect(find.text('1h'), findsOneWidget);
  });

  testWidgets('shows friendly copy for all-day free block', (tester) async {
    final allDay = TimeInterval(
      start: DateTime(2025, 1, 2),
      end: DateTime(2025, 1, 3),
    );

    await tester.pumpWidget(buildHost(FreeBlockTile(interval: allDay)));

    expect(find.text('All day free'), findsOneWidget);
    expect(find.text('No calendar conflicts today.'), findsOneWidget);
    final listTile = tester.widget<ListTile>(find.byType(ListTile));
    expect(listTile.trailing, isNull);
  });

  testWidgets('shows friendly copy for full-week free interval', (
    tester,
  ) async {
    final week = TimeInterval(
      start: DateTime(2025, 1, 6),
      end: DateTime(2025, 1, 13),
    );

    await tester.pumpWidget(
      buildHost(FreeBlockTile(interval: week, showDayLabel: true)),
    );

    expect(find.text('All week free'), findsOneWidget);
    expect(find.text('Clear schedule for the next 7 days.'), findsOneWidget);
    final listTile = tester.widget<ListTile>(find.byType(ListTile));
    expect(listTile.trailing, isNull);
  });

  testWidgets('does not show weekly copy when interval not aligned', (
    tester,
  ) async {
    final almostWeek = TimeInterval(
      start: DateTime(2025, 1, 7),
      end: DateTime(2025, 1, 14),
    );

    await tester.pumpWidget(
      buildHost(FreeBlockTile(interval: almostWeek, showDayLabel: true)),
    );

    expect(find.text('All week free'), findsNothing);
    expect(find.textContaining('Jan 7'), findsOneWidget);
    final listTile = tester.widget<ListTile>(find.byType(ListTile));
    expect(listTile.trailing, isA<Text>());
  });
}
