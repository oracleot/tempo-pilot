import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo_pilot/core/services/notification_service.dart';
import 'package:tempo_pilot/data/repositories/focus_session_repository.dart';
import 'package:tempo_pilot/features/timer/models/timer_state.dart';
import 'package:tempo_pilot/providers/focus_session_repository_provider.dart';
import 'package:tempo_pilot/providers/notification_provider.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});

/// Provider for the timer state and operations
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final repository = ref.watch(focusSessionRepositoryProvider);
  return TimerNotifier(prefs, notificationService, repository);
});

/// Manages the Pomodoro timer state with drift-safe wall-clock calculations.
///
/// This notifier:
/// - Persists state to SharedPreferences on each change
/// - Persists sessions to Drift via FocusSessionRepository
/// - Computes remaining time from wall clock (no free-running timers in background)
/// - Supports start, pause, resume, complete operations
/// - Reconciles state on app resume to handle backgrounding
/// - Schedules local notifications for phase transitions
class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier(
    SharedPreferences prefs,
    this._notificationService,
    this._repository,
  ) : _prefs = prefs,
      super(TimerState.idle()) {
    _selectedFocusDuration = _readInitialFocusDuration(_prefs);
    if (_selectedFocusDuration != const Duration(minutes: 25)) {
      state = TimerState.idle(focusDuration: _selectedFocusDuration);
    }
    _loadState();
  }

  static const _storageKey = 'tempo_pilot.timer_state';
  static const _focusDurationPrefKey = 'tempo_pilot.focus_duration_seconds';
  static const List<Duration> focusDurationOptions = <Duration>[
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 25),
  ];
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  final FocusSessionRepository _repository;
  late Duration _selectedFocusDuration;
  Timer? _ticker;

  static Duration _readInitialFocusDuration(SharedPreferences prefs) {
    final storedSeconds = prefs.getInt(_focusDurationPrefKey);
    if (storedSeconds != null && storedSeconds > 0) {
      final storedDuration = Duration(seconds: storedSeconds);
      if (focusDurationOptions.contains(storedDuration)) {
        return storedDuration;
      }
    }
    return const Duration(minutes: 25);
  }

  static Duration deriveBreakDuration(Duration focusDuration) {
    final rawSeconds = (focusDuration.inSeconds / 5).round();
    const minBreakSeconds = 30;
    final normalized = rawSeconds < minBreakSeconds
        ? minBreakSeconds
        : ((rawSeconds + 29) ~/ 30) * 30;
    return Duration(seconds: normalized);
  }

  Duration get selectedFocusDuration => _selectedFocusDuration;

  Duration get selectedBreakDuration =>
      deriveBreakDuration(_selectedFocusDuration);

  /// Starts a new focus session
  Future<void> start() async {
    final now = DateTime.now().toUtc();
    final focusDuration = _selectedFocusDuration;
    final endTime = now.add(focusDuration);

    // Create session in Drift (only if authenticated)
    String? sessionId;
    try {
      sessionId = await _repository.startSession(
        targetMinutes: focusDuration.inMinutes,
      );
    } catch (e) {
      // User not authenticated - timer still works, just no persistence
      sessionId = null;
    }

    state = TimerState(
      phase: TimerPhase.focus,
      status: TimerStatus.running,
      targetDuration: focusDuration,
      focusDurationSetting: focusDuration,
      startedAt: now,
      pausedAccumulated: Duration.zero,
      remaining: focusDuration,
      sessionId: sessionId,
    );

    await _persistState();
    _startTicker();

    // Schedule notification for focus end
    await _notificationService.scheduleFocusEndNotification(endTime);
  }

  /// Pauses the current timer
  Future<void> pause() async {
    if (state.status != TimerStatus.running) return;

    final now = DateTime.now().toUtc();
    final currentRemaining = state.computeRemaining(now);

    state = state.copyWith(
      status: TimerStatus.paused,
      remaining: currentRemaining,
    );

    await _persistState();
    _stopTicker();

    // Cancel scheduled notifications when pausing
    await _notificationService.cancelAll();
  }

  /// Resumes a paused timer
  Future<void> resume() async {
    if (state.status != TimerStatus.paused) return;

    final now = DateTime.now().toUtc();
    final pausedDuration = state.remaining ?? state.targetDuration;

    // Calculate new startedAt that preserves remaining time
    final newStartedAt = now.subtract(state.targetDuration - pausedDuration);
    final endTime = now.add(pausedDuration);

    state = state.copyWith(
      status: TimerStatus.running,
      startedAt: newStartedAt,
    );

    await _persistState();
    _startTicker();

    // Reschedule notification with updated end time
    if (state.phase == TimerPhase.focus) {
      await _notificationService.scheduleFocusEndNotification(endTime);
    } else {
      await _notificationService.scheduleBreakEndNotification(endTime);
    }
  }

  /// Completes the current phase
  Future<void> complete() async {
    final now = DateTime.now().toUtc();
    final currentPhase = state.phase;

    // Complete session in Drift if it exists
    if (state.sessionId != null) {
      try {
        await _repository.completeSession(
          sessionId: state.sessionId!,
          endedAt: now,
        );
      } catch (e) {
        // Failed to persist completion (e.g., not authenticated) - continue anyway
      }
    }

    // Set to completed state, user must manually start next phase
    state = state.copyWith(
      status: TimerStatus.completed,
      remaining: Duration.zero,
    );

    await _persistState();
    _stopTicker();

    // Cancel scheduled notifications
    await _notificationService.cancelAll();

    // Show immediate notification for foreground completion
    if (currentPhase == TimerPhase.focus) {
      await _notificationService.showFocusCompleteNotification();
    } else {
      await _notificationService.showBreakCompleteNotification();
    }
  }

  /// Starts a break session after focus completes
  Future<void> startBreak() async {
    final now = DateTime.now().toUtc();
    final breakDuration = deriveBreakDuration(_selectedFocusDuration);
    final endTime = now.add(breakDuration);

    // Note: Break sessions are not persisted to Drift (only focus sessions)
    // as per the task spec which focuses on focus_sessions table
    state = TimerState(
      phase: TimerPhase.break_,
      status: TimerStatus.running,
      targetDuration: breakDuration,
      focusDurationSetting: _selectedFocusDuration,
      startedAt: now,
      pausedAccumulated: Duration.zero,
      remaining: breakDuration,
      sessionId: null, // Break sessions don't get persisted
    );

    await _persistState();
    _startTicker();

    // Schedule notification for break end
    await _notificationService.scheduleBreakEndNotification(endTime);
  }

  /// Resets timer to idle state
  Future<void> reset() async {
    final now = DateTime.now().toUtc();

    // Cancel session in Drift if it was running
    if (state.sessionId != null && state.status == TimerStatus.running) {
      try {
        await _repository.cancelSession(
          sessionId: state.sessionId!,
          endedAt: now,
        );
      } catch (e) {
        // Failed to persist cancellation - continue anyway
      }
    }

    state = TimerState.idle(focusDuration: _selectedFocusDuration);
    await _persistState();
    _stopTicker();

    // Cancel all notifications when resetting
    await _notificationService.cancelAll();
  }

  /// Reconciles timer state after app resume or time jump
  ///
  /// This method should be called when the app returns from background
  /// or on app startup to handle any elapsed time correctly.
  Future<void> reconcile() async {
    if (state.status != TimerStatus.running) return;

    final now = DateTime.now().toUtc();
    final remaining = state.computeRemaining(now);

    if (remaining.inSeconds <= 0) {
      // Timer has expired while in background
      await complete();
    } else {
      // Update remaining time and reschedule notification
      state = state.copyWith(remaining: remaining);

      // Reschedule notification with corrected end time
      final endTime = now.add(remaining);
      if (state.phase == TimerPhase.focus) {
        await _notificationService.scheduleFocusEndNotification(endTime);
      } else {
        await _notificationService.scheduleBreakEndNotification(endTime);
      }
    }
  }

  /// Starts the foreground ticker for UI updates
  void _startTicker() {
    _stopTicker();
    // Use Timer for first tick to allow UI to render initial state,
    // then switch to periodic updates
    _ticker = Timer(const Duration(seconds: 1), () {
      _updateTimerState();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateTimerState();
      });
    });
  }

  /// Updates timer state by computing remaining time
  void _updateTimerState() {
    if (state.status == TimerStatus.running) {
      final now = DateTime.now().toUtc();
      final remaining = state.computeRemaining(now);

      if (remaining.inSeconds <= 0) {
        complete();
      } else {
        state = state.copyWith(remaining: remaining);
      }
    }
  }

  /// Stops the foreground ticker
  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Loads persisted state from SharedPreferences
  Future<void> _loadState() async {
    // First try loading from SharedPreferences (fast, in-memory state)
    final json = _prefs.getString(_storageKey);
    TimerState? loadedState;

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        loadedState = TimerState.fromJson(data);
      } catch (e) {
        // Invalid persisted state, will fall back to DB or idle
        loadedState = null;
      }
    }

    // If no state in SharedPreferences, check for running session in Drift
    // This handles app reinstall or SharedPreferences cleared scenarios
    if (loadedState == null || loadedState.status == TimerStatus.idle) {
      try {
        final runningSession = await _repository.getRunningSession();
        if (runningSession != null) {
          // Reconstruct timer state from database session
          final now = DateTime.now().toUtc();
          final targetDuration = Duration(
            minutes: runningSession.plannedDurationMinutes,
          );
          final elapsed = now.difference(runningSession.startedAt);
          final remaining = targetDuration - elapsed;

          if (remaining.inSeconds > 0) {
            // Session is still active, restore it
            loadedState = TimerState(
              phase: TimerPhase.focus,
              status: TimerStatus.running,
              targetDuration: targetDuration,
              focusDurationSetting: targetDuration,
              startedAt: runningSession.startedAt,
              pausedAccumulated: Duration.zero,
              remaining: remaining,
              sessionId: runningSession.id,
            );
          } else {
            // Session has expired, mark it as completed
            await _repository.completeSession(
              sessionId: runningSession.id,
              endedAt: now,
            );
            loadedState = TimerState.idle(
              focusDuration: _selectedFocusDuration,
            );
          }
        }
      } catch (e) {
        // Repository might fail if not authenticated, fall back to idle
        loadedState = TimerState.idle(focusDuration: _selectedFocusDuration);
      }
    }

    if (loadedState != null) {
      _selectedFocusDuration = loadedState.focusDurationSetting;
      await _prefs.setInt(
        _focusDurationPrefKey,
        _selectedFocusDuration.inSeconds,
      );

      state = loadedState;

      if (loadedState.status == TimerStatus.running) {
        await reconcile();
        _startTicker();
      }
    } else {
      state = TimerState.idle(focusDuration: _selectedFocusDuration);
    }
  }

  /// Persists current state to SharedPreferences
  Future<void> _persistState() async {
    if (state.status == TimerStatus.idle) {
      await _prefs.remove(_storageKey);
    } else {
      final json = jsonEncode(state.toJson());
      await _prefs.setString(_storageKey, json);
    }
    await _prefs.setInt(
      _focusDurationPrefKey,
      _selectedFocusDuration.inSeconds,
    );
  }

  Future<void> updateFocusDuration(Duration newFocusDuration) async {
    if (!focusDurationOptions.contains(newFocusDuration)) {
      return;
    }
    if (state.status != TimerStatus.idle) {
      return;
    }

    _selectedFocusDuration = newFocusDuration;
    state = TimerState.idle(focusDuration: newFocusDuration);
    await _persistState();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
