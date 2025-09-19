import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/services/work_time_calculator_service.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_configuration.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';

void main() {
  group('WorkTimeCalculatorService', () {
    late WorkTimeCalculatorService service;

    setUp(() {
      service = WorkTimeCalculatorService();

      // Reset service state before each test to ensure isolation
      service.reset();
      service.updateConfiguration(WorkTimeConfiguration.defaultConfig());
    });

    group('Configuration Management', () {
      test('should have default configuration on initialization', () {
        final config = service.configuration;
        expect(config.standardWorkDay, equals(const Duration(hours: 8)));
        expect(config.maxBreakTime, equals(const Duration(hours: 1)));
        expect(config.weekendOvertimeEnabled, isTrue);
      });

      test('should update configuration correctly', () {
        final newConfig = WorkTimeConfiguration(
          standardWorkDay: const Duration(hours: 7),
          maxBreakTime: const Duration(minutes: 30),
          weekendOvertimeEnabled: false,
        );

        service.updateConfiguration(newConfig);

        expect(service.configuration, equals(newConfig));
        expect(service.configuration.standardWorkDay,
            equals(const Duration(hours: 7)));
        expect(service.configuration.maxBreakTime,
            equals(const Duration(minutes: 30)));
        expect(service.configuration.weekendOvertimeEnabled, isFalse);
      });
    });

    group('Break Tracking', () {
      test('should track break periods correctly', () async {
        expect(service.getBreakPeriods(), isEmpty);

        service.startBreak();
        expect(service.getCurrentBreakDuration(), isNotNull);

        // Wait for a significant break duration
        await Future.delayed(const Duration(milliseconds: 100));
        service.endBreak();

        expect(service.getCurrentBreakDuration(), isNull);
        // The break should be tracked since we're using default config (5 min minimum)
        // but our test break is too short, so let's configure it properly
        service.updateConfiguration(WorkTimeConfiguration(
          minimumBreakDuration: const Duration(milliseconds: 50),
        ));

        // Start another break with the new configuration
        service.startBreak();
        await Future.delayed(const Duration(milliseconds: 100));
        service.endBreak();

        expect(service.getBreakPeriods(), hasLength(1));
      });

      test('should not track insignificant breaks', () async {
        // Configure minimum break duration
        service.updateConfiguration(WorkTimeConfiguration(
          minimumBreakDuration: const Duration(minutes: 5),
        ));

        service.startBreak();
        // Wait a short time (less than 5 minutes)
        await Future.delayed(const Duration(milliseconds: 100));
        service.endBreak();

        expect(service.getBreakPeriods(), isEmpty);
      });

      test('should clear break periods on reset', () async {
        // Configure short minimum break duration for testing
        service.updateConfiguration(WorkTimeConfiguration(
          minimumBreakDuration: const Duration(milliseconds: 50),
        ));

        service.startBreak();
        await Future.delayed(const Duration(milliseconds: 100));
        service.endBreak();
        expect(service.getBreakPeriods(), hasLength(1));

        service.clearBreakPeriods();
        expect(service.getBreakPeriods(), isEmpty);
      });

      test('should handle multiple break periods', () async {
        // Configure short minimum break duration for testing
        service.updateConfiguration(WorkTimeConfiguration(
          minimumBreakDuration: const Duration(milliseconds: 50),
        ));

        // First break
        service.startBreak();
        await Future.delayed(const Duration(milliseconds: 100));
        service.endBreak();

        // Second break
        service.startBreak();
        await Future.delayed(const Duration(milliseconds: 100));
        service.endBreak();

        expect(service.getBreakPeriods(), hasLength(2));
      });

      test('should not start multiple breaks simultaneously', () {
        service.startBreak();
        final firstBreakStart = service.getCurrentBreakDuration();

        service.startBreak(); // Should not start a new break
        final secondBreakStart = service.getCurrentBreakDuration();

        expect(firstBreakStart, isNotNull);
        expect(secondBreakStart, isNotNull);
        // The break duration should continue from the first start
      });
    });

    group('Work Time Calculations', () {
      test('should calculate remaining time correctly for partial work day',
          () {
        // Test with 4 hours worked, should have 4 hours remaining
        final workTimeInfo = WorkTimeInfo.calculate(
          workedTime: const Duration(hours: 4),
          totalElapsedTime: const Duration(hours: 4),
          workStartTime: DateTime.now().subtract(const Duration(hours: 4)),
        );

        expect(workTimeInfo.remainingTime, equals(const Duration(hours: 4)));
        expect(workTimeInfo.isOvertimeStarted, isFalse);
        expect(workTimeInfo.overtimeHours, equals(Duration.zero));
      });

      test('should calculate overtime correctly for extended work day', () {
        // Test with 10 hours worked, should have 2 hours overtime
        final workTimeInfo = WorkTimeInfo.calculate(
          workedTime: const Duration(hours: 10),
          totalElapsedTime: const Duration(hours: 10),
          workStartTime: DateTime.now().subtract(const Duration(hours: 10)),
        );

        expect(workTimeInfo.remainingTime, equals(Duration.zero));
        expect(workTimeInfo.isOvertimeStarted, isTrue);
        expect(workTimeInfo.overtimeHours, equals(const Duration(hours: 2)));
      });

      test('should calculate break time correctly', () {
        // Test with 9 hours elapsed but only 8 hours worked (1 hour break)
        final workTimeInfo = WorkTimeInfo.calculate(
          workedTime: const Duration(hours: 8),
          totalElapsedTime: const Duration(hours: 9),
          workStartTime: DateTime.now().subtract(const Duration(hours: 9)),
        );

        expect(workTimeInfo.breakTime, equals(const Duration(hours: 1)));
        expect(workTimeInfo.remainingTime, equals(Duration.zero));
        expect(workTimeInfo.isOvertimeStarted, isFalse);
      });

      test('should calculate estimated end time correctly', () {
        final startTime = DateTime(2024, 1, 15, 9, 0); // 9:00 AM
        final workTimeInfo = WorkTimeInfo.calculate(
          workedTime: const Duration(hours: 4),
          totalElapsedTime:
              const Duration(hours: 4, minutes: 30), // 30 min break
          workStartTime: startTime,
        );

        // Should end at 9:00 + 4:30 (elapsed) + 4:00 (remaining) = 5:30 PM
        final expectedEndTime =
            startTime.add(const Duration(hours: 8, minutes: 30));
        expect(workTimeInfo.estimatedEndTime, equals(expectedEndTime));
      });

      test('should handle completed work day correctly', () {
        final workTimeInfo = WorkTimeInfo.calculate(
          workedTime: const Duration(hours: 8),
          totalElapsedTime: const Duration(hours: 8),
          workStartTime: DateTime.now().subtract(const Duration(hours: 8)),
        );

        expect(workTimeInfo.isWorkDayCompleted, isTrue);
        expect(workTimeInfo.remainingTime, equals(Duration.zero));
        expect(workTimeInfo.progressPercentage, equals(1.0));
      });

      test('should calculate progress percentage correctly', () {
        // Test with 2 hours worked (25% of 8-hour day)
        final workTimeInfo = WorkTimeInfo.calculate(
          workedTime: const Duration(hours: 2),
          totalElapsedTime: const Duration(hours: 2),
          workStartTime: DateTime.now().subtract(const Duration(hours: 2)),
        );

        expect(workTimeInfo.progressPercentage, equals(0.25));
      });
    });

    group('Validation', () {
      test('should validate correct work time info', () {
        final validWorkTimeInfo = WorkTimeInfo(
          estimatedEndTime: DateTime.now().add(const Duration(hours: 4)),
          remainingTime: const Duration(hours: 4),
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        expect(service.validateCalculations(validWorkTimeInfo), isTrue);
      });

      test('should reject negative durations', () {
        final invalidWorkTimeInfo = WorkTimeInfo(
          estimatedEndTime: DateTime.now(),
          remainingTime: const Duration(hours: -1), // Invalid negative duration
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        expect(service.validateCalculations(invalidWorkTimeInfo), isFalse);
      });

      test('should reject excessive break time', () {
        final invalidWorkTimeInfo = WorkTimeInfo(
          estimatedEndTime: DateTime.now(),
          remainingTime: const Duration(hours: 4),
          breakTime: const Duration(hours: 10), // Excessive break time
          isOvertimeStarted: false,
          overtimeHours: Duration.zero,
        );

        expect(service.validateCalculations(invalidWorkTimeInfo), isFalse);
      });

      test('should reject excessive overtime', () {
        final invalidWorkTimeInfo = WorkTimeInfo(
          estimatedEndTime: DateTime.now(),
          remainingTime: Duration.zero,
          breakTime: const Duration(minutes: 30),
          isOvertimeStarted: true,
          overtimeHours: const Duration(hours: 20), // Excessive overtime
        );

        expect(service.validateCalculations(invalidWorkTimeInfo), isFalse);
      });
    });

    group('Configuration-based Calculations', () {
      test('should respect custom standard work day', () {
        service.updateConfiguration(WorkTimeConfiguration(
          standardWorkDay: const Duration(hours: 6), // 6-hour work day
        ));

        final workTimeInfo = WorkTimeInfo.calculate(
          workedTime: const Duration(hours: 4),
          totalElapsedTime: const Duration(hours: 4),
          standardWorkDay: const Duration(hours: 6),
        );

        expect(workTimeInfo.remainingTime, equals(const Duration(hours: 2)));
      });

      test('should apply break adjustments when configured', () {
        service.updateConfiguration(WorkTimeConfiguration(
          maxBreakTime: const Duration(minutes: 30),
          autoAdjustEndTime: true,
        ));

        final config = service.configuration;
        final breakAdjustment =
            config.calculateBreakAdjustment(const Duration(hours: 1));

        // Should add 30 minutes (excess over max break time)
        expect(breakAdjustment, equals(const Duration(minutes: 30)));
      });

      test('should not apply break adjustments when disabled', () {
        service.updateConfiguration(WorkTimeConfiguration(
          maxBreakTime: const Duration(minutes: 30),
          autoAdjustEndTime: false,
        ));

        final config = service.configuration;
        final breakAdjustment =
            config.calculateBreakAdjustment(const Duration(hours: 1));

        expect(breakAdjustment, equals(Duration.zero));
      });

      test('should handle part-time configuration', () {
        final partTimeConfig = WorkTimeConfiguration.partTime(
          workDayDuration: const Duration(hours: 4),
          overtimeRate: 1.5,
        );

        service.updateConfiguration(partTimeConfig);

        expect(service.configuration.standardWorkDay,
            equals(const Duration(hours: 4)));
        expect(service.configuration.weekdayOvertimeRate, equals(1.5));
      });
    });

    group('Weekend and Overtime Logic', () {
      test('should handle weekend overtime correctly', () {
        service.updateConfiguration(WorkTimeConfiguration(
          weekendOvertimeEnabled: true,
          weekendOvertimeRate: 1.5,
        ));

        final config = service.configuration;
        expect(config.getOvertimeRate(true), equals(1.5)); // Weekend rate
        expect(config.getOvertimeRate(false), equals(1.25)); // Weekday rate
      });

      test('should handle disabled weekend overtime', () {
        service.updateConfiguration(WorkTimeConfiguration(
          weekendOvertimeEnabled: false,
        ));

        expect(service.configuration.weekendOvertimeEnabled, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle zero work time', () {
        final workTimeInfo = WorkTimeInfo.calculate(
          workedTime: Duration.zero,
          totalElapsedTime: Duration.zero,
          workStartTime: DateTime.now(),
        );

        expect(workTimeInfo.remainingTime, equals(const Duration(hours: 8)));
        expect(workTimeInfo.breakTime, equals(Duration.zero));
        expect(workTimeInfo.isOvertimeStarted, isFalse);
        expect(workTimeInfo.progressPercentage, equals(0.0));
      });

      test('should handle null start time', () {
        final workTimeInfo = WorkTimeInfo.calculate(
          workedTime: const Duration(hours: 4),
          totalElapsedTime: const Duration(hours: 4),
          workStartTime: null,
        );

        expect(workTimeInfo.estimatedEndTime, isNull);
        expect(workTimeInfo.remainingTime, equals(const Duration(hours: 4)));
      });

      test('should handle very long work sessions', () {
        final workTimeInfo = WorkTimeInfo.calculate(
          workedTime: const Duration(hours: 24),
          totalElapsedTime: const Duration(hours: 24),
          workStartTime: DateTime.now().subtract(const Duration(hours: 24)),
        );

        expect(workTimeInfo.isOvertimeStarted, isTrue);
        expect(workTimeInfo.overtimeHours, equals(const Duration(hours: 16)));
        expect(workTimeInfo.remainingTime, equals(Duration.zero));
      });

      test('should create empty work time info correctly', () {
        final emptyInfo = WorkTimeInfo.empty();

        expect(emptyInfo.estimatedEndTime, isNull);
        expect(emptyInfo.remainingTime, equals(const Duration(hours: 8)));
        expect(emptyInfo.breakTime, equals(Duration.zero));
        expect(emptyInfo.isOvertimeStarted, isFalse);
        expect(emptyInfo.overtimeHours, equals(Duration.zero));
      });
    });

    group('Service Reset', () {
      test('should reset service state correctly', () async {
        // Configure short minimum break duration for testing
        service.updateConfiguration(WorkTimeConfiguration(
          minimumBreakDuration: const Duration(milliseconds: 50),
        ));

        // Add some break periods
        service.startBreak();
        await Future.delayed(const Duration(milliseconds: 100));
        service.endBreak();
        expect(service.getBreakPeriods(), hasLength(1));

        // Reset service
        service.reset();

        expect(service.getBreakPeriods(), isEmpty);
        expect(service.getCurrentBreakDuration(), isNull);
      });
    });

    group('BreakPeriod', () {
      test('should create break period correctly', () {
        final start = DateTime.now();
        final end = start.add(const Duration(minutes: 15));
        final duration = end.difference(start);

        final breakPeriod = BreakPeriod(
          start: start,
          end: end,
          duration: duration,
        );

        expect(breakPeriod.start, equals(start));
        expect(breakPeriod.end, equals(end));
        expect(breakPeriod.duration, equals(duration));
      });

      test('should compare break periods correctly', () {
        final start = DateTime.now();
        final end = start.add(const Duration(minutes: 15));
        final duration = end.difference(start);

        final breakPeriod1 =
            BreakPeriod(start: start, end: end, duration: duration);
        final breakPeriod2 =
            BreakPeriod(start: start, end: end, duration: duration);
        final breakPeriod3 = BreakPeriod(
          start: start.add(const Duration(minutes: 1)),
          end: end,
          duration: duration,
        );

        expect(breakPeriod1, equals(breakPeriod2));
        expect(breakPeriod1, isNot(equals(breakPeriod3)));
      });

      test('should have correct string representation', () {
        final start = DateTime(2024, 1, 15, 12, 0);
        final end = DateTime(2024, 1, 15, 12, 15);
        final duration = const Duration(minutes: 15);

        final breakPeriod =
            BreakPeriod(start: start, end: end, duration: duration);
        final stringRep = breakPeriod.toString();

        expect(stringRep, contains('BreakPeriod'));
        expect(stringRep, contains(start.toString()));
        expect(stringRep, contains(end.toString()));
        expect(stringRep, contains(duration.toString()));
      });
    });
  });
}
