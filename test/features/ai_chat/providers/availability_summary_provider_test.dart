import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/features/ai_chat/providers/ai_feature_flags_provider.dart';
import 'package:tempo_pilot/features/ai_chat/providers/availability_summary_provider.dart';
import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';
import 'package:tempo_pilot/features/planner/free_blocks/free_blocks_controller.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';

class _MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  final fixedNow = DateTime(2025, 11, 7, 10);

  group('availabilitySummaryProvider', () {
    test(
      'returns null when calendar_suggestions_enabled flag is false',
      () async {
        final container = ProviderContainer(
          overrides: [
            calendarSuggestionsEnabledFlagProvider.overrideWith(
              (ref) async => false,
            ),
            aiChatEnabledProvider.overrideWith((ref) async => true),
            availabilitySummaryNowProvider.overrideWithValue(fixedNow),
          ],
        );
        addTearDown(container.dispose);

        // Wait for flags to load
        await container.read(calendarSuggestionsEnabledFlagProvider.future);
        await container.read(aiChatEnabledProvider.future);

        // Trigger evaluation then await completion
        expect(
          container.read(availabilitySummaryProvider),
          isA<AsyncLoading>(),
        );
        final value = await container.read(availabilitySummaryProvider.future);
        expect(value, isNull);
        expect(
          container.read(availabilitySummaryProvider),
          isA<AsyncData<Map<String, dynamic>?>>(),
        );
      },
    );

    test('returns null when ai_chat_enabled flag is false', () async {
      final container = ProviderContainer(
        overrides: [
          calendarSuggestionsEnabledFlagProvider.overrideWith(
            (ref) async => true,
          ),
          aiChatEnabledProvider.overrideWith((ref) async => false),
          availabilitySummaryNowProvider.overrideWithValue(fixedNow),
        ],
      );
      addTearDown(container.dispose);

      // Wait for flags to load
      await container.read(calendarSuggestionsEnabledFlagProvider.future);
      await container.read(aiChatEnabledProvider.future);

      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncLoading>(),
      );
      final value = await container.read(availabilitySummaryProvider.future);
      expect(value, isNull);
      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncData<Map<String, dynamic>?>>(),
      );
    });

    test('returns null when both flags are false', () async {
      final container = ProviderContainer(
        overrides: [
          calendarSuggestionsEnabledFlagProvider.overrideWith(
            (ref) async => false,
          ),
          aiChatEnabledProvider.overrideWith((ref) async => false),
          availabilitySummaryNowProvider.overrideWithValue(fixedNow),
        ],
      );
      addTearDown(container.dispose);

      // Wait for flags to load
      await container.read(calendarSuggestionsEnabledFlagProvider.future);
      await container.read(aiChatEnabledProvider.future);

      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncLoading>(),
      );
      final value = await container.read(availabilitySummaryProvider.future);
      expect(value, isNull);
      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncData<Map<String, dynamic>?>>(),
      );
    });

    test('returns loading when flags are still loading', () {
      final container = ProviderContainer(
        overrides: [
          calendarSuggestionsEnabledFlagProvider.overrideWith((ref) async {
            await Future<void>.delayed(const Duration(seconds: 10));
            return true;
          }),
          aiChatEnabledProvider.overrideWith((ref) async => true),
          availabilitySummaryNowProvider.overrideWithValue(fixedNow),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(availabilitySummaryProvider);

      expect(result, isA<AsyncLoading>());
    });

    test('returns null when calendar data is loading', () async {
      final container = ProviderContainer(
        overrides: [
          calendarSuggestionsEnabledFlagProvider.overrideWith(
            (ref) async => true,
          ),
          aiChatEnabledProvider.overrideWith((ref) async => true),
          filteredFreeBlocksTodayProvider.overrideWith(
            (ref) => const AsyncValue<List<TimeInterval>>.loading(),
          ),
          availabilitySummaryNowProvider.overrideWithValue(fixedNow),
        ],
      );
      addTearDown(container.dispose);

      // Wait for flags to load
      await container.read(calendarSuggestionsEnabledFlagProvider.future);
      await container.read(aiChatEnabledProvider.future);

      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncLoading>(),
      );
      final value = await container.read(availabilitySummaryProvider.future);
      expect(value, isNull);
      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncData<Map<String, dynamic>?>>(),
      );
    });

    test('returns null gracefully when calendar data has error', () async {
      // Create a mock analytics service
      final mockAnalytics = _MockAnalyticsService();
      when(
        () => mockAnalytics.logException(
          any(),
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(mockAnalytics),
          calendarSuggestionsEnabledFlagProvider.overrideWith(
            (ref) async => true,
          ),
          aiChatEnabledProvider.overrideWith((ref) async => true),
          filteredFreeBlocksTodayProvider.overrideWith(
            (ref) => AsyncValue<List<TimeInterval>>.error(
              Exception('Calendar error'),
              StackTrace.current,
            ),
          ),
          availabilitySummaryNowProvider.overrideWithValue(fixedNow),
        ],
      );
      addTearDown(container.dispose);

      // Wait for flags to load
      await container.read(calendarSuggestionsEnabledFlagProvider.future);
      await container.read(aiChatEnabledProvider.future);

      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncLoading>(),
      );
      final value = await container.read(availabilitySummaryProvider.future);
      expect(value, isNull);
      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncData<Map<String, dynamic>?>>(),
      );
      verify(
        () => mockAnalytics.logException(
          any(),
          any(),
          context: 'availability_summary_provider',
        ),
      ).called(1);
    });

    test('gracefully skips when calendar flag fails', () async {
      final mockAnalytics = _MockAnalyticsService();
      when(
        () => mockAnalytics.logException(
          any(),
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(mockAnalytics),
          calendarSuggestionsEnabledFlagProvider.overrideWith((ref) async {
            throw Exception('flag fetch failed');
          }),
          aiChatEnabledProvider.overrideWith((ref) async => true),
          availabilitySummaryNowProvider.overrideWithValue(fixedNow),
        ],
      );
      addTearDown(container.dispose);

      // Allow futures to resolve
      try {
        await container.read(calendarSuggestionsEnabledFlagProvider.future);
      } catch (_) {}

      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncLoading>(),
      );
      final value = await container.read(availabilitySummaryProvider.future);
      expect(value, isNull);
      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncData<Map<String, dynamic>?>>(),
      );
      verify(
        () => mockAnalytics.logException(
          any(),
          any(),
          context: 'availability_summary_provider.calendar_flag',
        ),
      ).called(1);
    });

    test('gracefully skips when ai chat flag fails', () async {
      final mockAnalytics = _MockAnalyticsService();
      when(
        () => mockAnalytics.logException(
          any(),
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(mockAnalytics),
          calendarSuggestionsEnabledFlagProvider.overrideWith(
            (ref) async => true,
          ),
          aiChatEnabledProvider.overrideWith((ref) async {
            throw Exception('ai flag failed');
          }),
          availabilitySummaryNowProvider.overrideWithValue(fixedNow),
        ],
      );
      addTearDown(container.dispose);

      try {
        await container.read(aiChatEnabledProvider.future);
      } catch (_) {}

      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncLoading>(),
      );
      final value = await container.read(availabilitySummaryProvider.future);
      expect(value, isNull);
      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncData<Map<String, dynamic>?>>(),
      );
      verify(
        () => mockAnalytics.logException(
          any(),
          any(),
          context: 'availability_summary_provider.ai_flag',
        ),
      ).called(1);
    });

    test('returns JSON when data is available and flags are enabled', () async {
      final mockIntervals = [
        TimeInterval(
          start: DateTime(2025, 11, 7, 14, 0),
          end: DateTime(2025, 11, 7, 15, 30),
        ),
        TimeInterval(
          start: DateTime(2025, 11, 7, 16, 0),
          end: DateTime(2025, 11, 7, 17, 0),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          calendarSuggestionsEnabledFlagProvider.overrideWith(
            (ref) async => true,
          ),
          aiChatEnabledProvider.overrideWith((ref) async => true),
          filteredFreeBlocksTodayProvider.overrideWith(
            (ref) => AsyncValue.data(mockIntervals),
          ),
          availabilitySummaryNowProvider.overrideWithValue(
            DateTime(2025, 11, 7, 12),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for flags to load
      await container.read(calendarSuggestionsEnabledFlagProvider.future);
      await container.read(aiChatEnabledProvider.future);

      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncLoading>(),
      );
      final json = await container.read(availabilitySummaryProvider.future);
      expect(json, isNotNull);
      expect(json!['tz'], isA<String>());
      expect(json['tz_offset'], isA<String>());
      expect(json['tz_offset_minutes'], isA<int>());
      expect(json['generated_at'], isA<String>());
      expect(json['generated_at_utc'], isA<String>());
      expect(json['day'], 'today');
      expect(json['day_iso'], isA<String>());
      expect(json['intervals'], isA<List>());

      // Should have intervals (though exact count depends on filtering)
      final intervals = json['intervals'] as List;
      expect(intervals, isNotEmpty);

      // Check structure of first interval
      final firstInterval = intervals[0] as Map<String, dynamic>;
      expect(firstInterval['start'], isA<String>());
      expect(firstInterval['end'], isA<String>());
      expect(firstInterval['minutes'], isA<int>());
    });

    // Note: Test removed because formatForAi uses DateTime.now() internally,
    // making it difficult to reliably test "past" intervals without mocking time.
    // The formatter unit tests cover the past-filtering logic thoroughly.

    test('handles empty free blocks list', () async {
      final container = ProviderContainer(
        overrides: [
          calendarSuggestionsEnabledFlagProvider.overrideWith(
            (ref) async => true,
          ),
          aiChatEnabledProvider.overrideWith((ref) async => true),
          filteredFreeBlocksTodayProvider.overrideWith(
            (ref) => const AsyncValue.data(<TimeInterval>[]),
          ),
          availabilitySummaryNowProvider.overrideWithValue(
            DateTime(2025, 11, 7, 12),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for flags to load
      await container.read(calendarSuggestionsEnabledFlagProvider.future);
      await container.read(aiChatEnabledProvider.future);

      expect(
        container.read(availabilitySummaryProvider),
        isA<AsyncLoading>(),
      );
      final json = await container.read(availabilitySummaryProvider.future);
      expect(json, isNotNull);
      expect(json!['intervals'], isEmpty);
    });
  });
}
