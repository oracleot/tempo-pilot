import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';

/// Provides the platform calendar permission service.
final calendarPermissionServiceProvider = Provider<CalendarPermissionService>(
  (ref) => CalendarPermissionService(),
);

/// Riverpod controller that exposes the current calendar permission state and
/// wraps mutation helpers for requesting permissions or opening system
/// settings.
class CalendarPermissionController
    extends AutoDisposeAsyncNotifier<CalendarPermissionStatus> {
  CalendarPermissionService get _service =>
      ref.read(calendarPermissionServiceProvider);

  @override
  FutureOr<CalendarPermissionStatus> build() {
    return _service.getStatus();
  }

  /// Refreshes the calendar permission status from the platform.
  Future<CalendarPermissionStatus> refresh() async {
    state = const AsyncValue.loading();
    return _runAndUpdate(
      _service.getStatus,
      fallback: CalendarPermissionStatus.unknown,
    );
  }

  /// Requests calendar permission from the platform and updates state.
  Future<CalendarPermissionStatus> requestPermission() {
    return _runAndUpdate(_service.requestPermission);
  }

  /// Opens the system settings page so the user can adjust permissions.
  Future<bool> openSettings() {
    return _service.openSettings();
  }

  Future<CalendarPermissionStatus> _runAndUpdate(
    Future<CalendarPermissionStatus> Function() action, {
    CalendarPermissionStatus fallback = CalendarPermissionStatus.denied,
  }) async {
    try {
      final result = await action();
      state = AsyncValue.data(result);
      return result;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[CalendarPermissionController] Error: $error');
      }
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      state = AsyncValue.data(fallback);
      return fallback;
    }
  }
}

/// Exposes the calendar permission controller as an AsyncNotifier provider.
final calendarPermissionStatusProvider =
    AutoDisposeAsyncNotifierProvider<
      CalendarPermissionController,
      CalendarPermissionStatus
    >(CalendarPermissionController.new);
