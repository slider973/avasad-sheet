import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';

/// Comprehensive unit tests for ReminderSettings model
///
/// Tests cover:
/// - Serialization and deserialization edge cases
/// - Validation logic for all constraints
/// - Default settings compliance with requirements
/// - Copy functionality and immutability
/// - Time calculations and business logic
void main() {
  group('ReminderSettings - Comprehensive Tests', () {
    group('Default Settings Validation', () {
      test('should have disabled default settings per requirement 1.1', () {
        final defaults = ReminderSettings.defaultSettings;

        expect(defaults.enabled, false,
            reason: 'Requirement 1.1: disabled by default');
        expect(defaults.clockInTime, const TimeOfDay(hour: 8, minute: 0));
        expect(defaults.clockOutTime, const TimeOfDay(hour: 17, minute: 0));
        expect(defaults.activeDays, {1, 2, 3, 4, 5}); // Monday to Friday
        expect(defaults.respectHolidays, true);
        expect(defaults.snoozeMinutes, 15);
        expect(defaults.maxSnoozes, 2);
      });

      test('should have valid default configuration', () {
        final defaults = ReminderSettings.defaultSettings;
        expect(defaults.validate(), isNull);
        expect(defaults.hasValidTimeConfiguration, isTrue);
      });
    });

    group('Validation Logic - Comprehensive', () {
      test(
          'should validate clock-out time after clock-in time (requirement 2.4)',
          () {
        // Valid case
        final validSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );
        expect(validSettings.validate(), isNull);

        // Invalid case - same time
        final sameTimeSettings = validSettings.copyWith(
          clockOutTime: const TimeOfDay(hour: 8, minute: 0),
        );
        expect(sameTimeSettings.validate(),
            contains('Clock-out time must be after clock-in time'));

        // Invalid case - clock-out before clock-in
        final invalidSettings = validSettings.copyWith(
          clockOutTime: const TimeOfDay(hour: 7, minute: 30),
        );
        expect(invalidSettings.validate(),
            contains('Clock-out time must be after clock-in time'));

        // Edge case - 1 minute difference (should be valid)
        final edgeValidSettings = validSettings.copyWith(
          clockInTime: const TimeOfDay(hour: 8, minute: 59),
          clockOutTime: const TimeOfDay(hour: 9, minute: 0),
        );
        expect(edgeValidSettings.validate(), isNull);
      });

      test('should validate active days constraints', () {
        final baseSettings = ReminderSettings.defaultSettings;

        // Empty active days
        final emptyDaysSettings = baseSettings.copyWith(activeDays: <int>{});
        expect(emptyDaysSettings.validate(),
            contains('At least one active day must be selected'));

        // Invalid day numbers (below 1)
        final invalidLowDaySettings =
            baseSettings.copyWith(activeDays: {0, 1, 2});
        expect(invalidLowDaySettings.validate(),
            contains('Active days must be between 1'));

        // Invalid day numbers (above 7)
        final invalidHighDaySettings =
            baseSettings.copyWith(activeDays: {1, 2, 8});
        expect(invalidHighDaySettings.validate(),
            contains('Active days must be between 1'));

        // Valid edge cases
        final mondayOnlySettings = baseSettings.copyWith(activeDays: {1});
        expect(mondayOnlySettings.validate(), isNull);

        final sundayOnlySettings = baseSettings.copyWith(activeDays: {7});
        expect(sundayOnlySettings.validate(), isNull);

        final allDaysSettings =
            baseSettings.copyWith(activeDays: {1, 2, 3, 4, 5, 6, 7});
        expect(allDaysSettings.validate(), isNull);
      });

      test('should validate snooze minutes constraints', () {
        final baseSettings = ReminderSettings.defaultSettings;

        // Invalid snooze minutes (too low)
        final lowSnoozeSettings = baseSettings.copyWith(snoozeMinutes: 0);
        expect(lowSnoozeSettings.validate(),
            contains('Snooze minutes must be between 1 and 60'));

        final negativeSnoozeSettings = baseSettings.copyWith(snoozeMinutes: -5);
        expect(negativeSnoozeSettings.validate(),
            contains('Snooze minutes must be between 1 and 60'));

        // Invalid snooze minutes (too high)
        final highSnoozeSettings = baseSettings.copyWith(snoozeMinutes: 61);
        expect(highSnoozeSettings.validate(),
            contains('Snooze minutes must be between 1 and 60'));

        // Valid edge cases
        final minSnoozeSettings = baseSettings.copyWith(snoozeMinutes: 1);
        expect(minSnoozeSettings.validate(), isNull);

        final maxSnoozeSettings = baseSettings.copyWith(snoozeMinutes: 60);
        expect(maxSnoozeSettings.validate(), isNull);
      });

      test('should validate max snoozes constraints', () {
        final baseSettings = ReminderSettings.defaultSettings;

        // Invalid max snoozes (negative)
        final negativeMaxSnoozeSettings = baseSettings.copyWith(maxSnoozes: -1);
        expect(negativeMaxSnoozeSettings.validate(),
            contains('Maximum snoozes must be between 0 and 5'));

        // Invalid max snoozes (too high)
        final highMaxSnoozeSettings = baseSettings.copyWith(maxSnoozes: 6);
        expect(highMaxSnoozeSettings.validate(),
            contains('Maximum snoozes must be between 0 and 5'));

        // Valid edge cases
        final zeroMaxSnoozeSettings = baseSettings.copyWith(maxSnoozes: 0);
        expect(zeroMaxSnoozeSettings.validate(), isNull);

        final maxAllowedSnoozeSettings = baseSettings.copyWith(maxSnoozes: 5);
        expect(maxAllowedSnoozeSettings.validate(), isNull);
      });
    });

    group('Active Day Logic', () {
      test('should check active days correctly when enabled', () {
        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 3, 5}, // Monday, Wednesday, Friday
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Active days
        expect(settings.isActiveOnDay(1), true); // Monday
        expect(settings.isActiveOnDay(3), true); // Wednesday
        expect(settings.isActiveOnDay(5), true); // Friday

        // Inactive days
        expect(settings.isActiveOnDay(2), false); // Tuesday
        expect(settings.isActiveOnDay(4), false); // Thursday
        expect(settings.isActiveOnDay(6), false); // Saturday
        expect(settings.isActiveOnDay(7), false); // Sunday
      });

      test('should return false for all days when disabled', () {
        final settings = ReminderSettings(
          enabled: false, // Disabled
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5, 6, 7}, // All days configured
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Should return false for all days when disabled
        for (int day = 1; day <= 7; day++) {
          expect(settings.isActiveOnDay(day), false,
              reason:
                  'Day $day should be inactive when reminders are disabled');
        }
      });
    });

    group('Work Duration Calculations', () {
      test('should calculate work duration correctly', () {
        // Standard 8-hour workday
        final standardSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 9, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );
        expect(standardSettings.workDuration, const Duration(hours: 8));

        // 8.5-hour workday with 30-minute lunch
        final extendedSettings = standardSettings.copyWith(
          clockInTime: const TimeOfDay(hour: 8, minute: 30),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        );
        expect(extendedSettings.workDuration,
            const Duration(hours: 8, minutes: 30));

        // Part-time 4-hour workday
        final partTimeSettings = standardSettings.copyWith(
          clockInTime: const TimeOfDay(hour: 9, minute: 0),
          clockOutTime: const TimeOfDay(hour: 13, minute: 0),
        );
        expect(partTimeSettings.workDuration, const Duration(hours: 4));

        // Edge case - 1 minute workday
        final shortSettings = standardSettings.copyWith(
          clockInTime: const TimeOfDay(hour: 9, minute: 0),
          clockOutTime: const TimeOfDay(hour: 9, minute: 1),
        );
        expect(shortSettings.workDuration, const Duration(minutes: 1));
      });

      test('should handle cross-midnight work duration', () {
        // Night shift: 22:00 to 06:00 (8 hours)
        final nightShiftSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 22, minute: 0),
          clockOutTime: const TimeOfDay(hour: 6, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Note: This will calculate as negative duration in current implementation
        // This is a known limitation that could be addressed in future versions
        final duration = nightShiftSettings.workDuration;
        expect(duration.isNegative, true);
        expect(duration.inMinutes,
            -960); // -16 hours (22:00 to 06:00 calculated as 6:00 - 22:00)
      });
    });

    group('Serialization - Comprehensive', () {
      test('should serialize and deserialize all properties correctly', () {
        final originalSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 30),
          clockOutTime: const TimeOfDay(hour: 17, minute: 45),
          activeDays: {1, 3, 5, 7}, // Monday, Wednesday, Friday, Sunday
          respectHolidays: false,
          snoozeMinutes: 10,
          maxSnoozes: 3,
        );

        final json = originalSettings.toJson();
        final restoredSettings = ReminderSettings.fromJson(json);

        expect(restoredSettings, equals(originalSettings));
        expect(restoredSettings.enabled, originalSettings.enabled);
        expect(restoredSettings.clockInTime.hour,
            originalSettings.clockInTime.hour);
        expect(restoredSettings.clockInTime.minute,
            originalSettings.clockInTime.minute);
        expect(restoredSettings.clockOutTime.hour,
            originalSettings.clockOutTime.hour);
        expect(restoredSettings.clockOutTime.minute,
            originalSettings.clockOutTime.minute);
        expect(restoredSettings.activeDays, originalSettings.activeDays);
        expect(
            restoredSettings.respectHolidays, originalSettings.respectHolidays);
        expect(restoredSettings.snoozeMinutes, originalSettings.snoozeMinutes);
        expect(restoredSettings.maxSnoozes, originalSettings.maxSnoozes);
      });

      test('should handle missing JSON properties with defaults', () {
        // Minimal JSON with only required fields
        final minimalJson = {
          'enabled': true,
          'clockInTime': {'hour': 9, 'minute': 0},
          'clockOutTime': {'hour': 18, 'minute': 0},
          'activeDays': [1, 2, 3, 4, 5],
        };

        final settings = ReminderSettings.fromJson(minimalJson);

        expect(settings.enabled, true);
        expect(settings.clockInTime, const TimeOfDay(hour: 9, minute: 0));
        expect(settings.clockOutTime, const TimeOfDay(hour: 18, minute: 0));
        expect(settings.activeDays, {1, 2, 3, 4, 5});
        expect(settings.respectHolidays, true); // Default value
        expect(settings.snoozeMinutes, 15); // Default value
        expect(settings.maxSnoozes, 2); // Default value
      });

      test('should handle invalid JSON gracefully', () {
        // Empty JSON
        expect(() => ReminderSettings.fromJson({}),
            throwsA(isA<FormatException>()));

        // Missing required fields
        expect(() => ReminderSettings.fromJson({'enabled': true}),
            throwsA(isA<FormatException>()));

        // Invalid data types
        expect(
            () => ReminderSettings.fromJson({
                  'enabled': 'not_a_boolean',
                  'clockInTime': {'hour': 9, 'minute': 0},
                  'clockOutTime': {'hour': 18, 'minute': 0},
                  'activeDays': [1, 2, 3, 4, 5],
                }),
            throwsA(isA<FormatException>()));

        // Invalid time values - TimeOfDay constructor will clamp values,
        // but our fromJson should catch type errors
        expect(
            () => ReminderSettings.fromJson({
                  'enabled': true,
                  'clockInTime': {
                    'hour': 'invalid',
                    'minute': 0
                  }, // Invalid type
                  'clockOutTime': {'hour': 18, 'minute': 0},
                  'activeDays': [1, 2, 3, 4, 5],
                }),
            throwsA(isA<FormatException>()));
      });
    });

    group('Copy Functionality', () {
      test('should create copy with updated values', () {
        final original = ReminderSettings.defaultSettings;

        final updated = original.copyWith(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 9, minute: 30),
          activeDays: {1, 2, 3},
          snoozeMinutes: 20,
        );

        // Updated values should be different
        expect(updated.enabled, true);
        expect(updated.clockInTime, const TimeOfDay(hour: 9, minute: 30));
        expect(updated.activeDays, {1, 2, 3});
        expect(updated.snoozeMinutes, 20);

        // Non-updated values should remain the same
        expect(updated.clockOutTime, original.clockOutTime);
        expect(updated.respectHolidays, original.respectHolidays);
        expect(updated.maxSnoozes, original.maxSnoozes);
      });

      test('should create identical copy when no parameters provided', () {
        final original = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 15),
          clockOutTime: const TimeOfDay(hour: 16, minute: 45),
          activeDays: {2, 4, 6},
          respectHolidays: false,
          snoozeMinutes: 25,
          maxSnoozes: 1,
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
        expect(copy == original, true);
      });
    });

    group('Equality and Hash Code', () {
      test('should implement equality correctly', () {
        final settings1 = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        final settings2 = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        final settings3 = settings1.copyWith(enabled: false);

        expect(settings1, equals(settings2));
        expect(settings1 == settings2, true);
        expect(settings1, isNot(equals(settings3)));
        expect(settings1 == settings3, false);
      });

      test('should have consistent hash codes', () {
        final settings1 = ReminderSettings.defaultSettings;
        final settings2 = ReminderSettings.defaultSettings;
        final settings3 = settings1.copyWith(enabled: true);

        expect(settings1.hashCode, equals(settings2.hashCode));
        expect(settings1.hashCode, isNot(equals(settings3.hashCode)));
      });
    });

    group('String Representation', () {
      test('should provide readable string representation', () {
        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 30),
          clockOutTime: const TimeOfDay(hour: 17, minute: 15),
          activeDays: {1, 3, 5},
          respectHolidays: false,
          snoozeMinutes: 10,
          maxSnoozes: 3,
        );

        final stringRep = settings.toString();

        expect(stringRep, contains('enabled: true'));
        expect(stringRep, contains('clockInTime: 8:30'));
        expect(stringRep, contains('clockOutTime: 17:15'));
        expect(stringRep, contains('activeDays: {1, 3, 5}'));
        expect(stringRep, contains('respectHolidays: false'));
        expect(stringRep, contains('snoozeMinutes: 10'));
        expect(stringRep, contains('maxSnoozes: 3'));
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('should handle extreme time values', () {
        // Midnight to midnight (24-hour shift)
        final midnightSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 0, minute: 0),
          clockOutTime: const TimeOfDay(hour: 23, minute: 59),
          activeDays: {1},
          respectHolidays: true,
          snoozeMinutes: 1,
          maxSnoozes: 0,
        );

        expect(midnightSettings.validate(), isNull);
        expect(
            midnightSettings.workDuration.inMinutes, 1439); // 23:59 in minutes
      });

      test('should handle single day configuration', () {
        final singleDaySettings = ReminderSettings.defaultSettings.copyWith(
          activeDays: {7}, // Sunday only
        );

        expect(singleDaySettings.validate(), isNull);
        expect(
            singleDaySettings.isActiveOnDay(7), false); // Disabled by default

        final enabledSingleDay = singleDaySettings.copyWith(enabled: true);
        expect(enabledSingleDay.isActiveOnDay(7), true);
        expect(enabledSingleDay.isActiveOnDay(1), false);
      });

      test('should handle maximum configuration values', () {
        final maxSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 0, minute: 0),
          clockOutTime: const TimeOfDay(hour: 23, minute: 59),
          activeDays: {1, 2, 3, 4, 5, 6, 7}, // All days
          respectHolidays: true,
          snoozeMinutes: 60, // Maximum
          maxSnoozes: 5, // Maximum
        );

        expect(maxSettings.validate(), isNull);
        expect(maxSettings.hasValidTimeConfiguration, true);
      });
    });
  });
}
