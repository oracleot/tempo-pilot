import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo_pilot/core/config/supabase_config.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/features/ai_chat/data/ai_chat_repository.dart';
import 'package:tempo_pilot/features/ai_chat/models/ai_chat_models.dart';
import 'package:http/http.dart' as http;

class MockHttpClient extends Mock implements http.Client {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class FakeHttpRequest extends Fake implements http.BaseRequest {}

class RecordingAnalyticsService extends AnalyticsService {
  final List<Map<String, dynamic>> events = <Map<String, dynamic>>[];

  @override
  void logEvent(String eventName, [Map<String, dynamic>? properties]) {
    events.add({
      'name': eventName,
      'props': properties ?? const <String, dynamic>{},
    });
    super.logEvent(eventName, properties);
  }

  final List<String> exceptions = <String>[];

  @override
  void logException(
    dynamic exception,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? properties,
  }) {
    exceptions.add('${context ?? 'context'}:${exception.runtimeType}');
    super.logException(
      exception,
      stackTrace,
      context: context,
      properties: properties,
    );
  }
}

const List<Duration> _testRetryBackoff = <Duration>[
  Duration.zero,
  Duration.zero,
  Duration.zero,
];

void main() {
  setUpAll(() {
    registerFallbackValue(FakeHttpRequest());
  });

  group('AiChatRepository', () {
    late MockHttpClient httpClient;
    late MockSupabaseClient supabaseClient;
    late MockGoTrueClient authClient;
    late RecordingAnalyticsService analytics;
    late bool previousAuthDisabled;

    setUp(() {
      httpClient = MockHttpClient();
      supabaseClient = MockSupabaseClient();
      authClient = MockGoTrueClient();
      analytics = RecordingAnalyticsService();

      when(() => supabaseClient.auth).thenReturn(authClient);
      when(() => authClient.currentSession).thenReturn(null);

      previousAuthDisabled = SupabaseConfig.authDisabled;
      SupabaseConfig.authDisabled = true;
    });

    tearDown(() {
      SupabaseConfig.authDisabled = previousAuthDisabled;
    });

    test('streams chunks and completion events', () async {
      final repository = AiChatRepository(
        supabaseClient: supabaseClient,
        httpClient: httpClient,
        analyticsService: analytics,
        retryBackoff: _testRetryBackoff,
        endpoint: Uri.parse(
          'https://example.supabase.co/functions/v1/ai_proxy',
        ),
      );

      final controller = StreamController<List<int>>();

      when(() => httpClient.send(any())).thenAnswer((invocation) {
        Future.microtask(() async {
          controller.add(
            utf8.encode('event: start\ndata: {"model":"gpt"}\n\n'),
          );
          controller.add(
            utf8.encode('event: chunk\ndata: {"delta":"Hello"}\n\n'),
          );
          controller.add(
            utf8.encode('event: end\ndata: {"usage":{"in":5,"out":7}}\n\n'),
          );
          await controller.close();
        });
        return Future.value(http.StreamedResponse(controller.stream, 200));
      });

      final chunks = <String>[];
      AiChatStreamResult? completion;
      AiChatFailure? failure;

      final handle = repository.startStream(
        kind: AiChatRequestKind.plan,
        messages: const <AiChatRequestMessage>[
          AiChatRequestMessage(role: AiChatMessageRole.user, content: 'Hi'),
        ],
        onChunk: (chunk) => chunks.add(chunk.delta),
        onComplete: (result) => completion = result,
        onError: (error) => failure = error,
      );

      await handle.done;

      expect(chunks, equals(<String>['Hello']));
      expect(completion, isNotNull);
      expect(completion!.cancelled, isFalse);
      expect(completion!.usage?.inputTokens, 5);
      expect(completion!.usage?.outputTokens, 7);
      expect(failure, isNull);

      final eventNames = analytics.events.map((e) => e['name']).toList();
      expect(
        eventNames,
        containsAll(<String>['ai_request_sent', 'ai_stream_completed']),
      );
    });

    test('cancels active stream and reports cancellation', () async {
      final repository = AiChatRepository(
        supabaseClient: supabaseClient,
        httpClient: httpClient,
        analyticsService: analytics,
        retryBackoff: _testRetryBackoff,
        endpoint: Uri.parse(
          'https://example.supabase.co/functions/v1/ai_proxy',
        ),
      );

      final controller = StreamController<List<int>>();

      when(() => httpClient.send(any())).thenAnswer((invocation) {
        Future.microtask(() async {
          controller.add(
            utf8.encode('event: chunk\ndata: {"delta":"Partial"}\n\n'),
          );
        });
        return Future.value(http.StreamedResponse(controller.stream, 200));
      });

      AiChatStreamResult? completion;

      final handle = repository.startStream(
        kind: AiChatRequestKind.replan,
        messages: const <AiChatRequestMessage>[
          AiChatRequestMessage(
            role: AiChatMessageRole.user,
            content: 'Cancel please',
          ),
        ],
        onChunk: (_) {},
        onComplete: (result) => completion = result,
        onError: (_) {},
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      handle.cancel();
      await handle.done;
      await controller.close();

      expect(completion, isNotNull);
      expect(completion!.cancelled, isTrue);
      expect(completion!.usage, isNull);
    });

    test('retries on transient failures and eventually succeeds', () async {
      final repository = AiChatRepository(
        supabaseClient: supabaseClient,
        httpClient: httpClient,
        analyticsService: analytics,
        retryBackoff: _testRetryBackoff,
        endpoint: Uri.parse(
          'https://example.supabase.co/functions/v1/ai_proxy',
        ),
      );

      var attempts = 0;
      when(() => httpClient.send(any())).thenAnswer((invocation) {
        attempts += 1;
        if (attempts == 1) {
          final errorStream = Stream<List<int>>.value(
            utf8.encode('{"code":"overloaded"}'),
          );
          return Future.value(http.StreamedResponse(errorStream, 500));
        }
        final controller = StreamController<List<int>>();
        Future.microtask(() async {
          controller.add(utf8.encode('event: chunk\ndata: {"delta":"Hi"}\n\n'));
          controller.add(
            utf8.encode('event: end\ndata: {"usage":{"in":1,"out":2}}\n\n'),
          );
          await controller.close();
        });
        return Future.value(http.StreamedResponse(controller.stream, 200));
      });

      final chunks = <String>[];
      AiChatStreamResult? completion;

      final handle = repository.startStream(
        kind: AiChatRequestKind.reflect,
        messages: const <AiChatRequestMessage>[
          AiChatRequestMessage(role: AiChatMessageRole.user, content: 'Retry?'),
        ],
        onChunk: (chunk) => chunks.add(chunk.delta),
        onComplete: (result) => completion = result,
        onError: (error) => fail('Should not error: ${error.code}'),
      );

      await handle.done;

      expect(attempts, equals(2));
      expect(chunks, equals(<String>['Hi']));
      expect(completion, isNotNull);
      expect(completion!.cancelled, isFalse);
    });

    test('exhausts retries and reports error', () async {
      final repository = AiChatRepository(
        supabaseClient: supabaseClient,
        httpClient: httpClient,
        analyticsService: analytics,
        retryBackoff: _testRetryBackoff,
        endpoint: Uri.parse(
          'https://example.supabase.co/functions/v1/ai_proxy',
        ),
      );

      var attempts = 0;
      when(() => httpClient.send(any())).thenAnswer((invocation) {
        attempts += 1;
        final errorStream = Stream<List<int>>.value(
          utf8.encode('{"code":"overloaded","message":"Service overloaded"}'),
        );
        return Future.value(http.StreamedResponse(errorStream, 503));
      });

      AiChatFailure? failure;

      final handle = repository.startStream(
        kind: AiChatRequestKind.plan,
        messages: const <AiChatRequestMessage>[
          AiChatRequestMessage(role: AiChatMessageRole.user, content: 'Fail'),
        ],
        onChunk: (_) => fail('Should not chunk'),
        onComplete: (_) => fail('Should not complete'),
        onError: (error) => failure = error,
      );

      await handle.done;

      expect(attempts, equals(4)); // 1 initial + 3 retries
      expect(failure, isNotNull);
      expect(failure!.code, equals('overloaded'));
      expect(failure!.retryable, isFalse); // No more retries available
      expect(failure!.statusCode, equals(503));
    });

    test('handles non-retryable error immediately', () async {
      final repository = AiChatRepository(
        supabaseClient: supabaseClient,
        httpClient: httpClient,
        analyticsService: analytics,
        retryBackoff: _testRetryBackoff,
        endpoint: Uri.parse(
          'https://example.supabase.co/functions/v1/ai_proxy',
        ),
      );

      when(() => httpClient.send(any())).thenAnswer((invocation) {
        final errorStream = Stream<List<int>>.value(
          utf8.encode('{"code":"invalid_request","message":"Bad request"}'),
        );
        return Future.value(http.StreamedResponse(errorStream, 400));
      });

      AiChatFailure? failure;

      final handle = repository.startStream(
        kind: AiChatRequestKind.plan,
        messages: const <AiChatRequestMessage>[
          AiChatRequestMessage(
            role: AiChatMessageRole.user,
            content: 'Invalid',
          ),
        ],
        onChunk: (_) => fail('Should not chunk'),
        onComplete: (_) => fail('Should not complete'),
        onError: (error) => failure = error,
      );

      await handle.done;

      expect(failure, isNotNull);
      expect(failure!.code, equals('invalid_request'));
      expect(failure!.retryable, isFalse);
      expect(failure!.statusCode, equals(400));
    });

    test('handles quota exhausted (429) error', () async {
      final repository = AiChatRepository(
        supabaseClient: supabaseClient,
        httpClient: httpClient,
        analyticsService: analytics,
        retryBackoff: _testRetryBackoff,
        endpoint: Uri.parse(
          'https://example.supabase.co/functions/v1/ai_proxy',
        ),
      );

      when(() => httpClient.send(any())).thenAnswer((invocation) {
        final errorStream = Stream<List<int>>.value(
          utf8.encode(
            '{"code":"quota_exhausted","message":"Daily limit reached"}',
          ),
        );
        return Future.value(http.StreamedResponse(errorStream, 429));
      });

      AiChatFailure? failure;

      final handle = repository.startStream(
        kind: AiChatRequestKind.plan,
        messages: const <AiChatRequestMessage>[
          AiChatRequestMessage(
            role: AiChatMessageRole.user,
            content: 'Quota test',
          ),
        ],
        onChunk: (_) => fail('Should not chunk'),
        onComplete: (_) => fail('Should not complete'),
        onError: (error) => failure = error,
      );

      await handle.done;

      expect(failure, isNotNull);
      expect(failure!.code, equals('quota_exhausted'));
      expect(failure!.statusCode, equals(429));
    });

    test('handles stream ending unexpectedly without end event', () async {
      final repository = AiChatRepository(
        supabaseClient: supabaseClient,
        httpClient: httpClient,
        analyticsService: analytics,
        retryBackoff: _testRetryBackoff,
        endpoint: Uri.parse(
          'https://example.supabase.co/functions/v1/ai_proxy',
        ),
      );

      final controller = StreamController<List<int>>();

      when(() => httpClient.send(any())).thenAnswer((invocation) {
        Future.microtask(() async {
          controller.add(
            utf8.encode('event: chunk\ndata: {"delta":"Start"}\n\n'),
          );
          await controller.close(); // Close without sending 'end' event
        });
        return Future.value(http.StreamedResponse(controller.stream, 200));
      });

      final chunks = <String>[];
      AiChatFailure? failure;

      final handle = repository.startStream(
        kind: AiChatRequestKind.plan,
        messages: const <AiChatRequestMessage>[
          AiChatRequestMessage(role: AiChatMessageRole.user, content: 'Test'),
        ],
        onChunk: (chunk) => chunks.add(chunk.delta),
        onComplete: (_) => fail('Should not complete successfully'),
        onError: (error) => failure = error,
      );

      await handle.done;

      expect(chunks, equals(<String>['Start']));
      expect(failure, isNotNull);
      expect(failure!.code, equals('stream_incomplete'));
      expect(failure!.retryable, isTrue);
    });

    test('handles multiple chunks and accumulates text', () async {
      final repository = AiChatRepository(
        supabaseClient: supabaseClient,
        httpClient: httpClient,
        analyticsService: analytics,
        retryBackoff: _testRetryBackoff,
        endpoint: Uri.parse(
          'https://example.supabase.co/functions/v1/ai_proxy',
        ),
      );

      final controller = StreamController<List<int>>();

      when(() => httpClient.send(any())).thenAnswer((invocation) {
        Future.microtask(() async {
          controller.add(
            utf8.encode('event: chunk\ndata: {"delta":"Hello "}\n\n'),
          );
          controller.add(
            utf8.encode('event: chunk\ndata: {"delta":"world"}\n\n'),
          );
          controller.add(utf8.encode('event: chunk\ndata: {"delta":"!"}\n\n'));
          controller.add(
            utf8.encode('event: end\ndata: {"usage":{"in":3,"out":3}}\n\n'),
          );
          await controller.close();
        });
        return Future.value(http.StreamedResponse(controller.stream, 200));
      });

      final chunks = <String>[];
      AiChatStreamResult? completion;

      final handle = repository.startStream(
        kind: AiChatRequestKind.reflect,
        messages: const <AiChatRequestMessage>[
          AiChatRequestMessage(
            role: AiChatMessageRole.user,
            content: 'Multi-chunk',
          ),
        ],
        onChunk: (chunk) => chunks.add(chunk.delta),
        onComplete: (result) => completion = result,
        onError: (error) => fail('Should not error: ${error.code}'),
      );

      await handle.done;

      expect(chunks, equals(<String>['Hello ', 'world', '!']));
      expect(completion, isNotNull);
      expect(completion!.cancelled, isFalse);
      expect(completion!.usage?.inputTokens, equals(3));
      expect(completion!.usage?.outputTokens, equals(3));
    });
  });
}
