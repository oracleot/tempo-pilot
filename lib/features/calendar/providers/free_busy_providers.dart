import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_events_provider.dart';

typedef TimeWindow = ({DateTime start, DateTime end});

final freeBusyDeriverProvider = Provider<FreeBusyDeriver>(
  (ref) => const FreeBusyDeriver(),
);

class _TodayWindowNotifier extends AutoDisposeNotifier<TimeWindow> {
  Timer? _timer;

  @override
  TimeWindow build() {
    final now = DateTime.now();
    _scheduleNextBoundary(now);

    // Start from current time to show only remaining free time today
    final start = now;
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    ref.onDispose(() => _timer?.cancel());
    return (start: start, end: endOfDay);
  }

  void _scheduleNextBoundary(DateTime now) {
    _timer?.cancel();
    final nextMidnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    var delay = nextMidnight.difference(now);
    if (delay.isNegative || delay.inMilliseconds == 0) {
      delay = const Duration(minutes: 1);
    }
    _timer = Timer(delay, ref.invalidateSelf);
  }
}

final todayWindowProvider =
    AutoDisposeNotifierProvider<_TodayWindowNotifier, TimeWindow>(
      _TodayWindowNotifier.new,
    );

final thisWeekWindowProvider = Provider.autoDispose<TimeWindow>((ref) {
  // Start from current time, not beginning of week
  final now = DateTime.now();
  final weekdayIndex = now.weekday; // Monday = 1
  final startOfWeek = now.subtract(Duration(days: weekdayIndex - 1));
  final weekStart = DateTime(
    startOfWeek.year,
    startOfWeek.month,
    startOfWeek.day,
  );
  final weekEnd = weekStart.add(const Duration(days: 7));

  // Use current time as start to show only future availability
  return (start: now, end: weekEnd);
});

final busyIntervalsForWindowProvider = Provider.autoDispose
    .family<AsyncValue<List<TimeInterval>>, TimeWindow>((ref, window) {
      final eventsAsync = ref.watch(eventsInWindowProvider(window));
      final deriver = ref.watch(freeBusyDeriverProvider);

      return eventsAsync.when(
        data: (events) => AsyncValue.data(
          deriver.deriveBusyIntervals(
            events: events,
            windowStart: window.start,
            windowEnd: window.end,
          ),
        ),
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
      );
    });

final freeIntervalsForWindowProvider = Provider.autoDispose
    .family<AsyncValue<List<TimeInterval>>, TimeWindow>((ref, window) {
      final eventsAsync = ref.watch(eventsInWindowProvider(window));
      final deriver = ref.watch(freeBusyDeriverProvider);

      return eventsAsync.when(
        data: (events) {
          final busy = deriver.deriveBusyIntervals(
            events: events,
            windowStart: window.start,
            windowEnd: window.end,
          );
          final free = deriver.deriveFreeFromBusy(
            busyIntervals: busy,
            windowStart: window.start,
            windowEnd: window.end,
          );
          return AsyncValue.data(free);
        },
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
      );
    });

final freeBlocksTodayProvider =
    Provider.autoDispose<AsyncValue<List<TimeInterval>>>((ref) {
      final window = ref.watch(todayWindowProvider);
      return ref.watch(freeIntervalsForWindowProvider(window));
    });

final freeBlocksThisWeekProvider =
    Provider.autoDispose<AsyncValue<List<TimeInterval>>>((ref) {
      final window = ref.watch(thisWeekWindowProvider);
      return ref.watch(freeIntervalsForWindowProvider(window));
    });
