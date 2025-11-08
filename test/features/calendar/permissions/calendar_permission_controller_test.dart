import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tempo_pilot/features/calendar/permissions/calendar_permission_provider.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';

class _MockCalendarPermissionService extends Mock
    implements CalendarPermissionService {}

void main() {
  setUpAll(() {
    registerFallbackValue(CalendarPermissionStatus.unknown);
  });

  group('CalendarPermissionController', () {
    late _MockCalendarPermissionService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = _MockCalendarPermissionService();
      container = ProviderContainer(
        overrides: [
          calendarPermissionServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('build resolves to granted status when available', () async {
      when(
        () => mockService.getStatus(),
      ).thenAnswer((_) async => CalendarPermissionStatus.granted);

      final status = await container.read(
        calendarPermissionStatusProvider.future,
      );

      expect(status, CalendarPermissionStatus.granted);
      final state = container.read(calendarPermissionStatusProvider);
      expect(state.value, CalendarPermissionStatus.granted);
    });

    test('requestPermission updates state with service response', () async {
      when(
        () => mockService.getStatus(),
      ).thenAnswer((_) async => CalendarPermissionStatus.denied);
      when(
        () => mockService.requestPermission(),
      ).thenAnswer((_) async => CalendarPermissionStatus.permanentlyDenied);

      await container.read(calendarPermissionStatusProvider.future);
      final controller = container.read(
        calendarPermissionStatusProvider.notifier,
      );

      final newStatus = await controller.requestPermission();

      expect(newStatus, CalendarPermissionStatus.permanentlyDenied);
      final state = container.read(calendarPermissionStatusProvider);
      expect(state.value, CalendarPermissionStatus.permanentlyDenied);
      verify(() => mockService.requestPermission()).called(1);
    });

    test('refresh falls back to unknown when service throws', () async {
      when(
        () => mockService.getStatus(),
      ).thenAnswer((_) async => CalendarPermissionStatus.granted);

      await container.read(calendarPermissionStatusProvider.future);
      final controller = container.read(
        calendarPermissionStatusProvider.notifier,
      );

      when(() => mockService.getStatus()).thenThrow(Exception('fail'));

      final refreshed = await controller.refresh();

      expect(refreshed, CalendarPermissionStatus.unknown);
      final state = container.read(calendarPermissionStatusProvider);
      expect(state.value, CalendarPermissionStatus.unknown);
    });

    test('openSettings proxies to service', () async {
      when(
        () => mockService.getStatus(),
      ).thenAnswer((_) async => CalendarPermissionStatus.denied);
      when(() => mockService.openSettings()).thenAnswer((_) async => true);

      await container.read(calendarPermissionStatusProvider.future);
      final controller = container.read(
        calendarPermissionStatusProvider.notifier,
      );

      final didOpen = await controller.openSettings();

      expect(didOpen, isTrue);
      verify(() => mockService.openSettings()).called(1);
    });
  });
}
