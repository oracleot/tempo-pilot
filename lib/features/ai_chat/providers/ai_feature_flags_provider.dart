import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo_pilot/core/config/supabase_config.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';
import 'package:tempo_pilot/providers/auth_provider.dart';

/// Feature gate that ensures only testers with the flag enabled can access AI chat.
final aiChatEnabledProvider = FutureProvider<bool>((ref) async {
  if (SupabaseConfig.authDisabled) {
    return true;
  }

  final session = ref.watch(sessionProvider);
  if (session == null) {
    return false;
  }

  final supabase = ref.watch(supabaseClientProvider);
  final AnalyticsService analytics = ref.watch(analyticsServiceProvider);

  try {
    final Map<String, dynamic>? profileResponse = await supabase
        .from('profiles')
        .select('metadata')
        .eq('id', session.user.id)
        .maybeSingle();

    final metadata = profileResponse?['metadata'];
    final isTester =
        metadata is Map<String, dynamic> && metadata['tester'] == true;
    if (!isTester) {
      return false;
    }

    final Map<String, dynamic>? flagResponse = await supabase
        .from('feature_flags')
        .select('value')
        .eq('key', 'ai_chat_enabled')
        .maybeSingle();

    final value = flagResponse?['value'];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    return false;
  } on PostgrestException catch (error, stackTrace) {
    analytics.logException(
      error,
      stackTrace,
      context: 'ai_chat_enabled_provider',
    );
    rethrow;
  } catch (error, stackTrace) {
    analytics.logException(
      error,
      stackTrace,
      context: 'ai_chat_enabled_provider',
    );
    rethrow;
  }
});

/// Feature flag provider for calendar suggestions.
final calendarSuggestionsEnabledFlagProvider = FutureProvider<bool>((ref) async {
  if (SupabaseConfig.authDisabled) {
    return true;
  }

  final session = ref.watch(sessionProvider);
  if (session == null) {
    return false;
  }

  final supabase = ref.watch(supabaseClientProvider);
  final AnalyticsService analytics = ref.watch(analyticsServiceProvider);

  try {
    final Map<String, dynamic>? flagResponse = await supabase
        .from('feature_flags')
        .select('value')
        .eq('key', 'calendar_suggestions_enabled')
        .maybeSingle();

    final value = flagResponse?['value'];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    return false;
  } on PostgrestException catch (error, stackTrace) {
    analytics.logException(
      error,
      stackTrace,
      context: 'calendar_suggestions_enabled_provider',
    );
    rethrow;
  } catch (error, stackTrace) {
    analytics.logException(
      error,
      stackTrace,
      context: 'calendar_suggestions_enabled_provider',
    );
    rethrow;
  }
});
