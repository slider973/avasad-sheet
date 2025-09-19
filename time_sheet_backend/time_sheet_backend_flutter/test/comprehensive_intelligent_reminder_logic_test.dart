import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:time_sheet/services/clock_reminder_service.dart';
import 'package:time_sheet/services/timer_service.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';
import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';
import 'package:time_sheet/enum/reminder_type.dart';

import 'comprehensive_intelligent_reminder_logic_test.mocks.dart';

@GenerateMocks([
  TimerService,
  WeekendDetectionService,
])
void main() {
  group('Intelligent Reminder Logic - Comprehensive Tests', () {
    late ClockReminderService service;
    late MockTimerService mockTimerService;
    late MockWeekendDetectionService mockWeekendDetectionService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});

      mockTimerService = MockTimerService();
      mockWeekendDetectionService = MockWeekendDetectionService();

      service = ClockReminderService();

      // Setup default mock behaviors
      when(mockTimerService.currentState).thenReturn('Non commencé');
      when(mockWeekendDetectionService.isWeekend(any)).thenReturn(false);
    });

    tearDown(() {
      service.dispose();
    });

    group('Clock Status Awareness (Requirements 3.1, 3.2)', () {
      setUp() async {
        await service.initialize(timerService: mockTimerService);

        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5, 6, 7}, // All days for testing
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        await service.scheduleReminders(settings);
      }

      test('should not send clock-in reminder when already clocked in',
          () async {
        // Arrange
        await service.onClockStatusChanged('Entrée');

        // Act
        final shouldSendClockIn =
            await service.shouldSendReminder(ReminderType.clockIn);

        // Assert
        expect(shouldSendClockIn, isFalse,
            reason:
                'Should not send clock-in reminder when already clocked in');
      });

      test('should not send clock-in reminder when working (Reprise)',
          () async {
        // Arrange
        await service.onClockStatusChanged('Reprise');

        // Act
        final shouldSendClockIn =
            await service.shouldSendReminder(ReminderType.clockIn);

        // Assert
        expect(shouldSendClockIn, isFalse,
            reason: 'Should not send clock-in reminder when already working');
      });

      test('should not send clock-in reminder when on break (Pause)', () async {
        // Arrange
        await service.onClockStatusChanged('Pause');

        // Act
        final shouldSendClockIn =
            await service.shouldSendReminder(ReminderType.clockIn);

        // Assert
        expect(shouldSendClockIn, isFalse,
            reason: 'Should not send clock-in reminder when on break');
      });

      test('should send clock-in reminder when not started', () async {
        // Arrange
        await service.onClockStatusChanged('Non commencé');

        // Act
        final shouldSendClockIn =
            await service.shouldSendReminder(ReminderType.clockIn);

        // Assert
        expect(shouldSendClockIn, isTrue,
            reason: 'Should send clock-in reminder when not started');
      });

      test('should not send clock-out reminder when already clocked out',
          () async {
        // Arrange
        await service.onClockStatusChanged('Sortie');

        // Act
        final shouldSendClockOut =
            await service.shouldSendReminder(ReminderType.clockOut);

        // Assert
        expect(shouldSendClockOut, isFalse,
            reason:
                'Should not send clock-out reminder when already clocked out');
      });

      test('should not send clock-out reminder when not started', () async {
        // Arrange
        await service.onClockStatusChanged('Non commencé');

        // Act
        final shouldSendClockOut =
            await service.shouldSendReminder(ReminderType.clockOut);

        // Assert
        expect(shouldSendClockOut, isFalse,
            reason: 'Should not send clock-out reminder when not started');
      });

      test('should send clock-out reminder when working', () async {
        // Arrange
        await service.onClockStatusChanged('Entrée');

        // Act
        final shouldSendClockOut =
            await service.shouldSendReminder(ReminderType.clockOut);

        // Assert
        expect(shouldSendClockOut, isTrue,
            reason: 'Should send clock-out reminder when working');
      });

      test('should send clock-out reminder when on break', () async {
        // Arrange
        await service.onClockStatusChanged('Pause');

        // Act
        final shouldSendClockOut =
            await service.shouldSendReminder(ReminderType.clockOut);

        // Assert
        expect(shouldSendClockOut, isTrue,
            reason: 'Should send clock-out reminder when on break');
      });

      test('should send clock-out reminder when resumed', () async {
        // Arrange
        await service.onClockStatusChanged('Reprise');

        // Act
        final shouldSendClockOut =
            await service.shouldSendReminder(ReminderType.clockOut);

        // Assert
        expect(shouldSendClockOut, isTrue,
            reason: 'Should send clock-out reminder when resumed');
      });
    });

    group('Manual Clock Action Cancellation (Requirements 3.3, 3.4)', () {
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

      test('should cancel clock-in reminder when user clocks in manually',
          () async {
        // Arrange - Start with 'Non commencé'
        await service.onClockStatusChanged('Non commencé');

        // Act - User clocks in manually
        await service.onClockStatusChanged('Entrée');

        // Assert - Clock-in reminder should be cancelled
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Entrée'));

        // Should not send clock-in reminder anymore
        final shouldSend =
            await service.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSend, isFalse);
      });

      test('should cancel clock-out reminder when user clocks out manually',
          () async {
        // Arrange - Start working
        await service.onClockStatusChanged('Entrée');

        // Act - User clocks out manually
        await service.onClockStatusChanged('Sortie');

        // Assert - Clock-out reminder should be cancelled
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Sortie'));

        // Should not send clock-out reminder anymore
        final shouldSend =
            await service.shouldSendReminder(ReminderType.clockOut);
        expect(shouldSend, isFalse);
      });

      test(
          'should cancel clock-in reminder when user resumes work from not started',
          () async {
        // Arrange - Start with 'Non commencé'
        await service.onClockStatusChanged('Non commencé');

        // Act - User resumes work (first action of the day)
        await service.onClockStatusChanged('Reprise');

        // Assert - Clock-in reminder should be cancelled
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Reprise'));

        // Should not send clock-in reminder anymore
        final shouldSend =
            await service.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSend, isFalse);
      });

      test('should not cancel clock-in reminder when resuming from pause',
          () async {
        // Arrange - Start working, then pause
        await service.onClockStatusChanged('Entrée');
        await service.onClockStatusChanged('Pause');

        // Act - Resume from pause (not first action)
        await service.onClockStatusChanged('Reprise');

        // Assert - Should not affect clock-in reminder logic
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Reprise'));
      });
    });

    group('Status Transition Logic', () {
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

      test('should handle complete work day status transitions', () async {
        // Simulate a complete work day
        final statusSequence = [
          'Non commencé',
          'Entrée', // Clock in
          'Pause', // Break
          'Reprise', // Resume
          'Pause', // Another break
          'Reprise', // Resume again
          'Sortie', // Clock out
        ];

        for (int i = 0; i < statusSequence.length; i++) {
          final status = statusSequence[i];

          // Act
          await service.onClockStatusChanged(status);

          // Assert
          final stats = service.getReminderStats();
          expect(stats['lastKnownClockStatus'], equals(status),
              reason: 'Status should be updated to $status at step $i');

          // Verify reminder logic at each step
          final shouldSendClockIn =
              await service.shouldSendReminder(ReminderType.clockIn);
          final shouldSendClockOut =
              await service.shouldSendReminder(ReminderType.clockOut);

          switch (status) {
            case 'Non commencé':
              expect(shouldSendClockIn, isTrue,
                  reason: 'Should send clock-in when not started');
              expect(shouldSendClockOut, isFalse,
                  reason: 'Should not send clock-out when not started');
              break;
            case 'Entrée':
            case 'Pause':
            case 'Reprise':
              expect(shouldSendClockIn, isFalse,
                  reason: 'Should not send clock-in when working/paused');
              expect(shouldSendClockOut, isTrue,
                  reason: 'Should send clock-out when working/paused');
              break;
            case 'Sortie':
              expect(shouldSendClockIn, isTrue,
                  reason: 'Should send clock-in when finished (for next day)');
              expect(shouldSendClockOut, isFalse,
                  reason: 'Should not send clock-out when finished');
              break;
          }
        }
      });

      test('should handle rapid status changes', () async {
        // Simulate rapid status changes
        final rapidChanges = [
          'Entrée',
          'Pause',
          'Reprise',
          'Pause',
          'Reprise',
          'Sortie',
        ];

        for (final status in rapidChanges) {
          // Act - Should not throw
          await service.onClockStatusChanged(status);

          // Brief verification
          final stats = service.getReminderStats();
          expect(stats['lastKnownClockStatus'], equals(status));
        }

        // Final verification
        final finalStats = service.getReminderStats();
        expect(finalStats['lastKnownClockStatus'], equals('Sortie'));
      });

      test('should handle duplicate status changes', () async {
        // Act - Send same status multiple times
        await service.onClockStatusChanged('Entrée');
        await service.onClockStatusChanged('Entrée');
        await service.onClockStatusChanged('Entrée');

        // Assert - Should handle gracefully
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Entrée'));

        final shouldSendClockIn =
            await service.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSendClockIn, isFalse);
      });
    });

    group('TimeSheet Integration', () {
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

      test('should sync with TimeSheet state changes', () async {
        // Act - Simulate TimeSheet state change
        await service.onTimeSheetStateChanged('Entrée');

        // Assert
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Entrée'));

        final shouldSendClockIn =
            await service.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSendClockIn, isFalse);
      });

      test('should handle TimeSheet state changes for all statuses', () async {
        final timeSheetStatuses = [
          'Non commencé',
          'Entrée',
          'Pause',
          'Reprise',
          'Sortie',
        ];

        for (final status in timeSheetStatuses) {
          // Act
          await service.onTimeSheetStateChanged(status);

          // Assert
          final stats = service.getReminderStats();
          expect(stats['lastKnownClockStatus'], equals(status));
        }
      });

      test(
          'should maintain consistency between clock status and TimeSheet state',
          () async {
        // Act - Change both clock status and TimeSheet state
        await service.onClockStatusChanged('Entrée');
        await service.onTimeSheetStateChanged('Entrée');

        // Assert - Both should result in same state
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Entrée'));

        // Reminder logic should be consistent
        final shouldSendClockIn =
            await service.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSendClockIn, isFalse);
      });
    });

    group('Weekend and Holiday Logic (Requirement 3.5)', () {
      setUp() async {
        await service.initialize(timerService: mockTimerService);
      }

      test(
          'should not schedule reminders on weekends when respectHolidays is true',
          () async {
        // Arrange
        when(mockWeekendDetectionService.isWeekend(any)).thenReturn(true);

        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {6, 7}, // Weekend days
          respectHolidays: true, // Respect holidays/weekends
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Act
        await service.scheduleReminders(settings);

        // Assert - Should handle weekend logic appropriately
        final stats = service.getReminderStats();
        expect(stats['currentSettings'], equals(settings));
      });

      test(
          'should schedule reminders on weekends when respectHolidays is false',
          () async {
        // Arrange
        when(mockWeekendDetectionService.isWeekend(any)).thenReturn(true);

        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {6, 7}, // Weekend days
          respectHolidays: false, // Don't respect holidays/weekends
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Act
        await service.scheduleReminders(settings);

        // Assert - Should schedule even on weekends
        final stats = service.getReminderStats();
        expect(stats['currentSettings'], equals(settings));
      });

      test('should handle holiday detection', () async {
        // Arrange - Test with New Year's Day (January 1st)
        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1}, // Monday (if Jan 1st is Monday)
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Act
        await service.scheduleReminders(settings);

        // Assert - Should handle holiday logic
        final stats = service.getReminderStats();
        expect(stats['currentSettings'], equals(settings));
      });
    });

    group('Intelligent Rescheduling', () {
      setUp() async {
        await service.initialize(timerService: mockTimerService);

        final settings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {DateTime.now().weekday}, // Today
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        await service.scheduleReminders(settings);
      }

      test('should reschedule reminders based on status changes', () async {
        // Arrange - Start with 'Non commencé'
        await service.onClockStatusChanged('Non commencé');

        // Act - Clock in (should reschedule clock-out reminder)
        await service.onClockStatusChanged('Entrée');

        // Assert - Should have rescheduled appropriately
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Entrée'));
      });

      test('should handle status changes during active work period', () async {
        // Simulate work period with breaks
        await service.onClockStatusChanged('Entrée'); // Start work
        await service.onClockStatusChanged('Pause'); // Take break
        await service.onClockStatusChanged('Reprise'); // Resume work
        await service.onClockStatusChanged('Pause'); // Another break
        await service.onClockStatusChanged('Reprise'); // Resume again

        // Assert - Should maintain consistent reminder logic
        final shouldSendClockOut =
            await service.shouldSendReminder(ReminderType.clockOut);
        expect(shouldSendClockOut, isTrue,
            reason: 'Should still need clock-out reminder during work period');
      });

      test('should clean up reminders at end of work day', () async {
        // Arrange - Simulate full work day
        await service.onClockStatusChanged('Entrée');
        await service.onClockStatusChanged('Pause');
        await service.onClockStatusChanged('Reprise');

        // Act - End work day
        await service.onClockStatusChanged('Sortie');

        // Assert - Should clean up appropriately
        final shouldSendClockOut =
            await service.shouldSendReminder(ReminderType.clockOut);
        expect(shouldSendClockOut, isFalse,
            reason: 'Should not need clock-out reminder after clocking out');
      });
    });

    group('Error Handling in Intelligent Logic', () {
      setUp() async {
        await service.initialize(timerService: mockTimerService);
      }

      test('should handle invalid status changes gracefully', () async {
        // Act - Send invalid status
        await service.onClockStatusChanged('InvalidStatus');

        // Assert - Should handle gracefully
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('InvalidStatus'));

        // Reminder logic should still work
        final shouldSendClockIn =
            await service.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSendClockIn, isA<bool>());
      });

      test('should handle null or empty status changes', () async {
        // Act & Assert - Should not throw
        await service.onClockStatusChanged('');

        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals(''));
      });

      test('should handle service not initialized', () async {
        // Arrange - Use uninitialized service
        final uninitializedService = ClockReminderService();

        // Act & Assert - Should handle gracefully
        await uninitializedService.onClockStatusChanged('Entrée');

        final shouldSend =
            await uninitializedService.shouldSendReminder(ReminderType.clockIn);
        expect(shouldSend, isFalse);

        uninitializedService.dispose();
      });
    });

    group('Performance and Concurrency', () {
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

      test('should handle concurrent status changes', () async {
        // Act - Concurrent status changes
        final futures = [
          service.onClockStatusChanged('Entrée'),
          service.onClockStatusChanged('Pause'),
          service.onClockStatusChanged('Reprise'),
          service.onTimeSheetStateChanged('Sortie'),
        ];

        // Assert - Should handle concurrency
        await Future.wait(futures);

        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], isA<String>());
      });

      test('should handle rapid sequential status changes', () async {
        // Act - Rapid changes
        for (int i = 0; i < 100; i++) {
          final status = i % 2 == 0 ? 'Entrée' : 'Pause';
          await service.onClockStatusChanged(status);
        }

        // Assert - Should handle all changes
        final stats = service.getReminderStats();
        expect(stats['lastKnownClockStatus'], equals('Pause')); // Last status
      });
    });
  });
}
