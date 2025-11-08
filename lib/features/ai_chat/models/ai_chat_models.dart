import 'package:flutter/foundation.dart';

/// Available kinds of AI chat requests supported by the edge function.
enum AiChatRequestKind { plan, replan, reflect }

extension AiChatRequestKindX on AiChatRequestKind {
  String get value {
    switch (this) {
      case AiChatRequestKind.plan:
        return 'plan';
      case AiChatRequestKind.replan:
        return 'replan';
      case AiChatRequestKind.reflect:
        return 'reflect';
    }
  }

  static AiChatRequestKind fromValue(String value) {
    switch (value) {
      case 'plan':
        return AiChatRequestKind.plan;
      case 'replan':
        return AiChatRequestKind.replan;
      case 'reflect':
        return AiChatRequestKind.reflect;
      default:
        throw ArgumentError('Unknown AiChatRequestKind value: $value');
    }
  }
}

/// Roles a chat message can take in the conversation history.
enum AiChatMessageRole { system, user, assistant }

extension AiChatMessageRoleX on AiChatMessageRole {
  String get value {
    switch (this) {
      case AiChatMessageRole.system:
        return 'system';
      case AiChatMessageRole.user:
        return 'user';
      case AiChatMessageRole.assistant:
        return 'assistant';
    }
  }

  static AiChatMessageRole fromValue(String value) {
    switch (value) {
      case 'system':
        return AiChatMessageRole.system;
      case 'user':
        return AiChatMessageRole.user;
      case 'assistant':
        return AiChatMessageRole.assistant;
      default:
        throw ArgumentError('Unknown AiChatMessageRole value: $value');
    }
  }
}

/// Message payload that is sent to the ai_proxy edge function.
class AiChatRequestMessage {
  const AiChatRequestMessage({required this.role, required this.content});

  final AiChatMessageRole role;
  final String content;

  Map<String, dynamic> toJson() {
    return {'role': role.value, 'content': content};
  }
}

/// Chunk of streamed assistant text.
class AiChatStreamChunk {
  const AiChatStreamChunk({
    required this.requestId,
    required this.delta,
    this.index,
  });

  final String requestId;
  final String delta;
  final int? index;
}

/// Usage metrics returned by the edge function once the stream completes.
class AiChatUsage {
  const AiChatUsage({this.inputTokens, this.outputTokens});

  final int? inputTokens;
  final int? outputTokens;
}

/// Final result emitted when a stream ends (successfully or via cancel).
class AiChatStreamResult {
  const AiChatStreamResult({
    required this.requestId,
    this.usage,
    this.cancelled = false,
  });

  final String requestId;
  final AiChatUsage? usage;
  final bool cancelled;
}

/// Structured error propagated from the streaming layer.
class AiChatFailure {
  const AiChatFailure({
    required this.requestId,
    required this.code,
    required this.message,
    this.retryable = false,
    this.statusCode,
    this.cause,
  });

  final String requestId;
  final String code;
  final String message;
  final bool retryable;
  final int? statusCode;
  final Object? cause;

  AiChatFailure copyWith({
    String? requestId,
    String? code,
    String? message,
    bool? retryable,
    int? statusCode,
    Object? cause,
  }) {
    return AiChatFailure(
      requestId: requestId ?? this.requestId,
      code: code ?? this.code,
      message: message ?? this.message,
      retryable: retryable ?? this.retryable,
      statusCode: statusCode ?? this.statusCode,
      cause: cause ?? this.cause,
    );
  }
}

/// Handle returned for a streaming request, exposing cancellation and completion.
class AiChatStreamHandle {
  AiChatStreamHandle({
    required this.requestId,
    required Future<void> done,
    required VoidCallback onCancel,
  }) : _done = done,
       _onCancel = onCancel;

  final String requestId;
  final Future<void> _done;
  final VoidCallback _onCancel;
  bool _isCancelled = false;

  Future<void> get done => _done;

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;
    _onCancel();
  }
}

/// Current status of the AI chat controller.
enum AiChatStatus { idle, streaming, error }

/// Immutable chat message tracked by the controller state.
class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.requestId,
    this.isStreaming = false,
  });

  final String id;
  final AiChatMessageRole role;
  final String content;
  final DateTime createdAt;
  final String? requestId;
  final bool isStreaming;

  AiChatMessage copyWith({
    String? id,
    AiChatMessageRole? role,
    String? content,
    DateTime? createdAt,
    String? requestId,
    bool? isStreaming,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      requestId: requestId ?? this.requestId,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

/// State exposed by the AI chat controller provider.
class AiChatState {
  AiChatState({
    List<AiChatMessage> messages = const <AiChatMessage>[],
    this.status = AiChatStatus.idle,
    this.activeRequestId,
    this.activeKind,
    this.error,
    this.lastUsage,
  }) : messages = List<AiChatMessage>.unmodifiable(messages);

  final List<AiChatMessage> messages;
  final AiChatStatus status;
  final String? activeRequestId;
  final AiChatRequestKind? activeKind;
  final AiChatFailure? error;
  final AiChatUsage? lastUsage;

  bool get isStreaming => status == AiChatStatus.streaming;

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    AiChatStatus? status,
    String? activeRequestId,
    AiChatRequestKind? activeKind,
    AiChatFailure? error,
    bool clearError = false,
    AiChatUsage? lastUsage,
    bool clearLastUsage = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      activeRequestId: activeRequestId ?? this.activeRequestId,
      activeKind: activeKind ?? this.activeKind,
      error: clearError ? null : (error ?? this.error),
      lastUsage: clearLastUsage ? null : (lastUsage ?? this.lastUsage),
    );
  }

  static AiChatState initial() => AiChatState();
}
