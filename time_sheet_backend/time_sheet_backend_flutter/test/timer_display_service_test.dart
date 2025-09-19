import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_configuration.dart';
import 'package:time_sheet/services/timer_display_service.dart';

void main() {
  group('TimerDisplayService', () {
    late TimerDisplayService service;

    setUp(() {
      service = TimerDisplayService();
    });

    group('formatDuration', () {
      test('should format duration without seconds in standard format', () {
        const duration = Duration(hours: 8, minutes: 30);
        final result = service.formatDuration(duration);
        expect(result, equals('8h 30m'));
      });

      test('should format duration with seconds in standard format', () {
        const duration = Duration(hours: 8, minutes: 30, seconds: 45);
        final result = service.formatDuration(duration, showSeconds: true);
        expect(result, equals('8h 30m 45s'));
      });

      test('should format duration in compact format without seconds', () {
        const duration = Duration(hours: 8, minutes: 30);
        final result = service.formatDuration(duration, compact: true);
        expect(result, equals('08:30'));
      });

      test('should format duration in compact format with seconds', () {
        const duration = Duration(hours: 8, minutes: 30, seconds: 45);
        final result =
            service.formatDuration(duration, compact: true, showSeconds: true);
        expect(result, equals('08:30:45'));
      });

      test('should handle zero duration', () {
        const duration = Duration.zero;
        final result = service.formatDuration(duration);
        expect(result, equals('0h 00m'));
      });

      test('should handle single digit minutes and seconds', () {
        const duration = Duration(hours: 1, minutes: 5, seconds: 3);
        final result = service.formatDuration(duration, showSeconds: true);
        expect(result, equals('1h 05m 03s'));
      });

      test('should handle large durations', () {
        const duration = Duration(hours: 25, minutes: 30);
        final result = service.formatDuration(duration);
        expect(result, equals('25h 30m'));
      });
    });

    group('formatEndTime', () {
      test('should format end time in 24-hour format', () {
        final endTime = DateTime(2024, 1, 1, 17, 30);
        final result = service.formatEndTime(endTime);
        expect(result, equals('17:30'));
      });

      test('should format end time in 12-hour format', () {
        final endTime = DateTime(2024, 1, 1, 17, 30);
        final result = service.formatEndTime(endTime, format24Hour: false);
        expect(result, equals('5:30 PM'));
      });

      test('should handle null end time', () {
        final result = service.formatEndTime(null);
        expect(result, equals('N/A'));
      });

      test('should handle morning times', () {
        final endTime = DateTime(2024, 1, 1, 9, 15);
        final result = service.formatEndTime(endTime);
        expect(result, equals('09:15'));
      });

      test('should handle midnight', () {
        final endTime = DateTime(2024, 1, 1, 0, 0);
        final result = service.formatEndTime(endTime);
        expect(result, equals('00:00'));
      });
    });

    group('formatOvertimeStatus', () {
      test('should format weekend overtime status with hours', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: Duration.zero,
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: true,
          overtimeHours: const Duration(hours: 2, minutes: 30),
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 2, minutes: 30),
          isWeekendDay: true,
          weekendOvertimeEnabled: true,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.formatOvertimeStatus(extendedState);
        expect(result, equals('Weekend: 2h 30m overtime'));
      });

      test('should format weekend overtime status without hours', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 6),
          breakTime: Duration.zero,
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 2),
          isWeekendDay: true,
          weekendOvertimeEnabled: true,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.formatOvertimeStatus(extendedState);
        expect(result, equals('Weekend work (overtime)'));
      });

      test('should format weekday overtime status', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: Duration.zero,
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: true,
          overtimeHours: const Duration(hours: 1, minutes: 30),
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 9, minutes: 30),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.formatOvertimeStatus(extendedState);
        expect(result, equals('Overtime: 1h 30m'));
      });

      test('should format regular time remaining status', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 3, minutes: 15),
          breakTime: const Duration(minutes: 15),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 4, minutes: 45),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.formatOvertimeStatus(extendedState);
        expect(result, equals('Regular time: 3h 15m remaining'));
      });

      test('should format completed work day status', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: Duration.zero,
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Sortie',
          elapsedTime: const Duration(hours: 8, minutes: 30),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.formatOvertimeStatus(extendedState);
        expect(result, equals('Standard work day completed'));
      });
    });

    group('calculateProgressPercentages', () {
      test('should calculate progress for normal work day', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 4),
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 4, minutes: 30),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.calculateProgressPercentages(extendedState);

        expect(result['work'], closeTo(0.5, 0.01)); // 4 hours of 8 hours
        expect(result['break'], closeTo(0.111, 0.01)); // 30 min of 4.5 hours
        expect(result['overtime'], equals(0.0));
        expect(result['total'], closeTo(0.5, 0.01));
      });

      test('should calculate progress for overtime work', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: Duration.zero,
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: true,
          overtimeHours: const Duration(hours: 2),
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 10, minutes: 30),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.calculateProgressPercentages(extendedState);

        expect(result['work'], equals(1.0)); // Full work day completed
        expect(result['overtime'], equals(0.25)); // 2 hours overtime of 8 hours
        expect(result['total'], equals(1.25));
      });

      test('should calculate progress for weekend work', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 4),
          breakTime: const Duration(minutes: 15),
          isOvertimeStarted: true,
          overtimeHours: const Duration(hours: 4),
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 4, minutes: 15),
          isWeekendDay: true,
          weekendOvertimeEnabled: true,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.calculateProgressPercentages(extendedState);

        expect(result['work'], equals(0.0)); // No regular work on weekend
        expect(result['overtime'], equals(0.5)); // 4 hours overtime of 8 hours
        expect(result['total'], equals(0.5));
      });

      test('should handle zero elapsed time', () {
        final workTimeInfo = WorkTimeInfo.empty();

        final extendedState = ExtendedTimerState(
          currentState: 'Non commencé',
          elapsedTime: Duration.zero,
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.calculateProgressPercentages(extendedState);

        expect(result['work'], equals(0.0));
        expect(result['break'], equals(0.0));
        expect(result['overtime'], equals(0.0));
        expect(result['total'], equals(0.0));
      });
    });

    group('getSegmentColors', () {
      test('should return normal work colors for regular work day', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 4),
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 4, minutes: 30),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.getSegmentColors(extendedState);

        expect(result['work'], equals(const Color(0xFF4CAF50))); // Green
        expect(result['break'], equals(const Color(0xFFFF9800))); // Orange
        expect(
            result['overtime'], equals(const Color(0xFFFF5722))); // Red-Orange
        expect(result['accent'], equals(const Color(0xFF4CAF50))); // Green
      });

      test('should return overtime colors for overtime work', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: Duration.zero,
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: true,
          overtimeHours: const Duration(hours: 2),
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 10, minutes: 30),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.getSegmentColors(extendedState);

        expect(result['work'], equals(const Color(0xFFFF5722))); // Red-Orange
        expect(result['accent'], equals(const Color(0xFFFF5722))); // Red-Orange
      });

      test('should return weekend colors for weekend work', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 4),
          breakTime: const Duration(minutes: 15),
          isOvertimeStarted: true,
          overtimeHours: const Duration(hours: 4),
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 4, minutes: 15),
          isWeekendDay: true,
          weekendOvertimeEnabled: true,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.getSegmentColors(extendedState);

        expect(result['work'], equals(const Color(0xFF9C27B0))); // Purple
        expect(result['weekend'], equals(const Color(0xFF9C27B0))); // Purple
        expect(result['accent'], equals(const Color(0xFF9C27B0))); // Purple
      });

      test('should return paused colors for pause state', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 4),
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Pause',
          elapsedTime: const Duration(hours: 4, minutes: 30),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.getSegmentColors(extendedState);

        expect(result['work'], equals(const Color(0xFF757575))); // Grey
        expect(result['paused'], equals(const Color(0xFF757575))); // Grey
        expect(result['accent'], equals(const Color(0xFF757575))); // Grey
      });

      test('should return completed colors for completed state', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: Duration.zero,
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Sortie',
          elapsedTime: const Duration(hours: 8, minutes: 30),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.getSegmentColors(extendedState);

        expect(result['work'], equals(const Color(0xFF2196F3))); // Blue
        expect(result['completed'], equals(const Color(0xFF2196F3))); // Blue
        expect(result['accent'], equals(const Color(0xFF2196F3))); // Blue
      });
    });

    group('formatWorkTimeSummary', () {
      test('should format summary with remaining time', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 3, minutes: 15),
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final result = service.formatWorkTimeSummary(workTimeInfo);
        expect(result, equals('3h 15m remaining • 0h 30m break'));
      });

      test('should format summary with overtime', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: Duration.zero,
          breakTime: const Duration(minutes: 45),
          isOvertimeStarted: true,
          overtimeHours: const Duration(hours: 2),
        );

        final result = service.formatWorkTimeSummary(workTimeInfo);
        expect(result,
            equals('Work day completed • 2h 00m overtime • 0h 45m break'));
      });

      test('should format summary without break time when requested', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 2),
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final result = service.formatWorkTimeSummary(workTimeInfo,
            includeBreakTime: false);
        expect(result, equals('2h 00m remaining'));
      });

      test('should handle zero break time', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 4),
          breakTime: Duration.zero,
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final result = service.formatWorkTimeSummary(workTimeInfo);
        expect(result, equals('4h 00m remaining'));
      });
    });

    group('formatTimeUntilEnd', () {
      test('should format time until end with relative format', () {
        final now = DateTime.now();
        final endTime = now.add(const Duration(hours: 2, minutes: 30));

        final result = service.formatTimeUntilEnd(endTime);
        // Allow for small timing differences (within 1 minute)
        expect(
            result,
            anyOf(
              equals('Ends in 2h 30m'),
              equals('Ends in 2h 29m'),
              equals('Ends in 2h 31m'),
            ));
      });

      test('should format time until end without relative format', () {
        final now = DateTime.now();
        final endTime = now.add(const Duration(hours: 1, minutes: 15));

        final result = service.formatTimeUntilEnd(endTime, showRelative: false);
        // Allow for small timing differences (within 1 minute)
        expect(
            result,
            anyOf(
              equals('Time until end: 1h 15m'),
              equals('Time until end: 1h 14m'),
              equals('Time until end: 1h 16m'),
            ));
      });

      test('should handle past end time with relative format', () {
        final now = DateTime.now();
        final endTime = now.subtract(const Duration(hours: 1, minutes: 30));

        final result = service.formatTimeUntilEnd(endTime);
        // Allow for small timing differences (within 1 minute)
        expect(
            result,
            anyOf(
              equals('Overtime: 1h 30m past end time'),
              equals('Overtime: 1h 29m past end time'),
              equals('Overtime: 1h 31m past end time'),
            ));
      });

      test('should handle past end time without relative format', () {
        final now = DateTime.now();
        final endTime = now.subtract(const Duration(minutes: 45));

        final result = service.formatTimeUntilEnd(endTime, showRelative: false);
        // Allow for small timing differences (within 1 minute)
        expect(
            result,
            anyOf(
              equals('Past end time by 0h 45m'),
              equals('Past end time by 0h 44m'),
              equals('Past end time by 0h 46m'),
            ));
      });

      test('should handle null end time', () {
        final result = service.formatTimeUntilEnd(null);
        expect(result, equals('End time not available'));
      });
    });

    group('getStateDisplayText', () {
      test('should return display text for all states', () {
        expect(
            service.getStateDisplayText('Non commencé'), equals('Not Started'));
        expect(service.getStateDisplayText('Entrée'), equals('Working'));
        expect(service.getStateDisplayText('Pause'), equals('On Break'));
        expect(service.getStateDisplayText('Reprise'), equals('Working'));
        expect(service.getStateDisplayText('Sortie'), equals('Completed'));
      });

      test('should return original text for unknown states', () {
        expect(service.getStateDisplayText('Unknown State'),
            equals('Unknown State'));
        expect(service.getStateDisplayText('Custom State'),
            equals('Custom State'));
      });
    });

    group('formatCompleteTimerSummary', () {
      test('should format complete summary with all information', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: DateTime(2024, 1, 1, 17, 30),
          remainingTime: const Duration(hours: 2, minutes: 15),
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 6, minutes: 15),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.formatCompleteTimerSummary(extendedState);

        expect(result['state'], equals('Working'));
        expect(result['elapsed'], equals('6h 15m'));
        expect(
            result['workSummary'], equals('2h 15m remaining • 0h 30m break'));
        expect(result['endTime'], equals('17:30'));
        expect(
            result['overtimeStatus'], equals('Regular time: 2h 15m remaining'));
        expect(result['breakTime'], equals('0h 30m'));
        expect(result.containsKey('timeUntilEnd'), isTrue);
      });

      test('should format summary without optional information', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: Duration.zero,
          breakTime: Duration.zero,
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Sortie',
          elapsedTime: const Duration(hours: 8),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.formatCompleteTimerSummary(
          extendedState,
          includeEndTime: false,
          includeOvertimeStatus: false,
        );

        expect(result['state'], equals('Completed'));
        expect(result['elapsed'], equals('8h 00m'));
        expect(result['workSummary'], equals('Work day completed'));
        expect(result.containsKey('endTime'), isFalse);
        expect(result.containsKey('overtimeStatus'), isFalse);
        expect(result.containsKey('breakTime'), isFalse);
      });
    });

    group('validateDisplayInputs', () {
      test('should validate correct inputs', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 4),
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 4, minutes: 30),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.validateDisplayInputs(extendedState);
        expect(result, isTrue);
      });

      test('should reject empty current state', () {
        final workTimeInfo = WorkTimeInfo.empty();

        final extendedState = ExtendedTimerState(
          currentState: '',
          elapsedTime: const Duration(hours: 4),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.validateDisplayInputs(extendedState);
        expect(result, isFalse);
      });

      test('should reject negative elapsed time', () {
        final workTimeInfo = WorkTimeInfo.empty();

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: -1),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.validateDisplayInputs(extendedState);
        expect(result, isFalse);
      });

      test('should reject negative remaining time', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: -1),
          breakTime: Duration.zero,
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 4),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.validateDisplayInputs(extendedState);
        expect(result, isFalse);
      });

      test('should reject negative break time', () {
        final workTimeInfo = WorkTimeInfo(
          estimatedEndTime: null,
          remainingTime: const Duration(hours: 4),
          breakTime: const Duration(hours: -1),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        final extendedState = ExtendedTimerState(
          currentState: 'Entrée',
          elapsedTime: const Duration(hours: 4),
          isWeekendDay: false,
          weekendOvertimeEnabled: false,
          workTimeInfo: workTimeInfo,
          configuration: WorkTimeConfiguration.defaultConfig(),
        );

        final result = service.validateDisplayInputs(extendedState);
        expect(result, isFalse);
      });
    });

    group('singleton behavior', () {
      test('should return same instance', () {
        final service1 = TimerDisplayService();
        final service2 = TimerDisplayService();
        expect(identical(service1, service2), isTrue);
      });
    });
  });
}
