import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo_pilot/core/config/supabase_config.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/features/ai_chat/models/ai_chat_models.dart';
import 'package:uuid/uuid.dart';

/// Repository responsible for orchestrating AI chat streaming via the edge function.
class AiChatRepository {
  AiChatRepository({
    required SupabaseClient supabaseClient,
    required http.Client httpClient,
    required AnalyticsService analyticsService,
    Uuid? uuid,
    Uri? endpoint,
    List<Duration>? retryBackoff,
  }) : _supabaseClient = supabaseClient,
       _httpClient = httpClient,
       _analyticsService = analyticsService,
       _uuid = uuid ?? const Uuid(),
       _endpoint =
           endpoint ??
           Uri.parse('${SupabaseConfig.supabaseUrl}/functions/v1/ai_proxy'),
       _retryBackoff =
           retryBackoff ??
           const <Duration>[
             Duration(seconds: 1),
             Duration(seconds: 2),
             Duration(seconds: 4),
           ];

  final SupabaseClient _supabaseClient;
  final http.Client _httpClient;
  final AnalyticsService _analyticsService;
  final Uuid _uuid;
  final Uri _endpoint;
  final List<Duration> _retryBackoff;

  /// Initiates a streaming request to the ai_proxy edge function.
  ///
  /// Returns a handle that allows cancellation and exposes completion.
  AiChatStreamHandle startStream({
    required AiChatRequestKind kind,
    required List<AiChatRequestMessage> messages,
    required void Function(AiChatStreamChunk chunk) onChunk,
    required void Function(AiChatStreamResult result) onComplete,
    required void Function(AiChatFailure error) onError,
    Map<String, dynamic>? availabilityContext,
  }) {
    final requestId = _uuid.v4();
    final runner = _AiChatRequestRunner(
      requestId: requestId,
      kind: kind,
      messages: messages,
      availabilityContext: availabilityContext,
      supabaseClient: _supabaseClient,
      httpClient: _httpClient,
      analyticsService: _analyticsService,
      endpoint: _endpoint,
      retryBackoff: _retryBackoff,
      onChunk: onChunk,
      onComplete: onComplete,
      onError: onError,
    );
    runner.start();
    return AiChatStreamHandle(
      requestId: requestId,
      done: runner.done,
      onCancel: runner.cancel,
    );
  }
}

class _AiChatRequestRunner {
  _AiChatRequestRunner({
    required this.requestId,
    required this.kind,
    required this.messages,
    this.availabilityContext,
    required SupabaseClient supabaseClient,
    required http.Client httpClient,
    required AnalyticsService analyticsService,
    required Uri endpoint,
    required List<Duration> retryBackoff,
    required this.onChunk,
    required this.onComplete,
    required this.onError,
  }) : _supabaseClient = supabaseClient,
       _httpClient = httpClient,
       _analyticsService = analyticsService,
       _endpoint = endpoint,
       _retryBackoff = retryBackoff;

  final SupabaseClient _supabaseClient;
  final http.Client _httpClient;
  final AnalyticsService _analyticsService;
  final Uri _endpoint;
  final List<Duration> _retryBackoff;

  final String requestId;
  final AiChatRequestKind kind;
  final List<AiChatRequestMessage> messages;
  final Map<String, dynamic>? availabilityContext;

  final void Function(AiChatStreamChunk chunk) onChunk;
  final void Function(AiChatStreamResult result) onComplete;
  final void Function(AiChatFailure error) onError;

  final Completer<void> _done = Completer<void>();
  StreamSubscription<String>? _subscription;
  bool _terminalEmitted = false;
  bool _isCancelled = false;
  String _pending = '';
  AiChatUsage? _usage;

  Future<void> get done => _done.future;

  void start() {
    Future<void>(() async {
      try {
        _analyticsService.logEvent('ai_request_sent', {
          'kind': kind.value,
          'request_id': requestId,
        });
        await _executeWithRetries();
      } catch (error, stackTrace) {
        _emitError(
          AiChatFailure(
            requestId: requestId,
            code: 'unexpected',
            message: error.toString(),
            retryable: false,
            cause: error,
          ),
        );
        _analyticsService.logException(
          error,
          stackTrace,
          context: 'ai_chat_repository',
        );
      } finally {
        if (!_done.isCompleted) {
          _done.complete();
        }
      }
    });
  }

  void cancel() {
    if (_terminalEmitted || _isCancelled) {
      return;
    }
    _isCancelled = true;
    _subscription?.cancel();
    _emitCompletion(cancelled: true);
  }

  Future<void> _executeWithRetries() async {
    final session = _supabaseClient.auth.currentSession;
    final accessToken = session?.accessToken;

    if (accessToken == null && !SupabaseConfig.authDisabled) {
      _emitError(
        AiChatFailure(
          requestId: requestId,
          code: 'not_authenticated',
          message: 'Sign in required to use AI chat.',
          retryable: false,
          statusCode: 401,
        ),
      );
      return;
    }

    final totalAttempts = _retryBackoff.length + 1;
    for (var attempt = 0; attempt < totalAttempts; attempt++) {
      if (_isCancelled) {
        return;
      }

      if (attempt > 0) {
        final delay = _retryBackoff[attempt - 1];
        if (!delay.isNegative && delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
      }

      final request = http.Request('POST', _endpoint)
        ..headers.addAll({
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'text/event-stream',
          HttpHeaders.cacheControlHeader: 'no-cache',
          HttpHeaders.connectionHeader: 'keep-alive',
          'X-Request-Id': requestId,
        })
        ..body = jsonEncode({
          'kind': kind.value,
          'messages': messages.map((m) => m.toJson()).toList(),
          if (availabilityContext != null)
            'availability_context': availabilityContext,
        });

      // Debug: Log what we're sending
      _analyticsService.logEvent('ai_sending_availability', {
        'has_availability_context': availabilityContext != null,
        'request_body_length': request.body.length,
      });

      if (accessToken != null) {
        request.headers[HttpHeaders.authorizationHeader] =
            'Bearer $accessToken';
      }

      http.StreamedResponse response;
      try {
        response = await _httpClient.send(request);
      } catch (error) {
        final retryable = _isRetryableException(error);
        if (retryable && attempt < totalAttempts - 1) {
          continue;
        }
        _emitError(
          AiChatFailure(
            requestId: requestId,
            code: 'network_error',
            message: 'Failed to connect to AI service.',
            retryable: retryable && attempt < totalAttempts - 1,
            cause: error,
          ),
        );
        return;
      }

      if (response.statusCode != HttpStatus.ok) {
        final body = await response.stream.bytesToString();
        final retryable = _isTransientStatus(response.statusCode);
        if (retryable && attempt < totalAttempts - 1) {
          continue;
        }
        final failure = _parseErrorBody(body).copyWith(
          requestId: requestId,
          statusCode: response.statusCode,
          retryable: retryable && attempt < totalAttempts - 1,
        );
        _emitError(failure);
        return;
      }

      await _consumeResponse(response);
      return;
    }
  }

  Future<void> _consumeResponse(http.StreamedResponse response) async {
    final completer = Completer<void>();
    _subscription = utf8.decoder
        .bind(response.stream)
        .listen(
          (chunk) {
            if (_terminalEmitted || _isCancelled) {
              return;
            }
            _pending += chunk;
            _processPending();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (_terminalEmitted) {
              completer.complete();
              return;
            }
            _emitError(
              AiChatFailure(
                requestId: requestId,
                code: 'stream_error',
                message: 'Streaming error from AI service.',
                retryable: true,
                cause: error,
              ),
            );
            _analyticsService.logException(
              error,
              stackTrace,
              context: 'ai_chat_stream',
            );
            completer.complete();
          },
          onDone: () {
            if (_terminalEmitted) {
              completer.complete();
              return;
            }
            if (_isCancelled) {
              _emitCompletion(cancelled: true);
            } else {
              _emitError(
                AiChatFailure(
                  requestId: requestId,
                  code: 'stream_incomplete',
                  message: 'AI stream ended unexpectedly.',
                  retryable: true,
                ),
              );
            }
            completer.complete();
          },
          cancelOnError: true,
        );

    await completer.future;
  }

  void _processPending() {
    while (!_terminalEmitted && !_isCancelled) {
      final separator = _nextSeparator(_pending);
      if (separator == null) {
        return;
      }
      final eventChunk = _pending.substring(0, separator.index);
      _pending = _pending.substring(separator.index + separator.length);
      final event = _parseEvent(eventChunk);
      if (event == null) {
        continue;
      }
      _dispatchEvent(event);
    }
  }

  void _dispatchEvent(_SseEvent event) {
    if (_terminalEmitted) {
      return;
    }

    switch (event.event) {
      case 'chunk':
        final data = event.jsonData;
        if (data == null) {
          return;
        }
        final delta = data['delta'] as String? ?? '';
        final index = data['index'] is int ? data['index'] as int : null;
        if (delta.isEmpty && index == null) {
          return;
        }
        onChunk(
          AiChatStreamChunk(requestId: requestId, delta: delta, index: index),
        );
        break;
      case 'tool_calls_start':
        // AI is about to execute tools - show a "thinking" indicator
        onChunk(
          AiChatStreamChunk(requestId: requestId, delta: '\n\n🔧 Checking your calendar...', index: null),
        );
        break;
      case 'tool_result':
        final data = event.jsonData;
        if (data != null) {
          final result = data['result'] as String?;
          final error = data['error'] as String?;
          
          if (error != null) {
            onChunk(
              AiChatStreamChunk(requestId: requestId, delta: '\n❌ Error accessing calendar: $error', index: null),
            );
          } else if (result != null) {
            // Don't show raw tool results to user - let AI interpret them
            onChunk(
              AiChatStreamChunk(requestId: requestId, delta: '\n✅ Calendar data retrieved', index: null),
            );
          }
        }
        break;
      case 'tool_calls_complete':
        // Tools finished executing - AI will now respond with interpretation
        onChunk(
          AiChatStreamChunk(requestId: requestId, delta: '\n\n', index: null),
        );
        break;
      case 'end':
        _usage = _parseUsage(event.data);
        _analyticsService.logEvent('ai_stream_completed', {
          'kind': kind.value,
          'request_id': requestId,
          if (_usage?.inputTokens != null) 'tokens_in': _usage!.inputTokens,
          if (_usage?.outputTokens != null) 'tokens_out': _usage!.outputTokens,
        });
        _emitCompletion(cancelled: false);
        break;
      case 'error':
        final data = event.jsonData;
        final code = data?['code'] as String? ?? 'stream_error';
        final message = data?['message'] as String? ?? 'AI stream error.';
        final retryable = data?['retryable'] == true || _isTransientCode(code);
        final status = data?['status'] as int?;
        _emitError(
          AiChatFailure(
            requestId: requestId,
            code: code,
            message: message,
            retryable: retryable,
            statusCode: status,
          ),
        );
        break;
      default:
        // Ignore keep-alive or start events; controller does not require them yet.
        break;
    }
  }

  void _emitCompletion({required bool cancelled}) {
    if (_terminalEmitted) {
      return;
    }
    _terminalEmitted = true;
    _subscription?.cancel();
    onComplete(
      AiChatStreamResult(
        requestId: requestId,
        usage: cancelled ? null : _usage,
        cancelled: cancelled,
      ),
    );
    if (!_done.isCompleted) {
      _done.complete();
    }
  }

  void _emitError(AiChatFailure failure) {
    if (_terminalEmitted) {
      return;
    }
    _terminalEmitted = true;
    _subscription?.cancel();
    onError(failure);
    if (!_done.isCompleted) {
      _done.complete();
    }
  }

  bool _isRetryableException(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException;
  }

  bool _isTransientStatus(int statusCode) {
    return statusCode == 408 ||
        statusCode == 429 ||
        (statusCode >= 500 && statusCode < 600);
  }

  bool _isTransientCode(String code) {
    final normalized = code.toLowerCase();
    return normalized.contains('timeout') ||
        normalized.contains('rate') ||
        normalized.contains('backoff');
  }

  AiChatFailure _parseErrorBody(String body) {
    if (body.isEmpty) {
      return AiChatFailure(
        requestId: requestId,
        code: 'http_error',
        message: 'Request failed.',
      );
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return AiChatFailure(
          requestId: requestId,
          code: decoded['code'] as String? ?? 'http_error',
          message: decoded['message'] as String? ?? body,
          retryable: decoded['retryable'] == true,
        );
      }
      return AiChatFailure(
        requestId: requestId,
        code: 'http_error',
        message: body,
      );
    } catch (_) {
      return AiChatFailure(
        requestId: requestId,
        code: 'http_error',
        message: body,
      );
    }
  }

  AiChatUsage? _parseUsage(String data) {
    if (data.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        if (decoded['usage'] is Map<String, dynamic>) {
          final usage = decoded['usage'] as Map<String, dynamic>;
          return AiChatUsage(
            inputTokens: usage['in'] as int?,
            outputTokens: usage['out'] as int?,
          );
        }
        return AiChatUsage(
          inputTokens: decoded['tokens_in'] as int?,
          outputTokens: decoded['tokens_out'] as int?,
        );
      }
    } catch (_) {
      // Ignore parse errors and treat as no usage info.
    }
    return null;
  }

  _EventSeparator? _nextSeparator(String source) {
    final lfIndex = source.indexOf('\n\n');
    final crlfIndex = source.indexOf('\r\n\r\n');
    if (lfIndex == -1 && crlfIndex == -1) {
      return null;
    }
    if (lfIndex == -1) {
      return _EventSeparator(index: crlfIndex, length: 4);
    }
    if (crlfIndex == -1) {
      return _EventSeparator(index: lfIndex, length: 2);
    }
    if (lfIndex < crlfIndex) {
      return _EventSeparator(index: lfIndex, length: 2);
    }
    return _EventSeparator(index: crlfIndex, length: 4);
  }

  _SseEvent? _parseEvent(String raw) {
    final lines = raw.split(RegExp(r'\r?\n'));
    String? eventName;
    String? id;
    final dataBuffer = StringBuffer();

    for (final line in lines) {
      if (line.isEmpty) {
        continue;
      }
      if (line.startsWith(':')) {
        // Comment/heartbeat frame.
        continue;
      }
      final separatorIndex = line.indexOf(':');
      if (separatorIndex == -1) {
        continue;
      }
      final field = line.substring(0, separatorIndex);
      final value = line.substring(separatorIndex + 1).trimLeft();
      switch (field) {
        case 'event':
          eventName = value;
          break;
        case 'data':
          if (dataBuffer.isNotEmpty) {
            dataBuffer.write('\n');
          }
          dataBuffer.write(value);
          break;
        case 'id':
          id = value;
          break;
        default:
          break;
      }
    }

    if (eventName == null && dataBuffer.isEmpty) {
      return null;
    }

    return _SseEvent(
      event: eventName ?? 'message',
      data: dataBuffer.toString(),
      id: id,
    );
  }
}

class _SseEvent {
  _SseEvent({required this.event, required this.data, this.id});

  final String event;
  final String data;
  final String? id;

  Map<String, dynamic>? get jsonData {
    if (data.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore parse errors to avoid breaking the stream.
    }
    return null;
  }
}

class _EventSeparator {
  _EventSeparator({required this.index, required this.length});

  final int index;
  final int length;
}
