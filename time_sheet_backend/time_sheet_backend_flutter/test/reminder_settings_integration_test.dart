import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';

void main() {
  group('ReminderSettings Integration', () {
    testWidgets('should create and validate reminder settings correctly',
        (tester) async {
      // Test default settings creation
      final defaultSettings = ReminderSettings.defaultSettings;

      expect(defaultSettings.enabled,
          isFalse); // Requirement 1.1: disabled by default
      expect(defaultSettings.clockInTime, const TimeOfDay(hour: 8, minute: 0));
      expect(
          defaultSettings.clockOutTime, const TimeOfDay(hour: 17, minute: 0));
      expect(defaultSettings.activeDays, {1, 2, 3, 4, 5}); // Monday to Friday
      expect(defaultSettings.respectHolidays, isTrue);
      expect(defaultSettings.snoozeMinutes, 15);
      expect(defaultSettings.maxSnoozes, 2);
    });

    testWidgets('should validate time configuration correctly', (tester) async {
      // Test valid configuration
      final validSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(validSettings.validate(), isNull); // Should be valid
      expect(validSettings.hasValidTimeConfiguration, isTrue);

      // Test invalid configuration (clock-out before clock-in)
      final invalidSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 17, minute: 0), // 5 PM
        clockOutTime: const TimeOfDay(hour: 8, minute: 0), // 8 AM
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(invalidSettings.validate(), isNotNull); // Should be invalid
      expect(invalidSettings.hasValidTimeConfiguration, isFalse);
      expect(invalidSettings.validate(),
          contains('Clock-out time must be after clock-in time'));
    });

    testWidgets('should serialize and deserialize correctly', (tester) async {
      // Create settings
      final originalSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 9, minute: 30),
        clockOutTime: const TimeOfDay(hour: 18, minute: 15),
        activeDays: {1, 3, 5}, // Monday, Wednesday, Friday
        respectHolidays: false,
        snoozeMinutes: 30,
        maxSnoozes: 1,
      );

      // Serialize to JSON
      final json = originalSettings.toJson();

      // Deserialize from JSON
      final deserializedSettings = ReminderSettings.fromJson(json);

      // Verify all properties match
      expect(deserializedSettings.enabled, originalSettings.enabled);
      expect(deserializedSettings.clockInTime, originalSettings.clockInTime);
      expect(deserializedSettings.clockOutTime, originalSettings.clockOutTime);
      expect(deserializedSettings.activeDays, originalSettings.activeDays);
      expect(deserializedSettings.respectHolidays,
          originalSettings.respectHolidays);
      expect(
          deserializedSettings.snoozeMinutes, originalSettings.snoozeMinutes);
      expect(deserializedSettings.maxSnoozes, originalSettings.maxSnoozes);
      expect(deserializedSettings, originalSettings);
    });

    testWidgets('should handle day selection correctly', (tester) async {
      final settings = ReminderSettings.defaultSettings;

      // Test isActiveOnDay method
      expect(settings.isActiveOnDay(1),
          isFalse); // Monday - disabled because enabled=false
      expect(
          settings.isActiveOnDay(6), isFalse); // Saturday - not in activeDays

      // Enable settings
      final enabledSettings = settings.copyWith(enabled: true);
      expect(enabledSettings.isActiveOnDay(1),
          isTrue); // Monday - should be active
      expect(enabledSettings.isActiveOnDay(6),
          isFalse); // Saturday - not in activeDays
      expect(enabledSettings.isActiveOnDay(7),
          isFalse); // Sunday - not in activeDays
    });

    testWidgets('should calculate work duration correctly', (tester) async {
      final settings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 30),
        clockOutTime: const TimeOfDay(hour: 17, minute: 15),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      final workDuration = settings.workDuration;
      expect(workDuration.inHours, 8); // 8 hours 45 minutes
      expect(workDuration.inMinutes, 525); // 8*60 + 45 = 525 minutes
    });

    testWidgets('should validate edge cases correctly', (tester) async {
      // Test empty active days
      final noActiveDaysSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {}, // Empty set
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(noActiveDaysSettings.validate(),
          contains('At least one active day must be selected'));

      // Test invalid day values
      final invalidDaysSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {0, 8}, // Invalid day values
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(invalidDaysSettings.validate(),
          contains('Active days must be between 1 (Monday) and 7 (Sunday)'));

      // Test invalid snooze settings
      final invalidSnoozeSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 0, // Invalid
        maxSnoozes: 10, // Invalid
      );

      final validationError = invalidSnoozeSettings.validate();
      expect(validationError, isNotNull);
      expect(
          validationError,
          anyOf([
            contains('Snooze minutes must be between 1 and 60'),
            contains('Maximum snoozes must be between 0 and 5'),
          ]));
    });
  });
}
