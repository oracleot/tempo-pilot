/// Timer phases for the Pomodoro technique.
enum TimerPhase {
  /// Focus period in a Pomodoro-style cycle
  focus,

  /// Break period following a focus session
  break_,
}

/// Timer operational status.
enum TimerStatus {
  /// Timer not started
  idle,

  /// Timer actively running
  running,

  /// Timer paused by user
  paused,

  /// Timer completed a full cycle
  completed,
}

/// Immutable state representing the current timer session.
///
/// This state uses wall-clock calculations to avoid drift from background
/// suspension. The `remaining` duration is always computed from `startedAt`
/// and `pausedAccumulated`, never from a free-running timer.
class TimerState {
  const TimerState({
    required this.phase,
    required this.status,
    required this.targetDuration,
    required this.focusDurationSetting,
    this.startedAt,
    this.pausedAccumulated = Duration.zero,
    this.remaining,
    this.sessionId,
  });

  /// Current phase (focus or break)
  final TimerPhase phase;

  /// Current operational status
  final TimerStatus status;

  /// Target duration for this phase
  final Duration targetDuration;

  /// Selected focus duration that drives preset selection
  final Duration focusDurationSetting;

  /// UTC timestamp when the timer started (or last resumed)
  final DateTime? startedAt;

  /// Total duration the timer has been paused
  final Duration pausedAccumulated;

  /// Remaining time (computed from wall clock, not free-running)
  final Duration? remaining;

  /// ID of the persisted focus session in Drift (null if not persisted yet)
  final String? sessionId;

  /// Creates an idle state with default focus duration
  factory TimerState.idle({
    Duration focusDuration = const Duration(minutes: 25),
  }) {
    return TimerState(
      phase: TimerPhase.focus,
      status: TimerStatus.idle,
      targetDuration: focusDuration,
      focusDurationSetting: focusDuration,
      remaining: focusDuration,
    );
  }

  /// Computes remaining time from current wall clock
  Duration computeRemaining(DateTime now) {
    if (startedAt == null) {
      return targetDuration;
    }

    final elapsed = now.difference(startedAt!);
    final effectiveElapsed = elapsed - pausedAccumulated;
    final computed = targetDuration - effectiveElapsed;

    // Cap negative remaining to zero
    return computed.isNegative ? Duration.zero : computed;
  }

  /// Creates a copy with updated fields
  TimerState copyWith({
    TimerPhase? phase,
    TimerStatus? status,
    Duration? targetDuration,
    Duration? focusDurationSetting,
    DateTime? startedAt,
    Duration? pausedAccumulated,
    Duration? remaining,
    String? sessionId,
  }) {
    return TimerState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      targetDuration: targetDuration ?? this.targetDuration,
      focusDurationSetting: focusDurationSetting ?? this.focusDurationSetting,
      startedAt: startedAt ?? this.startedAt,
      pausedAccumulated: pausedAccumulated ?? this.pausedAccumulated,
      remaining: remaining ?? this.remaining,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  /// Converts state to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'phase': phase.name,
      'status': status.name,
      'targetDurationMs': targetDuration.inMilliseconds,
      'focusDurationSettingMs': focusDurationSetting.inMilliseconds,
      'startedAtMs': startedAt?.millisecondsSinceEpoch,
      'pausedAccumulatedMs': pausedAccumulated.inMilliseconds,
      'remainingMs': remaining?.inMilliseconds,
      'sessionId': sessionId,
    };
  }

  /// Creates state from persisted JSON
  factory TimerState.fromJson(Map<String, dynamic> json) {
    final phase = TimerPhase.values.firstWhere(
      (p) => p.name == json['phase'],
      orElse: () => TimerPhase.focus,
    );
    final status = TimerStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => TimerStatus.idle,
    );
    final targetDuration = Duration(
      milliseconds: json['targetDurationMs'] as int,
    );
    final focusDurationSettingMs = json['focusDurationSettingMs'] as int?;
    final focusDurationSetting = focusDurationSettingMs != null
        ? Duration(milliseconds: focusDurationSettingMs)
        : phase == TimerPhase.focus
        ? targetDuration
        : const Duration(minutes: 25);

    return TimerState(
      phase: phase,
      status: status,
      targetDuration: targetDuration,
      focusDurationSetting: focusDurationSetting,
      startedAt: json['startedAtMs'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startedAtMs'] as int)
          : null,
      pausedAccumulated: Duration(
        milliseconds: json['pausedAccumulatedMs'] as int,
      ),
      remaining: json['remainingMs'] != null
          ? Duration(milliseconds: json['remainingMs'] as int)
          : null,
      sessionId: json['sessionId'] as String?,
    );
  }

  @override
  String toString() {
    return 'TimerState(phase: $phase, status: $status, remaining: $remaining)';
  }
}
