import 'package:flutter_test/flutter_test.dart';
import 'package:tempo_pilot/features/ai_chat/logic/ai_availability_formatter.dart';
import 'package:tempo_pilot/features/calendar/logic/free_busy_deriver.dart';

void main() {
  group('AiAvailabilityFormatter', () {
    const formatter = AiAvailabilityFormatter();

    group('formatForAi', () {
      test('filters out intervals that already ended', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 8, 0),
            end: DateTime(2025, 11, 7, 9, 0),
          ), // Past
          TimeInterval(
            start: DateTime(2025, 11, 7, 11, 0),
            end: DateTime(2025, 11, 7, 12, 0),
          ), // Future
        ];

        final result = formatter.formatForAi(intervals, now: now);

        expect(result.length, 1);
        expect(result.single.start.isAfter(now), isTrue);
      });

      test('includes interval that is currently active by clamping to now', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 9, 30),
            end: DateTime(2025, 11, 7, 10, 45),
          ),
        ];

        final result = formatter.formatForAi(intervals, now: now);

        expect(result.length, 1);
        expect(result.single.start, DateTime(2025, 11, 7, 10, 0));
        expect(result.single.end, DateTime(2025, 11, 7, 10, 45));
      });

      test('filters intervals shorter than minimum duration', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 11, 0),
            end: DateTime(2025, 11, 7, 11, 10),
          ), // 10 minutes - too short
          TimeInterval(
            start: DateTime(2025, 11, 7, 12, 0),
            end: DateTime(2025, 11, 7, 12, 30),
          ), // 30 minutes - OK
        ];

        final result = formatter.formatForAi(
          intervals,
          now: now,
          minDuration: const Duration(minutes: 15),
        );

        expect(result.length, 1);
        expect(
          result.single.duration.inMinutes,
          greaterThanOrEqualTo(15),
        );
      });

      test('rounds start and end to 5-minute boundaries', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final intervals = [
          TimeInterval(
              start: DateTime(2025, 11, 7, 11, 3), // Ceil to 11:05
              end: DateTime(2025, 11, 7, 11, 47), // Floor to 11:45
          ),
        ];

        final result = formatter.formatForAi(intervals, now: now);

        expect(result.length, 1);
        expect(result[0].start.minute, 5); // Rounded up to next 5-minute mark
        expect(result[0].end.minute, 45); // Rounded down to previous 5-minute mark
      });

      test('sorts intervals by start time', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 14, 0),
            end: DateTime(2025, 11, 7, 15, 0),
          ),
          TimeInterval(
            start: DateTime(2025, 11, 7, 11, 0),
            end: DateTime(2025, 11, 7, 12, 0),
          ),
          TimeInterval(
            start: DateTime(2025, 11, 7, 16, 0),
            end: DateTime(2025, 11, 7, 17, 0),
          ),
        ];

        final result = formatter.formatForAi(intervals, now: now);

        expect(result.length, 3);
        for (var i = 0; i < result.length - 1; i++) {
          expect(
            result[i].start.isBefore(result[i + 1].start),
            isTrue,
            reason: 'Intervals should be sorted by start time',
          );
        }
      });

      test('limits to maxCount intervals', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final intervals = List.generate(
          20,
          (i) => TimeInterval(
            start: DateTime(2025, 11, 7, 11 + i, 0),
            end: DateTime(2025, 11, 7, 11 + i, 30),
          ),
        );

        final result = formatter.formatForAi(intervals, now: now, maxCount: 5);

        expect(result.length, 5);
      });

      test('handles empty input', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final result = formatter.formatForAi(<TimeInterval>[], now: now);
        expect(result, isEmpty);
      });

      test('removes intervals that become invalid after rounding', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        // Create an interval so short that rounding makes end <= start
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 11, 1), // Rounds to 11:00
            end: DateTime(2025, 11, 7, 11, 2), // Rounds to 11:00
          ),
        ];

        final result = formatter.formatForAi(intervals, now: now);
        expect(result, isEmpty);
      });
    });

    group('toJson', () {
      test('produces correct JSON structure', () {
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 14, 0),
            end: DateTime(2025, 11, 7, 15, 30),
          ),
          TimeInterval(
            start: DateTime(2025, 11, 7, 16, 0),
            end: DateTime(2025, 11, 7, 17, 0),
          ),
        ];
        final generatedAt = DateTime(2025, 11, 7, 10, 0);

        final json = formatter.toJson(intervals, 'GMT', generatedAt);

        expect(json['tz'], 'GMT');
        expect(json['tz_offset_minutes'], isA<int>());
        expect(json['tz_offset'], isA<String>());
        expect(json['generated_at'], generatedAt.toIso8601String());
        expect(json['generated_at_utc'], generatedAt.toUtc().toIso8601String());
        expect(json['day'], 'today');
        expect(json['day_iso'], '2025-11-07');
        expect(json['intervals'], isA<List>());
        expect((json['intervals'] as List).length, 2);
      });

      test('interval entries contain start, end, and minutes', () {
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 14, 15),
            end: DateTime(2025, 11, 7, 15, 45),
          ),
        ];
        final generatedAt = DateTime(2025, 11, 7, 10, 0);

        final json = formatter.toJson(intervals, 'GMT', generatedAt);
        final intervalList = json['intervals'] as List;
        final firstInterval = intervalList[0] as Map<String, dynamic>;

        expect(firstInterval['start'], '14:15');
        expect(firstInterval['end'], '15:45');
        expect(firstInterval['minutes'], 90);
        expect(json['tz_offset'], isNotEmpty);
      });

      test('handles empty intervals', () {
        final json = formatter.toJson(
          <TimeInterval>[],
          'GMT',
          DateTime(2025, 11, 7, 10, 0),
        );

        expect(json['intervals'], isEmpty);
      });
    });

    group('toSystemPrompt', () {
      test('generates prompt with intervals', () {
        final json = {
          'tz': 'GMT',
          'tz_offset': '+00:00',
          'day_iso': '2025-11-07',
          'generated_at': '2025-11-07T10:00:00.000Z',
          'intervals': [
            {'start': '14:00', 'end': '15:30', 'minutes': 90},
            {'start': '16:00', 'end': '17:00', 'minutes': 60},
          ],
        };

        final prompt = formatter.toSystemPrompt(json);

        expect(prompt, contains('CALENDAR ACCESS'));
        expect(prompt, contains('GMT'));
        expect(prompt, contains('UTC'));
        expect(prompt, contains('2025-11-07'));
        expect(prompt, contains('14:00–15:30'));
        expect(prompt, contains('16:00–17:00'));
        expect(prompt, contains('90 min'));
        expect(prompt, contains('60 min'));
        expect(
          prompt.toLowerCase(),
          contains('only use these exact time slots'),
        );
        expect(prompt.toLowerCase(), contains('do not invent'));
      });

      test('generates appropriate prompt when no intervals available', () {
        final json = {
          'tz': 'GMT',
          'tz_offset': '+00:00',
          'day_iso': '2025-11-07',
          'generated_at': '2025-11-07T10:00:00.000Z',
          'intervals': <Map<String, dynamic>>[],
        };

        final prompt = formatter.toSystemPrompt(json);

        expect(prompt, contains('CALENDAR ACCESS'));
        expect(prompt.toLowerCase(), contains('no free time available'));
        expect(
          prompt.toLowerCase(),
          anyOf(contains('review'), contains('another day')),
        );
      });

      test('includes warning not to invent time slots', () {
        final json = {
          'tz': 'GMT',
          'tz_offset': '+00:00',
          'day_iso': '2025-11-07',
          'generated_at': '2025-11-07T10:00:00.000Z',
          'intervals': [
            {'start': '14:00', 'end': '15:00', 'minutes': 60},
          ],
        };

        final prompt = formatter.toSystemPrompt(json);

        expect(prompt.toLowerCase(), contains('do not invent'));
      });
    });

    group('time formatting', () {
      test('formats times with leading zeros', () {
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 9, 5),
            end: DateTime(2025, 11, 7, 10, 30),
          ),
        ];

        final json = formatter.toJson(
          intervals,
          'GMT',
          DateTime(2025, 11, 7, 8, 0),
        );
        final intervalData =
            (json['intervals'] as List)[0] as Map<String, dynamic>;

        expect(intervalData['start'], '09:05');
        expect(intervalData['end'], '10:30');
      });
    });

    group('rounding behavior', () {
      test('rounds 12:32 to 12:30', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 12, 32),
            end: DateTime(2025, 11, 7, 13, 0),
          ),
        ];

        final result = formatter.formatForAi(intervals, now: now);
        expect(result[0].start.minute, 35);
      });

      test('rounds 12:33 to 12:35', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 12, 33),
            end: DateTime(2025, 11, 7, 13, 0),
          ),
        ];

        final result = formatter.formatForAi(intervals, now: now);
        expect(result[0].start.minute, 35);
      });

      test('rounds 12:37 to 12:35', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 12, 37),
            end: DateTime(2025, 11, 7, 13, 0),
          ),
        ];

        final result = formatter.formatForAi(intervals, now: now);
        expect(result[0].start.minute, 40);
      });

      test('rounds 12:38 to 12:40', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 12, 38),
            end: DateTime(2025, 11, 7, 13, 0),
          ),
        ];

        final result = formatter.formatForAi(intervals, now: now);
        expect(result[0].start.minute, 40);
      });

      test('floors end times to avoid extending availability', () {
        final now = DateTime(2025, 11, 7, 10, 0);
        final intervals = [
          TimeInterval(
            start: DateTime(2025, 11, 7, 12, 0),
            end: DateTime(2025, 11, 7, 12, 58),
          ),
        ];

        final result = formatter.formatForAi(intervals, now: now);
        expect(result[0].end.minute, 55);
      });
    });
  });
}
