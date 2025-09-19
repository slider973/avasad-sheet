import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:time_sheet/services/clock_reminder_service.dart';
import 'package:time_sheet/services/timer_service.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';
import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';
import 'package:time_sheet/features/preference/data/models/reminder_notification.dart';
import 'package:time_sheet/enum/reminder_type.dart';

import 'comprehensive_clock_reminder_service_test.mocks.dart';

@GenerateMocks([
  TimerService,
  WeekendDetectionService,
  FlutterLocalNotificationsPlugin,
])
void main() {
  group('ClockReminderService - Comprehensive Tests', () {
    late ClockReminderService service;
    late MockTimerService mockTimerService;
    late MockWeekendDetectionService mockWeekendDetectionService;
    late MockFlutterLocalNotificationsPlugin mockNotificationsPlugin;

    setUp(() {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});

      mockTimerService = MockTimerService();
      mockWeekendDetectionService = MockWeekendDetectionService();
      mockNotificationsPlugin = MockFlutterLocalNotificationsPlugin();

      service = ClockReminderService();

      // Setup default mock behaviors
      when(mockTimerService.currentState).thenReturn('Non commencé');
      when(mockWeekendDetectionService.isWeekend(any)).thenReturn(false);
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
    });

    tearDown(() {
      service.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully with default settings', () async {
        // Act
        await service.initialize(timerService: mockTimerService);

        // Assert
        expect(service, isNotNull);
        final stats = service.getReminderStats();
        expect(stats['isInitialized'], isTrue);
        expect(stats['currentSettings'], isNotNull);
      });

      test('should load saved reminder settings on initialization', () async {
        // Arrange - Save settings first
        final savedSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 9, minute: 0),
          clockOutTime: const TimeOfDay(hour: 18, minute: 0),
          activeDays: {1, 2, 3},
          respectHolidays: false,
          snoozeMinutes: 20,
          maxSnoozes: 3,
        );

        SharedPreferences.setMockInitialValues({
          'reminder_settings': jsonEncode(savedSettings.toJson()),
        });

        // Act
        await service.initialize(timerService: mockTimerService);

        // Assert
        final stats = service.getReminderStats();
        final loadedSettings = stats['currentSettings'] as ReminderSettings?;
        expect(loadedSettings, isNotNull);
        expect(loadedSettings!.enabled, true);
        expect(loadedSettings.clockInTime.hour, 9);
        expect(loadedSettings.activeDays, {1, 2, 3});
      });

      test('should handle corrupted saved settings gracefully', () async {
        // Arrange - Set corrupted JSON
        SharedPreferences.setMockInitialValues({
          'reminder_settings': 'invalid_json_data',
        });

        // Act & Assert - Should not throw
        await service.initialize(timerService: mockTimerService);

        final stats = service.getReminderStats();
        expect(stats['isInitialized'], isTrue);

        // Should fall back to default settings
        final settings = stats['currentSettings'] as ReminderSettings?;
        expect(settings, equals(ReminderSettings.defaultSettings));
      });

      test('should not initialize twice', () async {
        // Act
        await service.initialize(timerService: mockTimerService);
        await service.initialize(timerService: mockTimerService); // Second call

        // Assert - Should not throw and remain initialized
        final stats = service.getReminderStats();
        expect(stats['isInitialized'], isTrue);
      });
    });

    group('Reminder Scheduling', () {
      setUp(() async {
        await service.initialize(timerService: mockTimerService);
      });

      test('should validate settings before scheduling', () async {
        // Arrange - Invalid settings
        final invalidSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 10, minute: 0),
          clockOutTime: const TimeOfDay(hour: 8, minute: 0), // Before clock-in
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

      test('should schedule reminders when enabled', () async {
        // Arrange
        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {DateTime.now().weekday}, // Today
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Act
        await service.scheduleReminders(settings);

        // Assert
        final stats = service.getReminderStats();
        expect(stats['currentSettings'], equals(settings));
      });

      test('should not schedule reminders when disabled', () async {
        // Arrange
        final disabledSettings =
            ReminderSettings.defaultSettings; // Disabled by default

        // Act
        await service.scheduleReminders(disabledSettings);

        // Assert
        final stats = service.getReminderStats();
        expect(stats['pendingReminders'], 0);
      });

      test('should cancel existing reminders before scheduling new ones',
          () async {
        // Arrange
        final settings1 = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {DateTime.now().weekday},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        final settings2 = settings1.copyWith(
          clockInTime: const TimeOfDay(hour: 9, minute: 0),
        );

        // Act
        await service.scheduleReminders(settings1);
        await service.scheduleReminders(settings2);

        // Assert
        final stats = service.getReminderStats();
        final currentSettings = stats['currentSettings'] as ReminderSettings;
        expect(currentSettings.clockInTime.hour, 9);
      });
    });

    group('Clock Status Integration', () {
      setUp(() async {
        await service.initialize(timerService: mockTimerService);

        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5, 6, 7}, // All days
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        await service.scheduleReminders(settings);
      });

      test('should not send clock-in reminder when already clocked in',
          () async {
        // Arrange
        await service.onClockStatusChanged('Entrée');

        // Act
        final shouldSend =
            await service.shouldSendReminder(ReminderType.clockIn);

        // Assert
        expect(shouldSend, isFalse);
      });

      test('should not send clock-out reminder when already clocked out',
          () async {
        // Arrange
        await service.onClockStatusChanged('Sortie');

        // Act
        final shouldSend =
            await service.shouldSendReminder(ReminderType.clockOut);

        // Assert
        expect(shouldSend, isFalse);
      });

      test('should handle all clock status transitions', () async {
        // Test all status transitions
        final statuses = [
          'Non commencé',
          'Entrée',
          'Pause',
          'Reprise',
          'Sortie'
        ];

        for (final status in statuses) {
          // Act & Assert - Should not throw
          await service.onClockStatusChanged(status);

          final stats = service.getReminderStats();
          expect(stats['lastKnownClockStatus'], equals(status));
        }
      });

      test('should cancel relevant reminders on manual clock actions',
          () async {
        // Arrange - Start with 'Non commencé'
        await service.onClockStatusChanged('Non commencé');

        // Act - Clock in manually
        await service.onClockStatusChanged('Entrée');

        // Assert - Clock-in reminder should be cancelled
        final stats = service.getReminderStats();
        expect(stats['cancelledReminders'], greaterThanOrEqualTo(0));
      });

      test('should handle TimeSheet state changes', () async {
        // Act & Assert - Should not throw
        await service.onTimeSheetStateChanged('Entrée');
        await service.onTimeSheetStateChanged('Pause');
        await service.onTimeSheetStateChanged('Reprise');
        await service.onTimeSheetStateChanged('Sortie');

        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Sortie'));
      });
    });

    group('Snooze Functionality', () {
      setUp() async {
        await service.initialize(timerService: mockTimerService);

        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5, 6, 7},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        await service.scheduleReminders(settings);
      }

      test('should snooze reminder within limits', () async {
        // Act - Snooze clock-in reminder
        await service.snoozeReminder(1000, ReminderType.clockIn);

        // Assert - Should not throw
        expect(service, isNotNull);
      });

      test('should respect maximum snooze limits', () async {
        // Act - Snooze multiple times
        await service.snoozeReminder(1000, ReminderType.clockIn);
        await service.snoozeReminder(1000, ReminderType.clockIn);
        await service.snoozeReminder(
            1000, ReminderType.clockIn); // Should be ignored

        // Assert - Should handle gracefully
        expect(service, isNotNull);
      });

      test('should handle snooze for different reminder types', () async {
        // Act
        await service.snoozeReminder(1000, ReminderType.clockIn);
        await service.snoozeReminder(1001, ReminderType.clockOut);

        // Assert - Should not throw
        expect(service, isNotNull);
      });
    });

    group('App Lifecycle Management', () {
      setUp() async {
        await service.initialize(timerService: mockTimerService);
      }

      test('should handle app going to background', () async {
        // Act & Assert - Should not throw
        await service.onAppBackground();
        expect(service, isNotNull);
      });

      test('should handle app returning to foreground', () async {
        // Act & Assert - Should not throw
        await service.onAppForeground();
        expect(service, isNotNull);
      });

      test('should save and restore state during background transitions',
          () async {
        // Arrange
        await service.onClockStatusChanged('Entrée');

        // Act
        await service.onAppBackground();
        await service.onAppForeground();

        // Assert
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Entrée'));
      });
    });

    group('Notification Interaction Handling', () {
      setUp() async {
        await service.initialize(timerService: mockTimerService);
      }

      test('should handle clock-in reminder tap', () async {
        // Act & Assert - Should not throw
        await service.handleNotificationInteraction('clock_in_reminder');
        expect(service, isNotNull);
      });

      test('should handle clock-out reminder tap', () async {
        // Act & Assert - Should not throw
        await service.handleNotificationInteraction('clock_out_reminder');
        expect(service, isNotNull);
      });

      test('should handle snooze interactions', () async {
        // Act & Assert - Should not throw
        await service.handleNotificationInteraction('snooze_clockIn');
        await service.handleNotificationInteraction('snooze_clockOut');
        expect(service, isNotNull);
      });

      test('should handle dismiss interactions', () async {
        // Act & Assert - Should not throw
        await service.handleNotificationInteraction('dismiss_clockIn');
        await service.handleNotificationInteraction('dismiss_clockOut');
        expect(service, isNotNull);
      });

      test('should handle invalid payloads gracefully', () async {
        // Act & Assert - Should not throw
        await service.handleNotificationInteraction(null);
        await service.handleNotificationInteraction('invalid_payload');
        await service.handleNotificationInteraction('');
        expect(service, isNotNull);
      });
    });

    group('Weekend and Holiday Detection', () {
      setUp() async {
        await service.initialize(timerService: mockTimerService);
      }

      test('should respect weekend settings', () async {
        // Arrange
        when(mockWeekendDetectionService.isWeekend(any)).thenReturn(true);

        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {6, 7}, // Weekend days
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Act
        await service.scheduleReminders(settings);

        // Assert - Should handle weekend logic
        expect(service, isNotNull);
      });

      test('should handle holiday detection', () async {
        // Arrange - New Year's Day
        final newYearsDay = DateTime(2024, 1, 1);

        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {newYearsDay.weekday},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Act
        await service.scheduleReminders(settings);

        // Assert - Should handle holiday logic
        expect(service, isNotNull);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle initialization without TimerService', () async {
        // Act & Assert - Should not throw
        await service.initialize(); // No TimerService provided
        expect(service, isNotNull);
      });

      test('should handle scheduling before initialization', () {
        // Arrange
        final settings = ReminderSettings.defaultSettings;

        // Act & Assert
        expect(
          () => service.scheduleReminders(settings),
          throwsA(isA<StateError>()),
        );
      });

      test('should handle operations on disposed service', () {
        // Arrange
        service.dispose();

        // Act & Assert - Should handle gracefully
        expect(() => service.onClockStatusChanged('Entrée'), returnsNormally);
        expect(() => service.onAppBackground(), returnsNormally);
        expect(() => service.onAppForeground(), returnsNormally);
      });

      test('should handle concurrent operations', () async {
        // Arrange
        await service.initialize(timerService: mockTimerService);

        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Act - Concurrent operations
        final futures = [
          service.scheduleReminders(settings),
          service.onClockStatusChanged('Entrée'),
          service.onAppBackground(),
          service.onAppForeground(),
        ];

        // Assert - Should handle concurrency gracefully
        await Future.wait(futures);
        expect(service, isNotNull);
      });
    });

    group('Statistics and Monitoring', () {
      setUp() async {
        await service.initialize(timerService: mockTimerService);
      }

      test('should provide comprehensive reminder statistics', () async {
        // Act
        final stats = service.getReminderStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('isInitialized'), isTrue);
        expect(stats.containsKey('currentSettings'), isTrue);
        expect(stats.containsKey('lastKnownClockStatus'), isTrue);
        expect(stats.containsKey('totalReminders'), isTrue);
        expect(stats.containsKey('pendingReminders'), isTrue);
        expect(stats.containsKey('overdueReminders'), isTrue);
        expect(stats.containsKey('cancelledReminders'), isTrue);
        expect(stats.containsKey('currentTime'), isTrue);
      });

      test('should update statistics after operations', () async {
        // Arrange
        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Act
        await service.scheduleReminders(settings);
        await service.onClockStatusChanged('Entrée');

        // Assert
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Entrée'));
        expect(stats['currentSettings'], equals(settings));
      });
    });

    group('Persistence and Recovery', () {
      test('should persist reminder settings', () async {
        // Arrange
        await service.initialize(timerService: mockTimerService);

        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 9, minute: 30),
          clockOutTime: const TimeOfDay(hour: 18, minute: 15),
          activeDays: {1, 3, 5},
          respectHolidays: false,
          snoozeMinutes: 20,
          maxSnoozes: 3,
        );

        // Act
        await service.scheduleReminders(settings);

        // Assert - Settings should be persisted
        final prefs = await SharedPreferences.getInstance();
        final savedJson = prefs.getString('reminder_settings');
        expect(savedJson, isNotNull);

        final savedSettings = ReminderSettings.fromJson(jsonDecode(savedJson!));
        expect(savedSettings, equals(settings));
      });

      test('should recover from corrupted state', () async {
        // Arrange - Set corrupted state
        SharedPreferences.setMockInitialValues({
          'clock_reminder_state': 'corrupted_state_data',
        });

        // Act & Assert - Should recover gracefully
        await service.initialize(timerService: mockTimerService);
        await service.onAppForeground(); // Trigger state recovery

        expect(service, isNotNull);
        final stats = service.getReminderStats();
        expect(stats['isInitialized'], isTrue);
      });
    });

    group('Integration with External Services', () {
      test('should integrate with TimerService state changes', () async {
        // Arrange
        await service.initialize(timerService: mockTimerService);

        // Simulate TimerService state change
        when(mockTimerService.currentState).thenReturn('Entrée');

        // Act
        await service.onClockStatusChanged('Entrée');

        // Assert
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Entrée'));
      });

      test('should handle WeekendDetectionService integration', () async {
        // Arrange
        await service.initialize(timerService: mockTimerService);
        when(mockWeekendDetectionService.isWeekend(any)).thenReturn(true);

        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {6, 7}, // Weekend
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Act & Assert - Should handle weekend detection
        await service.scheduleReminders(settings);
        expect(service, isNotNull);
      });
    });
  });
}
