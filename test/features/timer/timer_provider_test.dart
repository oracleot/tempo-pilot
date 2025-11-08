import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo_pilot/core/services/notification_service.dart';
import 'package:tempo_pilot/data/repositories/focus_session_repository.dart';
import 'package:tempo_pilot/features/timer/models/timer_state.dart';
import 'package:tempo_pilot/features/timer/providers/timer_provider.dart';

// Mock classes
class MockNotificationService extends Mock implements NotificationService {}

class MockFocusSessionRepository extends Mock
    implements FocusSessionRepository {}

void main() {
  setUpAll(() {
    // Register fallback values for all DateTime parameters
    registerFallbackValue(DateTime.now());
  });

  group('TimerNotifier', () {
    late SharedPreferences prefs;
    late MockNotificationService mockNotificationService;
    late MockFocusSessionRepository mockRepository;
    late TimerNotifier notifier;

    setUp(() async {
      // Initialize test instance of SharedPreferences
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      // Create mock notification service
      mockNotificationService = MockNotificationService();
      when(
        () => mockNotificationService.scheduleFocusEndNotification(any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockNotificationService.scheduleBreakEndNotification(any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockNotificationService.showFocusCompleteNotification(),
      ).thenAnswer((_) async => {});
      when(
        () => mockNotificationService.showBreakCompleteNotification(),
      ).thenAnswer((_) async => {});
      when(
        () => mockNotificationService.cancelAll(),
      ).thenAnswer((_) async => {});
      when(
        () => mockNotificationService.cancelFocusNotification(),
      ).thenAnswer((_) async => {});
      when(
        () => mockNotificationService.cancelBreakNotification(),
      ).thenAnswer((_) async => {});

      // Create mock repository
      mockRepository = MockFocusSessionRepository();
      when(
        () => mockRepository.startSession(
          targetMinutes: any(named: 'targetMinutes'),
        ),
      ).thenAnswer((_) async => 'test-session-id');
      when(
        () => mockRepository.completeSession(
          sessionId: any(named: 'sessionId'),
          endedAt: any(named: 'endedAt'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockRepository.cancelSession(
          sessionId: any(named: 'sessionId'),
          endedAt: any(named: 'endedAt'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockRepository.getRunningSession(),
      ).thenAnswer((_) async => null);

      notifier = TimerNotifier(prefs, mockNotificationService, mockRepository);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('initial state is idle with default 25 minute focus', () {
      expect(notifier.state.status, TimerStatus.idle);
      expect(notifier.state.phase, TimerPhase.focus);
      expect(notifier.state.targetDuration, const Duration(minutes: 25));
      expect(notifier.state.remaining, const Duration(minutes: 25));
      expect(notifier.state.focusDurationSetting, const Duration(minutes: 25));
    });

    test('start creates running state with default 25 minute focus', () async {
      await notifier.start();

      expect(notifier.state.status, TimerStatus.running);
      expect(notifier.state.phase, TimerPhase.focus);
      expect(notifier.state.targetDuration, const Duration(minutes: 25));
      expect(notifier.state.focusDurationSetting, const Duration(minutes: 25));
      expect(notifier.state.startedAt, isNotNull);
      expect(notifier.state.pausedAccumulated, Duration.zero);
    });

    test('pause transitions from running to paused', () async {
      await notifier.start();
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.pause();

      expect(notifier.state.status, TimerStatus.paused);
      expect(notifier.state.remaining, isNotNull);
      expect(
        notifier.state.remaining!.inSeconds,
        lessThan(const Duration(minutes: 25).inSeconds),
      );
    });

    test('resume transitions from paused back to running', () async {
      await notifier.start();
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.pause();

      final remainingBeforeResume = notifier.state.remaining;
      await notifier.resume();

      expect(notifier.state.status, TimerStatus.running);
      expect(notifier.state.startedAt, isNotNull);
      // Remaining should be preserved (within 1 second tolerance)
      expect(
        (notifier.state.remaining!.inSeconds - remainingBeforeResume!.inSeconds)
            .abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('reset returns to idle state', () async {
      await notifier.start();
      await notifier.reset();

      expect(notifier.state.status, TimerStatus.idle);
      expect(notifier.state.phase, TimerPhase.focus);
      expect(notifier.state.remaining, const Duration(minutes: 25));
      expect(notifier.state.focusDurationSetting, const Duration(minutes: 25));
    });

    test('complete transitions to completed status', () async {
      await notifier.start();
      await notifier.complete();

      expect(notifier.state.status, TimerStatus.completed);
      expect(notifier.state.phase, TimerPhase.focus);
      expect(notifier.state.remaining, Duration.zero);
    });

    test('startBreak transitions focus to break', () async {
      await notifier.start();
      await notifier.complete();
      await notifier.startBreak();

      expect(notifier.state.status, TimerStatus.running);
      expect(notifier.state.phase, TimerPhase.break_);
      expect(notifier.state.targetDuration, const Duration(minutes: 5));
      expect(notifier.state.focusDurationSetting, const Duration(minutes: 25));
    });

    test('updateFocusDuration changes preset and persists selection', () async {
      await notifier.updateFocusDuration(const Duration(minutes: 2));

      expect(notifier.state.status, TimerStatus.idle);
      expect(notifier.state.targetDuration, const Duration(minutes: 2));
      expect(notifier.state.focusDurationSetting, const Duration(minutes: 2));
      expect(notifier.selectedBreakDuration, const Duration(seconds: 30));
      expect(
        prefs.getInt('tempo_pilot.focus_duration_seconds'),
        const Duration(minutes: 2).inSeconds,
      );
    });

    test('custom preset drives break duration', () async {
      await notifier.updateFocusDuration(const Duration(minutes: 2));
      await notifier.start();
      await notifier.complete();
      await notifier.startBreak();

      expect(notifier.state.phase, TimerPhase.break_);
      expect(notifier.state.targetDuration, const Duration(seconds: 30));
      expect(notifier.state.focusDurationSetting, const Duration(minutes: 2));
    });

    test('focus preset persists across restarts when idle', () async {
      await notifier.updateFocusDuration(const Duration(minutes: 10));

      notifier.dispose();
      notifier = TimerNotifier(prefs, mockNotificationService, mockRepository);

      expect(notifier.state.status, TimerStatus.idle);
      expect(notifier.state.targetDuration, const Duration(minutes: 10));
      expect(notifier.state.focusDurationSetting, const Duration(minutes: 10));
      expect(
        notifier.selectedBreakDuration,
        TimerNotifier.deriveBreakDuration(const Duration(minutes: 10)),
      );
    });

    test('complete on break sets to completed', () async {
      await notifier.start();
      await notifier.complete();
      await notifier.startBreak();
      await notifier.complete();

      expect(notifier.state.status, TimerStatus.completed);
      expect(notifier.state.phase, TimerPhase.break_);
    });

    test('computeRemaining calculates correctly', () {
      final startedAt = DateTime.now().toUtc();
      final state = TimerState(
        phase: TimerPhase.focus,
        status: TimerStatus.running,
        targetDuration: const Duration(minutes: 2),
        focusDurationSetting: const Duration(minutes: 2),
        startedAt: startedAt,
        pausedAccumulated: Duration.zero,
      );

      final now = startedAt.add(const Duration(seconds: 10));
      final remaining = state.computeRemaining(now);

      expect(remaining.inSeconds, 120 - 10);
    });

    test('computeRemaining caps negative to zero', () {
      final startedAt = DateTime.now().toUtc().subtract(
        const Duration(hours: 1),
      );
      final state = TimerState(
        phase: TimerPhase.focus,
        status: TimerStatus.running,
        targetDuration: const Duration(minutes: 2),
        focusDurationSetting: const Duration(minutes: 2),
        startedAt: startedAt,
        pausedAccumulated: Duration.zero,
      );

      final remaining = state.computeRemaining(DateTime.now().toUtc());

      expect(remaining, Duration.zero);
    });

    test('state persists to SharedPreferences', () async {
      await notifier.start();
      await Future.delayed(const Duration(milliseconds: 100));

      final stored = prefs.getString('tempo_pilot.timer_state');
      expect(stored, isNotNull);
      expect(stored, contains('"status":"running"'));
      expect(stored, contains('"phase":"focus"'));
    });

    test('state loads from SharedPreferences on initialization', () async {
      // Start and persist a timer
      await notifier.start();
      await Future.delayed(const Duration(milliseconds: 100));
      // Don't call dispose here - let tearDown handle it

      // Create new notifier instance (simulating app restart)
      final newNotifier = TimerNotifier(
        prefs,
        mockNotificationService,
        mockRepository,
      );
      await Future.delayed(const Duration(milliseconds: 100));

      // Should restore running state
      expect(newNotifier.state.status, TimerStatus.running);
      expect(newNotifier.state.phase, TimerPhase.focus);
      newNotifier.dispose();
    });

    test('paused state preserves remaining time after app restart', () async {
      await notifier.updateFocusDuration(const Duration(minutes: 2));
      // Start timer and let it run for 2 seconds
      await notifier.start();
      await Future.delayed(const Duration(seconds: 2));

      // Pause the timer
      await notifier.pause();
      final pausedRemaining = notifier.state.remaining!;

      // Should be around 1:58 remaining
      expect(pausedRemaining.inSeconds, greaterThanOrEqualTo(116));
      expect(pausedRemaining.inSeconds, lessThanOrEqualTo(118));

      // Simulate app restart by creating new notifier
      final newNotifier = TimerNotifier(
        prefs,
        mockNotificationService,
        mockRepository,
      );
      await Future.delayed(const Duration(milliseconds: 100));

      // Should restore paused state with correct remaining time
      expect(newNotifier.state.status, TimerStatus.paused);
      expect(newNotifier.state.phase, TimerPhase.focus);
      expect(newNotifier.state.remaining, isNotNull);
      expect(
        (newNotifier.state.remaining!.inSeconds - pausedRemaining.inSeconds)
            .abs(),
        lessThanOrEqualTo(1),
      );

      // Resume should preserve the remaining time
      await newNotifier.resume();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(newNotifier.state.status, TimerStatus.running);
      expect(
        (newNotifier.state.remaining!.inSeconds - pausedRemaining.inSeconds)
            .abs(),
        lessThanOrEqualTo(2),
      );

      newNotifier.dispose();
    });

    test('reconcile handles elapsed time in background', () async {
      await notifier.updateFocusDuration(const Duration(minutes: 2));
      await notifier.start();

      // Simulate time passing (2 seconds)
      await Future.delayed(const Duration(seconds: 2));
      await notifier.reconcile();

      final remaining = notifier.state.remaining;
      expect(remaining, isNotNull);
      expect(
        remaining!.inSeconds,
        lessThan(const Duration(minutes: 2).inSeconds),
      );
      expect(
        remaining.inSeconds,
        greaterThanOrEqualTo(const Duration(minutes: 1, seconds: 56).inSeconds),
      );
    });

    test('drift is minimal over short periods', () async {
      await notifier.updateFocusDuration(const Duration(minutes: 2));
      await notifier.start();
      final startTime = DateTime.now();

      // Wait 5 seconds
      await Future.delayed(const Duration(seconds: 5));

      final elapsed = DateTime.now().difference(startTime);
      final remaining = notifier.state.remaining;
      final expectedRemaining =
          const Duration(minutes: 2) - Duration(seconds: elapsed.inSeconds);

      expect(remaining, isNotNull);
      // Allow 1 second drift tolerance
      expect(
        (remaining!.inSeconds - expectedRemaining.inSeconds).abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('start schedules focus end notification', () async {
      await notifier.start();

      // Verify notification was scheduled
      verify(
        () => mockNotificationService.scheduleFocusEndNotification(any()),
      ).called(1);
    });

    test('startBreak schedules break end notification', () async {
      await notifier.start();
      await notifier.complete();
      await notifier.startBreak();

      // Verify break notification was scheduled
      verify(
        () => mockNotificationService.scheduleBreakEndNotification(any()),
      ).called(1);
    });

    test('pause cancels all notifications', () async {
      await notifier.start();
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.pause();

      // Verify all notifications were cancelled
      verify(() => mockNotificationService.cancelAll()).called(1);
    });

    test('reset cancels all notifications', () async {
      await notifier.start();
      await notifier.reset();

      // Verify all notifications were cancelled
      verify(() => mockNotificationService.cancelAll()).called(1);
    });

    test('complete cancels all notifications', () async {
      await notifier.start();
      await notifier.complete();

      // Verify all notifications were cancelled
      verify(() => mockNotificationService.cancelAll()).called(1);
    });

    test('resume reschedules focus notification', () async {
      await notifier.start();
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.pause();

      // Clear previous invocations
      clearInteractions(mockNotificationService);

      await notifier.resume();

      // Verify focus notification was rescheduled
      verify(
        () => mockNotificationService.scheduleFocusEndNotification(any()),
      ).called(1);
    });

    test('resume reschedules break notification', () async {
      await notifier.start();
      await notifier.complete();
      await notifier.startBreak();
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.pause();

      // Clear previous invocations
      clearInteractions(mockNotificationService);

      await notifier.resume();

      // Verify break notification was rescheduled
      verify(
        () => mockNotificationService.scheduleBreakEndNotification(any()),
      ).called(1);
    });

    test('reconcile reschedules notification if still running', () async {
      await notifier.start();

      // Clear previous invocations
      clearInteractions(mockNotificationService);

      await Future.delayed(const Duration(seconds: 1));
      await notifier.reconcile();

      // Should reschedule with corrected end time
      verify(
        () => mockNotificationService.scheduleFocusEndNotification(any()),
      ).called(1);
    });
  });

  group('TimerState', () {
    test('toJson and fromJson round-trip correctly', () {
      final original = TimerState(
        phase: TimerPhase.focus,
        status: TimerStatus.running,
        targetDuration: const Duration(minutes: 2),
        focusDurationSetting: const Duration(minutes: 2),
        startedAt: DateTime.now().toUtc(),
        pausedAccumulated: const Duration(seconds: 30),
      );

      final json = original.toJson();
      final restored = TimerState.fromJson(json);

      expect(restored.phase, original.phase);
      expect(restored.status, original.status);
      expect(restored.targetDuration, original.targetDuration);
      // Compare milliseconds since epoch (JSON loses microsecond precision)
      expect(
        restored.startedAt?.millisecondsSinceEpoch,
        original.startedAt?.millisecondsSinceEpoch,
      );
      expect(restored.pausedAccumulated, original.pausedAccumulated);
      expect(restored.focusDurationSetting, original.focusDurationSetting);
    });

    test('copyWith updates specified fields only', () {
      final original = TimerState.idle();
      final updated = original.copyWith(
        status: TimerStatus.running,
        startedAt: DateTime.now().toUtc(),
      );

      expect(updated.status, TimerStatus.running);
      expect(updated.startedAt, isNotNull);
      expect(updated.phase, original.phase); // Unchanged
      expect(updated.targetDuration, original.targetDuration); // Unchanged
    });
  });
}
