import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling deep links and magic link auth callbacks.
///
/// Listens to deep links on both cold start (getInitialUri) and
/// runtime (uriLinkStream) and forwards auth callbacks to Supabase
/// for session completion.
///
/// Managed by Riverpod provider to ensure proper lifecycle management
/// and disposal of stream subscriptions.
class DeepLinkService {
  DeepLinkService(
    this._supabase, {
    AppLinks? appLinks,
    this.onReturnPathExtracted,
    this.onAuthError,
  }) : _appLinks = appLinks ?? AppLinks();

  final SupabaseClient _supabase;
  final AppLinks _appLinks;
  final void Function(String?)? onReturnPathExtracted;
  final void Function(String)? onAuthError;
  StreamSubscription<Uri>? _linkSubscription;

  /// Initialize deep link handling.
  ///
  /// Should be called early in app startup, before routing is finalized.
  /// Handles both initial deep link (cold start) and runtime deep links.
  Future<void> initialize() async {
    // Handle initial link (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('DeepLinkService: Error getting initial URI: $e');
    }

    // Listen to runtime links (app already running)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (Object err) {
        debugPrint('DeepLinkService: Error in URI link stream: $err');
      },
    );
  }

  /// Handle a deep link URI.
  ///
  /// Supabase Flutter SDK automatically intercepts magic link URLs
  /// containing auth tokens and completes the session. We just need
  /// to pass the URI to getSessionFromUrl.
  ///
  /// If the deep link contains a `from` query parameter, the intended
  /// route is stored for the router to use after authentication.
  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('DeepLinkService: Handling deep link: $uri');

    // Check if this is an auth callback
    if (uri.scheme == 'tempopilot' && uri.host == 'auth-callback') {
      try {
        // Extract return path before processing auth (if present)
        final returnPath = uri.queryParameters['from'];

        // Notify callback about return path if present
        if (returnPath != null && returnPath.isNotEmpty) {
          onReturnPathExtracted?.call(returnPath);
          debugPrint('DeepLinkService: Return path specified: $returnPath');
        }

        // Supabase will extract the session from the URI fragment/query params
        // This handles the magic link token exchange
        await _supabase.auth.getSessionFromUrl(uri);
        debugPrint('DeepLinkService: Session established successfully');

        // The auth state stream will automatically update via Supabase's
        // onAuthStateChange, which will trigger router redirects
      } catch (e) {
        debugPrint('DeepLinkService: Error handling auth callback: $e');
        // Surface error to UI via callback
        final errorMessage = e is AuthException
            ? e.message
            : 'Failed to sign in. Please try again.';
        onAuthError?.call(errorMessage);
        // TODO(task-5): Replace debug prints with proper logging via Crashlytics
      }
    } else {
      debugPrint(
        'DeepLinkService: Unknown deep link scheme/host: ${uri.scheme}://${uri.host}',
      );
    }
  }

  /// Dispose resources.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
