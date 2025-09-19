import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';
import 'package:time_sheet/features/preference/data/models/reminder_notification.dart';
import 'package:time_sheet/enum/reminder_type.dart';

void main() {
  group('Clock Reminder Notifications Integration Tests', () {
    group('End-to-End Reminder Notification Flow', () {
      testWidgets('should validate reminder settings flow', (tester) async {
        // Requirement 1.1, 1.2, 1.3: Complete reminder settings validation

        // Step 1: Create default settings (disabled by default)
        final defaultSettings = ReminderSettings.defaultSettings;
        expect(defaultSettings.enabled,
            isFalse); // Requirement 1.1: disabled by default

        // Step 2: Configure reminder settings
        final reminderSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5}, // Monday to Friday
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Step 3: Validate settings
        expect(reminderSettings.validate(), isNull); // Should be valid
        expect(reminderSettings.hasValidTimeConfiguration, isTrue);

        // Step 4: Test serialization
        final json = reminderSettings.toJson();
        final deserializedSettings = ReminderSettings.fromJson(json);
        expect(deserializedSettings, equals(reminderSettings));
      });

      testWidgets('should handle invalid settings correctly', (tester) async {
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
        expect(invalidSettings.validate(),
            contains('Clock-out time must be after clock-in time'));
        expect(invalidSettings.hasValidTimeConfiguration, isFalse);
      });
    });

    group('Notification Content and Professional Messaging', () {
      testWidgets('should create professional clock-in notifications',
          (tester) async {
        // Requirement 5.1, 5.2: Professional notification content

        final clockInNotification = ReminderNotification.clockIn(
          id: 1,
          scheduledTime: DateTime(2025, 1, 20, 8, 0),
        );

        expect(clockInNotification.type, ReminderType.clockIn);
        expect(clockInNotification.title, isNotEmpty);
        expect(clockInNotification.body, contains('8:00'));
        expect(clockInNotification.body, isNot(contains('!!!')));
        expect(clockInNotification.body, isNot(contains('URGENT')));
        expect(clockInNotification.payload, 'clock_in_reminder');
      });

      testWidgets('should create professional clock-out notifications',
          (tester) async {
        // Requirement 5.1, 5.2: Professional notification content

        final clockOutNotification = ReminderNotification.clockOut(
          id: 2,
          scheduledTime: DateTime(2025, 1, 20, 17, 0),
        );

        expect(clockOutNotification.type, ReminderType.clockOut);
        expect(clockOutNotification.title, isNotEmpty);
        expect(clockOutNotification.body, contains('5:00'));
        expect(clockOutNotification.body, isNot(contains('!!!')));
        expect(clockOutNotification.body, isNot(contains('URGENT')));
        expect(clockOutNotification.payload, 'clock_out_reminder');
      });

      testWidgets(
          'should handle snoozed notifications with professional content',
          (tester) async {
        // Requirement 5.4: Snooze functionality with professional messaging

        final originalNotification = ReminderNotification.clockIn(
          id: 1,
          scheduledTime: DateTime(2025, 1, 20, 8, 0),
        );

        final snoozedNotification =
            originalNotification.snooze(const Duration(minutes: 15));

        expect(snoozedNotification.snoozeCount, 1);
        expect(snoozedNotification.title, contains('Snoozed'));
        expect(snoozedNotification.body, contains('snoozed 1 time'));
        expect(
            snoozedNotification.scheduledTime
                .isAfter(originalNotification.scheduledTime),
            isTrue);
      });
    });

    group('Snooze Functionality and Limits', () {
      testWidgets('should handle snooze functionality with limits',
          (tester) async {
        // Requirement 5.4, 5.5: Snooze functionality

        final notification = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now(),
          title: 'Clock In Reminder',
          body: 'Time to clock in!',
          payload: '{"type":"clockIn"}',
          snoozeCount: 0,
        );

        // Test first snooze
        expect(notification.canSnooze(2), isTrue);
        final snoozed1 = notification.snooze(const Duration(minutes: 15));
        expect(snoozed1.snoozeCount, 1);

        // Test second snooze
        expect(snoozed1.canSnooze(2), isTrue);
        final snoozed2 = snoozed1.snooze(const Duration(minutes: 15));
        expect(snoozed2.snoozeCount, 2);

        // Test maximum snooze limit reached
        expect(snoozed2.canSnooze(2),
            isFalse); // Should fail due to max snooze limit
      });

      testWidgets(
          'should prevent snoozing delivered or cancelled notifications',
          (tester) async {
        final deliveredNotification = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now(),
          title: 'Clock In Reminder',
          body: 'Time to clock in!',
          payload: '{"type":"clockIn"}',
          isDelivered: true,
        );

        expect(deliveredNotification.canSnooze(2), isFalse);

        final cancelledNotification = ReminderNotification(
          id: 2,
          type: ReminderType.clockOut,
          scheduledTime: DateTime.now(),
          title: 'Clock Out Reminder',
          body: 'Time to clock out!',
          payload: '{"type":"clockOut"}',
          isCancelled: true,
        );

        expect(cancelledNotification.canSnooze(2), isFalse);
      });
    });

    group('Weekend and Holiday Handling', () {
      testWidgets('should respect weekend settings in reminder configuration',
          (tester) async {
        // Requirement 3.5: Weekend/holiday handling

        final weekdayOnlySettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5}, // Weekdays only
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Test weekday (should be active)
        expect(weekdayOnlySettings.isActiveOnDay(1), isTrue); // Monday
        expect(weekdayOnlySettings.isActiveOnDay(5), isTrue); // Friday

        // Test weekend (should not be active)
        expect(weekdayOnlySettings.isActiveOnDay(6), isFalse); // Saturday
        expect(weekdayOnlySettings.isActiveOnDay(7), isFalse); // Sunday

        final allDaysSettings = weekdayOnlySettings.copyWith(
          activeDays: {1, 2, 3, 4, 5, 6, 7}, // All days
        );

        // Test all days (should be active)
        expect(allDaysSettings.isActiveOnDay(6), isTrue); // Saturday
        expect(allDaysSettings.isActiveOnDay(7), isTrue); // Sunday
      });
    });

    group('Notification State Management', () {
      testWidgets('should track notification states correctly', (tester) async {
        final notification = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          title: 'Clock In Reminder',
          body: 'Time to clock in!',
          payload: '{"type":"clockIn"}',
        );

        // Test initial state
        expect(notification.isPending, isTrue);
        expect(notification.isOverdue, isFalse);
        expect(notification.isDelivered, isFalse);
        expect(notification.isCancelled, isFalse);

        // Test delivered state
        final deliveredNotification = notification.markAsDelivered();
        expect(deliveredNotification.isDelivered, isTrue);
        expect(deliveredNotification.isPending, isFalse);

        // Test cancelled state
        final cancelledNotification = notification.markAsCancelled();
        expect(cancelledNotification.isCancelled, isTrue);
        expect(cancelledNotification.isPending, isFalse);

        // Test overdue state
        final overdueNotification = ReminderNotification(
          id: 2,
          type: ReminderType.clockOut,
          scheduledTime: DateTime.now().subtract(const Duration(hours: 1)),
          title: 'Clock Out Reminder',
          body: 'Time to clock out!',
          payload: '{"type":"clockOut"}',
        );

        expect(overdueNotification.isOverdue, isTrue);
        expect(overdueNotification.isPending, isFalse);
      });
    });

    group('Notification Validation', () {
      testWidgets('should validate notification models correctly',
          (tester) async {
        // Test valid notification
        final validNotification = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          title: 'Test Reminder',
          body: 'Test body',
          payload: 'test_payload',
        );

        expect(validNotification.validate(), isNull);

        // Test invalid notification (empty title)
        final invalidNotification = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          title: '',
          body: 'Test body',
          payload: 'test_payload',
        );

        expect(invalidNotification.validate(), isNotNull);
        expect(
            invalidNotification.validate(), contains('title cannot be empty'));

        // Test invalid notification (negative ID)
        final negativeIdNotification = ReminderNotification(
          id: -1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          title: 'Test',
          body: 'Test body',
          payload: 'test_payload',
        );

        expect(negativeIdNotification.validate(),
            contains('ID must be non-negative'));
      });
    });

    group('Serialization and Persistence', () {
      testWidgets('should serialize and deserialize settings correctly',
          (tester) async {
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
        expect(deserializedSettings, equals(originalSettings));
      });

      testWidgets('should serialize and deserialize notifications correctly',
          (tester) async {
        final originalNotification = ReminderNotification(
          id: 123,
          type: ReminderType.clockOut,
          scheduledTime: DateTime(2025, 1, 20, 17, 0),
          title: 'Test Notification',
          body: 'Test body content',
          payload: 'test_payload',
          snoozeCount: 1,
        );

        // Serialize to JSON
        final json = originalNotification.toJson();

        // Deserialize from JSON
        final deserializedNotification = ReminderNotification.fromJson(json);

        // Verify all properties match
        expect(deserializedNotification, equals(originalNotification));
      });

      testWidgets('should handle invalid JSON gracefully', (tester) async {
        // Test invalid settings JSON
        expect(() => ReminderSettings.fromJson({}),
            throwsA(isA<FormatException>()));

        // Test invalid notification JSON
        expect(() => ReminderNotification.fromJson({}),
            throwsA(isA<FormatException>()));
      });
    });

    group('Edge Cases and Error Scenarios', () {
      testWidgets('should handle edge cases in settings validation',
          (tester) async {
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

      testWidgets('should generate unique keys for notifications',
          (tester) async {
        final notification1 = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime(2025, 1, 20, 8, 0),
          title: 'Clock In',
          body: 'Time to clock in',
          payload: 'clock_in',
        );

        final notification2 = ReminderNotification(
          id: 2,
          type: ReminderType.clockOut,
          scheduledTime: DateTime(2025, 1, 20, 17, 0),
          title: 'Clock Out',
          body: 'Time to clock out',
          payload: 'clock_out',
        );

        final notification3 = ReminderNotification(
          id: 3,
          type: ReminderType.clockIn,
          scheduledTime: DateTime(2025, 1, 21, 8, 0), // Different day
          title: 'Clock In',
          body: 'Time to clock in',
          payload: 'clock_in',
        );

        expect(notification1.uniqueKey, isNot(equals(notification2.uniqueKey)));
        expect(notification1.uniqueKey, isNot(equals(notification3.uniqueKey)));
        expect(notification2.uniqueKey, isNot(equals(notification3.uniqueKey)));
      });
    });
  });
}
