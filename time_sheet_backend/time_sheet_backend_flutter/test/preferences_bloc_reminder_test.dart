import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/features/preference/data/models/reminder_settings.dart';

void main() {
  group('ReminderSettings Tests', () {
    test('should have default reminder settings disabled', () {
      final defaultSettings = ReminderSettings.defaultSettings;
      expect(defaultSettings.enabled,
          false); // Requirement 1.1: disabled by default
      expect(defaultSettings.clockInTime, const TimeOfDay(hour: 8, minute: 0));
      expect(
          defaultSettings.clockOutTime, const TimeOfDay(hour: 17, minute: 0));
      expect(defaultSettings.activeDays, {1, 2, 3, 4, 5}); // Monday to Friday
    });

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
      expect(validSettings.validate(), null);

      // Test invalid settings - clock out before clock in (requirement 2.4)
      final invalidSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 17, minute: 0),
        clockOutTime: const TimeOfDay(hour: 8, minute: 0),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );
      expect(invalidSettings.validate(),
          contains('Clock-out time must be after clock-in time'));

      // Test empty active days
      final noActiveDaysSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );
      expect(noActiveDaysSettings.validate(),
          contains('At least one active day must be selected'));
    });

    test('should serialize and deserialize correctly', () {
      final originalSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 9, minute: 30),
        clockOutTime: const TimeOfDay(hour: 18, minute: 15),
        activeDays: {1, 3, 5}, // Monday, Wednesday, Friday
        respectHolidays: false,
        snoozeMinutes: 10,
        maxSnoozes: 3,
      );

      // Serialize to JSON
      final json = originalSettings.toJson();

      // Deserialize from JSON
      final deserializedSettings = ReminderSettings.fromJson(json);

      // Verify all properties match
      expect(deserializedSettings.enabled, originalSettings.enabled);
      expect(deserializedSettings.clockInTime.hour,
          originalSettings.clockInTime.hour);
      expect(deserializedSettings.clockInTime.minute,
          originalSettings.clockInTime.minute);
      expect(deserializedSettings.clockOutTime.hour,
          originalSettings.clockOutTime.hour);
      expect(deserializedSettings.clockOutTime.minute,
          originalSettings.clockOutTime.minute);
      expect(deserializedSettings.activeDays, originalSettings.activeDays);
      expect(deserializedSettings.respectHolidays,
          originalSettings.respectHolidays);
      expect(
          deserializedSettings.snoozeMinutes, originalSettings.snoozeMinutes);
      expect(deserializedSettings.maxSnoozes, originalSettings.maxSnoozes);
    });

    test('should check active days correctly', () {
      final settings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {1, 3, 5}, // Monday, Wednesday, Friday
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      // Should be active on configured days
      expect(settings.isActiveOnDay(1), true); // Monday
      expect(settings.isActiveOnDay(3), true); // Wednesday
      expect(settings.isActiveOnDay(5), true); // Friday

      // Should not be active on non-configured days
      expect(settings.isActiveOnDay(2), false); // Tuesday
      expect(settings.isActiveOnDay(4), false); // Thursday
      expect(settings.isActiveOnDay(6), false); // Saturday
      expect(settings.isActiveOnDay(7), false); // Sunday

      // Should not be active when disabled
      final disabledSettings = settings.copyWith(enabled: false);
      expect(disabledSettings.isActiveOnDay(1), false); // Monday - disabled
    });

    test('should calculate work duration correctly', () {
      final settings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 30),
        clockOutTime: const TimeOfDay(hour: 17, minute: 15),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      final duration = settings.workDuration;
      expect(duration.inHours, 8); // 8 hours 45 minutes
      expect(duration.inMinutes, 525); // 8 * 60 + 45 = 525 minutes
    });

    test('should create copy with updated values', () {
      final originalSettings = ReminderSettings.defaultSettings;

      final updatedSettings = originalSettings.copyWith(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 9, minute: 0),
        activeDays: {1, 2, 3},
      );

      // Updated values should be different
      expect(updatedSettings.enabled, true);
      expect(updatedSettings.clockInTime, const TimeOfDay(hour: 9, minute: 0));
      expect(updatedSettings.activeDays, {1, 2, 3});

      // Non-updated values should remain the same
      expect(updatedSettings.clockOutTime, originalSettings.clockOutTime);
      expect(updatedSettings.respectHolidays, originalSettings.respectHolidays);
      expect(updatedSettings.snoozeMinutes, originalSettings.snoozeMinutes);
      expect(updatedSettings.maxSnoozes, originalSettings.maxSnoozes);
    });
  });
}
