import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo_pilot/core/services/deep_link_service.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAppLinks extends Mock implements AppLinks {}

class MockAuthSessionUrlResponse extends Mock
    implements AuthSessionUrlResponse {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;
  late MockAppLinks mockAppLinks;
  late DeepLinkService deepLinkService;
  late StreamController<Uri> linkStreamController;

  setUpAll(() {
    // Register fallback value for Uri to work with mocktail
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockAppLinks = MockAppLinks();
    linkStreamController = StreamController<Uri>.broadcast();

    // Setup default mock behavior
    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);

    // Always return a stream for uriLinkStream (tests can add events to controller)
    when(
      () => mockAppLinks.uriLinkStream,
    ).thenAnswer((_) => linkStreamController.stream);

    // Create service with mocked AppLinks
    deepLinkService = DeepLinkService(mockSupabaseClient);
    // Replace the private _appLinks instance with our mock
    // Note: This requires making _appLinks injectable via constructor
    // For now, we'll test the public interface behavior
  });

  tearDown(() {
    linkStreamController.close();
    deepLinkService.dispose();
  });

  group('DeepLinkService', () {
    group('initialize', () {
      test('handles initial link on cold start', () async {
        // Arrange
        final initialUri = Uri.parse(
          'tempopilot://auth-callback?access_token=test_token',
        );
        when(
          () => mockAppLinks.getInitialLink(),
        ).thenAnswer((_) async => initialUri);
        when(
          () => mockAuth.getSessionFromUrl(initialUri),
        ).thenAnswer((_) async => MockAuthSessionUrlResponse());

        // Create a service instance with mocked AppLinks
        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
        );

        // Act
        await testService.initialize();

        // Assert
        verify(() => mockAppLinks.getInitialLink()).called(1);
        verify(() => mockAuth.getSessionFromUrl(initialUri)).called(1);
      });

      test('handles null initial link gracefully', () async {
        // Arrange
        when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
        );

        // Act
        await testService.initialize();

        // Assert
        verify(() => mockAppLinks.getInitialLink()).called(1);
        verifyNever(() => mockAuth.getSessionFromUrl(any()));
      });

      test('handles errors when getting initial link', () async {
        // Arrange
        when(
          () => mockAppLinks.getInitialLink(),
        ).thenThrow(Exception('Platform error'));

        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
        );

        // Act - should not throw
        await testService.initialize();

        // Assert
        verify(() => mockAppLinks.getInitialLink()).called(1);
        verifyNever(() => mockAuth.getSessionFromUrl(any()));
      });

      test('subscribes to runtime deep links', () async {
        // Arrange
        when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
        );

        // Act
        await testService.initialize();

        // Assert
        verify(() => mockAppLinks.uriLinkStream).called(1);
      });
    });

    group('handleDeepLink', () {
      test('processes auth callback with valid scheme and host', () async {
        // Arrange
        final authUri = Uri.parse(
          'tempopilot://auth-callback?access_token=valid_token&refresh_token=refresh',
        );
        when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);
        when(
          () => mockAuth.getSessionFromUrl(authUri),
        ).thenAnswer((_) async => MockAuthSessionUrlResponse());

        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
        );
        await testService.initialize();

        // Act
        linkStreamController.add(authUri);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockAuth.getSessionFromUrl(authUri)).called(1);
      });

      test('ignores deep links with unknown scheme', () async {
        // Arrange
        final unknownUri = Uri.parse('unknown://auth-callback');
        when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
        );
        await testService.initialize();

        // Act
        linkStreamController.add(unknownUri);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verifyNever(() => mockAuth.getSessionFromUrl(any()));
      });

      test('ignores deep links with unknown host', () async {
        // Arrange
        final unknownUri = Uri.parse('tempopilot://unknown-host');
        when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
        );
        await testService.initialize();

        // Act
        linkStreamController.add(unknownUri);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verifyNever(() => mockAuth.getSessionFromUrl(any()));
      });

      test('handles auth callback errors gracefully', () async {
        // Arrange
        final authUri = Uri.parse('tempopilot://auth-callback?invalid=token');
        when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);
        when(
          () => mockAuth.getSessionFromUrl(authUri),
        ).thenThrow(const AuthException('Invalid token'));

        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
        );
        await testService.initialize();

        // Act - should not throw
        linkStreamController.add(authUri);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockAuth.getSessionFromUrl(authUri)).called(1);
      });

      test('calls onAuthError callback when session exchange fails', () async {
        // Arrange
        final authUri = Uri.parse('tempopilot://auth-callback?invalid=token');
        when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);
        when(
          () => mockAuth.getSessionFromUrl(authUri),
        ).thenThrow(const AuthException('Invalid token'));

        String? capturedError;
        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
          onAuthError: (error) {
            capturedError = error;
          },
        );
        await testService.initialize();

        // Act
        linkStreamController.add(authUri);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(capturedError, equals('Invalid token'));
      });

      test(
        'calls onAuthError with generic message for non-AuthException errors',
        () async {
          // Arrange
          final authUri = Uri.parse('tempopilot://auth-callback?token=test');
          when(
            () => mockAppLinks.getInitialLink(),
          ).thenAnswer((_) async => null);
          when(
            () => mockAuth.getSessionFromUrl(authUri),
          ).thenThrow(Exception('Network error'));

          String? capturedError;
          final testService = DeepLinkService(
            mockSupabaseClient,
            appLinks: mockAppLinks,
            onAuthError: (error) {
              capturedError = error;
            },
          );
          await testService.initialize();

          // Act
          linkStreamController.add(authUri);
          await Future.delayed(const Duration(milliseconds: 100));

          // Assert
          expect(capturedError, equals('Failed to sign in. Please try again.'));
        },
      );

      test('does not crash when onAuthError callback is null', () async {
        // Arrange
        final authUri = Uri.parse('tempopilot://auth-callback?invalid=token');
        when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);
        when(
          () => mockAuth.getSessionFromUrl(authUri),
        ).thenThrow(const AuthException('Invalid token'));

        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
          // No onAuthError callback provided
        );
        await testService.initialize();

        // Act - should not throw
        linkStreamController.add(authUri);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockAuth.getSessionFromUrl(authUri)).called(1);
      });
    });

    group('dispose', () {
      test('cancels stream subscription', () async {
        // Arrange
        when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
        );
        await testService.initialize();

        // Act
        testService.dispose();

        // Add event after disposal - should not be processed
        final authUri = Uri.parse('tempopilot://auth-callback?token=test');
        linkStreamController.add(authUri);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - getSessionFromUrl should not be called after disposal
        verifyNever(() => mockAuth.getSessionFromUrl(any()));
      });

      test('can be called multiple times safely', () {
        // Arrange
        final testService = DeepLinkService(
          mockSupabaseClient,
          appLinks: mockAppLinks,
        );

        // Act & Assert - should not throw
        testService.dispose();
        testService.dispose();
      });
    });
  });
}
