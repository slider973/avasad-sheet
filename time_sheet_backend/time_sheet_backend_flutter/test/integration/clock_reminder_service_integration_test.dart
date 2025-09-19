import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';
import 'package:time_sheet/features/preference/data/models/reminder_notification.dart';
import 'package:time_sheet/enum/reminder_type.dart';
import 'package:time_sheet/services/clock_reminder_service.dart';
import 'package:time_sheet/services/timer_service.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';

import 'clock_reminder_service_integration_test.mocks.dart';

@GenerateMocks([
  TimerService,
  WeekendDetectionService,
])
void main() {
  group('Clock Reminder Service Integration Tests', () {
    late ClockReminderService reminderService;
    late MockTimerService mockTimerService;
    late MockWeekendDetectionService mockWeekendService;

    setUp(() {
      mockTimerService = MockTimerService();
      mockWeekendService = MockWeekendDetectionService();

      // Setup default mocks
      when(mockTimerService.currentState).thenReturn('Non commencé');
      when(mockWeekendService.isWeekend(any)).thenReturn(false);

      // Reset singleton and create new instance with mocks
      ClockReminderService.resetInstance();
      reminderService = ClockReminderService(
        timerService: mockTimerService,
        weekendDetectionService: mockWeekendService,
      );
    });

    tearDown(() {
      reminderService.dispose();
    });

    group('Clock Status Integration', () {
      testWidgets('should not send clock-in reminder when already clocked in',
          (tester) async {
        // Requirement 3.1: Intelligent reminder logic

        // Setup: User is already clocked in
        when(mockTimerService.currentState).thenReturn('Entrée');

        // Check if clock-in reminder should be sent
        final shouldSend =
            await reminderService.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSend, isFalse);
      });

      testWidgets('should not send clock-out reminder when already clocked out',
          (tester) async {
        // Requirement 3.2: Intelligent reminder logic

        // Setup: User is already clocked out
        when(mockTimerService.currentState).thenReturn('Sortie');

        // Check if clock-out reminder should be sent
        final shouldSend =
            await reminderService.shouldSendReminder(ReminderType.clockOut);
        expect(shouldSend, isFalse);
      });

      testWidgets('should send clock-in reminder when not started',
          (tester) async {
        // Setup: User has not started work
        when(mockTimerService.currentState).thenReturn('Non commencé');

        // Check if clock-in reminder should be sent
        final shouldSend =
            await reminderService.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSend, isTrue);
      });

      testWidgets('should send clock-out reminder when working',
          (tester) async {
        // Setup: User is working
        when(mockTimerService.currentState).thenReturn('Entrée');

        // Check if clock-out reminder should be sent
        final shouldSend =
            await reminderService.shouldSendReminder(ReminderType.clockOut);
        expect(shouldSend, isTrue);
      });

      testWidgets('should handle pause status correctly', (tester) async {
        // Setup: User is on pause
        when(mockTimerService.currentState).thenReturn('Pause');

        // Clock-in reminder should not be sent (already at work)
        final shouldSendClockIn =
            await reminderService.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSendClockIn, isFalse);

        // Clock-out reminder should be sent (still at work)
        final shouldSendClockOut =
            await reminderService.shouldSendReminder(ReminderType.clockOut);
        expect(shouldSendClockOut, isTrue);
      });

      testWidgets('should handle resume status correctly', (tester) async {
        // Setup: User resumed work
        when(mockTimerService.currentState).thenReturn('Reprise');

        // Clock-in reminder should not be sent (already at work)
        final shouldSendClockIn =
            await reminderService.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSendClockIn, isFalse);

        // Clock-out reminder should be sent (still at work)
        final shouldSendClockOut =
            await reminderService.shouldSendReminder(ReminderType.clockOut);
        expect(shouldSendClockOut, isTrue);
      });
    });

    group('Weekend and Holiday Integration', () {
      testWidgets('should respect weekend settings', (tester) async {
        // Requirement 3.5: Weekend/holiday handling

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
        when(mockWeekendService.isWeekend(any)).thenReturn(true);
        final shouldSendOnWeekend =
            await reminderService.shouldSendReminderOnDay(
          DateTime(2025, 1, 25), // Saturday
          reminderSettings,
        );
        expect(shouldSendOnWeekend, isFalse);

        // Test weekday (should send reminder)
        when(mockWeekendService.isWeekend(any)).thenReturn(false);
        final shouldSendOnWeekday =
            await reminderService.shouldSendReminderOnDay(
          DateTime(2025, 1, 20), // Monday
          reminderSettings,
        );
        expect(shouldSendOnWeekday, isTrue);
      });

      testWidgets('should handle weekend work when configured', (tester) async {
        final weekendWorkSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5, 6, 7}, // All days including weekends
          respectHolidays: false, // Don't respect holidays
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Test weekend day with weekend work enabled
        when(mockWeekendService.isWeekend(any)).thenReturn(true);
        final shouldSendOnWeekend =
            await reminderService.shouldSendReminderOnDay(
          DateTime(2025, 1, 25), // Saturday
          weekendWorkSettings,
        );
        expect(shouldSendOnWeekend,
            isTrue); // Should send because weekend work is enabled
      });
    });

    group('Notification Creation and Content', () {
      testWidgets('should create professional clock-in notifications',
          (tester) async {
        // Requirement 5.1, 5.2: Professional notification content

        final clockInNotification = reminderService.createReminderNotification(
          ReminderType.clockIn,
          DateTime(2025, 1, 20, 8, 0),
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

        final clockOutNotification = reminderService.createReminderNotification(
          ReminderType.clockOut,
          DateTime(2025, 1, 20, 17, 0),
        );

        expect(clockOutNotification.type, ReminderType.clockOut);
        expect(clockOutNotification.title, isNotEmpty);
        expect(clockOutNotification.body, contains('5:00'));
        expect(clockOutNotification.body, isNot(contains('!!!')));
        expect(clockOutNotification.body, isNot(contains('URGENT')));
        expect(clockOutNotification.payload, 'clock_out_reminder');
      });
    });

    group('Snooze Functionality Integration', () {
      testWidgets('should handle snooze functionality correctly',
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
        final result1 =
            await reminderService.snoozeNotification(notification, 15);
        expect(result1, isTrue);
        expect(notification.snoozeCount, 1);

        // Test second snooze
        final result2 =
            await reminderService.snoozeNotification(notification, 15);
        expect(result2, isTrue);
        expect(notification.snoozeCount, 2);

        // Test maximum snooze limit reached (default max is 2)
        final result3 =
            await reminderService.snoozeNotification(notification, 15);
        expect(result3, isFalse); // Should fail due to max snooze limit
        expect(notification.snoozeCount, 2); // Should not increment
      });
    });

    group('App Lifecycle Integration', () {
      testWidgets('should handle app lifecycle transitions', (tester) async {
        // Test app lifecycle handling

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
        expect(reminderService.isInBackground, isFalse);
      });
    });

    group('Clock Status Change Integration', () {
      testWidgets('should handle clock status changes correctly',
          (tester) async {
        // Requirement 3.3, 3.4: Reminder cancellation on manual actions

        // Test clock-in status change
        await reminderService.onClockStatusChanged('Entrée');
        expect(reminderService.lastKnownClockStatus, 'Entrée');

        // Test clock-out status change
        await reminderService.onClockStatusChanged('Sortie');
        expect(reminderService.lastKnownClockStatus, 'Sortie');

        // Test pause status change
        await reminderService.onClockStatusChanged('Pause');
        expect(reminderService.lastKnownClockStatus, 'Pause');

        // Test resume status change
        await reminderService.onClockStatusChanged('Reprise');
        expect(reminderService.lastKnownClockStatus, 'Reprise');
      });

      testWidgets('should handle TimeSheet state changes', (tester) async {
        // Test TimeSheet state integration

        await reminderService.onTimeSheetStateChanged('Entrée');
        expect(reminderService.lastKnownClockStatus, 'Entrée');

        await reminderService.onTimeSheetStateChanged('Sortie');
        expect(reminderService.lastKnownClockStatus, 'Sortie');
      });
    });

    group('Notification Interaction Integration', () {
      testWidgets('should handle notification tap correctly', (tester) async {
        // Requirement 1.5: Notification tap handling

        // Test clock-in notification tap
        const clockInPayload =
            '{"type":"clockIn","scheduledTime":"2025-01-20T08:00:00.000Z"}';
        await reminderService.handleNotificationTap(clockInPayload);
        expect(reminderService.lastProcessedPayload, clockInPayload);

        // Test clock-out notification tap
        const clockOutPayload =
            '{"type":"clockOut","scheduledTime":"2025-01-20T17:00:00.000Z"}';
        await reminderService.handleNotificationTap(clockOutPayload);
        expect(reminderService.lastProcessedPayload, clockOutPayload);
      });

      testWidgets('should handle invalid notification payloads gracefully',
          (tester) async {
        // Error scenario: Invalid payload

        // Test with invalid JSON
        await reminderService.handleNotificationTap('invalid json');
        expect(reminderService.lastProcessedPayload, 'invalid json');

        // Test with missing required fields
        await reminderService.handleNotificationTap('{"invalid":"payload"}');
        expect(reminderService.lastProcessedPayload, '{"invalid":"payload"}');

        // Service should remain functional (no exceptions thrown)
      });
    });

    group('Settings Integration', () {
      testWidgets('should handle settings updates correctly', (tester) async {
        // Test settings integration

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

        // Verify settings were updated (this would normally be persisted)
        expect(reminderService.currentSettings, equals(newSettings));
      });

      testWidgets('should handle disabled settings correctly', (tester) async {
        // Test disabling reminders

        final disabledSettings =
            ReminderSettings.defaultSettings.copyWith(enabled: false);
        await reminderService.updateSettings(disabledSettings);

        // Verify settings were updated
        expect(reminderService.currentSettings?.enabled, isFalse);
      });
    });

    group('Permission Integration', () {
      testWidgets('should handle permission checks', (tester) async {
        // Test permission handling (in test environment, should return true)
        final hasPermissions =
            await reminderService.checkNotificationPermissions();
        expect(hasPermissions, isTrue); // Should be true in test environment
      });
    });

    group('Service State Management', () {
      testWidgets('should track service state correctly', (tester) async {
        // Test service state tracking

        // Initially not initialized
        expect(reminderService.isInitialized, isFalse);

        // After initialization (skipped in test to avoid SharedPreferences)
        // expect(reminderService.isInitialized, isTrue);

        // Test disposal
        reminderService.dispose();
        expect(reminderService.isInitialized, isFalse);
      });

      testWidgets('should provide reminder statistics', (tester) async {
        // Test reminder statistics

        final stats = reminderService.getReminderStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('isInitialized'), isTrue);
        expect(stats.containsKey('lastKnownClockStatus'), isTrue);
        expect(stats.containsKey('totalReminders'), isTrue);
        expect(stats.containsKey('pendingReminders'), isTrue);
        expect(stats.containsKey('overdueReminders'), isTrue);
        expect(stats.containsKey('cancelledReminders'), isTrue);
        expect(stats.containsKey('currentTime'), isTrue);
      });
    });

    group('Error Handling Integration', () {
      testWidgets('should handle service errors gracefully', (tester) async {
        // Test error scenarios

        // Test with null timer service
        ClockReminderService.resetInstance();
        final serviceWithoutTimer = ClockReminderService();

        // Should not throw exceptions
        await serviceWithoutTimer.onClockStatusChanged('Entrée');
        final shouldSend =
            await serviceWithoutTimer.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSend,
            isFalse); // Should default to false when no timer service

        serviceWithoutTimer.dispose();
      });

      testWidgets('should handle weekend service errors gracefully',
          (tester) async {
        // Test with weekend service that throws
        when(mockWeekendService.isWeekend(any))
            .thenThrow(Exception('Weekend service error'));

        final reminderSettings =
            ReminderSettings.defaultSettings.copyWith(enabled: true);

        // Should not throw exceptions and default to allowing reminders
        final shouldSend = await reminderService.shouldSendReminderOnDay(
          DateTime(2025, 1, 20),
          reminderSettings,
        );
        expect(shouldSend, isTrue); // Should default to true on error
      });
    });
  });
}
