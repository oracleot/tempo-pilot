import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tempo_pilot/data/local/app_database.dart';
import 'package:tempo_pilot/data/repositories/focus_session_repository.dart';
import 'package:uuid/uuid.dart';

class MockFocusSessionDao extends Mock implements FocusSessionDao {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late MockFocusSessionDao mockDao;
  late MockUuid mockUuid;
  late FocusSessionRepository repository;
  const testUserId = 'test-user-id';
  const testSessionId = 'test-session-id';

  setUp(() {
    mockDao = MockFocusSessionDao();
    mockUuid = MockUuid();
    repository = FocusSessionRepository(
      dao: mockDao,
      userId: testUserId,
      uuidGenerator: mockUuid,
    );

    // Register fallback values for mocktail
    registerFallbackValue(const LocalFocusSessionsCompanion());
  });

  group('FocusSessionRepository', () {
    group('startSession', () {
      test('creates a new session with generated UUID', () async {
        // Arrange
        when(() => mockUuid.v4()).thenReturn(testSessionId);
        when(() => mockDao.insertSession(any())).thenAnswer((_) async {});

        // Act
        final sessionId = await repository.startSession(targetMinutes: 25);

        // Assert
        expect(sessionId, testSessionId);
        verify(() => mockUuid.v4()).called(1);

        final captured =
            verify(() => mockDao.insertSession(captureAny())).captured.single
                as LocalFocusSessionsCompanion;

        expect(captured.id.value, testSessionId);
        expect(captured.userId.value, testUserId);
        expect(captured.plannedDurationMinutes.value, 25);
        expect(captured.completed.value, false);
        expect(captured.sessionType.value, 'pomodoro');
        expect(captured.startedAt.present, true);
      });

      test('uses current UTC timestamp for startedAt', () async {
        // Arrange
        final beforeCall = DateTime.now().toUtc();
        when(() => mockUuid.v4()).thenReturn(testSessionId);
        when(() => mockDao.insertSession(any())).thenAnswer((_) async {});

        // Act
        await repository.startSession(targetMinutes: 25);
        final afterCall = DateTime.now().toUtc();

        // Assert
        final captured =
            verify(() => mockDao.insertSession(captureAny())).captured.single
                as LocalFocusSessionsCompanion;

        final startedAt = captured.startedAt.value;
        expect(
          startedAt.isAfter(beforeCall) ||
              startedAt.isAtSameMomentAs(beforeCall),
          true,
        );
        expect(
          startedAt.isBefore(afterCall) ||
              startedAt.isAtSameMomentAs(afterCall),
          true,
        );
      });
    });

    group('completeSession', () {
      test('marks session as completed with correct duration', () async {
        // Arrange
        final startedAt = DateTime.utc(2025, 1, 1, 10, 0, 0);
        final endedAt = DateTime.utc(2025, 1, 1, 10, 25, 30); // 25 min 30 sec
        final mockSession = LocalFocusSession(
          id: testSessionId,
          userId: testUserId,
          startedAt: startedAt,
          endedAt: null,
          plannedDurationMinutes: 25,
          actualDurationMinutes: null,
          sessionType: 'pomodoro',
          completed: false,
          metadata: null,
          createdAt: startedAt,
          updatedAt: startedAt,
          deletedAt: null,
          synced: false,
        );

        when(
          () => mockDao.getById(testSessionId),
        ).thenAnswer((_) async => mockSession);
        when(
          () => mockDao.completeSession(
            id: any(named: 'id'),
            endedAt: any(named: 'endedAt'),
            actualDurationMinutes: any(named: 'actualDurationMinutes'),
          ),
        ).thenAnswer((_) async => 1);

        // Act
        await repository.completeSession(
          sessionId: testSessionId,
          endedAt: endedAt,
        );

        // Assert
        verify(
          () => mockDao.completeSession(
            id: testSessionId,
            endedAt: endedAt.toUtc(),
            actualDurationMinutes: 26, // ceil(25.5 minutes) = 26
          ),
        ).called(1);
      });

      test('calculates actual minutes as ceiling of elapsed time', () async {
        // Arrange
        final startedAt = DateTime.utc(2025, 1, 1, 10, 0, 0);
        final endedAt = DateTime.utc(2025, 1, 1, 10, 0, 30); // 30 seconds
        final mockSession = LocalFocusSession(
          id: testSessionId,
          userId: testUserId,
          startedAt: startedAt,
          endedAt: null,
          plannedDurationMinutes: 25,
          actualDurationMinutes: null,
          sessionType: 'pomodoro',
          completed: false,
          metadata: null,
          createdAt: startedAt,
          updatedAt: startedAt,
          deletedAt: null,
          synced: false,
        );

        when(
          () => mockDao.getById(testSessionId),
        ).thenAnswer((_) async => mockSession);
        when(
          () => mockDao.completeSession(
            id: any(named: 'id'),
            endedAt: any(named: 'endedAt'),
            actualDurationMinutes: any(named: 'actualDurationMinutes'),
          ),
        ).thenAnswer((_) async => 1);

        // Act
        await repository.completeSession(
          sessionId: testSessionId,
          endedAt: endedAt,
        );

        // Assert
        verify(
          () => mockDao.completeSession(
            id: testSessionId,
            endedAt: endedAt.toUtc(),
            actualDurationMinutes: 1, // ceil(0.5 minutes) = 1
          ),
        ).called(1);
      });

      test('throws StateError if session not found', () async {
        // Arrange
        when(
          () => mockDao.getById(testSessionId),
        ).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.completeSession(
            sessionId: testSessionId,
            endedAt: DateTime.now().toUtc(),
          ),
          throwsStateError,
        );

        verifyNever(
          () => mockDao.completeSession(
            id: any(named: 'id'),
            endedAt: any(named: 'endedAt'),
            actualDurationMinutes: any(named: 'actualDurationMinutes'),
          ),
        );
      });
    });

    group('cancelSession', () {
      test(
        'sets endedAt and actualMinutes but keeps completed false',
        () async {
          // Arrange
          final startedAt = DateTime.utc(2025, 1, 1, 10, 0, 0);
          final endedAt = DateTime.utc(2025, 1, 1, 10, 10, 0); // 10 minutes
          final mockSession = LocalFocusSession(
            id: testSessionId,
            userId: testUserId,
            startedAt: startedAt,
            endedAt: null,
            plannedDurationMinutes: 25,
            actualDurationMinutes: null,
            sessionType: 'pomodoro',
            completed: false,
            metadata: null,
            createdAt: startedAt,
            updatedAt: startedAt,
            deletedAt: null,
            synced: false,
          );

          when(
            () => mockDao.getById(testSessionId),
          ).thenAnswer((_) async => mockSession);
          when(
            () => mockDao.updateSession(any(), any()),
          ).thenAnswer((_) async => 1);

          // Act
          await repository.cancelSession(
            sessionId: testSessionId,
            endedAt: endedAt,
          );

          // Assert
          final captured =
              verify(
                    () => mockDao.updateSession(testSessionId, captureAny()),
                  ).captured.single
                  as LocalFocusSessionsCompanion;

          expect(captured.endedAt.value, endedAt.toUtc());
          expect(captured.actualDurationMinutes.value, 10);
          expect(captured.completed.value, false);
        },
      );

      test('throws StateError if session not found', () async {
        // Arrange
        when(
          () => mockDao.getById(testSessionId),
        ).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.cancelSession(
            sessionId: testSessionId,
            endedAt: DateTime.now().toUtc(),
          ),
          throwsStateError,
        );

        verifyNever(() => mockDao.updateSession(any(), any()));
      });
    });

    group('updateActualMinutes', () {
      test('updates actual minutes for a session', () async {
        // Arrange
        when(
          () => mockDao.updateSession(any(), any()),
        ).thenAnswer((_) async => 1);

        // Act
        await repository.updateActualMinutes(
          sessionId: testSessionId,
          actualMinutes: 30,
        );

        // Assert
        final captured =
            verify(
                  () => mockDao.updateSession(testSessionId, captureAny()),
                ).captured.single
                as LocalFocusSessionsCompanion;

        expect(captured.actualDurationMinutes.value, 30);
      });
    });

    group('getRunningSession', () {
      test('returns running session from DAO', () async {
        // Arrange
        final mockSession = LocalFocusSession(
          id: testSessionId,
          userId: testUserId,
          startedAt: DateTime.now().toUtc(),
          endedAt: null,
          plannedDurationMinutes: 25,
          actualDurationMinutes: null,
          sessionType: 'pomodoro',
          completed: false,
          metadata: null,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          deletedAt: null,
          synced: false,
        );

        when(
          () => mockDao.getRunningSession(testUserId),
        ).thenAnswer((_) async => mockSession);

        // Act
        final result = await repository.getRunningSession();

        // Assert
        expect(result, mockSession);
        verify(() => mockDao.getRunningSession(testUserId)).called(1);
      });

      test('returns null if no running session', () async {
        // Arrange
        when(
          () => mockDao.getRunningSession(testUserId),
        ).thenAnswer((_) async => null);

        // Act
        final result = await repository.getRunningSession();

        // Assert
        expect(result, null);
        verify(() => mockDao.getRunningSession(testUserId)).called(1);
      });
    });

    group('getSessionById', () {
      test('returns session from DAO', () async {
        // Arrange
        final mockSession = LocalFocusSession(
          id: testSessionId,
          userId: testUserId,
          startedAt: DateTime.now().toUtc(),
          endedAt: null,
          plannedDurationMinutes: 25,
          actualDurationMinutes: null,
          sessionType: 'pomodoro',
          completed: false,
          metadata: null,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          deletedAt: null,
          synced: false,
        );

        when(
          () => mockDao.getById(testSessionId),
        ).thenAnswer((_) async => mockSession);

        // Act
        final result = await repository.getSessionById(testSessionId);

        // Assert
        expect(result, mockSession);
        verify(() => mockDao.getById(testSessionId)).called(1);
      });

      test('returns null if session not found', () async {
        // Arrange
        when(
          () => mockDao.getById(testSessionId),
        ).thenAnswer((_) async => null);

        // Act
        final result = await repository.getSessionById(testSessionId);

        // Assert
        expect(result, null);
        verify(() => mockDao.getById(testSessionId)).called(1);
      });
    });
  });
}
