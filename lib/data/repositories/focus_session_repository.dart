import 'package:drift/drift.dart';
import 'package:tempo_pilot/data/local/app_database.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing focus session persistence and business logic.
///
/// Provides a clean API for the timer feature to persist sessions to Drift,
/// abstracting away DAO details and handling business rules like duration calculations.
class FocusSessionRepository {
  FocusSessionRepository({
    required FocusSessionDao dao,
    required String userId,
    Uuid? uuidGenerator,
  }) : _dao = dao,
       _userId = userId,
       _uuid = uuidGenerator ?? const Uuid();

  final FocusSessionDao _dao;
  final String _userId;
  final Uuid _uuid;

  /// Starts a new focus session.
  ///
  /// Creates a session record with:
  /// - Generated UUID
  /// - Current user ID
  /// - UTC start timestamp
  /// - Target duration in minutes
  /// - completed = false (running state)
  ///
  /// Returns the generated session ID for tracking.
  Future<String> startSession({required int targetMinutes}) async {
    final sessionId = _uuid.v4();
    final now = DateTime.now().toUtc();

    final companion = LocalFocusSessionsCompanion(
      id: Value(sessionId),
      userId: Value(_userId),
      startedAt: Value(now),
      plannedDurationMinutes: Value(targetMinutes),
      completed: const Value(false),
      sessionType: const Value('pomodoro'),
    );

    await _dao.insertSession(companion);
    return sessionId;
  }

  /// Completes a focus session successfully.
  ///
  /// Updates the session with:
  /// - End timestamp (UTC)
  /// - Actual duration calculated from elapsed time (ceiling to nearest minute)
  /// - completed = true
  ///
  /// Calculates actual minutes as: ceil((endedAt - startedAt) / 60 seconds)
  /// This matches the task spec and ensures partial minutes count as full minutes.
  Future<void> completeSession({
    required String sessionId,
    required DateTime endedAt,
  }) async {
    // Get the session to calculate actual duration
    final session = await _dao.getById(sessionId);
    if (session == null) {
      throw StateError('Session $sessionId not found');
    }

    final elapsed = endedAt.difference(session.startedAt);
    final actualMinutes = (elapsed.inSeconds / 60).ceil();

    await _dao.completeSession(
      id: sessionId,
      endedAt: endedAt.toUtc(),
      actualDurationMinutes: actualMinutes,
    );
  }

  /// Cancels a focus session (user stopped early).
  ///
  /// Similar to complete but marks the session as not completed.
  /// Still records actual duration for analytics purposes.
  ///
  /// Uses soft delete pattern: sets endedAt and actualDurationMinutes
  /// but keeps completed=false to indicate cancellation.
  Future<void> cancelSession({
    required String sessionId,
    required DateTime endedAt,
  }) async {
    // Get the session to calculate actual duration
    final session = await _dao.getById(sessionId);
    if (session == null) {
      throw StateError('Session $sessionId not found');
    }

    final elapsed = endedAt.difference(session.startedAt);
    final actualMinutes = (elapsed.inSeconds / 60).ceil();

    // Update with endedAt and actualDuration but keep completed=false
    await _dao.updateSession(
      sessionId,
      LocalFocusSessionsCompanion(
        endedAt: Value(endedAt.toUtc()),
        actualDurationMinutes: Value(actualMinutes),
        completed: const Value(
          false,
        ), // Explicitly keep as false for cancellation
      ),
    );
  }

  /// Updates the actual minutes for a session.
  ///
  /// This can be used for manual adjustments or corrections.
  /// Typically called by completeSession or cancelSession, but exposed
  /// as a separate method for flexibility.
  Future<void> updateActualMinutes({
    required String sessionId,
    required int actualMinutes,
  }) async {
    await _dao.updateSession(
      sessionId,
      LocalFocusSessionsCompanion(actualDurationMinutes: Value(actualMinutes)),
    );
  }

  /// Gets the currently running session for this user, if any.
  ///
  /// Returns null if no running session exists.
  /// A running session is one where:
  /// - completed = false
  /// - deletedAt = null
  /// - Most recent by startedAt
  ///
  /// Used for reconciliation on app launch to restore timer state.
  Future<LocalFocusSession?> getRunningSession() async {
    return _dao.getRunningSession(_userId);
  }

  /// Gets a specific session by ID.
  ///
  /// Returns null if the session doesn't exist.
  Future<LocalFocusSession?> getSessionById(String sessionId) async {
    return _dao.getById(sessionId);
  }
}
