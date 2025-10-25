import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';

void main() {
  group('Reminder Permission Improvements Tests', () {
    test('should validate reminder settings correctly', () {
      // Test valid settings
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
      expect(validSettings.hasValidTimeConfiguration, isTrue);
    });

    test('should detect invalid time configuration', () {
      // Test invalid settings (clock-out before clock-in)
      final invalidSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 18, minute: 0),
        clockOutTime: const TimeOfDay(hour: 8, minute: 0), // Invalid
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(invalidSettings.validate(), isNotNull);
      expect(invalidSettings.validate(),
          contains('Clock-out time must be after clock-in time'));
      expect(invalidSettings.hasValidTimeConfiguration, isFalse);
    });

    test('should detect empty active days', () {
      final noActiveDaysSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {}, // Empty
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(noActiveDaysSettings.validate(), isNotNull);
      expect(noActiveDaysSettings.validate(),
          contains('At least one active day must be selected'));
    });

    test('should handle default settings correctly', () {
      final defaultSettings = ReminderSettings.defaultSettings;

      // Requirement 1.1: Default disabled state
      expect(defaultSettings.enabled, isFalse);
      expect(defaultSettings.validate(), isNull);
      expect(defaultSettings.hasValidTimeConfiguration, isTrue);

      // Default configuration should be reasonable
      expect(defaultSettings.clockInTime, const TimeOfDay(hour: 8, minute: 0));
      expect(
          defaultSettings.clockOutTime, const TimeOfDay(hour: 17, minute: 0));
      expect(defaultSettings.activeDays, {1, 2, 3, 4, 5}); // Weekdays
      expect(defaultSettings.respectHolidays, isTrue);
      expect(defaultSettings.snoozeMinutes, 15);
      expect(defaultSettings.maxSnoozes, 2);
    });

    test('should handle boundary conditions correctly', () {
      // Test extreme but valid settings
      final boundarySettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 0, minute: 0), // Midnight
        clockOutTime: const TimeOfDay(hour: 23, minute: 59), // Almost midnight
        activeDays: {1, 2, 3, 4, 5, 6, 7}, // All days
        respectHolidays: true,
        snoozeMinutes: 60, // Maximum
        maxSnoozes: 5, // Maximum
      );

      expect(boundarySettings.validate(), isNull);
      expect(boundarySettings.hasValidTimeConfiguration, isTrue);
      expect(boundarySettings.workDuration.inHours, 23); // Almost 24 hours
    });

    test('should handle serialization correctly', () {
      final settings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 9, minute: 30),
        clockOutTime: const TimeOfDay(hour: 18, minute: 15),
        activeDays: {1, 3, 5}, // Monday, Wednesday, Friday
        respectHolidays: false,
        snoozeMinutes: 30,
        maxSnoozes: 3,
      );

      // Test serialization
      final json = settings.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['enabled'], isTrue);
      expect(json['respectHolidays'], isFalse);
      expect(json['snoozeMinutes'], 30);
      expect(json['maxSnoozes'], 3);

      // Test deserialization
      final deserializedSettings = ReminderSettings.fromJson(json);
      expect(deserializedSettings, equals(settings));
      expect(deserializedSettings.enabled, settings.enabled);
      expect(deserializedSettings.clockInTime, settings.clockInTime);
      expect(deserializedSettings.clockOutTime, settings.clockOutTime);
      expect(deserializedSettings.activeDays, settings.activeDays);
      expect(deserializedSettings.respectHolidays, settings.respectHolidays);
      expect(deserializedSettings.snoozeMinutes, settings.snoozeMinutes);
      expect(deserializedSettings.maxSnoozes, settings.maxSnoozes);
    });

    test('should handle day activity checks correctly', () {
      final weekdaySettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {1, 2, 3, 4, 5}, // Weekdays only
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      // Test weekday activity
      expect(weekdaySettings.isActiveOnDay(1), isTrue); // Monday
      expect(weekdaySettings.isActiveOnDay(2), isTrue); // Tuesday
      expect(weekdaySettings.isActiveOnDay(3), isTrue); // Wednesday
      expect(weekdaySettings.isActiveOnDay(4), isTrue); // Thursday
      expect(weekdaySettings.isActiveOnDay(5), isTrue); // Friday

      // Test weekend inactivity
      expect(weekdaySettings.isActiveOnDay(6), isFalse); // Saturday
      expect(weekdaySettings.isActiveOnDay(7), isFalse); // Sunday

      // Test when disabled - no days should be active
      final disabledSettings = weekdaySettings.copyWith(enabled: false);
      // Note: isActiveOnDay checks both enabled state AND day configuration
      expect(disabledSettings.isActiveOnDay(1),
          isFalse); // Should be false when disabled
      expect(disabledSettings.isActiveOnDay(6),
          isFalse); // Should be false when disabled
    });

    test('should handle copyWith functionality correctly', () {
      final originalSettings = ReminderSettings.defaultSettings;

      // Test enabling
      final enabledSettings = originalSettings.copyWith(enabled: true);
      expect(enabledSettings.enabled, isTrue);
      expect(enabledSettings.clockInTime,
          originalSettings.clockInTime); // Other properties unchanged

      // Test time changes
      final newTimeSettings = originalSettings.copyWith(
        clockInTime: const TimeOfDay(hour: 9, minute: 0),
        clockOutTime: const TimeOfDay(hour: 18, minute: 0),
      );
      expect(newTimeSettings.clockInTime, const TimeOfDay(hour: 9, minute: 0));
      expect(
          newTimeSettings.clockOutTime, const TimeOfDay(hour: 18, minute: 0));
      expect(newTimeSettings.enabled,
          originalSettings.enabled); // Other properties unchanged

      // Test day changes (need to enable first)
      final weekendSettings = originalSettings.copyWith(
        enabled: true, // Enable to test day activity
        activeDays: {6, 7}, // Weekend only
      );
      expect(weekendSettings.activeDays, {6, 7});
      expect(weekendSettings.isActiveOnDay(6), isTrue);
      expect(weekendSettings.isActiveOnDay(1), isFalse);
    });

    test('should calculate work duration correctly', () {
      // Standard work day
      final standardSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 9, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 30),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(standardSettings.workDuration.inHours, 8); // 8.5 hours
      expect(
          standardSettings.workDuration.inMinutes, 510); // 8h 30m = 510 minutes

      // Short work day
      final shortSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 14, minute: 0),
        clockOutTime: const TimeOfDay(hour: 16, minute: 0),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(shortSettings.workDuration.inHours, 2);
      expect(shortSettings.workDuration.inMinutes, 120);
    });

    test('should provide meaningful string representation', () {
      final settings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 30),
        clockOutTime: const TimeOfDay(hour: 17, minute: 15),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      final stringRep = settings.toString();
      expect(stringRep, contains('enabled: true'));
      expect(stringRep, contains('8:30'));
      expect(stringRep, contains('17:15'));
      expect(stringRep, contains('{1, 2, 3, 4, 5}'));
      expect(stringRep, contains('respectHolidays: true'));
      expect(stringRep, contains('snoozeMinutes: 15'));
      expect(stringRep, contains('maxSnoozes: 2'));
    });

    test('should handle equality correctly', () {
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

      final settings3 = ReminderSettings(
        enabled: false, // Different
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(settings1, equals(settings2));
      expect(settings1, isNot(equals(settings3)));
      expect(settings1.hashCode, equals(settings2.hashCode));
      expect(settings1.hashCode, isNot(equals(settings3.hashCode)));
    });
  });
}
