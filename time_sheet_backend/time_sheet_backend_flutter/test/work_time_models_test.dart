import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_configuration.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';

void main() {
  group('WorkTimeConfiguration', () {
    test('should create default configuration with standard values', () {
      final config = WorkTimeConfiguration.defaultConfig();

      expect(config.standardWorkDay, const Duration(hours: 8));
      expect(config.maxBreakTime, const Duration(hours: 1));
      expect(config.weekendOvertimeEnabled, true);
      expect(config.weekdayOvertimeRate, 1.25);
      expect(config.weekendOvertimeRate, 1.5);
      expect(config.minimumBreakDuration, const Duration(minutes: 5));
      expect(config.autoAdjustEndTime, true);
    });

    test('should create part-time configuration', () {
      final config = WorkTimeConfiguration.partTime(
        workDayDuration: const Duration(hours: 6),
        overtimeRate: 1.5,
      );

      expect(config.standardWorkDay, const Duration(hours: 6));
      expect(config.weekdayOvertimeRate, 1.5);
      expect(config.weekendOvertimeRate, 1.5);
    });

    test('should return correct overtime rate for weekend/weekday', () {
      final config = WorkTimeConfiguration.defaultConfig();

      expect(config.getOvertimeRate(false), 1.25); // weekday
      expect(config.getOvertimeRate(true), 1.5); // weekend
    });

    test('should detect excessive breaks', () {
      final config = WorkTimeConfiguration.defaultConfig();

      expect(config.isBreakExcessive(const Duration(minutes: 30)), false);
      expect(
          config.isBreakExcessive(const Duration(hours: 1, minutes: 30)), true);
    });

    test('should detect significant breaks', () {
      final config = WorkTimeConfiguration.defaultConfig();

      expect(config.isSignificantBreak(const Duration(minutes: 2)), false);
      expect(config.isSignificantBreak(const Duration(minutes: 10)), true);
    });

    test('should calculate break adjustment correctly', () {
      final config = WorkTimeConfiguration.defaultConfig();

      // No adjustment for normal breaks
      expect(config.calculateBreakAdjustment(const Duration(minutes: 30)),
          Duration.zero);

      // Adjustment for excessive breaks
      final excessiveBreak = const Duration(hours: 1, minutes: 30);
      final expectedAdjustment = const Duration(minutes: 30);
      expect(
          config.calculateBreakAdjustment(excessiveBreak), expectedAdjustment);
    });

    test('should support copyWith', () {
      final original = WorkTimeConfiguration.defaultConfig();
      final modified = original.copyWith(
        standardWorkDay: const Duration(hours: 7),
        weekendOvertimeEnabled: false,
      );

      expect(modified.standardWorkDay, const Duration(hours: 7));
      expect(modified.weekendOvertimeEnabled, false);
      expect(modified.maxBreakTime, original.maxBreakTime); // unchanged
    });
  });

  group('WorkTimeInfo', () {
    test('should create empty work time info', () {
      final info = WorkTimeInfo.empty();

      expect(info.estimatedEndTime, null);
      expect(info.remainingTime, const Duration(hours: 8));
      expect(info.breakTime, Duration.zero);
      expect(info.isOvertimeStarted, false);
      expect(info.overtimeHours, Duration.zero);
    });

    test('should calculate work time info for normal work day', () {
      final startTime = DateTime(2024, 1, 15, 8, 0); // 8:00 AM
      final workedTime = const Duration(hours: 4); // 4 hours worked
      final totalElapsedTime =
          const Duration(hours: 4, minutes: 30); // 4.5 hours total

      final info = WorkTimeInfo.calculate(
        workedTime: workedTime,
        totalElapsedTime: totalElapsedTime,
        workStartTime: startTime,
      );

      expect(info.breakTime, const Duration(minutes: 30)); // 30 min break
      expect(info.remainingTime, const Duration(hours: 4)); // 4 hours remaining
      expect(info.isOvertimeStarted, false);
      expect(info.overtimeHours, Duration.zero);
      expect(info.estimatedEndTime, DateTime(2024, 1, 15, 16, 30)); // 4:30 PM
    });

    test('should calculate work time info for overtime', () {
      final startTime = DateTime(2024, 1, 15, 8, 0); // 8:00 AM
      final workedTime =
          const Duration(hours: 9); // 9 hours worked (1 hour overtime)
      final totalElapsedTime =
          const Duration(hours: 9, minutes: 30); // 9.5 hours total

      final info = WorkTimeInfo.calculate(
        workedTime: workedTime,
        totalElapsedTime: totalElapsedTime,
        workStartTime: startTime,
      );

      expect(info.breakTime, const Duration(minutes: 30)); // 30 min break
      expect(info.remainingTime, Duration.zero); // no remaining time
      expect(info.isOvertimeStarted, true);
      expect(info.overtimeHours, const Duration(hours: 1)); // 1 hour overtime
      expect(
          info.estimatedEndTime, null); // no end time when already in overtime
    });

    test('should calculate progress percentage correctly', () {
      final info1 = WorkTimeInfo.calculate(
        workedTime: const Duration(hours: 4),
        totalElapsedTime: const Duration(hours: 4),
      );
      expect(info1.progressPercentage, 0.5); // 50%

      final info2 = WorkTimeInfo.calculate(
        workedTime: const Duration(hours: 8),
        totalElapsedTime: const Duration(hours: 8),
      );
      expect(info2.progressPercentage, 1.0); // 100%

      final info3 = WorkTimeInfo.calculate(
        workedTime: const Duration(hours: 10),
        totalElapsedTime: const Duration(hours: 10),
      );
      expect(info3.progressPercentage, 1.0); // 100% (capped at 1.0)
    });

    test('should detect work day completion', () {
      final incomplete = WorkTimeInfo.calculate(
        workedTime: const Duration(hours: 6),
        totalElapsedTime: const Duration(hours: 6),
      );
      expect(incomplete.isWorkDayCompleted, false);

      final complete = WorkTimeInfo.calculate(
        workedTime: const Duration(hours: 8),
        totalElapsedTime: const Duration(hours: 8),
      );
      expect(complete.isWorkDayCompleted, true);
    });

    test('should support copyWith', () {
      final original = WorkTimeInfo.empty();
      final modified = original.copyWith(
        remainingTime: const Duration(hours: 4),
        isOvertimeStarted: true,
      );

      expect(modified.remainingTime, const Duration(hours: 4));
      expect(modified.isOvertimeStarted, true);
      expect(modified.breakTime, original.breakTime); // unchanged
    });
  });

  group('ExtendedTimerState', () {
    test('should create from timer service data', () {
      final startTime = DateTime(2024, 1, 15, 8, 0);
      final elapsedTime = const Duration(hours: 4);

      final state = ExtendedTimerState.fromTimerService(
        currentState: 'Entrée',
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: true,
      );

      expect(state.currentState, 'Entrée');
      expect(state.elapsedTime, elapsedTime);
      expect(state.startTime, startTime);
      expect(state.isWeekendDay, false);
      expect(state.weekendOvertimeEnabled, true);
      expect(state.workTimeInfo.remainingTime, const Duration(hours: 4));
    });

    test('should detect work states correctly', () {
      final activeState = ExtendedTimerState.fromTimerService(
        currentState: 'Entrée',
        elapsedTime: const Duration(hours: 2),
        isWeekendDay: false,
        weekendOvertimeEnabled: true,
      );
      expect(activeState.isActivelyWorking, true);
      expect(activeState.isOnBreak, false);
      expect(activeState.isWorkDayCompleted, false);
      expect(activeState.isNotStarted, false);

      final breakState = ExtendedTimerState.fromTimerService(
        currentState: 'Pause',
        elapsedTime: const Duration(hours: 2),
        isWeekendDay: false,
        weekendOvertimeEnabled: true,
      );
      expect(breakState.isActivelyWorking, false);
      expect(breakState.isOnBreak, true);

      final completedState = ExtendedTimerState.fromTimerService(
        currentState: 'Sortie',
        elapsedTime: const Duration(hours: 8),
        isWeekendDay: false,
        weekendOvertimeEnabled: true,
      );
      expect(completedState.isWorkDayCompleted, true);

      final notStartedState = ExtendedTimerState.fromTimerService(
        currentState: 'Non commencé',
        elapsedTime: Duration.zero,
        isWeekendDay: false,
        weekendOvertimeEnabled: true,
      );
      expect(notStartedState.isNotStarted, true);
    });

    test('should detect overtime correctly', () {
      // Weekday overtime (after 8 hours)
      final weekdayOvertime = ExtendedTimerState.fromTimerService(
        currentState: 'Entrée',
        elapsedTime: const Duration(hours: 9),
        isWeekendDay: false,
        weekendOvertimeEnabled: true,
      );
      expect(weekdayOvertime.isCurrentlyInOvertime, true);

      // Weekend overtime (when enabled)
      final weekendOvertime = ExtendedTimerState.fromTimerService(
        currentState: 'Entrée',
        elapsedTime: const Duration(hours: 4),
        isWeekendDay: true,
        weekendOvertimeEnabled: true,
      );
      expect(weekendOvertime.isCurrentlyInOvertime, true);

      // Weekend no overtime (when disabled)
      final weekendNoOvertime = ExtendedTimerState.fromTimerService(
        currentState: 'Entrée',
        elapsedTime: const Duration(hours: 4),
        isWeekendDay: true,
        weekendOvertimeEnabled: false,
      );
      expect(weekendNoOvertime.isCurrentlyInOvertime, false);
    });

    test('should support copyWith', () {
      final original = ExtendedTimerState.fromTimerService(
        currentState: 'Entrée',
        elapsedTime: const Duration(hours: 4),
        isWeekendDay: false,
        weekendOvertimeEnabled: true,
      );

      final modified = original.copyWith(
        currentState: 'Pause',
        isWeekendDay: true,
      );

      expect(modified.currentState, 'Pause');
      expect(modified.isWeekendDay, true);
      expect(modified.elapsedTime, original.elapsedTime); // unchanged
    });
  });

  group('Model Integration', () {
    test('should work together for complete work day scenario', () {
      final config = WorkTimeConfiguration.defaultConfig();
      final startTime = DateTime(2024, 1, 15, 8, 0); // 8:00 AM

      // Start of day
      var state = ExtendedTimerState.fromTimerService(
        currentState: 'Entrée',
        elapsedTime: Duration.zero,
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: true,
        configuration: config,
      );

      expect(state.workTimeInfo.remainingTime, const Duration(hours: 8));
      expect(state.workTimeInfo.estimatedEndTime,
          DateTime(2024, 1, 15, 16, 0)); // 4:00 PM

      // Mid-day (4 hours worked)
      state = state.copyWith(
        elapsedTime: const Duration(hours: 4),
        workTimeInfo: WorkTimeInfo.calculate(
          workedTime: const Duration(hours: 4),
          totalElapsedTime: const Duration(hours: 4),
          workStartTime: startTime,
          standardWorkDay: config.standardWorkDay,
        ),
      );

      expect(state.workTimeInfo.remainingTime, const Duration(hours: 4));
      expect(state.workTimeInfo.progressPercentage, 0.5);
      expect(state.isCurrentlyInOvertime, false);

      // End of day (8 hours worked)
      state = state.copyWith(
        currentState: 'Sortie',
        elapsedTime: const Duration(hours: 8),
        workTimeInfo: WorkTimeInfo.calculate(
          workedTime: const Duration(hours: 8),
          totalElapsedTime: const Duration(hours: 8),
          workStartTime: startTime,
          standardWorkDay: config.standardWorkDay,
        ),
      );

      expect(state.workTimeInfo.remainingTime, Duration.zero);
      expect(state.workTimeInfo.isWorkDayCompleted, true);
      expect(state.isWorkDayCompleted, true);
    });
  });
}
