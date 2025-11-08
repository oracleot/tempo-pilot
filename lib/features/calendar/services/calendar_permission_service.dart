import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

/// Status of calendar permission.
enum CalendarPermissionStatus {
  /// Permission status has not been checked yet.
  unknown,

  /// Permission has been granted.
  granted,

  /// Permission has been denied but can be requested again.
  denied,

  /// Permission has been permanently denied (user must open settings).
  permanentlyDenied,
}

/// Service for managing calendar permission requests.
class CalendarPermissionService {
  /// Get the current calendar permission status.
  Future<CalendarPermissionStatus> getStatus() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      final status = await _bestAvailableStatus(request: false);
      return _mapStatus(status);
    } on MissingPluginException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[CalendarPermissionService] Plugin missing when checking status: $e',
        );
      }
      return CalendarPermissionStatus.unknown;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarPermissionService] Error checking permission: $e');
      }
      return CalendarPermissionStatus.unknown;
    }
  }

  /// Request calendar permission.
  /// Returns the new permission status.
  Future<CalendarPermissionStatus> requestPermission() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final status = await _bestAvailableStatus(request: true);
      return _mapStatus(status);
    } on MissingPluginException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[CalendarPermissionService] Plugin missing when requesting permission: $e',
        );
      }
      return CalendarPermissionStatus.denied;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[CalendarPermissionService] Error requesting permission: $e',
        );
      }
      return CalendarPermissionStatus.denied;
    }
  }

  /// Open system settings for the app.
  Future<bool> openSettings() async {
    WidgetsFlutterBinding.ensureInitialized();
    return await openAppSettings();
  }

  Future<PermissionStatus> _bestAvailableStatus({required bool request}) async {
    final candidates = _candidatePermissions();
    PermissionStatus? firstResult;

    for (final permission in candidates) {
      final status = await _safePermissionStatus(permission, request: request);

      firstResult ??= status;

      if (status != null && !_needsFallback(status)) {
        return status;
      }
    }

    return firstResult ?? PermissionStatus.denied;
  }

  List<Permission> _candidatePermissions() {
    if (kIsWeb) {
      return const [];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return const [Permission.calendarFullAccess];
      default:
        return const [
          Permission.calendarFullAccess,
          Permission.calendarWriteOnly,
        ];
    }
  }

  Future<PermissionStatus?> _safePermissionStatus(
    Permission permission, {
    required bool request,
  }) async {
    try {
      return request ? await permission.request() : await permission.status;
    } on MissingPluginException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[CalendarPermissionService] Missing plugin for ${permission.value}: $e',
        );
      }
      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[CalendarPermissionService] Platform error for ${permission.value}: $e',
        );
      }
      return null;
    }
  }

  CalendarPermissionStatus _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return CalendarPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CalendarPermissionStatus.permanentlyDenied;
    }
    if (status.isDenied) {
      return CalendarPermissionStatus.denied;
    }
    return CalendarPermissionStatus.unknown;
  }

  bool _needsFallback(PermissionStatus status) {
    if (status.isDenied) {
      return true;
    }
    return false;
  }
}
