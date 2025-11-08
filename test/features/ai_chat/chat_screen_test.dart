import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/features/ai_chat/data/ai_chat_repository.dart';
import 'package:tempo_pilot/features/ai_chat/models/ai_chat_models.dart';
import 'package:tempo_pilot/features/ai_chat/providers/ai_chat_providers.dart';
import 'package:tempo_pilot/features/ai_chat/ui/chat_screen.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo_pilot/features/ai_chat/providers/ai_quota_provider.dart';
import 'package:tempo_pilot/providers/auth_provider.dart';

class _FakeRef extends Fake implements Ref {
  @override
  T read<T>(ProviderListenable<T> provider) {
    throw UnimplementedError('read not needed for these tests');
  }
}

class _TestAiChatController extends AiChatController {
  _TestAiChatController({AiChatState? initial, required super.ref})
    : super(repository: const _NoopAiChatRepository()) {
    if (initial != null) {
      state = initial;
    }
  }

  String? lastPrompt;
  bool cancelInvoked = false;

  @override
  Future<void> send({
    required AiChatRequestKind kind,
    required String content,
    List<AiChatMessage>? additionalContext,
  }) async {
    lastPrompt = content;
    final now = DateTime.now().toUtc();
    final userMessage = AiChatMessage(
      id: 'user-${now.microsecondsSinceEpoch}',
      role: AiChatMessageRole.user,
      content: content,
      createdAt: now,
    );
    final streamMessage = AiChatMessage(
      id: 'assistant-${now.microsecondsSinceEpoch}',
      role: AiChatMessageRole.assistant,
      content: 'Preparing your plan…',
      createdAt: now,
      requestId: 'req-${now.microsecondsSinceEpoch}',
      isStreaming: true,
    );
    state = state.copyWith(
      messages: <AiChatMessage>[...state.messages, userMessage, streamMessage],
      status: AiChatStatus.streaming,
      activeRequestId: streamMessage.requestId,
      activeKind: kind,
    );
  }

  @override
  Future<void> cancelActiveRequest() async {
    cancelInvoked = true;
    if (state.messages.isEmpty) {
      return;
    }
    final updated = List<AiChatMessage>.from(state.messages);
    final lastIndex = updated.length - 1;
    updated[lastIndex] = updated[lastIndex].copyWith(isStreaming: false);
    state = state.copyWith(
      messages: updated,
      status: AiChatStatus.idle,
      activeRequestId: null,
      activeKind: null,
    );
  }

  void completeWith(String content) {
    if (state.messages.isEmpty) {
      return;
    }
    final updated = List<AiChatMessage>.from(state.messages);
    final lastIndex = updated.length - 1;
    updated[lastIndex] = updated[lastIndex].copyWith(
      content: content,
      isStreaming: false,
    );
    state = state.copyWith(messages: updated, status: AiChatStatus.idle);
  }
}

class _NoopAiChatRepository implements AiChatRepository {
  const _NoopAiChatRepository();

  @override
  AiChatStreamHandle startStream({
    required AiChatRequestKind kind,
    required List<AiChatRequestMessage> messages,
    required void Function(AiChatStreamChunk chunk) onChunk,
    required void Function(AiChatStreamResult result) onComplete,
    required void Function(AiChatFailure error) onError,
    Map<String, dynamic>? availabilityContext,
  }) {
    throw UnimplementedError('startStream should not be invoked in tests');
  }
}

class _RecordingAnalyticsService extends AnalyticsService {
  final List<String> events = <String>[];

  @override
  void logEvent(String eventName, [Map<String, dynamic>? properties]) {
    events.add(eventName);
    super.logEvent(eventName, properties);
  }
}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _StubAiQuotaController extends AiQuotaController {
  _StubAiQuotaController({AiQuotaState? initial})
    : _fixedNow = DateTime(2025, 1, 1, 12, 0, 0).toUtc(),
      super(
        supabaseClient: _MockSupabaseClient(),
        analyticsService: _RecordingAnalyticsService(),
        clock: () => DateTime(2025, 1, 1, 12, 0, 0).toUtc(),
      ) {
    state =
        initial ??
        AiQuotaState(
          remaining: 10,
          limit: 10,
          status: AiQuotaStatus.success,
          lastUpdated: _fixedNow,
          error: null,
        );
  }

  final DateTime _fixedNow;

  @override
  Future<void> refresh() async {
    state = state.copyWith(
      status: AiQuotaStatus.success,
      lastUpdated: _fixedNow,
    );
  }

  @override
  void decrementOptimistic() {
    final remaining = (state.remaining - 1).clamp(0, state.limit);
    state = state.copyWith(remaining: remaining, lastUpdated: _fixedNow);
  }
}

Widget _buildTestableApp({
  required _TestAiChatController controller,
  bool enabled = true,
  AnalyticsService? analytics,
}) {
  final analyticsService = analytics ?? _RecordingAnalyticsService();
  final quotaController = _StubAiQuotaController();
  return ProviderScope(
    overrides: [
      aiChatControllerProvider.overrideWith((ref) => controller),
      aiChatEnabledProvider.overrideWith((ref) => Future.value(enabled)),
      analyticsServiceProvider.overrideWithValue(analyticsService),
      supabaseClientProvider.overrideWithValue(_MockSupabaseClient()),
      aiQuotaProvider.overrideWith((ref) => quotaController),
    ],
    child: const MaterialApp(home: AiChatScreen()),
  );
}

void main() {
  testWidgets('sends prompt and renders streaming message', (tester) async {
    final controller = _TestAiChatController(ref: _FakeRef());
    await tester.pumpWidget(_buildTestableApp(controller: controller));
    await tester.pump();
    await tester.pump();

    // Verify input area is present
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);

    // Manually trigger send to simulate UI interaction
    await controller.send(
      kind: AiChatRequestKind.plan,
      content: 'Help me plan next focus block',
    );
    await tester.pump();

    expect(find.text('Help me plan next focus block'), findsOneWidget);
    expect(find.text('Preparing your plan…'), findsOneWidget);
  });

  testWidgets('shows cancel button while streaming and triggers cancel', (
    tester,
  ) async {
    final controller = _TestAiChatController(ref: _FakeRef());
    await tester.pumpWidget(_buildTestableApp(controller: controller));
    await tester.pump();
    await tester.pump();

    await controller.send(
      kind: AiChatRequestKind.plan,
      content: 'Need a break plan',
    );
    await tester.pump();

    // Verify cancel button appears when streaming
    expect(find.text('Cancel'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is FilledButton),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(controller.cancelInvoked, isTrue);
  });

  testWidgets('renders error banner when controller is in error state', (
    tester,
  ) async {
    final failure = AiChatFailure(
      requestId: 'req-1',
      code: 'network',
      message: 'Network unavailable.',
      retryable: true,
    );
    final controller = _TestAiChatController(
      ref: _FakeRef(),
      initial: AiChatState(status: AiChatStatus.error, error: failure),
    );

    await tester.pumpWidget(_buildTestableApp(controller: controller));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Network unavailable.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows access denied copy when AI chat disabled', (tester) async {
    final controller = _TestAiChatController(ref: _FakeRef());
    await tester.pumpWidget(
      _buildTestableApp(controller: controller, enabled: false),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('limited to tester accounts'), findsOneWidget);
  });

  testWidgets('retry button resubmits last user message', (tester) async {
    final failure = AiChatFailure(
      requestId: 'req-1',
      code: 'network',
      message: 'Network unavailable.',
      retryable: true,
    );
    final userMessage = AiChatMessage(
      id: 'user-1',
      role: AiChatMessageRole.user,
      content: 'Resend me',
      createdAt: DateTime(2025, 1, 1).toUtc(),
    );
    final controller = _TestAiChatController(
      ref: _FakeRef(),
      initial: AiChatState(
        messages: <AiChatMessage>[userMessage],
        status: AiChatStatus.error,
        error: failure,
        activeKind: AiChatRequestKind.plan,
      ),
    );

    await tester.pumpWidget(_buildTestableApp(controller: controller));
    await tester.pump();
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);

    controller.lastPrompt = null;
    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(controller.lastPrompt, equals('Resend me'));
  });

  testWidgets('streaming indicator shows while processing', (tester) async {
    final controller = _TestAiChatController(ref: _FakeRef());
    await tester.pumpWidget(_buildTestableApp(controller: controller));
    await tester.pump();
    await tester.pump();

    await controller.send(
      kind: AiChatRequestKind.plan,
      content: 'Test streaming',
    );
    await tester.pump();

    // Verify streaming message is present
    expect(find.text('Preparing your plan…'), findsOneWidget);
    final streamingMessages = controller.state.messages.where(
      (m) => m.isStreaming,
    );
    expect(streamingMessages.length, equals(1));
  });

  testWidgets('completed message stops showing streaming state', (
    tester,
  ) async {
    final controller = _TestAiChatController(ref: _FakeRef());
    await tester.pumpWidget(_buildTestableApp(controller: controller));
    await tester.pump();
    await tester.pump();

    await controller.send(
      kind: AiChatRequestKind.plan,
      content: 'Complete this',
    );
    await tester.pump();

    controller.completeWith('Your plan is ready!');
    await tester.pump();

    expect(find.text('Your plan is ready!'), findsOneWidget);
    final streamingMessages = controller.state.messages.where(
      (m) => m.isStreaming,
    );
    expect(streamingMessages.length, equals(0));
  });

  testWidgets('multiple rapid sends preserve message order', (tester) async {
    final controller = _TestAiChatController(ref: _FakeRef());
    await tester.pumpWidget(_buildTestableApp(controller: controller));
    await tester.pump();
    await tester.pump();

    await controller.send(
      kind: AiChatRequestKind.plan,
      content: 'First message',
    );
    await tester.pump();

    await controller.send(
      kind: AiChatRequestKind.replan,
      content: 'Second message',
    );
    await tester.pump();

    // Verify both user messages are present in order
    final userMessages = controller.state.messages
        .where((m) => m.role == AiChatMessageRole.user)
        .toList();
    expect(userMessages.length, equals(2));
    expect(userMessages[0].content, equals('First message'));
    expect(userMessages[1].content, equals('Second message'));
  });

  testWidgets('long message content renders without overflow', (tester) async {
    final controller = _TestAiChatController(ref: _FakeRef());
    await tester.pumpWidget(_buildTestableApp(controller: controller));
    await tester.pump();
    await tester.pump();

    final longContent = 'This is a very long message ' * 20;
    await controller.send(kind: AiChatRequestKind.plan, content: longContent);
    await tester.pump();

    controller.completeWith('$longContent Response with equally long text.');
    await tester.pump();

    // Verify no overflow errors
    expect(tester.takeException(), isNull);
    expect(controller.state.messages.length, equals(2));
  });
}
