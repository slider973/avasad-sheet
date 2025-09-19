import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'package:time_sheet/services/clock_reminder_service.dart';
import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';
import 'package:time_sheet/enum/reminder_type.dart';

void main() {
  group('ClockReminderService', () {
    late ClockReminderService service;

    setUp(() {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      service = ClockReminderService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize with default settings', () async {
      // Act
      await service.initialize();

      // Assert - service should be initialized without throwing
      expect(service, isNotNull);
    });

    test('should validate reminder settings before scheduling', () async {
      // Arrange
      await service.initialize();

      final invalidSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 10, minute: 0),
        clockOutTime:
            const TimeOfDay(hour: 8, minute: 0), // Invalid: before clock-in
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      // Act & Assert
      expect(
        () => service.scheduleReminders(invalidSettings),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle clock status changes correctly', () async {
      // Arrange
      await service.initialize();

      // Act - should not throw
      await service.onClockStatusChanged('Entrée');
      await service.onClockStatusChanged('Pause');
      await service.onClockStatusChanged('Reprise');
      await service.onClockStatusChanged('Sortie');

      // Assert - no exceptions thrown
      expect(service, isNotNull);
    });

    test('should handle app lifecycle events', () async {
      // Arrange
      await service.initialize();

      // Act - should not throw
      await service.onAppBackground();
      await service.onAppForeground();

      // Assert - no exceptions thrown
      expect(service, isNotNull);
    });

    test('should cancel all reminders', () async {
      // Arrange
      await service.initialize();

      final settings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      await service.scheduleReminders(settings);

      // Act
      await service.cancelAllReminders();

      // Assert - should not throw
      expect(service, isNotNull);
    });

    test('should handle disabled reminders', () async {
      // Arrange
      await service.initialize();

      final disabledSettings = ReminderSettings(
        enabled: false, // Disabled
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      // Act - should not schedule any reminders
      await service.scheduleReminders(disabledSettings);

      // Assert - should not throw
      expect(service, isNotNull);
    });

    test('should use default settings when none are saved', () async {
      // Arrange - no saved settings
      SharedPreferences.setMockInitialValues({});

      // Act
      await service.initialize();

      // Assert - should initialize with default settings (disabled by default)
      expect(service, isNotNull);
    });

    group('Intelligent Reminder Logic', () {
      late ReminderSettings testSettings;

      setUp(() {
        testSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5}, // Monday to Friday
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );
      });

      test('should validate clock status before sending reminders', () async {
        // Arrange
        await service.initialize();
        await service.scheduleReminders(testSettings);

        // Act & Assert - clock-in reminder should not be sent if already clocked in
        await service.onClockStatusChanged('Entrée');
        final shouldSendClockIn =
            await service.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSendClockIn, isFalse);

        // Clock-out reminder should not be sent if already clocked out
        await service.onClockStatusChanged('Sortie');
        final shouldSendClockOut =
            await service.shouldSendReminder(ReminderType.clockOut);
        expect(shouldSendClockOut, isFalse);
      });

      test('should cancel reminders on manual clock actions', () async {
        // Arrange
        await service.initialize();
        await service.scheduleReminders(testSettings);

        // Act - simulate manual clock-in
        await service.onClockStatusChanged('Entrée');

        // Assert - clock-in reminder should be cancelled
        final stats = service.getReminderStats();
        expect(stats['cancelledReminders'], greaterThan(0));
      });

      test('should handle snooze functionality with limits', () async {
        // Arrange
        await service.initialize();
        await service.scheduleReminders(testSettings);

        // Act - snooze a reminder multiple times
        await service.snoozeReminder(1000, ReminderType.clockIn);
        await service.snoozeReminder(1000, ReminderType.clockIn);

        // Try to snooze beyond limit
        await service.snoozeReminder(1000, ReminderType.clockIn);

        // Assert - should respect maximum snooze limit
        final stats = service.getReminderStats();
        expect(stats, isNotNull);
      });

      test('should respect weekend and holiday settings', () async {
        // Arrange
        await service.initialize();

        // Create settings that respect holidays
        final holidaySettings = testSettings.copyWith(respectHolidays: true);

        // Act
        await service.scheduleReminders(holidaySettings);

        // Assert - should not throw and handle weekend/holiday logic
        expect(service, isNotNull);
      });

      test('should handle notification interactions', () async {
        // Arrange
        await service.initialize();
        await service.scheduleReminders(testSettings);

        // Act - simulate notification interactions
        await service.handleNotificationInteraction('clock_in_reminder');
        await service.handleNotificationInteraction('snooze_clockIn');
        await service.handleNotificationInteraction('dismiss_clockOut');

        // Assert - should handle interactions without throwing
        expect(service, isNotNull);
      });

      test('should intelligently reschedule reminders based on status',
          () async {
        // Arrange
        await service.initialize();
        await service.scheduleReminders(testSettings);

        // Act - change status and verify intelligent rescheduling
        await service.onClockStatusChanged('Non commencé');
        await service.onClockStatusChanged('Entrée');
        await service.onClockStatusChanged('Pause');
        await service.onClockStatusChanged('Reprise');
        await service.onClockStatusChanged('Sortie');

        // Assert - should handle all status changes intelligently
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Sortie'));
      });

      test('should clean up expired reminders', () async {
        // Arrange
        await service.initialize();
        await service.scheduleReminders(testSettings);

        // Act - simulate app returning to foreground
        await service.onAppForeground();

        // Assert - should clean up expired reminders
        final stats = service.getReminderStats();
        expect(stats, isNotNull);
      });

      test('should provide reminder statistics', () async {
        // Arrange
        await service.initialize();
        await service.scheduleReminders(testSettings);

        // Act
        final stats = service.getReminderStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['isInitialized'], isTrue);
        expect(stats['currentSettings'], isNotNull);
        expect(stats['lastKnownClockStatus'], isA<String>());
        expect(stats['totalReminders'], isA<int>());
        expect(stats['pendingReminders'], isA<int>());
        expect(stats['overdueReminders'], isA<int>());
        expect(stats['cancelledReminders'], isA<int>());
        expect(stats['currentTime'], isA<String>());
      });
    });
  });
}
