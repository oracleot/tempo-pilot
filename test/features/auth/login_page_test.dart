import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo_pilot/features/auth/login_page.dart';
import 'package:tempo_pilot/providers/auth_provider.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUpAll(() {
    // Register fallback value for String to work with mocktail named parameters
    registerFallbackValue('');
  });

  setUp(() {
    mockAuthService = MockAuthService();
    when(
      () => mockAuthService.signInWithMagicLink(
        any(),
        returnPath: any(named: 'returnPath'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockAuthService.signOut()).thenAnswer((_) async {});
  });

  Widget createLoginPage({AuthService? authService}) {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(authService ?? mockAuthService),
      ],
      child: const MaterialApp(home: LoginPage()),
    );
  }

  group('LoginPage', () {
    testWidgets('displays welcome message and email input', (tester) async {
      await tester.pumpWidget(createLoginPage());

      expect(find.text('Welcome to Tempo Pilot'), findsOneWidget);
      expect(
        find.text(
          'An AI-guided focus planner that respects your real schedule',
        ),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Send Magic Link'), findsOneWidget);
    });

    testWidgets('validates empty email', (tester) async {
      await tester.pumpWidget(createLoginPage());

      // Tap send button without entering email
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('validates invalid email format', (tester) async {
      await tester.pumpWidget(createLoginPage());

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('accepts valid email format', (tester) async {
      when(
        () => mockAuthService.signInWithMagicLink(
          any(),
          returnPath: any(named: 'returnPath'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createLoginPage(authService: mockAuthService));

      // Enter valid email
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      // Should not show validation error
      expect(find.text('Please enter a valid email'), findsNothing);
      expect(find.text('Please enter your email'), findsNothing);
    });

    testWidgets('shows loading indicator while sending magic link', (
      tester,
    ) async {
      // Create a completer to control when the async operation completes
      var shouldComplete = false;
      when(
        () => mockAuthService.signInWithMagicLink(
          any(),
          returnPath: any(named: 'returnPath'),
        ),
      ).thenAnswer((_) async {
        while (!shouldComplete) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });

      await tester.pumpWidget(createLoginPage(authService: mockAuthService));

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send Magic Link'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the operation
      shouldComplete = true;
      await tester.pumpAndSettle();
    });

    testWidgets('shows success screen after sending magic link', (
      tester,
    ) async {
      when(
        () => mockAuthService.signInWithMagicLink(
          any(),
          returnPath: any(named: 'returnPath'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createLoginPage(authService: mockAuthService));

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      // Should show success screen
      expect(find.text('Check Your Email'), findsOneWidget);
      expect(find.text('We\'ve sent a magic link to:'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);

      verify(
        () => mockAuthService.signInWithMagicLink(
          'test@example.com',
          returnPath: null,
        ),
      ).called(1);
    });

    testWidgets('displays error message on auth failure', (tester) async {
      when(
        () => mockAuthService.signInWithMagicLink(
          any(),
          returnPath: any(named: 'returnPath'),
        ),
      ).thenThrow(const AuthException('Invalid email'));

      await tester.pumpWidget(createLoginPage(authService: mockAuthService));

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Invalid email'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays generic error for unexpected failures', (
      tester,
    ) async {
      when(
        () => mockAuthService.signInWithMagicLink(
          any(),
          returnPath: any(named: 'returnPath'),
        ),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createLoginPage(authService: mockAuthService));

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      // Should show generic error message
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('back to login clears form and returns to input', (
      tester,
    ) async {
      when(
        () => mockAuthService.signInWithMagicLink(
          any(),
          returnPath: any(named: 'returnPath'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createLoginPage(authService: mockAuthService));

      // Send magic link
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      // Verify success screen
      expect(find.text('Check Your Email'), findsOneWidget);

      // Tap back to login
      await tester.tap(find.text('Back to Login'));
      await tester.pumpAndSettle();

      // Should be back on login screen with cleared form
      expect(find.text('Welcome to Tempo Pilot'), findsOneWidget);
      expect(find.text('Send Magic Link'), findsOneWidget);
      expect(find.text('Check Your Email'), findsNothing);

      // Email field should be empty
      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('trims whitespace from email before validation', (
      tester,
    ) async {
      when(
        () => mockAuthService.signInWithMagicLink(
          any(),
          returnPath: any(named: 'returnPath'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createLoginPage(authService: mockAuthService));

      // Enter email with leading/trailing spaces
      await tester.enterText(
        find.byType(TextFormField),
        '  test@example.com  ',
      );
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      // Should call with trimmed email
      verify(
        () => mockAuthService.signInWithMagicLink(
          'test@example.com',
          returnPath: null,
        ),
      ).called(1);
    });

    testWidgets('success screen shows next steps information', (tester) async {
      when(
        () => mockAuthService.signInWithMagicLink(
          any(),
          returnPath: any(named: 'returnPath'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createLoginPage(authService: mockAuthService));

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      // Verify next steps are shown
      expect(find.text('Next Steps'), findsOneWidget);
      expect(
        find.textContaining('Open the email from Tempo Pilot'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
