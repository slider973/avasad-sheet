import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';
import 'package:time_sheet/features/preference/data/models/reminder_notification.dart';
import 'package:time_sheet/enum/reminder_type.dart';
import 'package:time_sheet/services/clock_reminder_service.dart';

void main() {
  group('Clock Reminder Notifications Integration Tests', () {
    late ClockReminderService reminderService;

    setUp(() {
      // Reset singleton instance for each test
      ClockReminderService.resetInstance();
      reminderService = ClockReminderService();
    });

    tearDown(() {
      reminderService.dispose();
    });

    group('End-to-End Reminder Notification Flow', () {
      testWidgets(
          'should complete full reminder flow from settings to notification delivery',
          (tester) async {
        // Requirement 1.1, 1.2, 1.3, 1.4, 1.5: Complete reminder flow

        // Step 1: Initialize service
        await reminderService.initialize();
        expect(reminderService.isInitialized, isTrue);

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

        // Step 3: Schedule reminders
        await reminderService.scheduleReminders(reminderSettings);

        // Verify settings were saved
        expect(reminderService.currentSettings, equals(reminderSettings));

        // Step 4: Test notification creation
        final clockInNotification = reminderService.createReminderNotification(
          ReminderType.clockIn,
          DateTime(2025, 1, 20, 8, 0),
        );

        expect(clockInNotification.type, ReminderType.clockIn);
        expect(clockInNotification.title, isNotEmpty);
        expect(clockInNotification.body, isNotEmpty);

        // Verify the flow completed successfully
        expect(reminderService.isInitialized, isTrue);
      });

      testWidgets('should handle settings disabled state correctly',
          (tester) async {
        // Test disabling reminders

        await reminderService.initialize();

        // Enable reminders first
        final enabledSettings =
            ReminderSettings.defaultSettings.copyWith(enabled: true);
        await reminderService.scheduleReminders(enabledSettings);

        // Disable reminders
        final disabledSettings = enabledSettings.copyWith(enabled: false);
        await reminderService.updateSettings(disabledSettings);

        // Verify settings were updated
        expect(reminderService.currentSettings?.enabled, isFalse);
      });
    });

    group('Notification Interaction and App Navigation', () {
      testWidgets('should handle notification tap correctly', (tester) async {
        // Requirement 1.5: Notification tap handling

        await reminderService.initialize();

        // Test clock-in notification tap
        const clockInPayload =
            '{"type":"clockIn","scheduledTime":"2025-01-20T08:00:00.000Z"}';
        await reminderService.handleNotificationTap(clockInPayload);

        // Test clock-out notification tap
        const clockOutPayload =
            '{"type":"clockOut","scheduledTime":"2025-01-20T17:00:00.000Z"}';
        await reminderService.handleNotificationTap(clockOutPayload);

        // Verify both payloads were processed
        expect(reminderService.lastProcessedPayload, isNotNull);
      });

      testWidgets('should handle snooze functionality with limits',
          (tester) async {
        // Requirement 5.4, 5.5: Snooze functionality

        await reminderService.initialize();

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
        final result1 =
            await reminderService.snoozeNotification(notification, 15);
        expect(result1, isTrue);
        expect(notification.snoozeCount, 1);

        // Test second snooze
        final result2 =
            await reminderService.snoozeNotification(notification, 15);
        expect(result2, isTrue);
        expect(notification.snoozeCount, 2);

        // Test maximum snooze limit reached
        final result3 =
            await reminderService.snoozeNotification(notification, 15);
        expect(result3, isFalse); // Should fail due to max snooze limit
        expect(notification.snoozeCount, 2); // Should not increment
      });
    });

    group('Clock Status Integration and Reminder Cancellation', () {
      testWidgets('should not send clock-in reminder when already clocked in',
          (tester) async {
        // Requirement 3.1: Intelligent reminder logic

        await reminderService.initialize();

        // Simulate user being clocked in
        await reminderService.onClockStatusChanged('Entrée');

        // Check if clock-in reminder should be sent
        final shouldSend =
            await reminderService.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSend, isFalse);
      });

      testWidgets('should not send clock-out reminder when already clocked out',
          (tester) async {
        // Requirement 3.2: Intelligent reminder logic

        await reminderService.initialize();

        // Simulate user being clocked out
        await reminderService.onClockStatusChanged('Sortie');

        // Check if clock-out reminder should be sent
        final shouldSend =
            await reminderService.shouldSendReminder(ReminderType.clockOut);
        expect(shouldSend, isFalse);
      });

      testWidgets('should respect weekend and holiday settings',
          (tester) async {
        // Requirement 3.5: Weekend/holiday handling

        await reminderService.initialize();

        final reminderSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5}, // Weekdays only
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Test weekend day (should not send reminder)
        final shouldSendOnWeekend =
            await reminderService.shouldSendReminderOnDay(
          DateTime(2025, 1, 25), // Saturday
          reminderSettings,
        );
        expect(shouldSendOnWeekend, isFalse);

        // Test weekday (should send reminder)
        final shouldSendOnWeekday =
            await reminderService.shouldSendReminderOnDay(
          DateTime(2025, 1, 20), // Monday
          reminderSettings,
        );
        expect(shouldSendOnWeekday, isTrue);
      });
    });

    group('Permission Handling and Error Scenarios', () {
      testWidgets('should handle invalid notification payload gracefully',
          (tester) async {
        // Error scenario: Invalid payload

        await reminderService.initialize();

        // Test with invalid JSON
        await reminderService.handleNotificationTap('invalid json');

        // Test with missing required fields
        await reminderService.handleNotificationTap('{"invalid":"payload"}');

        // Service should remain functional
        expect(reminderService.isInitialized, isTrue);
      });

      testWidgets('should handle service disposal correctly', (tester) async {
        // Error scenario: Service disposal

        await reminderService.initialize();

        final reminderSettings =
            ReminderSettings.defaultSettings.copyWith(enabled: true);
        await reminderService.scheduleReminders(reminderSettings);

        // Dispose service
        reminderService.dispose();

        // Verify cleanup
        expect(reminderService.isInitialized, isFalse);
      });

      testWidgets('should handle app lifecycle transitions correctly',
          (tester) async {
        // Test app lifecycle handling

        await reminderService.initialize();

        // Test background transition
        await reminderService.onAppBackgroundWithTracking();
        expect(reminderService.isInBackground, isTrue);

        // Test foreground transition
        await reminderService.onAppForegroundWithTracking();
        expect(reminderService.isInBackground, isFalse);

        // Test multiple rapid transitions
        await reminderService.onAppBackgroundWithTracking();
        await reminderService.onAppForegroundWithTracking();
        await reminderService.onAppBackgroundWithTracking();
        await reminderService.onAppForegroundWithTracking();

        // Service should remain stable
        expect(reminderService.isInitialized, isTrue);
      });
    });

    group('Professional Notification Content', () {
      testWidgets('should create professional reminder messages',
          (tester) async {
        // Requirement 5.1, 5.2: Professional notification content

        await reminderService.initialize();

        final clockInNotification = reminderService.createReminderNotification(
          ReminderType.clockIn,
          DateTime(2025, 1, 20, 8, 0),
        );

        expect(clockInNotification.title, isNotEmpty);
        expect(clockInNotification.body, contains('8:00'));
        expect(clockInNotification.body, isNot(contains('!!!')));
        expect(clockInNotification.body, isNot(contains('URGENT')));

        final clockOutNotification = reminderService.createReminderNotification(
          ReminderType.clockOut,
          DateTime(2025, 1, 20, 17, 0),
        );

        expect(clockOutNotification.title, isNotEmpty);
        expect(clockOutNotification.body, contains('5:00'));
        expect(clockOutNotification.body, isNot(contains('!!!')));
        expect(clockOutNotification.body, isNot(contains('URGENT')));
      });

      testWidgets('should include current time and action in notifications',
          (tester) async {
        // Requirement 5.2: Include time and action

        await reminderService.initialize();

        final now = DateTime(2025, 1, 20, 8, 30);
        final notification = reminderService.createReminderNotification(
          ReminderType.clockIn,
          now,
        );

        expect(notification.body, contains('8:30'));
        expect(
            notification.body,
            anyOf([
              contains('clock in'),
              contains('Clock In'),
              contains('start work'),
            ]));
      });
    });

    group('Settings Integration', () {
      testWidgets('should integrate with preferences system correctly',
          (tester) async {
        // Test integration with PreferencesBloc

        await reminderService.initialize();

        // Simulate settings change
        final newSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 9, minute: 0),
          clockOutTime: const TimeOfDay(hour: 18, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 30,
          maxSnoozes: 1,
        );

        await reminderService.updateSettings(newSettings);

        // Verify settings were updated
        expect(reminderService.currentSettings, equals(newSettings));
      });
    });

    group('Reminder Settings Validation', () {
      testWidgets('should validate reminder settings correctly',
          (tester) async {
        await reminderService.initialize();

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
      });
    });

    group('Notification Model Validation', () {
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
    });
  });
}
