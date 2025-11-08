import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tempo_pilot/core/config/supabase_config.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';
import 'package:tempo_pilot/providers/auth_provider.dart';
import 'package:timezone/timezone.dart' as tz;

/// Provider that exposes the current AI quota state for the user.
/// Reads from Supabase and caches locally.
final aiQuotaProvider = StateNotifierProvider<AiQuotaController, AiQuotaState>((
  ref,
) {
  final supabase = ref.watch(supabaseClientProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return AiQuotaController(
    supabaseClient: supabase,
    analyticsService: analytics,
    clock: _defaultClock,
  );
});

DateTime _defaultClock() => DateTime.now().toUtc();

/// Controller that manages AI quota state and handles refresh from Supabase.
class AiQuotaController extends StateNotifier<AiQuotaState> {
  AiQuotaController({
    required SupabaseClient supabaseClient,
    required AnalyticsService analyticsService,
    required DateTime Function() clock,
  }) : _supabaseClient = supabaseClient,
       _analyticsService = analyticsService,
       _clock = clock,
       super(AiQuotaState.initial());

  final SupabaseClient _supabaseClient;
  final AnalyticsService _analyticsService;
  final DateTime Function() _clock;

  static const int _quotaLimit = 10;

  /// Refreshes quota from the server by counting today's ai_messages in Europe/London timezone.
  Future<void> refresh() async {
    if (state.status == AiQuotaStatus.loading) {
      return;
    }

    state = state.copyWith(status: AiQuotaStatus.loading);

    try {
      if (SupabaseConfig.authDisabled) {
        // In test/demo mode, return mock quota
        state = AiQuotaState(
          remaining: 10,
          limit: _quotaLimit,
          status: AiQuotaStatus.success,
          lastUpdated: _clock(),
          error: null,
        );
        return;
      }

      final now = _clock();
      final londonLocation = tz.getLocation('Europe/London');
      final londonNow = tz.TZDateTime.from(now, londonLocation);

      // Get start of day in London time
      final londonDayStart = tz.TZDateTime(
        londonLocation,
        londonNow.year,
        londonNow.month,
        londonNow.day,
      );
      final londonDayEnd = londonDayStart.add(const Duration(days: 1));

      // Convert to UTC for Supabase query
      final dayStart = londonDayStart.toUtc();
      final dayEnd = londonDayEnd.toUtc();

      // Query ai_messages table for today's usage
      final response =
          await _supabaseClient
                  .from('ai_messages')
                  .select('id')
                  .gte('created_at', dayStart.toIso8601String())
                  .lt('created_at', dayEnd.toIso8601String())
              as List<dynamic>;

      final count = response.length;
      final remaining = (_quotaLimit - count).clamp(0, _quotaLimit);

      state = AiQuotaState(
        remaining: remaining,
        limit: _quotaLimit,
        status: AiQuotaStatus.success,
        lastUpdated: now,
        error: null,
      );

      _analyticsService.logEvent('ai_quota_checked', {
        'remaining': remaining,
        'limit': _quotaLimit,
      });
    } on PostgrestException catch (error, stackTrace) {
      _analyticsService.logException(
        error,
        stackTrace,
        context: 'ai_quota_provider',
      );
      state = state.copyWith(
        status: AiQuotaStatus.error,
        error: 'Failed to load quota: ${error.message}',
      );
    } catch (error, stackTrace) {
      _analyticsService.logException(
        error,
        stackTrace,
        context: 'ai_quota_provider',
      );
      state = state.copyWith(
        status: AiQuotaStatus.error,
        error: 'Failed to load quota: $error',
      );
    }
  }

  /// Optimistically decrements remaining quota after a successful AI request.
  /// Should be followed by a background refresh to reconcile with server.
  void decrementOptimistic() {
    if (state.remaining > 0) {
      state = state.copyWith(
        remaining: state.remaining - 1,
        lastUpdated: _clock(),
      );
    }
  }
}

/// Status of the quota provider.
enum AiQuotaStatus { initial, loading, success, error }

/// Immutable state exposed by the AI quota provider.
class AiQuotaState {
  const AiQuotaState({
    required this.remaining,
    required this.limit,
    required this.status,
    required this.lastUpdated,
    this.error,
  });

  final int remaining;
  final int limit;
  final AiQuotaStatus status;
  final DateTime lastUpdated;
  final String? error;

  bool get isLoading => status == AiQuotaStatus.loading;
  bool get hasError => status == AiQuotaStatus.error;
  bool get isExhausted => remaining == 0;

  AiQuotaState copyWith({
    int? remaining,
    int? limit,
    AiQuotaStatus? status,
    DateTime? lastUpdated,
    String? error,
  }) {
    return AiQuotaState(
      remaining: remaining ?? this.remaining,
      limit: limit ?? this.limit,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error ?? this.error,
    );
  }

  static AiQuotaState initial() {
    return AiQuotaState(
      remaining: 10,
      limit: 10,
      status: AiQuotaStatus.initial,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
      error: null,
    );
  }
}
