import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Service for managing local notifications for timer phase transitions.
///
/// Handles initialization, scheduling, cancellation, and permission requests
/// for Android notifications. Uses exact timing with AndroidScheduleMode.exactAllowWhileIdle
/// to ensure notifications fire on time even when device is in Doze mode.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static bool _timezoneInitialized = false;

  /// Notification channel ID for Pomodoro alerts
  static const String _channelId = 'pomodoro_alerts';

  /// Notification channel name
  static const String _channelName = 'Pomodoro Alerts';

  /// Notification channel description
  static const String _channelDescription =
      'Notifications for focus and break phase transitions';

  /// Notification ID for focus phase end
  static const int _focusNotificationId = 1;

  /// Notification ID for break phase end
  static const int _breakNotificationId = 2;

  /// Callback for notification tap events
  void Function()? _onNotificationTap;

  /// Initializes the notification plugin and creates the Android channel.
  ///
  /// Must be called before scheduling notifications. Also initializes
  /// timezone database for zoned scheduling.
  Future<void> initialize({void Function()? onNotificationTap}) async {
    // Initialize timezone database if not already done
    if (!_timezoneInitialized) {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/London'));
      _timezoneInitialized = true;
    }

    _onNotificationTap = onNotificationTap;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create notification channel for Android 8.0+
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  /// Requests notification permission on Android 13+ (API 33+).
  ///
  /// Returns true if permission is granted or not required (pre-Android 13).
  /// Returns false if permission is denied.
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) {
      return true; // Not Android, assume granted
    }

    // Request notification permission for Android 13+
    final granted = await androidPlugin.requestNotificationsPermission();

    // Request exact alarm permission for Android 12+ (API 31+)
    // This is required for zonedSchedule with exactAllowWhileIdle
    final exactAlarmGranted = await androidPlugin
        .requestExactAlarmsPermission();

    if (kDebugMode) {
      debugPrint('📱 Notification permission: ${granted ?? true}');
      debugPrint('⏰ Exact alarm permission: ${exactAlarmGranted ?? true}');
    }

    return (granted ?? true) && (exactAlarmGranted ?? true);
  }

  /// Schedules a notification for focus phase end.
  ///
  /// [scheduledTime] should be the UTC DateTime when the focus phase ends.
  /// Notification will show "Focus complete! Time for a break."
  Future<void> scheduleFocusEndNotification(DateTime scheduledTime) async {
    // Check if we can schedule exact alarms
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();
      if (canScheduleExact == false) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ Cannot schedule exact notifications - permission not granted',
          );
        }
        return;
      }
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    if (kDebugMode) {
      debugPrint(
        '🔔 Scheduling focus end notification for: $tzScheduledTime (in ${scheduledTime.difference(DateTime.now().toUtc()).inSeconds}s)',
      );
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      _focusNotificationId,
      'Focus Complete! 🎯',
      'Great work! Time for a quick break.',
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'focus_complete',
    );

    if (kDebugMode) {
      debugPrint('✅ Focus notification scheduled successfully');
    }
  }

  /// Schedules a notification for break phase end.
  ///
  /// [scheduledTime] should be the UTC DateTime when the break phase ends.
  /// Notification will show "Break complete! Ready for another focus session?"
  Future<void> scheduleBreakEndNotification(DateTime scheduledTime) async {
    // Check if we can schedule exact alarms
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();
      if (canScheduleExact == false) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ Cannot schedule exact notifications - permission not granted',
          );
        }
        return;
      }
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    if (kDebugMode) {
      debugPrint(
        '🔔 Scheduling break end notification for: $tzScheduledTime (in ${scheduledTime.difference(DateTime.now().toUtc()).inSeconds}s)',
      );
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      _breakNotificationId,
      'Break Complete! ☕',
      'Feeling refreshed? Start another focus session.',
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'break_complete',
    );

    if (kDebugMode) {
      debugPrint('✅ Break notification scheduled successfully');
    }
  }

  /// Cancels any pending focus phase end notification.
  Future<void> cancelFocusNotification() async {
    await _plugin.cancel(_focusNotificationId);
  }

  /// Cancels the break phase end notification.
  Future<void> cancelBreakNotification() async {
    await _plugin.cancel(_breakNotificationId);
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Shows an immediate notification for focus completion (for foreground completion).
  Future<void> showFocusCompleteNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      _focusNotificationId,
      'Focus Complete! 🎯',
      'Great work! Time for a quick break.',
      notificationDetails,
      payload: 'focus_complete',
    );

    if (kDebugMode) {
      debugPrint('✅ Immediate focus notification shown');
    }
  }

  /// Shows an immediate notification for break phase end.
  Future<void> showBreakCompleteNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      _breakNotificationId,
      'Break Complete! ☕',
      'Feeling refreshed? Start another focus session.',
      notificationDetails,
      payload: 'break_complete',
    );

    if (kDebugMode) {
      debugPrint('✅ Immediate break notification shown');
    }
  }

  /// Handles notification tap events.
  void _handleNotificationTap(NotificationResponse response) {
    _onNotificationTap?.call();
  }

  /// Gets a list of pending notification requests (for debugging/testing).
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
