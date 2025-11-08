import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_events_provider.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_providers.dart';
import 'package:tempo_pilot/features/calendar/providers/free_busy_providers.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';

/// Minimum duration a free block must have to be surfaced in the UI.
const Duration kMinimumFreeBlockDuration = Duration(minutes: 15);

List<TimeInterval> _filterShortBlocks(List<TimeInterval> intervals) {
  return intervals
      .where((interval) => interval.duration >= kMinimumFreeBlockDuration)
      .toList();
}

/// Filters and exposes free blocks for today with the minimum duration applied.
final filteredFreeBlocksTodayProvider =
    Provider<AsyncValue<List<TimeInterval>>>((ref) {
      final raw = ref.watch(freeBlocksTodayProvider);
      return raw.whenData(_filterShortBlocks);
    });

/// Filters and exposes free blocks for the current week with the minimum
/// duration applied.
final filteredFreeBlocksWeekProvider =
    Provider<AsyncValue<List<TimeInterval>>>((ref) {
      final raw = ref.watch(freeBlocksThisWeekProvider);
      return raw.whenData(_filterShortBlocks);
    });

/// Controller responsible for refreshing calendar data backing the free blocks
/// views. It triggers a 7-day fetch and surfaces the loading/error state.
class FreeBlocksController extends AutoDisposeAsyncNotifier<void> {
  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);

  @override
  FutureOr<void> build() async {}

  /// Pull-to-refresh entry point invoked by the UI.
  Future<void> refresh() async {
    _analytics.logEvent('free_blocks_refresh_start');

    state = const AsyncValue<void>.loading();

    try {
      final permission = await ref.read(
        calendarPermissionStatusProvider.future,
      );

      if (permission != CalendarPermissionStatus.granted) {
        state = const AsyncValue<void>.data(null);
        _analytics.logEvent('free_blocks_refresh_skipped', {
          'reason': 'permission_denied',
        });
        return;
      }

      final calendars = await ref.read(includedCalendarSourcesProvider.future);
      final calendarCount = calendars.length;

      if (calendarCount == 0) {
        state = const AsyncValue<void>.data(null);
        _analytics.logEvent('free_blocks_refresh_skipped', {
          'reason': 'no_calendars',
        });
        return;
      }

      final repository = ref.read(calendarRepositoryProvider);
      final calendarIds = calendars.map((calendar) => calendar.id).toList();

      await repository.fetchEvents7d(calendarIds: calendarIds);

      ref
        ..invalidate(freeBlocksTodayProvider)
        ..invalidate(freeBlocksThisWeekProvider)
        ..invalidate(filteredFreeBlocksTodayProvider)
        ..invalidate(filteredFreeBlocksWeekProvider);

      state = const AsyncValue<void>.data(null);
      _analytics.logEvent('free_blocks_refresh_succeeded', {
        'calendar_count': calendarCount,
      });
    } catch (error, stackTrace) {
      _analytics.logException(
        error,
        stackTrace,
        context: 'free_blocks_refresh',
      );
      state = AsyncValue<void>.error(error, stackTrace);
      rethrow;
    }
  }
}

/// Provider exposing the controller to the UI.
final freeBlocksControllerProvider =
    AutoDisposeAsyncNotifierProvider<FreeBlocksController, void>(
      FreeBlocksController.new,
    );
