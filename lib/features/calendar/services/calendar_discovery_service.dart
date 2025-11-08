import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_source.dart';

/// Service for discovering and managing device calendars.
class CalendarDiscoveryService {
  CalendarDiscoveryService({DeviceCalendarPlugin? plugin})
    : _plugin = plugin ?? DeviceCalendarPlugin();

  final DeviceCalendarPlugin _plugin;

  /// Retrieve all calendars from the device.
  /// Marks primary calendars based on isPrimary flag from the platform.
  Future<List<CalendarSource>> listCalendars() async {
    try {
      final result = await _plugin.retrieveCalendars();

      if (result.isSuccess && result.data != null) {
        return result.data!
            .map((cal) {
              // Determine if this is a primary calendar
              // Device calendar plugin marks the primary calendar with isPrimary
              final isPrimary = cal.isDefault ?? false;

              return CalendarSource(
                id: cal.id ?? '',
                name: cal.name ?? 'Unnamed Calendar',
                accountName: cal.accountName,
                accountType: cal.accountType,
                isPrimary: isPrimary,
                // By default, only include primary calendars
                included: isPrimary,
              );
            })
            .where((source) => source.id.isNotEmpty)
            .toList();
      } else {
        if (kDebugMode) {
          debugPrint(
            '[CalendarDiscoveryService] Failed to retrieve calendars: ${result.errors}',
          );
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarDiscoveryService] Error listing calendars: $e');
      }
      return [];
    }
  }
}
