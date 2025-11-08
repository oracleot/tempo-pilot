import 'package:flutter_test/flutter_test.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_permission_service.dart';

void main() {
  group('CalendarPermissionService', () {
    late CalendarPermissionService service;

    setUp(() {
      service = CalendarPermissionService();
    });

    test('getStatus returns correct status when granted', () async {
      // This test requires platform-specific mocking
      // For now, we just verify the method exists and returns a valid enum
      final status = await service.getStatus();
      expect(status, isA<CalendarPermissionStatus>());
    });

    test('requestPermission returns a valid status', () async {
      // This test requires platform-specific mocking
      // For now, we just verify the method exists and returns a valid enum
      final status = await service.requestPermission();
      expect(status, isA<CalendarPermissionStatus>());
    });

    test('CalendarPermissionStatus enum has all expected values', () {
      expect(CalendarPermissionStatus.unknown, isNotNull);
      expect(CalendarPermissionStatus.granted, isNotNull);
      expect(CalendarPermissionStatus.denied, isNotNull);
      expect(CalendarPermissionStatus.permanentlyDenied, isNotNull);
    });
  });
}
