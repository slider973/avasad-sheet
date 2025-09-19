import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:time_sheet/services/ios_notification_service.dart';
import 'package:time_sheet/services/timer_service.dart';
import 'package:time_sheet/features/pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';
import 'package:time_sheet/features/preference/data/models/reminder_notification.dart';
import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';
import 'package:time_sheet/enum/reminder_type.dart';

import 'dynamic_multiplatform_notification_service_reminder_test.mocks.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  TimeSheetBloc,
  PreferencesBloc,
  TimerService,
  AndroidFlutterLocalNotificationsPlugin,
  IOSFlutterLocalNotificationsPlugin,
])
void main() {
  setUpAll(() {
    // Initialize timezone data for tests
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  group('DynamicMultiplatformNotificationService - Reminder Tests', () {
    late DynamicMultiplatformNotificationService notificationService;
    late MockFlutterLocalNotificationsPlugin mockNotificationsPlugin;
    late MockTimeSheetBloc mockTimeSheetBloc;
    late MockPreferencesBloc mockPreferencesBloc;
    late MockTimerService mockTimerService;

    setUp(() {
      mockNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
      mockTimeSheetBloc = MockTimeSheetBloc();
      mockPreferencesBloc = MockPreferencesBloc();
      mockTimerService = MockTimerService();

      notificationService = DynamicMultiplatformNotificationService(
        flutterLocalNotificationsPlugin: mockNotificationsPlugin,
        timeSheetBloc: mockTimeSheetBloc,
        preferencesBloc: mockPreferencesBloc,
        timerService: mockTimerService,
      );

      // Setup default mock behaviors
      when(mockTimerService.currentState).thenReturn('Non commencé');
    });

    group('scheduleReminderNotification', () {
      test('should schedule reminder notification successfully', () async {
        // Arrange
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        );
        final settings = ReminderSettings.defaultSettings;

        when(mockNotificationsPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async {});

        // Act
        final result = await notificationService.scheduleReminderNotification(
          reminder,
          settings,
        );

        // Assert
        expect(result, isTrue);
        verify(mockNotificationsPlugin.zonedSchedule(
          1000,
          'Time to Clock In',
          any,
          any,
          any,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'clock_in_reminder',
        )).called(1);
      });

      test('should not schedule clock-in reminder when already clocked in',
          () async {
        // Arrange
        when(mockTimerService.currentState).thenReturn('Entrée');

        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        );
        final settings = ReminderSettings.defaultSettings;

        // Act
        final result = await notificationService.scheduleReminderNotification(
          reminder,
          settings,
        );

        // Assert
        expect(result, isFalse);
        verifyNever(mockNotificationsPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        ));
      });

      test('should not schedule clock-out reminder when already clocked out',
          () async {
        // Arrange
        when(mockTimerService.currentState).thenReturn('Sortie');

        final reminder = ReminderNotification.clockOut(
          id: 1001,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        );
        final settings = ReminderSettings.defaultSettings;

        // Act
        final result = await notificationService.scheduleReminderNotification(
          reminder,
          settings,
        );

        // Assert
        expect(result, isFalse);
        verifyNever(mockNotificationsPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        ));
      });

      test('should not schedule reminder for weekend', () async {
        // Arrange
        final saturday = DateTime(2024, 1, 6); // A Saturday
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: saturday,
        );
        final settings = ReminderSettings.defaultSettings;

        // Act
        final result = await notificationService.scheduleReminderNotification(
          reminder,
          settings,
        );

        // Assert
        expect(result, isFalse);
        verifyNever(mockNotificationsPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        ));
      });

      test('should not schedule reminder in the past', () async {
        // Arrange
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now().subtract(const Duration(hours: 1)),
        );
        final settings = ReminderSettings.defaultSettings;

        // Act
        final result = await notificationService.scheduleReminderNotification(
          reminder,
          settings,
        );

        // Assert
        expect(result, isFalse);
        verifyNever(mockNotificationsPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        ));
      });
    });

    group('cancelReminderNotification', () {
      test('should cancel specific reminder notification', () async {
        // Arrange
        const notificationId = 1000;
        when(mockNotificationsPlugin.cancel(notificationId))
            .thenAnswer((_) async {});

        // Act
        await notificationService.cancelReminderNotification(notificationId);

        // Assert
        verify(mockNotificationsPlugin.cancel(notificationId)).called(1);
      });
    });

    group('cancelAllReminderNotifications', () {
      test('should cancel all reminder notifications', () async {
        // Arrange
        when(mockNotificationsPlugin.cancel(any)).thenAnswer((_) async {});

        // Act
        await notificationService.cancelAllReminderNotifications();

        // Assert
        verify(mockNotificationsPlugin.cancel(1000)).called(1); // Clock-in
        verify(mockNotificationsPlugin.cancel(1001)).called(1); // Clock-out
      });
    });

    group('snoozeReminderNotification', () {
      test('should snooze reminder notification successfully', () async {
        // Arrange
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now(),
          snoozeCount: 0,
        );
        final settings = ReminderSettings.defaultSettings;

        when(mockNotificationsPlugin.cancel(any)).thenAnswer((_) async {});
        when(mockNotificationsPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async {});

        // Act
        final result = await notificationService.snoozeReminderNotification(
          reminder,
          settings,
        );

        // Assert
        expect(result, isTrue);
        verify(mockNotificationsPlugin.cancel(1000)).called(1);
        verify(mockNotificationsPlugin.zonedSchedule(
          1000,
          'Time to Clock In',
          argThat(contains('Snoozed 1x')),
          any,
          any,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'clock_in_reminder',
        )).called(1);
      });

      test('should not snooze when maximum snoozes reached', () async {
        // Arrange
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now(),
          snoozeCount: 2, // Already at max snoozes
        );
        final settings =
            ReminderSettings.defaultSettings.copyWith(maxSnoozes: 2);

        // Act
        final result = await notificationService.snoozeReminderNotification(
          reminder,
          settings,
        );

        // Assert
        expect(result, isFalse);
        verifyNever(mockNotificationsPlugin.cancel(any));
        verifyNever(mockNotificationsPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        ));
      });
    });

    group('getPendingReminderNotifications', () {
      test('should return pending reminder notifications', () async {
        // Arrange
        final pendingNotifications = <PendingNotificationRequest>[
          PendingNotificationRequest(
            1000,
            'Time to Clock In',
            'Good morning! Time to start your workday.',
            'clock_in_reminder',
          ),
          PendingNotificationRequest(
            1001,
            'Time to Clock Out',
            'End of workday! Time to clock out.',
            'clock_out_reminder',
          ),
          PendingNotificationRequest(
            500, // Non-reminder notification
            'Other notification',
            'This is not a reminder',
            'other',
          ),
        ];

        when(mockNotificationsPlugin.pendingNotificationRequests())
            .thenAnswer((_) async => pendingNotifications);

        // Act
        final result =
            await notificationService.getPendingReminderNotifications();

        // Assert
        expect(result,
            hasLength(2)); // Only reminder notifications (IDs 1000-1999)
        expect(result.map((n) => n.id), containsAll([1000, 1001]));
      });
    });
  });
}
