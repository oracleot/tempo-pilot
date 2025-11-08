import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo_pilot/core/config/supabase_config.dart';
import 'package:tempo_pilot/core/services/deep_link_service.dart';

/// Supabase client instance provider.
/// Provides access to the initialized Supabase client throughout the app.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Deep link service provider.
/// Handles magic link auth callbacks with proper lifecycle management.
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService(
    ref.watch(supabaseClientProvider),
    onReturnPathExtracted: (path) {
      // Store return path in state for router to use
      ref.read(returnPathProvider.notifier).state = path;
    },
    onAuthError: (error) {
      // Store error message in state for UI to display
      ref.read(authErrorProvider.notifier).state = error;
    },
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Return path state provider.
/// Stores the intended destination after successful authentication.
/// Used by deep link service to preserve navigation state through auth flow.
final returnPathProvider = StateProvider<String?>((ref) => null);

/// Auth error state provider.
/// Stores authentication error messages from deep link processing.
/// Used to surface auth callback failures to the UI via SnackBar.
final authErrorProvider = StateProvider<String?>((ref) => null);

/// Session stream provider that emits current session immediately.
/// This prevents the router redirect flicker on cold start when a session exists.
final sessionStreamProvider = StreamProvider<Session?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);

  // Emit current session synchronously first
  yield client.auth.currentSession;

  // Then listen to auth state changes
  await for (final authState in client.auth.onAuthStateChange) {
    yield authState.session;
  }
});

/// Current session provider.
/// Returns the current user session if authenticated, null otherwise.
/// Emits synchronously on first read to avoid router redirect flicker.
final sessionProvider = Provider<Session?>((ref) {
  final sessionStream = ref.watch(sessionStreamProvider);
  return sessionStream.when(
    data: (session) => session,
    loading: () {
      // Return current session synchronously while stream is loading
      final client = ref.read(supabaseClientProvider);
      return client.auth.currentSession;
    },
    error: (_, __) => null,
  );
});

/// Auth state provider for router integration.
/// Returns true if user is authenticated, false otherwise.
/// This is used by the router to redirect between login and authenticated routes.
final authStateProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  return session != null;
});

/// Auth service provider.
/// Provides methods for authentication operations.
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

/// Auth service class for authentication operations.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  /// Send a magic link to the user's email for passwordless sign-in.
  ///
  /// The user will receive an email with a link. When clicked, the link
  /// will redirect to the app via deep link handling.
  ///
  /// [returnPath] Optional path to redirect to after successful sign-in.
  /// If not provided, defaults to /timer.
  ///
  /// Throws [AuthException] if the request fails.
  Future<void> signInWithMagicLink(String email, {String? returnPath}) async {
    // Build redirect URL with optional return path
    var redirectUrl = SupabaseConfig.authRedirectUrl;
    if (returnPath != null && returnPath.isNotEmpty) {
      redirectUrl = '$redirectUrl?from=${Uri.encodeComponent(returnPath)}';
    }

    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectUrl,
    );

    // TODO(analytics): Fire magic_link_login event when analytics is implemented (task 6)
    // analyticsService.logEvent('magic_link_login', {'email_domain': email.split('@').last});
  }

  /// Sign out the current user.
  /// Clears the session and removes persisted auth data.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get the current user session.
  Session? get currentSession => _client.auth.currentSession;

  /// Get the current user.
  User? get currentUser => _client.auth.currentUser;
}
