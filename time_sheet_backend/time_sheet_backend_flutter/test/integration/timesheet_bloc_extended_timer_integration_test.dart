import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_configuration.dart';
import 'package:time_sheet/services/work_time_calculator_service.dart';

void main() {
  group('WorkTimeCalculatorService and ExtendedTimerState Integration Tests',
      () {
    late WorkTimeCalculatorService calculatorService;

    setUp(() {
      calculatorService = WorkTimeCalculatorService();
    });

    tearDown(() {
      calculatorService.reset();
    });

    test('should generate ExtendedTimerState with correct work time info', () {
      // Arrange
      const currentState = 'Entrée';
      const elapsedTime = Duration(hours: 4);
      final startTime = DateTime.now().subtract(elapsedTime);
      const isWeekendDay = false;
      const weekendOvertimeEnabled = false;

      // Act
      final extendedTimerState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: isWeekendDay,
        weekendOvertimeEnabled: weekendOvertimeEnabled,
      );

      // Assert
      expect(extendedTimerState.currentState, equals(currentState));
      expect(extendedTimerState.elapsedTime, equals(elapsedTime));
      expect(extendedTimerState.startTime, equals(startTime));
      expect(extendedTimerState.isWeekendDay, equals(isWeekendDay));
      expect(extendedTimerState.weekendOvertimeEnabled,
          equals(weekendOvertimeEnabled));
      expect(extendedTimerState.workTimeInfo, isA<WorkTimeInfo>());
      expect(extendedTimerState.workTimeInfo.remainingTime,
          equals(const Duration(hours: 4)));
      expect(extendedTimerState.workTimeInfo.isOvertimeStarted, isFalse);
    });

    test('should handle weekend overtime correctly in ExtendedTimerState', () {
      // Arrange
      const currentState = 'Entrée';
      const elapsedTime = Duration(hours: 2);
      final startTime = DateTime.now().subtract(elapsedTime);
      const isWeekendDay = true;
      const weekendOvertimeEnabled = true;

      // Act
      final extendedTimerState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: isWeekendDay,
        weekendOvertimeEnabled: weekendOvertimeEnabled,
      );

      // Assert
      expect(extendedTimerState.isWeekendDay, isTrue);
      expect(extendedTimerState.weekendOvertimeEnabled, isTrue);
      expect(extendedTimerState.isCurrentlyInOvertime, isTrue);
      expect(
          extendedTimerState.workTimeInfo.overtimeHours, equals(elapsedTime));
    });

    test('should handle overtime transition correctly', () {
      // Arrange
      const currentState = 'Entrée';
      const elapsedTime = Duration(hours: 9); // Over 8 hours
      final startTime = DateTime.now().subtract(elapsedTime);
      const isWeekendDay = false;
      const weekendOvertimeEnabled = false;

      // Act
      final extendedTimerState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: isWeekendDay,
        weekendOvertimeEnabled: weekendOvertimeEnabled,
      );

      // Assert
      expect(extendedTimerState.workTimeInfo.isOvertimeStarted, isTrue);
      expect(extendedTimerState.workTimeInfo.overtimeHours,
          equals(const Duration(hours: 1)));
      expect(
          extendedTimerState.workTimeInfo.remainingTime, equals(Duration.zero));
      expect(extendedTimerState.isCurrentlyInOvertime, isTrue);
    });

    test('should calculate estimated end time correctly', () {
      // Arrange
      const currentState = 'Entrée';
      const elapsedTime = Duration(hours: 4);
      final startTime = DateTime(2025, 1, 1, 9, 0); // 9:00 AM
      const isWeekendDay = false;
      const weekendOvertimeEnabled = false;

      // Act
      final extendedTimerState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: isWeekendDay,
        weekendOvertimeEnabled: weekendOvertimeEnabled,
      );

      // Assert
      expect(extendedTimerState.workTimeInfo.estimatedEndTime, isNotNull);
      // Should be around 5:00 PM (9:00 AM + 8 hours)
      final expectedEndTime = startTime.add(const Duration(hours: 8));
      expect(
        extendedTimerState.workTimeInfo.estimatedEndTime!.hour,
        equals(expectedEndTime.hour),
      );
    });

    test('should handle break tracking integration', () {
      // Arrange
      const currentState = 'Pause';
      const elapsedTime = Duration(hours: 4, minutes: 30);
      final startTime = DateTime.now().subtract(elapsedTime);
      const isWeekendDay = false;
      const weekendOvertimeEnabled = false;

      // Start a break
      calculatorService.startBreak();

      // Act
      final extendedTimerState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: isWeekendDay,
        weekendOvertimeEnabled: weekendOvertimeEnabled,
      );

      // Assert
      expect(extendedTimerState.currentState, equals('Pause'));
      expect(extendedTimerState.isOnBreak, isTrue);
      expect(extendedTimerState.isActivelyWorking, isFalse);
    });

    test('should handle work day completion correctly', () {
      // Arrange
      const currentState = 'Sortie';
      const elapsedTime = Duration(hours: 8); // Exactly 8 hours
      final startTime = DateTime.now().subtract(elapsedTime);
      const isWeekendDay = false;
      const weekendOvertimeEnabled = false;

      // Act
      final extendedTimerState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: isWeekendDay,
        weekendOvertimeEnabled: weekendOvertimeEnabled,
      );

      // Assert
      expect(extendedTimerState.isWorkDayCompleted, isTrue);
      expect(extendedTimerState.workTimeInfo.isWorkDayCompleted, isTrue);
      expect(
          extendedTimerState.workTimeInfo.remainingTime, equals(Duration.zero));
      expect(extendedTimerState.workTimeInfo.progressPercentage, equals(1.0));
    });

    test('should handle configuration changes correctly', () {
      // Arrange
      final customConfig = WorkTimeConfiguration(
        standardWorkDay: const Duration(hours: 6), // 6-hour work day
        maxBreakTime: const Duration(minutes: 45),
        weekendOvertimeEnabled: true,
        weekdayOvertimeRate: 1.5,
        weekendOvertimeRate: 2.0,
        minimumBreakDuration: const Duration(minutes: 10),
        autoAdjustEndTime: true,
      );

      calculatorService.updateConfiguration(customConfig);

      const currentState = 'Entrée';
      const elapsedTime = Duration(hours: 7); // Over 6-hour work day
      final startTime = DateTime.now().subtract(elapsedTime);
      const isWeekendDay = false;
      const weekendOvertimeEnabled = false;

      // Act
      final extendedTimerState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: isWeekendDay,
        weekendOvertimeEnabled: weekendOvertimeEnabled,
      );

      // Assert
      expect(extendedTimerState.configuration.standardWorkDay,
          equals(const Duration(hours: 6)));
      expect(extendedTimerState.workTimeInfo.isOvertimeStarted, isTrue);
      expect(extendedTimerState.workTimeInfo.overtimeHours,
          equals(const Duration(hours: 1)));
    });

    test('should handle state transitions correctly', () {
      // Test the flow: Non commencé -> Entrée -> Pause -> Reprise -> Sortie

      // 1. Non commencé
      var extendedState = calculatorService.generateExtendedTimerState(
        currentState: 'Non commencé',
        elapsedTime: Duration.zero,
        startTime: null,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      expect(extendedState.isNotStarted, isTrue);
      expect(extendedState.isActivelyWorking, isFalse);

      // 2. Entrée
      final startTime = DateTime.now();
      extendedState = calculatorService.generateExtendedTimerState(
        currentState: 'Entrée',
        elapsedTime: const Duration(hours: 2),
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      expect(extendedState.isActivelyWorking, isTrue);
      expect(extendedState.isOnBreak, isFalse);

      // 3. Pause
      calculatorService.startBreak();
      extendedState = calculatorService.generateExtendedTimerState(
        currentState: 'Pause',
        elapsedTime: const Duration(hours: 2, minutes: 15),
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      expect(extendedState.isOnBreak, isTrue);
      expect(extendedState.isActivelyWorking, isFalse);

      // 4. Reprise
      calculatorService.endBreak();
      extendedState = calculatorService.generateExtendedTimerState(
        currentState: 'Reprise',
        elapsedTime: const Duration(hours: 6),
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      expect(extendedState.isActivelyWorking, isTrue);
      expect(extendedState.isOnBreak, isFalse);

      // 5. Sortie
      extendedState = calculatorService.generateExtendedTimerState(
        currentState: 'Sortie',
        elapsedTime: const Duration(hours: 8),
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      expect(extendedState.isWorkDayCompleted, isTrue);
      expect(extendedState.workTimeInfo.isWorkDayCompleted, isTrue);
    });
  });
}
