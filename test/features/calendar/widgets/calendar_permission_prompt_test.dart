import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/features/calendar/providers/calendar_providers.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';
import 'package:tempo_pilot/features/calendar/widgets/calendar_permission_prompt.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

class TestCalendarPermissionController extends CalendarPermissionController {
  TestCalendarPermissionController({
    required this.initialStatus,
    List<CalendarPermissionStatus> requestSequence = const [],
    bool openSettingsResult = true,
    this.loadDelay = Duration.zero,
  }) : _requestResults = Queue.of(requestSequence),
       _openSettingsResult = openSettingsResult;

  final CalendarPermissionStatus initialStatus;
  final Queue<CalendarPermissionStatus> _requestResults;
  final bool _openSettingsResult;
  final Duration loadDelay;

  int requestCallCount = 0;
  int openSettingsCallCount = 0;

  @override
  FutureOr<CalendarPermissionStatus> build() {
    if (loadDelay == Duration.zero) {
      return initialStatus;
    }
    return Future<CalendarPermissionStatus>.delayed(
      loadDelay,
      () => initialStatus,
    );
  }

  @override
  Future<CalendarPermissionStatus> requestPermission() async {
    requestCallCount++;
    final result = _requestResults.isNotEmpty
        ? _requestResults.removeFirst()
        : initialStatus;
    state = AsyncValue.data(result);
    return result;
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCallCount++;
    return _openSettingsResult;
  }
}

void main() {
  group('CalendarPermissionPrompt Widget', () {
    late MockAnalyticsService mockAnalyticsService;

    setUp(() {
      mockAnalyticsService = MockAnalyticsService();

      when(
        () => mockAnalyticsService.logCalendarPermissionPromptShown(),
      ).thenReturn(null);
      when(
        () => mockAnalyticsService.logCalendarPermissionGranted(),
      ).thenReturn(null);
      when(
        () => mockAnalyticsService.logCalendarPermissionDenied(
          permanent: any(named: 'permanent'),
        ),
      ).thenReturn(null);
    });

    ({Widget widget, TestCalendarPermissionController controller})
    createScenario({
      required CalendarPermissionStatus status,
      List<CalendarPermissionStatus> requestSequence = const [],
      bool openSettingsResult = true,
      Duration loadDelay = Duration.zero,
      VoidCallback? onPermissionGranted,
      VoidCallback? onPermissionDenied,
    }) {
      final controller = TestCalendarPermissionController(
        initialStatus: status,
        requestSequence: requestSequence,
        openSettingsResult: openSettingsResult,
        loadDelay: loadDelay,
      );

      final widget = ProviderScope(
        overrides: [
          calendarPermissionStatusProvider.overrideWith(() => controller),
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CalendarPermissionPrompt(
              onPermissionGranted: onPermissionGranted,
              onPermissionDenied: onPermissionDenied,
            ),
          ),
        ),
      );

      return (widget: widget, controller: controller);
    }

    testWidgets('shows rationale view when permission is unknown', (
      tester,
    ) async {
      final scenario = createScenario(status: CalendarPermissionStatus.unknown);

      await tester.pumpWidget(scenario.widget);
      await tester.pumpAndSettle();

      expect(find.text('Connect Your Calendar'), findsOneWidget);
      expect(
        find.text(
          'Tempo Pilot reads your calendar to find free time for focus sessions.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Your calendar details stay on your device and are never uploaded.',
        ),
        findsOneWidget,
      );
      expect(find.text('Allow Calendar Access'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);

      await tester.pump();
      verify(
        () => mockAnalyticsService.logCalendarPermissionPromptShown(),
      ).called(1);
    });

    testWidgets('shows rationale view when permission is denied', (
      tester,
    ) async {
      final scenario = createScenario(status: CalendarPermissionStatus.denied);

      await tester.pumpWidget(scenario.widget);
      await tester.pumpAndSettle();

      expect(find.text('Connect Your Calendar'), findsOneWidget);
      expect(find.text('Allow Calendar Access'), findsOneWidget);
    });

    testWidgets('shows granted view when permission is already granted', (
      tester,
    ) async {
      final scenario = createScenario(status: CalendarPermissionStatus.granted);

      await tester.pumpWidget(scenario.widget);
      await tester.pumpAndSettle();

      expect(find.text('Calendar Connected'), findsOneWidget);
      expect(
        find.text(
          'Your calendars are connected. You can now see free time slots.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows denied view when permission is permanently denied', (
      tester,
    ) async {
      final scenario = createScenario(
        status: CalendarPermissionStatus.permanentlyDenied,
      );

      await tester.pumpWidget(scenario.widget);
      await tester.pumpAndSettle();

      expect(find.text('Calendar Access Needed'), findsOneWidget);
      expect(
        find.text(
          'You\'ve denied calendar permission. Please enable it in Settings to use this feature.',
        ),
        findsOneWidget,
      );
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('requests permission when Allow button is tapped', (
      tester,
    ) async {
      bool grantedCallbackCalled = false;

      final scenario = createScenario(
        status: CalendarPermissionStatus.unknown,
        requestSequence: const [CalendarPermissionStatus.granted],
        onPermissionGranted: () {
          grantedCallbackCalled = true;
        },
      );

      await tester.pumpWidget(scenario.widget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Allow Calendar Access'));
      await tester.pumpAndSettle();

      expect(scenario.controller.requestCallCount, 1);
      verify(
        () => mockAnalyticsService.logCalendarPermissionGranted(),
      ).called(1);
      expect(grantedCallbackCalled, isTrue);
    });

    testWidgets('handles permission denial when Allow button is tapped', (
      tester,
    ) async {
      bool deniedCallbackCalled = false;

      final scenario = createScenario(
        status: CalendarPermissionStatus.unknown,
        requestSequence: const [CalendarPermissionStatus.denied],
        onPermissionDenied: () {
          deniedCallbackCalled = true;
        },
      );

      await tester.pumpWidget(scenario.widget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Allow Calendar Access'));
      await tester.pumpAndSettle();

      expect(scenario.controller.requestCallCount, 1);
      verify(
        () =>
            mockAnalyticsService.logCalendarPermissionDenied(permanent: false),
      ).called(1);
      expect(deniedCallbackCalled, isTrue);
    });

    testWidgets('handles permanent denial correctly', (tester) async {
      bool deniedCallbackCalled = false;

      final scenario = createScenario(
        status: CalendarPermissionStatus.unknown,
        requestSequence: const [CalendarPermissionStatus.permanentlyDenied],
        onPermissionDenied: () {
          deniedCallbackCalled = true;
        },
      );

      await tester.pumpWidget(scenario.widget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Allow Calendar Access'));
      await tester.pumpAndSettle();

      expect(scenario.controller.requestCallCount, 1);
      verify(
        () => mockAnalyticsService.logCalendarPermissionDenied(permanent: true),
      ).called(1);
      expect(deniedCallbackCalled, isTrue);
    });

    testWidgets('opens settings when Open Settings button is tapped', (
      tester,
    ) async {
      final scenario = createScenario(
        status: CalendarPermissionStatus.permanentlyDenied,
        openSettingsResult: true,
      );

      await tester.pumpWidget(scenario.widget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(scenario.controller.openSettingsCallCount, 1);
    });

    testWidgets('calls onCancel when Not Now button is tapped', (tester) async {
      bool cancelCallbackCalled = false;

      final scenario = createScenario(
        status: CalendarPermissionStatus.unknown,
        onPermissionDenied: () {
          cancelCallbackCalled = true;
        },
      );

      await tester.pumpWidget(scenario.widget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not Now'));
      await tester.pumpAndSettle();

      expect(cancelCallbackCalled, isTrue);
    });

    testWidgets('shows loading indicator while fetching permission status', (
      tester,
    ) async {
      final scenario = createScenario(
        status: CalendarPermissionStatus.unknown,
        loadDelay: const Duration(seconds: 1),
      );

      await tester.pumpWidget(scenario.widget);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
