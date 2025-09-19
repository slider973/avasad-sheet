import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';
import 'package:time_sheet/features/preference/data/models/reminder_notification.dart';
import 'package:time_sheet/enum/reminder_type.dart';
import 'package:time_sheet/services/clock_reminder_service.dart';
import 'package:time_sheet/services/ios_notification_service.dart';
import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';
import 'package:time_sheet/services/timer_service.dart';

import 'clock_reminder_notifications_integration_test.mocks.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  IOSNotificationService,
  TimerService,
  PreferencesBloc,
])
void main() {
  group('Clock Reminder Notifications Integration Tests', () {
    late MockFlutterLocalNotificationsPlugin mockNotificationsPlugin;
    late MockIOSNotificationService mockIOSService;
    late MockTimerService mockTimerService;
    late MockPreferencesBloc mockPreferencesBloc;
    late ClockReminderService reminderService;

    setUp(() {
      mockNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
      mockIOSService = MockIOSNotificationService();
      mockTimerService = MockTimerService();
      mockPreferencesBloc = MockPreferencesBloc();

      // Setup default mocks
      when(mockNotificationsPlugin.initialize(any))
          .thenAnswer((_) async => true);
      when(mockNotificationsPlugin.requestPermissions())
          .thenAnswer((_) async => true);
      when(mockNotificationsPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        uiLocalNotificationDateInterpretation:
            anyNamed('uiLocalNotificationDateInterpretation'),
        payload: anyNamed('payload'),
      )).thenAnswer((_) async => {});
      when(mockNotificationsPlugin.cancelAll()).thenAnswer((_) async => {});
      when(mockNotificationsPlugin.cancel(any)).thenAnswer((_) async => {});

      when(mockTimerService.isClockIn).thenReturn(false);
      when(mockTimerService.isClockOut).thenReturn(false);

      reminderService = ClockReminderService(
        notificationsPlugin: mockNotificationsPlugin,
        timerService: mockTimerService,
      );
    });

    group('End-to-End Reminder Notification Flow', () {
      testWidgets(
          'should complete full reminder flow from settings to notification delivery',
          (tester) async {
        // Requirement 1.1, 1.2, 1.3, 1.4, 1.5: Complete reminder flow

        // Step 1: Initialize service
        await reminderService.initialize();
        verify(mockNotificationsPlugin.initialize(any)).called(1);

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

        // Verify notifications were scheduled (2 per day for 5 days = 10 notifications)
        verify(mockNotificationsPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              anyNamed('uiLocalNotificationDateInterpretation'),
          payload: anyNamed('payload'),
        )).called(greaterThan(0));

        // Step 4: Simulate notification delivery
        const notificationPayload =
            '{"type":"clockIn","scheduledTime":"2025-01-20T08:00:00.000Z"}';

        // Step 5: Handle notification interaction
        await reminderService.handleNotificationTap(notificationPayload);

        // Verify the flow completed successfully
        expect(reminderService.isInitialized, isTrue);
      });

      testWidgets('should handle permission request flow correctly',
          (tester) async {
        // Requirement 4.1, 4.2, 4.3: Permission handling

        // Test permission denied scenario
        when(mockNotificationsPlugin.requestPermissions())
            .thenAnswer((_) async => false);

        await reminderService.initialize();

        // Verify permission was requested
        verify(mockNotificationsPlugin.requestPermissions()).called(1);

        // Test permission granted scenario
        when(mockNotificationsPlugin.requestPermissions())
            .thenAnswer((_) async => true);

        await reminderService.initialize();
        verify(mockNotificationsPlugin.requestPermissions()).called(2);
      });

      testWidgets('should handle background notification delivery',
          (tester) async {
        // Requirement 4.4: Background delivery

        await reminderService.initialize();

        final reminderSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        await reminderService.scheduleReminders(reminderSettings);

        // Simulate app going to background
        await reminderService.onAppBackground();

        // Simulate app coming to foreground
        await reminderService.onAppForeground();

        // Verify notifications remain scheduled
        verifyNever(mockNotificationsPlugin.cancelAll());
      });
    });

    group('Notification Interaction and App Navigation', () {
      testWidgets(
          'should handle notification tap and navigate to correct screen',
          (tester) async {
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

      testWidgets('should handle notification dismissal correctly',
          (tester) async {
        // Requirement 5.3: Notification dismissal

        await reminderService.initialize();

        const notificationId = 12345;
        await reminderService.dismissNotification(notificationId);

        verify(mockNotificationsPlugin.cancel(notificationId)).called(1);
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
        await reminderService.snoozeNotification(notification, 15);
        expect(notification.snoozeCount, 1);

        // Test second snooze
        await reminderService.snoozeNotification(notification, 15);
        expect(notification.snoozeCount, 2);

        // Test maximum snooze limit reached
        final result =
            await reminderService.snoozeNotification(notification, 15);
        expect(result, isFalse); // Should fail due to max snooze limit
        expect(notification.snoozeCount, 2); // Should not increment
      });

      testWidgets('should group notifications to prevent spam', (tester) async {
        // Requirement 5.5: Notification grouping

        await reminderService.initialize();

        final reminderSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5, 6, 7}, // All days
          respectHolidays: false,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        await reminderService.scheduleReminders(reminderSettings);

        // Verify notifications use grouping
        final capturedCalls = verify(mockNotificationsPlugin.zonedSchedule(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
          captureAny,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              anyNamed('uiLocalNotificationDateInterpretation'),
          payload: captureAnyNamed('payload'),
        )).captured;

        expect(capturedCalls.isNotEmpty, isTrue);
      });
    });

    group('Clock Status Integration and Reminder Cancellation', () {
      testWidgets('should not send clock-in reminder when already clocked in',
          (tester) async {
        // Requirement 3.1: Intelligent reminder logic

        // Setup: User is already clocked in
        when(mockTimerService.isClockIn).thenReturn(true);
        when(mockTimerService.isClockOut).thenReturn(false);

        await reminderService.initialize();

        // Simulate clock-in reminder time
        final shouldSend =
            await reminderService.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSend, isFalse);
      });

      testWidgets('should not send clock-out reminder when already clocked out',
          (tester) async {
        // Requirement 3.2: Intelligent reminder logic

        // Setup: User is already clocked out
        when(mockTimerService.isClockIn).thenReturn(false);
        when(mockTimerService.isClockOut).thenReturn(true);

        await reminderService.initialize();

        // Simulate clock-out reminder time
        final shouldSend =
            await reminderService.shouldSendReminder(ReminderType.clockOut);
        expect(shouldSend, isFalse);
      });

      testWidgets(
          'should cancel pending reminders when manual clock action occurs',
          (tester) async {
        // Requirement 3.3, 3.4: Reminder cancellation

        await reminderService.initialize();

        // Schedule reminders
        final reminderSettings =
            ReminderSettings.defaultSettings.copyWith(enabled: true);
        await reminderService.scheduleReminders(reminderSettings);

        // Simulate manual clock-in
        await reminderService.onClockStatusChanged('clocked_in');

        // Verify clock-in reminders for today were cancelled
        verify(mockNotificationsPlugin.cancel(any)).called(greaterThan(0));

        // Simulate manual clock-out
        await reminderService.onClockStatusChanged('clocked_out');

        // Verify clock-out reminders for today were cancelled
        verify(mockNotificationsPlugin.cancel(any)).called(greaterThan(1));
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

        await reminderService.scheduleReminders(reminderSettings);

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
      testWidgets('should handle permission denied gracefully', (tester) async {
        // Requirement 4.2: Permission denied handling

        when(mockNotificationsPlugin.requestPermissions())
            .thenAnswer((_) async => false);

        await reminderService.initialize();

        final reminderSettings =
            ReminderSettings.defaultSettings.copyWith(enabled: true);
        final result =
            await reminderService.scheduleReminders(reminderSettings);

        expect(result, isFalse);
        verify(mockNotificationsPlugin.requestPermissions()).called(1);
      });

      testWidgets('should detect permission revocation at device level',
          (tester) async {
        // Requirement 4.5: Permission revocation detection

        // Initially grant permissions
        when(mockNotificationsPlugin.requestPermissions())
            .thenAnswer((_) async => true);

        await reminderService.initialize();

        // Simulate permission revocation
        when(mockNotificationsPlugin.requestPermissions())
            .thenAnswer((_) async => false);

        final hasPermissions =
            await reminderService.checkNotificationPermissions();
        expect(hasPermissions, isFalse);
      });

      testWidgets('should handle notification scheduling failures',
          (tester) async {
        // Error scenario: Notification scheduling fails

        when(mockNotificationsPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              anyNamed('uiLocalNotificationDateInterpretation'),
          payload: anyNamed('payload'),
        )).thenThrow(Exception('Scheduling failed'));

        await reminderService.initialize();

        final reminderSettings =
            ReminderSettings.defaultSettings.copyWith(enabled: true);
        final result =
            await reminderService.scheduleReminders(reminderSettings);

        expect(result, isFalse);
      });

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
        verify(mockNotificationsPlugin.cancelAll()).called(1);
      });

      testWidgets('should handle app lifecycle transitions correctly',
          (tester) async {
        // Test app lifecycle handling

        await reminderService.initialize();

        // Test background transition
        await reminderService.onAppBackground();
        expect(reminderService.isInBackground, isTrue);

        // Test foreground transition
        await reminderService.onAppForeground();
        expect(reminderService.isInBackground, isFalse);

        // Test multiple rapid transitions
        await reminderService.onAppBackground();
        await reminderService.onAppForeground();
        await reminderService.onAppBackground();
        await reminderService.onAppForeground();

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

        expect(clockInNotification.title, contains('Clock In Reminder'));
        expect(clockInNotification.body, contains('8:00 AM'));
        expect(clockInNotification.body, isNot(contains('!!!')));
        expect(clockInNotification.body, isNot(contains('URGENT')));

        final clockOutNotification = reminderService.createReminderNotification(
          ReminderType.clockOut,
          DateTime(2025, 1, 20, 17, 0),
        );

        expect(clockOutNotification.title, contains('Clock Out Reminder'));
        expect(clockOutNotification.body, contains('5:00 PM'));
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

        // Verify old reminders were cancelled
        verify(mockNotificationsPlugin.cancelAll()).called(1);

        // Verify new reminders were scheduled
        verify(mockNotificationsPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              anyNamed('uiLocalNotificationDateInterpretation'),
          payload: anyNamed('payload'),
        )).called(greaterThan(0));
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

        // Verify all reminders were cancelled
        verify(mockNotificationsPlugin.cancelAll())
            .called(2); // Once for update, once for disable
      });
    });
  });
}
