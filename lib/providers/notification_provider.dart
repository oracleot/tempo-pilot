import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/core/services/notification_service.dart';

/// Provider for the NotificationService singleton instance.
///
/// This provider creates and provides the notification service for dependency
/// injection throughout the app. The service must be initialized via
/// main.dart before use.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
    'notificationServiceProvider must be overridden in main.dart',
  );
});
