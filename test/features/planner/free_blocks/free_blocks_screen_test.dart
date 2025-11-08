import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_source.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_providers.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';
import 'package:tempo_pilot/features/planner/free_blocks/free_blocks_controller.dart';
import 'package:tempo_pilot/features/planner/free_blocks/free_blocks_screen.dart';
import 'package:tempo_pilot/features/planner/free_blocks/widgets/free_block_tile.dart';

class _FakePermissionController extends CalendarPermissionController {
  _FakePermissionController(this._value);

  final CalendarPermissionStatus _value;

  @override
  FutureOr<CalendarPermissionStatus> build() => _value;

  @override
  Future<CalendarPermissionStatus> refresh() async => _value;

  @override
  Future<CalendarPermissionStatus> requestPermission() async => _value;
}

class _FakeFreeBlocksController extends FreeBlocksController {
  @override
  FutureOr<void> build() {}

  @override
  Future<void> refresh() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TimeInterval interval({required int startHour, required int endHour}) {
    return TimeInterval(
      start: DateTime(2025, 1, 2, startHour),
      end: DateTime(2025, 1, 2, endHour),
    );
  }

  Widget host(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: true),
          child: child,
        ),
      ),
    );
  }

  testWidgets('shows permission prompt when calendar access denied', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FreeBlocksScreen(),
        overrides: [
          calendarPermissionStatusProvider.overrideWith(
            () => _FakePermissionController(CalendarPermissionStatus.denied),
          ),
        ],
      ),
    );

    await tester.pump();

    expect(find.text('Connect Your Calendar'), findsOneWidget);
  });

  testWidgets('renders today free blocks when available', (tester) async {
    final todayBlocks = [interval(startHour: 9, endHour: 10)];
    final weekBlocks = [interval(startHour: 9, endHour: 11)];

    await tester.pumpWidget(
      host(
        const FreeBlocksScreen(),
        overrides: [
          calendarPermissionStatusProvider.overrideWith(
            () => _FakePermissionController(CalendarPermissionStatus.granted),
          ),
          filteredFreeBlocksTodayProvider.overrideWithValue(
            AsyncValue.data(todayBlocks),
          ),
          filteredFreeBlocksWeekProvider.overrideWithValue(
            AsyncValue.data(weekBlocks),
          ),
          includedCalendarSourcesProvider.overrideWith(
            (ref) => Stream.value([
              const CalendarSource(
                id: 'primary',
                name: 'Personal',
                included: true,
              ),
            ]),
          ),
          freeBlocksControllerProvider.overrideWith(
            _FakeFreeBlocksController.new,
          ),
        ],
      ),
    );

    await tester.pump();

    expect(find.byType(FreeBlockTile), findsOneWidget);
    expect(find.textContaining('09:00'), findsWidgets);
    expect(find.text('1h'), findsOneWidget);
  });

  testWidgets('shows no calendar empty state when nothing included', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FreeBlocksScreen(),
        overrides: [
          calendarPermissionStatusProvider.overrideWith(
            () => _FakePermissionController(CalendarPermissionStatus.granted),
          ),
          filteredFreeBlocksTodayProvider.overrideWithValue(
            AsyncValue.data([
              TimeInterval(
                start: DateTime(2025, 1, 2),
                end: DateTime(2025, 1, 3),
              ),
            ]),
          ),
          filteredFreeBlocksWeekProvider.overrideWithValue(
            const AsyncValue.data([]),
          ),
          includedCalendarSourcesProvider.overrideWith(
            (ref) => Stream<List<CalendarSource>>.value(const []),
          ),
          freeBlocksControllerProvider.overrideWith(
            _FakeFreeBlocksController.new,
          ),
        ],
      ),
    );

    await tester.pump();

    expect(
      find.text('No calendars are included. Add one to see your open time.'),
      findsOneWidget,
    );
    expect(find.byType(FreeBlockTile), findsNothing);
  });
}
