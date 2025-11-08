import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo_pilot/providers/auth_provider.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthService authService;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    authService = AuthService(mockClient);

    // Setup default mock behavior
    when(() => mockClient.auth).thenReturn(mockAuth);
  });

  group('AuthService', () {
    group('signInWithMagicLink', () {
      test('calls signInWithOtp with correct email and redirect URL', () async {
        // Arrange
        const testEmail = 'test@example.com';
        const authRedirectUrl = 'tempopilot://auth-callback';
        when(
          () => mockAuth.signInWithOtp(
            email: testEmail,
            emailRedirectTo: authRedirectUrl,
          ),
        ).thenAnswer((_) async => MockAuthResponse());

        // Act
        await authService.signInWithMagicLink(testEmail);

        // Assert
        verify(
          () => mockAuth.signInWithOtp(
            email: testEmail,
            emailRedirectTo: authRedirectUrl,
          ),
        ).called(1);
      });

      test('throws AuthException when signInWithOtp fails', () async {
        // Arrange
        const testEmail = 'test@example.com';
        const authRedirectUrl = 'tempopilot://auth-callback';
        when(
          () => mockAuth.signInWithOtp(
            email: testEmail,
            emailRedirectTo: authRedirectUrl,
          ),
        ).thenThrow(const AuthException('Invalid email'));

        // Act & Assert
        expect(
          () => authService.signInWithMagicLink(testEmail),
          throwsA(isA<AuthException>()),
        );
      });

      test('uses configured authRedirectUrl', () async {
        // Arrange
        const testEmail = 'user@test.com';
        const authRedirectUrl = 'tempopilot://auth-callback';
        when(
          () => mockAuth.signInWithOtp(
            email: any(named: 'email'),
            emailRedirectTo: authRedirectUrl,
          ),
        ).thenAnswer((_) async => MockAuthResponse());

        // Act
        await authService.signInWithMagicLink(testEmail);

        // Assert - verify the configured URL is used
        verify(
          () => mockAuth.signInWithOtp(
            email: testEmail,
            emailRedirectTo: authRedirectUrl,
          ),
        ).called(1);
      });

      test(
        'includes encoded return path in redirect URL when provided',
        () async {
          // Arrange
          const testEmail = 'user@test.com';
          const returnPath = '/planner';
          const expectedRedirectUrl =
              'tempopilot://auth-callback?from=%2Fplanner';

          when(
            () => mockAuth.signInWithOtp(
              email: testEmail,
              emailRedirectTo: expectedRedirectUrl,
            ),
          ).thenAnswer((_) async => MockAuthResponse());

          // Act
          await authService.signInWithMagicLink(
            testEmail,
            returnPath: returnPath,
          );

          // Assert - verify URL includes encoded return path
          verify(
            () => mockAuth.signInWithOtp(
              email: testEmail,
              emailRedirectTo: expectedRedirectUrl,
            ),
          ).called(1);
        },
      );

      test('encodes special characters in return path correctly', () async {
        // Arrange
        const testEmail = 'user@test.com';
        const returnPath = '/planner?date=2024-01-01&view=week';
        const expectedRedirectUrl =
            'tempopilot://auth-callback?from=%2Fplanner%3Fdate%3D2024-01-01%26view%3Dweek';

        when(
          () => mockAuth.signInWithOtp(
            email: testEmail,
            emailRedirectTo: expectedRedirectUrl,
          ),
        ).thenAnswer((_) async => MockAuthResponse());

        // Act
        await authService.signInWithMagicLink(
          testEmail,
          returnPath: returnPath,
        );

        // Assert - verify special characters are properly encoded
        verify(
          () => mockAuth.signInWithOtp(
            email: testEmail,
            emailRedirectTo: expectedRedirectUrl,
          ),
        ).called(1);
      });

      test('uses base redirect URL when return path is null', () async {
        // Arrange
        const testEmail = 'user@test.com';
        const authRedirectUrl = 'tempopilot://auth-callback';

        when(
          () => mockAuth.signInWithOtp(
            email: testEmail,
            emailRedirectTo: authRedirectUrl,
          ),
        ).thenAnswer((_) async => MockAuthResponse());

        // Act
        await authService.signInWithMagicLink(testEmail, returnPath: null);

        // Assert - verify base URL is used without query params
        verify(
          () => mockAuth.signInWithOtp(
            email: testEmail,
            emailRedirectTo: authRedirectUrl,
          ),
        ).called(1);
      });

      test('uses base redirect URL when return path is empty string', () async {
        // Arrange
        const testEmail = 'user@test.com';
        const authRedirectUrl = 'tempopilot://auth-callback';

        when(
          () => mockAuth.signInWithOtp(
            email: testEmail,
            emailRedirectTo: authRedirectUrl,
          ),
        ).thenAnswer((_) async => MockAuthResponse());

        // Act
        await authService.signInWithMagicLink(testEmail, returnPath: '');

        // Assert - verify base URL is used when empty string provided
        verify(
          () => mockAuth.signInWithOtp(
            email: testEmail,
            emailRedirectTo: authRedirectUrl,
          ),
        ).called(1);
      });
    });

    group('signOut', () {
      test('calls auth.signOut', () async {
        // Arrange
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(() => mockAuth.signOut()).called(1);
      });

      test('propagates errors from auth.signOut', () async {
        // Arrange
        when(
          () => mockAuth.signOut(),
        ).thenThrow(const AuthException('Sign out failed'));

        // Act & Assert
        expect(() => authService.signOut(), throwsA(isA<AuthException>()));
      });
    });

    group('currentSession', () {
      test('returns current session from auth client', () {
        // Arrange
        final mockSession = MockSession();
        when(() => mockAuth.currentSession).thenReturn(mockSession);

        // Act
        final session = authService.currentSession;

        // Assert
        expect(session, equals(mockSession));
        verify(() => mockAuth.currentSession).called(1);
      });

      test('returns null when no session exists', () {
        // Arrange
        when(() => mockAuth.currentSession).thenReturn(null);

        // Act
        final session = authService.currentSession;

        // Assert
        expect(session, isNull);
      });
    });

    group('currentUser', () {
      test('returns current user from auth client', () {
        // Arrange
        final mockUser = MockUser();
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final user = authService.currentUser;

        // Assert
        expect(user, equals(mockUser));
        verify(() => mockAuth.currentUser).called(1);
      });

      test('returns null when no user is authenticated', () {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        // Act
        final user = authService.currentUser;

        // Assert
        expect(user, isNull);
      });
    });
  });
}
