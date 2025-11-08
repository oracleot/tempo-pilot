import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/features/ai_chat/data/ai_chat_repository.dart';
import 'package:tempo_pilot/features/ai_chat/models/ai_chat_models.dart';
import 'package:tempo_pilot/features/ai_chat/providers/ai_chat_providers.dart';
import 'package:tempo_pilot/features/ai_chat/providers/ai_quota_provider.dart';
import 'package:tempo_pilot/features/ai_chat/providers/ai_feature_flags_provider.dart';
import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';
import 'package:tempo_pilot/features/planner/free_blocks/free_blocks_controller.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';

class MockAiChatRepository extends Mock implements AiChatRepository {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  GoTrueClient get auth => FakeGoTrueClient();
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  @override
  Session? get currentSession => null;
}

void main() {
  setUpAll(() {
    registerFallbackValue(AiChatRequestKind.plan);
    registerFallbackValue(<AiChatRequestMessage>[]);
    registerFallbackValue(AiChatStreamChunk(requestId: '', delta: ''));
    registerFallbackValue(AiChatStreamResult(requestId: ''));
    registerFallbackValue(AiChatFailure(requestId: '', code: '', message: ''));
  });

  group('AI Chat with Availability Context Integration', () {
    late MockAiChatRepository mockRepository;
    late MockAnalyticsService mockAnalytics;

    setUp(() {
      mockRepository = MockAiChatRepository();
      mockAnalytics = MockAnalyticsService();

      // Setup default analytics behavior
      when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
      when(
        () => mockAnalytics.logException(
          any(),
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});
    });

    test(
      'system prompt contains availability intervals when flags enabled and data available',
      () async {
        // Use times that are definitely in the future relative to test execution
        final now = DateTime.now();
        final futureTime1 = now.add(const Duration(hours: 2));
        final futureTime2 = now.add(const Duration(hours: 4));
        
        final mockIntervals = [
          TimeInterval(
            start: futureTime1,
            end: futureTime1.add(const Duration(minutes: 90)),
          ),
          TimeInterval(
            start: futureTime2,
            end: futureTime2.add(const Duration(minutes: 60)),
          ),
        ];

        List<AiChatRequestMessage>? capturedMessages;
        when(
          () => mockRepository.startStream(
            kind: any(named: 'kind'),
            messages: any(named: 'messages'),
            onChunk: any(named: 'onChunk'),
            onComplete: any(named: 'onComplete'),
            onError: any(named: 'onError'),
          ),
        ).thenAnswer((invocation) {
          capturedMessages =
              invocation.namedArguments[Symbol('messages')]
                  as List<AiChatRequestMessage>?;
          return AiChatStreamHandle(
            requestId: 'test-request',
            done: Future.value(),
            onCancel: () {},
          );
        });

        final container = ProviderContainer(
          overrides: [
            aiChatRepositoryProvider.overrideWithValue(mockRepository),
            analyticsServiceProvider.overrideWithValue(mockAnalytics),
            calendarSuggestionsEnabledFlagProvider.overrideWith(
              (ref) async => true,
            ),
            aiChatEnabledProvider.overrideWith((ref) async => true),
            filteredFreeBlocksTodayProvider.overrideWith(
              (ref) => AsyncValue.data(mockIntervals),
            ),
            aiQuotaProvider.overrideWith(
              (ref) => AiQuotaController(
                supabaseClient: FakeSupabaseClient(),
                analyticsService: mockAnalytics,
                clock: () => DateTime.now().toUtc(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Wait for flags to load
        await container.read(calendarSuggestionsEnabledFlagProvider.future);
        await container.read(aiChatEnabledProvider.future);

        final controller = container.read(aiChatControllerProvider.notifier);

        await controller.send(
          kind: AiChatRequestKind.plan,
          content: 'What free time do I have between 4pm and 6pm?',
        );

        // Verify repository was called
        verify(
          () => mockRepository.startStream(
            kind: any(named: 'kind'),
            messages: any(named: 'messages'),
            onChunk: any(named: 'onChunk'),
            onComplete: any(named: 'onComplete'),
            onError: any(named: 'onError'),
          ),
        ).called(1);

        // Verify messages include system prompt with availability
        expect(capturedMessages, isNotNull);
        expect(capturedMessages!.length, greaterThanOrEqualTo(2));

        // First message should be system prompt with availability
        final systemMessage = capturedMessages!.first;
        expect(systemMessage.role, AiChatMessageRole.system);
        expect(
          systemMessage.content.toLowerCase(),
          contains('calendar access'),
        );
        // Should contain time intervals (content will have actual times)
        expect(systemMessage.content, contains(':'));
        expect(systemMessage.content, contains('min'));
        // Should contain warning not to invent times
        expect(systemMessage.content.toLowerCase(), contains('do not invent'));

        // Last message should be user message
        final userMessage = capturedMessages!.last;
        expect(userMessage.role, AiChatMessageRole.user);
        expect(
          userMessage.content,
          contains('What free time do I have between 4pm and 6pm?'),
        );
      },
    );

    test(
      'system prompt is omitted when calendar_suggestions_enabled flag is false',
      () async {
        List<AiChatRequestMessage>? capturedMessages;
        when(
          () => mockRepository.startStream(
            kind: any(named: 'kind'),
            messages: any(named: 'messages'),
            onChunk: any(named: 'onChunk'),
            onComplete: any(named: 'onComplete'),
            onError: any(named: 'onError'),
          ),
        ).thenAnswer((invocation) {
          capturedMessages =
              invocation.namedArguments[Symbol('messages')]
                  as List<AiChatRequestMessage>?;
          return AiChatStreamHandle(
            requestId: 'test-request',
            done: Future.value(),
            onCancel: () {},
          );
        });

        final container = ProviderContainer(
          overrides: [
            aiChatRepositoryProvider.overrideWithValue(mockRepository),
            analyticsServiceProvider.overrideWithValue(mockAnalytics),
            calendarSuggestionsEnabledFlagProvider.overrideWith(
              (ref) async => false,
            ),
            aiChatEnabledProvider.overrideWith((ref) async => true),
            aiQuotaProvider.overrideWith(
              (ref) => AiQuotaController(
                supabaseClient: FakeSupabaseClient(),
                analyticsService: mockAnalytics,
                clock: () => DateTime.now().toUtc(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Wait for flags to load
        await container.read(calendarSuggestionsEnabledFlagProvider.future);
        await container.read(aiChatEnabledProvider.future);

        final controller = container.read(aiChatControllerProvider.notifier);

        await controller.send(
          kind: AiChatRequestKind.plan,
          content: 'What should I focus on today?',
        );

        // Verify messages do NOT include system prompt with availability
        expect(capturedMessages, isNotNull);
        expect(capturedMessages!.length, 1);

        // Only user message, no system prompt
        final userMessage = capturedMessages!.first;
        expect(userMessage.role, AiChatMessageRole.user);
        expect(userMessage.content, contains('What should I focus on today?'));
      },
    );

    test(
      'system prompt gracefully omitted when calendar data unavailable',
      () async {
        List<AiChatRequestMessage>? capturedMessages;
        when(
          () => mockRepository.startStream(
            kind: any(named: 'kind'),
            messages: any(named: 'messages'),
            onChunk: any(named: 'onChunk'),
            onComplete: any(named: 'onComplete'),
            onError: any(named: 'onError'),
          ),
        ).thenAnswer((invocation) {
          capturedMessages =
              invocation.namedArguments[Symbol('messages')]
                  as List<AiChatRequestMessage>?;
          return AiChatStreamHandle(
            requestId: 'test-request',
            done: Future.value(),
            onCancel: () {},
          );
        });

        final container = ProviderContainer(
          overrides: [
            aiChatRepositoryProvider.overrideWithValue(mockRepository),
            analyticsServiceProvider.overrideWithValue(mockAnalytics),
            calendarSuggestionsEnabledFlagProvider.overrideWith(
              (ref) async => true,
            ),
            aiChatEnabledProvider.overrideWith((ref) async => true),
            filteredFreeBlocksTodayProvider.overrideWith(
              (ref) => AsyncValue<List<TimeInterval>>.error(
                Exception('Calendar permission denied'),
                StackTrace.current,
              ),
            ),
            aiQuotaProvider.overrideWith(
              (ref) => AiQuotaController(
                supabaseClient: FakeSupabaseClient(),
                analyticsService: mockAnalytics,
                clock: () => DateTime.now().toUtc(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Wait for flags to load
        await container.read(calendarSuggestionsEnabledFlagProvider.future);
        await container.read(aiChatEnabledProvider.future);

        final controller = container.read(aiChatControllerProvider.notifier);

        await controller.send(
          kind: AiChatRequestKind.plan,
          content: 'Help me plan my day',
        );

        // Should still work without availability (graceful degradation)
        expect(capturedMessages, isNotNull);
        expect(capturedMessages!.length, 1);

        final userMessage = capturedMessages!.first;
        expect(userMessage.role, AiChatMessageRole.user);
        expect(userMessage.content, contains('Help me plan my day'));
      },
    );
  });
}
