/// Supabase configuration for Tempo Pilot.
///
/// Environment variables for Supabase connection.
/// In production, these should be loaded from a secure source (e.g., --dart-define or env file).
/// For development, replace with actual values from your Supabase project dashboard.
class SupabaseConfig {
  /// Supabase project URL (e.g., https://xxxxxxxxxxxxx.supabase.co)
  ///
  /// Get this from: Supabase Dashboard > Project Settings > API > Project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  /// Supabase anonymous key (public key safe for client-side use)
  ///
  /// Get this from: Supabase Dashboard > Project Settings > API > Project API keys > anon public
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );

  /// Deep link redirect URL for magic link authentication
  ///
  /// This should match the custom scheme configured in Android manifest
  /// and will be wired in the deep link handling ticket.
  static const String authRedirectUrl = 'tempopilot://auth-callback';

  /// Validate configuration
  static bool get isConfigured {
    return supabaseUrl != 'https://your-project.supabase.co' &&
        supabaseAnonKey != 'your-anon-key-here';
  }

  /// Emergency flag to bypass authentication if Supabase is unavailable.
  ///
  /// Set via --dart-define=DISABLE_AUTH=true to disable authentication.
  /// Defaults to enabled (false). Tests can override this value at runtime.
  static bool authDisabled = const bool.fromEnvironment(
    'DISABLE_AUTH',
    defaultValue: false,
  );
}
