import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempo_pilot/features/calendar/services/calendar_events_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarEventsService availability mapping', () {
    test('returns tri-state busy hints', () {
      final service = CalendarEventsService();
      expect(service.availabilityToBusyForTesting(null), isNull);
      expect(service.availabilityToBusyForTesting(Availability.Free), isFalse);
      expect(service.availabilityToBusyForTesting(Availability.Busy), isTrue);
      expect(
        service.availabilityToBusyForTesting(Availability.Tentative),
        isTrue,
      );
      expect(
        service.availabilityToBusyForTesting(Availability.Unavailable),
        isTrue,
      );
    });
  });
}
