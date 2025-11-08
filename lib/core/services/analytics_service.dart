import 'package:flutter/foundation.dart';

/// Service for logging analytics events and exceptions.
///
/// Currently logs to console in debug mode. Will be enhanced with
/// Supabase-based logging in later iterations.
class AnalyticsService {
  /// Log an analytics event with optional properties.
  ///
  /// Events are logged to console in debug mode.
  /// PII should be redacted before calling this method.
  void logEvent(String eventName, [Map<String, dynamic>? properties]) {
    if (kDebugMode) {
      final propsStr = properties != null && properties.isNotEmpty
          ? ' | ${properties.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
          : '';
      debugPrint('📊 [Analytics] $eventName$propsStr');
    }
    // TODO: Send to Supabase analytics table when backend is ready
  }

  /// Log an exception with optional context.
  ///
  /// Exceptions are logged to console in debug mode.
  /// Will be sent to Supabase crash logging in production.
  void logException(
    dynamic exception,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? properties,
  }) {
    if (kDebugMode) {
      final contextStr = context != null ? ' [$context]' : '';
      final propsStr = properties != null && properties.isNotEmpty
          ? ' | ${properties.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'
          : '';
      debugPrint('💥 [Crash]$contextStr $exception$propsStr');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
    }
    // TODO: Send to Supabase crash logging when backend is ready
  }

  /// Log calendar permission prompt shown event.
  void logCalendarPermissionPromptShown() {
    logEvent('calendar_permission_prompt_shown');
  }

  /// Log calendar permission granted event.
  void logCalendarPermissionGranted() {
    logEvent('calendar_permission_granted');
  }

  /// Log calendar permission denied event.
  void logCalendarPermissionDenied({bool permanent = false}) {
    logEvent('calendar_permission_denied', {'permanent': permanent});
  }

  /// Log calendar discovery event.
  void logCalendarCalendarsDiscovered(int count) {
    logEvent('calendar_calendars_discovered', {'count': count});
  }

  /// Log when the calendar picker screen is opened.
  void logCalendarPickerOpened() {
    logEvent('calendar_picker_opened');
  }

  /// Log when a calendar's inclusion state changes from the picker UI.
  void logCalendarPickerToggleIncluded({
    required bool included,
    required bool isPrimary,
    required bool hasAccountName,
  }) {
    logEvent('calendar_picker_toggle_included', {
      'included': included,
      'is_primary': isPrimary,
      'has_account_name': hasAccountName,
    });
  }

  /// Log when the user searches within the calendar picker.
  /// Only non-PII signals are captured.
  void logCalendarPickerSearch({
    required int queryLength,
    required int resultsCount,
  }) {
    logEvent('calendar_picker_search', {
      'query_length': queryLength,
      'results_count': resultsCount,
    });
  }
}
