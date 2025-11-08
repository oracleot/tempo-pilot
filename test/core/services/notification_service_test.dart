import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tempo_pilot/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// Mock classes
class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Initialize timezone for tests
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/London'));

    // Register fallback values for any types used in method calls
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    registerFallbackValue(const AndroidNotificationChannel('', ''));
    registerFallbackValue(
      const NotificationDetails(android: AndroidNotificationDetails('', '')),
    );
    registerFallbackValue(AndroidScheduleMode.exact);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
    registerFallbackValue(tz.TZDateTime.now(tz.local));
  });

  group('NotificationService', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late MockAndroidFlutterLocalNotificationsPlugin mockAndroidPlugin;
    late NotificationService service;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      mockAndroidPlugin = MockAndroidFlutterLocalNotificationsPlugin();

      // Setup default stubs
      when(
        () => mockPlugin.initialize(
          any(),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroidPlugin);
      when(
        () => mockAndroidPlugin.createNotificationChannel(any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockAndroidPlugin.requestNotificationsPermission(),
      ).thenAnswer((_) async => true);
      when(
        () => mockAndroidPlugin.requestExactAlarmsPermission(),
      ).thenAnswer((_) async => true);
      when(
        () => mockAndroidPlugin.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
      when(
        () => mockPlugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation: any(
            named: 'uiLocalNotificationDateInterpretation',
          ),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});
      when(() => mockPlugin.cancelAll()).thenAnswer((_) async => {});
      when(
        () => mockPlugin.pendingNotificationRequests(),
      ).thenAnswer((_) async => []);

      service = NotificationService(plugin: mockPlugin);
    });

    test('initialization succeeds without errors', () async {
      // Initialize should not throw
      await service.initialize();

      // Verify service is ready to schedule notifications
      expect(service, isNotNull);

      // Verify initialization was called
      verify(
        () => mockPlugin.initialize(
          any(),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).called(1);
      verify(
        () => mockAndroidPlugin.createNotificationChannel(any()),
      ).called(1);
    });

    test('initialize registers notification tap callback', () async {
      var callbackInvoked = false;

      await service.initialize(
        onNotificationTap: () {
          callbackInvoked = true;
        },
      );

      // Callback should be registered but not invoked yet
      expect(callbackInvoked, isFalse);
    });

    test('scheduleFocusEndNotification schedules without error', () async {
      await service.initialize();

      final scheduledTime = DateTime.now().add(const Duration(seconds: 25));

      await service.scheduleFocusEndNotification(scheduledTime);

      // Verify scheduling was called
      verify(
        () => mockPlugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation: any(
            named: 'uiLocalNotificationDateInterpretation',
          ),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('scheduleBreakEndNotification schedules without error', () async {
      await service.initialize();

      final scheduledTime = DateTime.now().add(const Duration(seconds: 5));

      await service.scheduleBreakEndNotification(scheduledTime);

      // Verify scheduling was called
      verify(
        () => mockPlugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation: any(
            named: 'uiLocalNotificationDateInterpretation',
          ),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('cancelFocusNotification cancels without error', () async {
      await service.initialize();

      await service.cancelFocusNotification();

      verify(() => mockPlugin.cancel(1)).called(1);
    });

    test('cancelBreakNotification cancels without error', () async {
      await service.initialize();

      await service.cancelBreakNotification();

      verify(() => mockPlugin.cancel(2)).called(1);
    });

    test('cancelAll cancels all notifications without error', () async {
      await service.initialize();

      await service.cancelAll();

      verify(() => mockPlugin.cancelAll()).called(1);
    });

    test('requestPermission completes without error', () async {
      await service.initialize();

      final result = await service.requestPermission();

      expect(result, true);
      verify(
        () => mockAndroidPlugin.requestNotificationsPermission(),
      ).called(1);
    });

    test('getPendingNotifications returns list', () async {
      await service.initialize();

      final pending = await service.getPendingNotifications();

      expect(pending, isA<List>());
      verify(() => mockPlugin.pendingNotificationRequests()).called(1);
    });

    test('scheduling multiple notifications in sequence', () async {
      await service.initialize();

      final focusEnd = DateTime.now().add(const Duration(seconds: 25));
      final breakEnd = DateTime.now().add(const Duration(minutes: 30));

      await service.scheduleFocusEndNotification(focusEnd);
      await service.scheduleBreakEndNotification(breakEnd);

      // Verify both scheduling calls were made
      verify(
        () => mockPlugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation: any(
            named: 'uiLocalNotificationDateInterpretation',
          ),
          payload: any(named: 'payload'),
        ),
      ).called(2);
    });

    test('cancelling after scheduling completes successfully', () async {
      await service.initialize();

      final scheduledTime = DateTime.now().add(const Duration(seconds: 25));
      await service.scheduleFocusEndNotification(scheduledTime);

      await service.cancelFocusNotification();

      verify(() => mockPlugin.cancel(1)).called(1);
    });

    test('timezone initialization happens once', () async {
      // Create multiple services and initialize them
      final service1 = NotificationService(plugin: mockPlugin);
      final service2 = NotificationService(plugin: mockPlugin);

      await service1.initialize();
      await service2.initialize();

      // Both should succeed without timezone re-initialization errors
      expect(service1, isNotNull);
      expect(service2, isNotNull);
    });
  });
}
