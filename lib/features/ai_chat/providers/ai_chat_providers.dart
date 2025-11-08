import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/features/ai_chat/data/ai_chat_repository.dart';
import 'package:tempo_pilot/features/ai_chat/models/ai_chat_models.dart';
import 'package:tempo_pilot/features/ai_chat/prompts/prompts.dart';
import 'package:tempo_pilot/features/ai_chat/providers/ai_quota_provider.dart';
import 'package:tempo_pilot/features/ai_chat/providers/availability_summary_provider.dart';
import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';
import 'package:tempo_pilot/features/planner/free_blocks/free_blocks_controller.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';
import 'package:tempo_pilot/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

export 'ai_feature_flags_provider.dart' show aiChatEnabledProvider;

/// Repository provider wires dependencies and manages the HTTP client lifecycle.
final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final AnalyticsService analytics = ref.watch(analyticsServiceProvider);
  final client = http.Client();
  ref.onDispose(client.close);
  return AiChatRepository(
    supabaseClient: supabase,
    httpClient: client,
    analyticsService: analytics,
  );
});

/// Controller provider that the UI will interact with to send prompts and observe state.
final aiChatControllerProvider =
    StateNotifierProvider<AiChatController, AiChatState>((ref) {
      final repository = ref.watch(aiChatRepositoryProvider);
      return AiChatController(
        repository: repository,
        uuid: const Uuid(),
        clock: () => DateTime.now().toUtc(),
        ref: ref,
      );
    });

/// Riverpod controller that manages conversation state and streaming lifecycle.
class AiChatController extends StateNotifier<AiChatState> {
  AiChatController({
    required AiChatRepository repository,
    required Ref ref,
    Uuid? uuid,
    DateTime Function()? clock,
  }) : _repository = repository,
       _ref = ref,
       _uuid = uuid ?? const Uuid(),
       _clock = clock ?? DateTime.now,
       super(AiChatState.initial());

  final AiChatRepository _repository;
  final Ref _ref;
  final Uuid _uuid;
  final DateTime Function() _clock;

  AiChatStreamHandle? _activeHandle;

  /// Sends a user prompt to the AI service and begins streaming.
  Future<void> send({
    required AiChatRequestKind kind,
    required String content,
    List<AiChatMessage>? additionalContext,
  }) async {
    // Pre-check quota before sending
    final quotaState = _ref.read(aiQuotaProvider);
    if (quotaState.isExhausted) {
      state = state.copyWith(
        status: AiChatStatus.error,
        error: AiChatFailure(
          requestId: _uuid.v4(),
          code: 'quota_exhausted',
          message:
              'Daily AI limit reached (10). Try again after 00:00 London time.',
          retryable: false,
          statusCode: 429,
        ),
      );
      return;
    }

    // Sanitize input
    final sanitization = Prompts.sanitizeInput(content);
    if (sanitization.cleaned.isEmpty) {
      return;
    }

    // Block suspicious input that attempts prompt injection or data exfiltration
    if (sanitization.suspicious) {
      state = state.copyWith(
        status: AiChatStatus.error,
        error: AiChatFailure(
          requestId: _uuid.v4(),
          code: 'input_blocked',
          message:
              'Your message contains patterns that conflict with Tempo Coach guidelines. Please rephrase without override instructions.',
          retryable: false,
        ),
      );
      return;
    }

    if (state.isStreaming) {
      await cancelActiveRequest();
    }

    final timestamp = _clock().toUtc();
    final userMessage = AiChatMessage(
      id: _uuid.v4(),
      role: AiChatMessageRole.user,
      content: sanitization.cleaned,
      createdAt: timestamp,
    );

    final updatedMessages = <AiChatMessage>[
      ...state.messages,
      if (additionalContext != null) ...additionalContext,
      userMessage,
    ];

    state = state.copyWith(
      messages: updatedMessages,
      status: AiChatStatus.streaming,
      activeRequestId: null,
      activeKind: kind,
      clearError: true,
      clearLastUsage: true,
    );

    // Build request messages (no system message needed for tool calling)
    final requestMessages = updatedMessages
        .map(
          (message) => AiChatRequestMessage(
            role: message.role,
            content: message.content,
          ),
        )
        .toList();

    // Get availability context for tools
    // Use read() - StateNotifier methods cannot use watch()
    Map<String, dynamic>? availabilityContext;
    final availabilitySummaryAsync = _ref.read(availabilitySummaryProvider);
    final analytics = _ref.read(analyticsServiceProvider);
    
    // Debug: Log provider state
    analytics.logEvent('ai_availability_provider_state', {
      'is_loading': availabilitySummaryAsync is AsyncLoading,
      'is_error': availabilitySummaryAsync is AsyncError,
      'is_data': availabilitySummaryAsync is AsyncData,
      'type': availabilitySummaryAsync.runtimeType.toString(),
    });
    
    // If still loading, wait and retry multiple times (flags or calendar may be loading)
    if (availabilitySummaryAsync is AsyncLoading) {
      analytics.logEvent('ai_availability_waiting_for_data', {
        'reason': 'loading',
      });
      
      // Try up to 3 times with increasing delays
      for (int attempt = 0; attempt < 3; attempt++) {
        await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        final retryAsync = _ref.read(availabilitySummaryProvider);
        
        if (retryAsync is AsyncData<Map<String, dynamic>?>) {
          availabilityContext = retryAsync.value;
          analytics.logEvent('ai_availability_context_extracted_after_wait', {
            'attempt': attempt + 1,
            'is_null': availabilityContext == null,
            'has_intervals': availabilityContext?['intervals'] != null,
            'interval_count': (availabilityContext?['intervals'] as List?)?.length ?? 0,
            'keys': availabilityContext?.keys.join(',') ?? 'none',
          });
          break;
        }
      }
      
      if (availabilityContext == null) {
        analytics.logEvent('ai_availability_still_loading_after_retries', {});
        
        // Last resort: try reading the raw free blocks provider directly
        final rawFreeBlocks = _ref.read(filteredFreeBlocksTodayProvider);
        analytics.logEvent('ai_availability_raw_free_blocks_check', {
          'is_loading': rawFreeBlocks is AsyncLoading,
          'is_error': rawFreeBlocks is AsyncError,
          'is_data': rawFreeBlocks is AsyncData,
        });

        if (rawFreeBlocks is AsyncData<List<TimeInterval>>) {
          final intervals = rawFreeBlocks.value;
          final formatter = _ref.read(aiAvailabilityFormatterProvider);
          final now = DateTime.now();
          final formattedIntervals = formatter.formatForAi(
            intervals,
            now: now,
            minDuration: Duration.zero,
          );
          final fallbackJson = formatter.toJson(
            formattedIntervals,
            now.timeZoneName,
            now,
          );

          availabilityContext = fallbackJson;
          analytics.logEvent('ai_availability_context_fallback_generated', {
            'interval_count': formattedIntervals.length,
            'has_intervals': formattedIntervals.isNotEmpty,
            'keys': fallbackJson.keys.join(','),
          });
        }
      }
    } else if (availabilitySummaryAsync is AsyncData<Map<String, dynamic>?>) {
      availabilityContext = availabilitySummaryAsync.value;
      // Debug: Log what we're sending
      analytics.logEvent('ai_availability_context_extracted', {
        'is_null': availabilityContext == null,
        'has_intervals': availabilityContext?['intervals'] != null,
        'interval_count': (availabilityContext?['intervals'] as List?)?.length ?? 0,
        'keys': availabilityContext?.keys.join(',') ?? 'none',
      });
    }

    final handle = _repository.startStream(
      kind: kind,
      messages: requestMessages,
      availabilityContext: availabilityContext,
      onChunk: _handleChunk,
      onComplete: _handleComplete,
      onError: _handleError,
    );

    _activeHandle = handle;
    state = state.copyWith(activeRequestId: handle.requestId);
  }

  /// Cancels the active streaming request, if any.
  Future<void> cancelActiveRequest() async {
    final handle = _activeHandle;
    if (handle == null) {
      return;
    }
    handle.cancel();
    await handle.done;
    _activeHandle = null;
    state = state.copyWith(
      status: AiChatStatus.idle,
      activeRequestId: null,
      activeKind: null,
    );
  }

  /// Clears the current conversation history.
  void resetConversation() {
    _activeHandle?.cancel();
    _activeHandle = null;
    state = AiChatState.initial();
  }

  void _handleChunk(AiChatStreamChunk chunk) {
    final messages = List<AiChatMessage>.from(state.messages);
    final index = messages.indexWhere(
      (message) =>
          message.requestId == chunk.requestId &&
          message.role == AiChatMessageRole.assistant,
    );

    if (index == -1) {
      messages.add(
        AiChatMessage(
          id: _uuid.v4(),
          role: AiChatMessageRole.assistant,
          content: chunk.delta,
          createdAt: _clock().toUtc(),
          requestId: chunk.requestId,
          isStreaming: true,
        ),
      );
    } else {
      final existing = messages[index];
      messages[index] = existing.copyWith(
        content: existing.content + chunk.delta,
        isStreaming: true,
      );
    }

    state = state.copyWith(
      messages: messages,
      activeRequestId: chunk.requestId,
    );
  }

  void _handleComplete(AiChatStreamResult result) {
    _activeHandle = null;
    final messages = List<AiChatMessage>.from(state.messages);
    final index = messages.indexWhere(
      (message) => message.requestId == result.requestId,
    );
    if (index != -1) {
      final existing = messages[index];
      messages[index] = existing.copyWith(isStreaming: false);
    }

    state = state.copyWith(
      messages: messages,
      status: AiChatStatus.idle,
      activeRequestId: null,
      activeKind: null,
      clearError: true,
      lastUsage: result.usage,
      clearLastUsage: result.cancelled,
    );

    // Update quota after successful completion (not cancelled)
    if (!result.cancelled) {
      _ref.read(aiQuotaProvider.notifier).decrementOptimistic();
      // Background refresh to reconcile with server
      // Small delay allows server to write the ai_messages record
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        _ref.read(aiQuotaProvider.notifier).refresh();
      });
    }
  }

  void _handleError(AiChatFailure failure) {
    _activeHandle = null;
    final messages = List<AiChatMessage>.from(state.messages);
    final index = messages.indexWhere(
      (message) => message.requestId == failure.requestId,
    );
    if (index != -1) {
      final existing = messages[index];
      messages[index] = existing.copyWith(isStreaming: false);
    }

    state = state.copyWith(
      messages: messages,
      status: AiChatStatus.error,
      activeRequestId: null,
      activeKind: null,
      error: failure,
    );
  }
}
