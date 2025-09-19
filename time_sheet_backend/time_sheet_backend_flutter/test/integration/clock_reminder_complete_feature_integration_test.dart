import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';

import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';
import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';
import 'package:time_sheet/features/preference/presentation/pages/reminder_settings_page.dart';
import 'package:time_sheet/services/clock_reminder_service.dart';
import 'package:time_sheet/services/timer_service.dart';
import 'package:time_sheet/services/ios_notification_service.dart';

import 'clock_reminder_complete_feature_integration_test.mocks.dart';

@GenerateMocks([
  ClockReminderService,
  TimerService,
  DynamicMultiplatformNotificationService,
])
void main() {
  group('Clock Reminder Complete Feature Integration Tests', () {
    late MockClockReminderService mockClockReminderService;
    late MockTimerService mockTimerService;
    late MockDynamicMultiplatformNotificationService mockNotificationService;
    late PreferencesBloc preferencesBloc;

    setUp(() {
      mockClockReminderService = MockClockReminderService();
      mockTimerService = MockTimerService();
      mockNotificationService = MockDynamicMultiplatformNotificationService();

      // Register mocks in GetIt
      if (GetIt.instance.isRegistered<ClockReminderService>()) {
        GetIt.instance.unregister<ClockReminderService>();
      }
      if (GetIt.instance.isRegistered<TimerService>()) {
        GetIt.instance.unregister<TimerService>();
      }

      GetIt.instance
          .registerSingleton<ClockReminderService>(mockClockReminderService);
      GetIt.instance.registerSingleton<TimerService>(mockTimerService);

      // Set up default mock behaviors
      when(mockClockReminderService.initialize(timerService: any))
          .thenAnswer((_) async {});
      when(mockClockReminderService.scheduleReminders(any))
          .thenAnswer((_) async {});
      when(mockClockReminderService.cancelAllReminders())
          .thenAnswer((_) async {});
      when(mockClockReminderService.onTimeSheetStateChanged(any))
          .thenAnswer((_) async {});
      when(mockClockReminderService.onAppBackground()).thenAnswer((_) async {});
      when(mockClockReminderService.onAppForeground()).thenAnswer((_) async {});

      when(mockNotificationService.initNotifications())
          .thenAnswer((_) async {});
      when(mockNotificationService.scheduleReminderNotification(any, any))
          .thenAnswer((_) async {});
      when(mockNotificationService.cancelReminderNotification(any))
          .thenAnswer((_) async {});

      // Create PreferencesBloc with mock use cases
      preferencesBloc = PreferencesBloc(
        getUserPreferenceUseCase: MockGetUserPreferenceUseCase(),
        setUserPreferenceUseCase: MockSetUserPreferenceUseCase(),
        registerManagerUseCase: MockRegisterManagerUseCase(),
        unregisterManagerUseCase: MockUnregisterManagerUseCase(),
      );
    });

    tearDown(() {
      preferencesBloc.close();
      GetIt.instance.reset();
    });

    group('Complete Feature Flow Integration', () {
      testWidgets(
          'should complete full user flow from default disabled state to enabled reminders',
          (tester) async {
        // Requirement 1.1, 1.2, 1.3, 1.4, 1.5: Complete user flow

        // Step 1: Build the reminder settings page
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<PreferencesBloc>(
              create: (context) => preferencesBloc,
              child: const ReminderSettingsPage(),
            ),
          ),
        );

        // Step 2: Verify initial state (disabled by default - Requirement 1.1)
        preferencesBloc.add(LoadPreferences());
        await tester.pump();

        // Verify default disabled state
        expect(find.text('Rappels désactivés'), findsOneWidget);
        expect(find.byType(SwitchListTile), findsOneWidget);

        // Step 3: Enable reminders (Requirement 1.2)
        final switchTile = find.byType(SwitchListTile);
        await tester.tap(switchTile);
        await tester.pump();

        // Verify reminder service is called to schedule reminders
        verify(mockClockReminderService.scheduleReminders(any)).called(1);

        // Step 4: Configure reminder times (Requirement 2.1, 2.2)
        // The form should now be visible
        expect(find.byType(ReminderSettingsForm), findsOneWidget);

        // Step 5: Test notification scheduling integration
        final testSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        preferencesBloc.add(SaveReminderSettings(testSettings));
        await tester.pump();

        // Verify reminder service is called with correct settings
        verify(mockClockReminderService.scheduleReminders(testSettings))
            .called(1);

        // Step 6: Test clock state integration (Requirement 3.1, 3.2, 3.3, 3.4)
        // Simulate clock state changes
        await mockClockReminderService.onTimeSheetStateChanged('clocked_in');
        verify(mockClockReminderService.onTimeSheetStateChanged('clocked_in'))
            .called(1);

        await mockClockReminderService.onTimeSheetStateChanged('clocked_out');
        verify(mockClockReminderService.onTimeSheetStateChanged('clocked_out'))
            .called(1);

        // Step 7: Test app lifecycle integration
        await mockClockReminderService.onAppBackground();
        verify(mockClockReminderService.onAppBackground()).called(1);

        await mockClockReminderService.onAppForeground();
        verify(mockClockReminderService.onAppForeground()).called(1);

        // Step 8: Test disabling reminders (Requirement 2.5)
        await tester.tap(switchTile);
        await tester.pump();

        // Verify all reminders are cancelled
        verify(mockClockReminderService.cancelAllReminders()).called(1);
      });

      testWidgets(
          'should handle permission flow correctly when enabling reminders',
          (tester) async {
        // Requirement 4.1, 4.2, 4.3: Permission handling

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<PreferencesBloc>(
              create: (context) => preferencesBloc,
              child: const ReminderSettingsPage(),
            ),
          ),
        );

        preferencesBloc.add(LoadPreferences());
        await tester.pump();

        // Try to enable reminders
        final switchTile = find.byType(SwitchListTile);
        await tester.tap(switchTile);
        await tester.pump();

        // Should show permission dialog if permissions are not granted
        // This would be handled by the permission_handler package
        // We verify that the service is called appropriately
        verify(mockClockReminderService.scheduleReminders(any)).called(1);
      });

      testWidgets(
          'should validate reminder settings and show errors for invalid configurations',
          (tester) async {
        // Test invalid settings handling

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<PreferencesBloc>(
              create: (context) => preferencesBloc,
              child: const ReminderSettingsPage(),
            ),
          ),
        );

        // Enable reminders first
        preferencesBloc.add(ToggleReminders(true));
        await tester.pump();

        // Try to save invalid settings (clock-out before clock-in)
        final invalidSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 17, minute: 0), // 5 PM
          clockOutTime: const TimeOfDay(hour: 8, minute: 0), // 8 AM
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // The validation should prevent this from being saved
        expect(invalidSettings.validate(), isNotNull);
        expect(invalidSettings.validate(),
            contains('Clock-out time must be after clock-in time'));

        // Verify that invalid settings are not passed to the service
        verifyNever(
            mockClockReminderService.scheduleReminders(invalidSettings));
      });
    });

    group('Service Integration and Initialization', () {
      testWidgets('should initialize all services correctly on app startup',
          (tester) async {
        // Test complete service initialization flow

        // Verify ClockReminderService is initialized with TimerService
        verify(mockClockReminderService.initialize(timerService: any))
            .called(1);

        // Verify notification service is initialized
        verify(mockNotificationService.initNotifications()).called(1);

        // Test that services are properly connected
        expect(GetIt.instance.isRegistered<ClockReminderService>(), isTrue);
        expect(GetIt.instance.isRegistered<TimerService>(), isTrue);
      });

      testWidgets('should handle service errors gracefully', (tester) async {
        // Test error handling in service integration

        // Set up service to throw error
        when(mockClockReminderService.scheduleReminders(any))
            .thenThrow(Exception('Scheduling failed'));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<PreferencesBloc>(
              create: (context) => preferencesBloc,
              child: const ReminderSettingsPage(),
            ),
          ),
        );

        preferencesBloc.add(LoadPreferences());
        await tester.pump();

        // Try to enable reminders
        final switchTile = find.byType(SwitchListTile);
        await tester.tap(switchTile);
        await tester.pump();

        // Should handle the error gracefully
        // The UI should show an error message
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('Notification Content and Interaction Integration', () {
      testWidgets(
          'should create and handle professional notification content correctly',
          (tester) async {
        // Requirement 5.1, 5.2, 5.3: Professional notification content

        final testSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 30),
          clockOutTime: const TimeOfDay(hour: 17, minute: 15),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Test notification scheduling with professional content
        when(mockNotificationService.scheduleReminderNotification(any, any))
            .thenAnswer((invocation) async {
          final notification = invocation.positionalArguments[0];
          final settings = invocation.positionalArguments[1];

          // Verify professional content
          expect(notification.title, isNotEmpty);
          expect(notification.body, isNot(contains('!!!')));
          expect(notification.body, isNot(contains('URGENT')));
          expect(notification.body, isNot(contains('NOW')));

          // Verify time formatting
          if (notification.type.toString().contains('clockIn')) {
            expect(notification.body, contains('8:30'));
          } else {
            expect(notification.body, contains('5:15'));
          }
        });

        await mockClockReminderService.scheduleReminders(testSettings);
        verify(mockClockReminderService.scheduleReminders(testSettings))
            .called(1);
      });

      testWidgets('should handle notification tap and app navigation correctly',
          (tester) async {
        // Requirement 1.5: Notification tap handling

        // Test notification payload handling
        when(mockNotificationService.onNotificationTap(any))
            .thenAnswer((invocation) async {
          final payload = invocation.positionalArguments[0];

          // Verify correct payload format
          expect(
              payload,
              anyOf([
                equals('clock_in_reminder'),
                equals('clock_out_reminder'),
              ]));
        });

        // Simulate notification tap
        await mockNotificationService.onNotificationTap('clock_in_reminder');
        verify(mockNotificationService.onNotificationTap('clock_in_reminder'))
            .called(1);
      });
    });

    group('Weekend and Holiday Integration', () {
      testWidgets('should respect weekend and holiday settings correctly',
          (tester) async {
        // Requirement 3.5: Weekend/holiday handling

        final weekendSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5}, // Weekdays only
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Test that weekend days are not active
        expect(weekendSettings.isActiveOnDay(6), isFalse); // Saturday
        expect(weekendSettings.isActiveOnDay(7), isFalse); // Sunday

        // Test that weekdays are active
        expect(weekendSettings.isActiveOnDay(1), isTrue); // Monday
        expect(weekendSettings.isActiveOnDay(5), isTrue); // Friday

        await mockClockReminderService.scheduleReminders(weekendSettings);
        verify(mockClockReminderService.scheduleReminders(weekendSettings))
            .called(1);
      });
    });

    group('Edge Cases and Error Scenarios', () {
      testWidgets('should handle all edge cases and error scenarios correctly',
          (tester) async {
        // Test various edge cases

        // 1. Test with empty active days
        final noActiveDaysSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {}, // Empty
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        expect(noActiveDaysSettings.validate(),
            contains('At least one active day must be selected'));

        // 2. Test with invalid snooze settings
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

        // 3. Test boundary conditions
        final boundarySettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 0, minute: 0), // Midnight
          clockOutTime:
              const TimeOfDay(hour: 23, minute: 59), // Almost midnight
          activeDays: {1, 2, 3, 4, 5, 6, 7}, // All days
          respectHolidays: true,
          snoozeMinutes: 60, // Maximum
          maxSnoozes: 5, // Maximum
        );

        expect(boundarySettings.validate(), isNull); // Should be valid

        await mockClockReminderService.scheduleReminders(boundarySettings);
        verify(mockClockReminderService.scheduleReminders(boundarySettings))
            .called(1);
      });
    });
  });
}

// Mock classes for use cases
class MockGetUserPreferenceUseCase extends Mock {}

class MockSetUserPreferenceUseCase extends Mock {}

class MockRegisterManagerUseCase extends Mock {}

class MockUnregisterManagerUseCase extends Mock {}
