import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/core/services/analytics_service.dart';

/// Provider for the analytics service.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);
