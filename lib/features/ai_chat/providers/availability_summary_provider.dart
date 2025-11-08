import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/features/ai_chat/logic/ai_availability_formatter.dart';
import 'package:tempo_pilot/features/ai_chat/providers/ai_feature_flags_provider.dart';
import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';
import 'package:tempo_pilot/features/planner/free_blocks/free_blocks_controller.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';

/// Provides the availability formatter singleton.
final aiAvailabilityFormatterProvider = Provider<AiAvailabilityFormatter>(
  (ref) => const AiAvailabilityFormatter(),
);

/// Provides a formatted availability summary for AI chat injection.
///
/// Returns null if:
/// - Calendar suggestions flag is disabled
/// - AI chat flag is disabled
/// - Calendar data is loading or errored (graceful degradation)
///
/// Otherwise returns a JSON object with coarsened free intervals.
/// Override in tests to freeze the clock.
final availabilitySummaryNowProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

final availabilitySummaryProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
      final analytics = ref.read(analyticsServiceProvider);

      final calendarFlagState = ref.watch(calendarSuggestionsEnabledFlagProvider);
      final aiChatFlagState = ref.watch(aiChatEnabledProvider);

      analytics.logEvent('availability_summary_flags', {
        'calendar_suggestions_loading': calendarFlagState is AsyncLoading,
        'calendar_suggestions_error': calendarFlagState is AsyncError,
        'calendar_suggestions_data': calendarFlagState is AsyncData,
        'calendar_suggestions_value': calendarFlagState.maybeWhen(
          data: (value) => value,
          orElse: () => null,
        ),
        'ai_chat_loading': aiChatFlagState is AsyncLoading,
        'ai_chat_error': aiChatFlagState is AsyncError,
        'ai_chat_data': aiChatFlagState is AsyncData,
        'ai_chat_value': aiChatFlagState.maybeWhen(
          data: (value) => value,
          orElse: () => null,
        ),
      });

      bool calendarEnabled;
      try {
        calendarEnabled = await ref.watch(
          calendarSuggestionsEnabledFlagProvider.future,
        );
      } catch (error, stackTrace) {
        analytics.logException(
          error,
          stackTrace,
          context: 'availability_summary_provider.calendar_flag',
        );
        return null;
      }

      bool aiChatEnabled;
      try {
        aiChatEnabled = await ref.watch(aiChatEnabledProvider.future);
      } catch (error, stackTrace) {
        analytics.logException(
          error,
          stackTrace,
          context: 'availability_summary_provider.ai_flag',
        );
        return null;
      }

      if (!calendarEnabled || !aiChatEnabled) {
        analytics.logEvent('availability_summary_flags_disabled', {
          'calendar_suggestions': calendarEnabled,
          'ai_chat': aiChatEnabled,
        });
        return null;
      }

      analytics.logEvent('availability_summary_flags_passed', {
        'proceeding_to_free_blocks': true,
      });

      final freeBlocksState = ref.watch(filteredFreeBlocksTodayProvider);
      analytics.logEvent('availability_summary_free_blocks', {
        'is_loading': freeBlocksState is AsyncLoading,
        'is_error': freeBlocksState is AsyncError,
        'is_data': freeBlocksState is AsyncData,
      });

      if (freeBlocksState is AsyncError<List<TimeInterval>>) {
        analytics.logException(
          freeBlocksState.error,
          freeBlocksState.stackTrace,
          context: 'availability_summary_provider.free_blocks',
        );
        return null;
      }

      List<TimeInterval> intervals;
      if (freeBlocksState is AsyncData<List<TimeInterval>>) {
        intervals = freeBlocksState.value;
      } else {
        try {
          intervals = await _waitForFreeBlocks(ref)
              .timeout(const Duration(seconds: 3));
        } on TimeoutException {
          analytics.logEvent('availability_summary_free_blocks_timeout', {
            'timeout_ms': 3000,
          });
          return null;
        } catch (error, stackTrace) {
          analytics.logException(
            error,
            stackTrace,
            context: 'availability_summary_provider',
          );
          return null;
        }
      }

      analytics.logEvent('availability_summary_intervals', {
        'interval_count': intervals.length,
        'has_data': intervals.isNotEmpty,
      });

      final formatter = ref.watch(aiAvailabilityFormatterProvider);
      final now = ref.watch(availabilitySummaryNowProvider);
      final formatted = formatter.formatForAi(
        intervals,
        now: now,
        minDuration: Duration.zero,
      );
      final timezone = now.timeZoneName;

      return formatter.toJson(formatted, timezone, now);
    });

Future<List<TimeInterval>> _waitForFreeBlocks(Ref ref) {
  final completer = Completer<List<TimeInterval>>();
  ProviderSubscription<AsyncValue<List<TimeInterval>>>? subscription;

  subscription = ref.listen<AsyncValue<List<TimeInterval>>>(
    filteredFreeBlocksTodayProvider,
    (previous, next) {
      next.when(
        data: (value) {
          if (!completer.isCompleted) {
            completer.complete(value);
          }
          subscription?.close();
        },
        error: (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
          subscription?.close();
        },
        loading: () {},
      );
    },
  );

  ref.onDispose(() {
    subscription?.close();
    if (!completer.isCompleted) {
      completer.complete(<TimeInterval>[]);
    }
  });

  return completer.future;
}
