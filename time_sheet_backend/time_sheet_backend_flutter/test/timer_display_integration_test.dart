import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_configuration.dart';
import 'package:time_sheet/services/timer_display_service.dart';
import 'package:time_sheet/services/work_time_calculator_service.dart';

void main() {
  group('TimerDisplayService Integration', () {
    late TimerDisplayService displayService;
    late WorkTimeCalculatorService calculatorService;

    setUp(() {
      displayService = TimerDisplayService();
      calculatorService = WorkTimeCalculatorService();
    });

    tearDown(() {
      calculatorService.reset();
    });

    test('should integrate with WorkTimeCalculatorService for normal work day',
        () {
      // Arrange
      final startTime = DateTime(2024, 1, 15, 9, 0); // Monday 9:00 AM
      const elapsedTime = Duration(hours: 4, minutes: 30);
      const currentState = 'Entrée';

      // Generate extended timer state using WorkTimeCalculatorService
      final extendedState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      // Act - Format display data
      final progressPercentages =
          displayService.calculateProgressPercentages(extendedState);
      final segmentColors = displayService.getSegmentColors(extendedState);
      final overtimeStatus = displayService.formatOvertimeStatus(extendedState);
      final completeSummary =
          displayService.formatCompleteTimerSummary(extendedState);

      // Assert
      expect(progressPercentages['work'],
          closeTo(0.5625, 0.01)); // 4.5 hours of 8 hours
      expect(progressPercentages['overtime'], equals(0.0));
      expect(segmentColors['accent']?.value,
          equals(0xFF4CAF50)); // Green for normal work
      expect(overtimeStatus, contains('remaining'));
      expect(completeSummary['state'], equals('Working'));
      expect(completeSummary['elapsed'], equals('4h 30m'));
    });

    test('should integrate with WorkTimeCalculatorService for overtime work',
        () {
      // Arrange
      final startTime = DateTime(2024, 1, 15, 9, 0); // Monday 9:00 AM
      const elapsedTime = Duration(hours: 10, minutes: 30);
      const currentState = 'Entrée';

      // Generate extended timer state using WorkTimeCalculatorService
      final extendedState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      // Act - Format display data
      final progressPercentages =
          displayService.calculateProgressPercentages(extendedState);
      final segmentColors = displayService.getSegmentColors(extendedState);
      final overtimeStatus = displayService.formatOvertimeStatus(extendedState);
      final completeSummary =
          displayService.formatCompleteTimerSummary(extendedState);

      // Assert
      expect(
          progressPercentages['work'], equals(1.0)); // Full work day completed
      expect(progressPercentages['overtime'], greaterThan(0.0)); // Has overtime
      expect(segmentColors['accent']?.value,
          equals(0xFFFF5722)); // Red-Orange for overtime
      expect(overtimeStatus, contains('Overtime:'));
      expect(completeSummary['state'], equals('Working'));
      expect(completeSummary['elapsed'], equals('10h 30m'));
    });

    test('should integrate with WorkTimeCalculatorService for weekend work',
        () {
      // Arrange
      final startTime = DateTime(2024, 1, 13, 10, 0); // Saturday 10:00 AM
      const elapsedTime = Duration(hours: 6, minutes: 15);
      const currentState = 'Entrée';

      // Generate extended timer state using WorkTimeCalculatorService
      final extendedState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: true,
        weekendOvertimeEnabled: true,
      );

      // Act - Format display data
      final progressPercentages =
          displayService.calculateProgressPercentages(extendedState);
      final segmentColors = displayService.getSegmentColors(extendedState);
      final overtimeStatus = displayService.formatOvertimeStatus(extendedState);
      final completeSummary =
          displayService.formatCompleteTimerSummary(extendedState);

      // Assert
      expect(progressPercentages['work'],
          equals(0.0)); // No regular work on weekend
      expect(progressPercentages['overtime'],
          greaterThan(0.0)); // All work is overtime
      expect(segmentColors['accent']?.value,
          equals(0xFF9C27B0)); // Purple for weekend
      expect(overtimeStatus, contains('Weekend'));
      expect(completeSummary['state'], equals('Working'));
      expect(completeSummary['elapsed'], equals('6h 15m'));
    });

    test('should integrate with WorkTimeCalculatorService for break state', () {
      // Arrange
      final startTime = DateTime(2024, 1, 15, 9, 0); // Monday 9:00 AM
      const elapsedTime = Duration(hours: 4, minutes: 45);
      const currentState = 'Pause';

      // Simulate break tracking
      calculatorService.startBreak();

      // Generate extended timer state using WorkTimeCalculatorService
      final extendedState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      // Act - Format display data
      final segmentColors = displayService.getSegmentColors(extendedState);
      final stateText = displayService.getStateDisplayText(currentState);
      final completeSummary =
          displayService.formatCompleteTimerSummary(extendedState);

      // Assert
      expect(segmentColors['accent']?.value,
          equals(0xFF757575)); // Grey for paused
      expect(stateText, equals('On Break'));
      expect(completeSummary['state'], equals('On Break'));
      expect(completeSummary['elapsed'], equals('4h 45m'));
    });

    test(
        'should integrate with WorkTimeCalculatorService for completed work day',
        () {
      // Arrange
      final startTime = DateTime(2024, 1, 15, 9, 0); // Monday 9:00 AM
      const elapsedTime = Duration(hours: 8, minutes: 30);
      const currentState = 'Sortie';

      // Generate extended timer state using WorkTimeCalculatorService
      final extendedState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      // Act - Format display data
      final progressPercentages =
          displayService.calculateProgressPercentages(extendedState);
      final segmentColors = displayService.getSegmentColors(extendedState);
      final overtimeStatus = displayService.formatOvertimeStatus(extendedState);
      final completeSummary =
          displayService.formatCompleteTimerSummary(extendedState);

      // Assert
      expect(
          progressPercentages['work'], equals(1.0)); // Full work day completed
      expect(segmentColors['accent']?.value,
          equals(0xFF2196F3)); // Blue for completed
      expect(overtimeStatus,
          contains('Overtime:')); // Shows overtime since 8.5 hours > 8 hours
      expect(completeSummary['state'], equals('Completed'));
      expect(completeSummary['elapsed'], equals('8h 30m'));
    });

    test('should handle custom work time configuration', () {
      // Arrange
      final customConfig = WorkTimeConfiguration(
        standardWorkDay: const Duration(hours: 6), // Part-time 6 hours
        maxBreakTime: const Duration(minutes: 45),
        weekdayOvertimeRate: 1.5,
      );

      calculatorService.updateConfiguration(customConfig);

      final startTime = DateTime(2024, 1, 15, 9, 0); // Monday 9:00 AM
      const elapsedTime = Duration(hours: 7, minutes: 0);
      const currentState = 'Entrée';

      // Generate extended timer state using WorkTimeCalculatorService
      final extendedState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      // Act - Format display data
      final progressPercentages =
          displayService.calculateProgressPercentages(extendedState);
      final overtimeStatus = displayService.formatOvertimeStatus(extendedState);

      // Assert
      expect(progressPercentages['work'],
          equals(1.0)); // Full 6-hour work day completed
      expect(
          progressPercentages['overtime'], greaterThan(0.0)); // 1 hour overtime
      expect(overtimeStatus, contains('Overtime: 1h 00m'));
    });

    test('should validate display inputs from WorkTimeCalculatorService', () {
      // Arrange
      final startTime = DateTime(2024, 1, 15, 9, 0); // Monday 9:00 AM
      const elapsedTime = Duration(hours: 5, minutes: 15);
      const currentState = 'Reprise';

      // Generate extended timer state using WorkTimeCalculatorService
      final extendedState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      // Act - Validate inputs
      final isValid = displayService.validateDisplayInputs(extendedState);

      // Assert
      expect(isValid, isTrue);
    });

    test('should format end time correctly with WorkTimeCalculatorService', () {
      // Arrange
      final startTime = DateTime(2024, 1, 15, 9, 0); // Monday 9:00 AM
      const elapsedTime = Duration(hours: 3, minutes: 0);
      const currentState = 'Entrée';

      // Generate extended timer state using WorkTimeCalculatorService
      final extendedState = calculatorService.generateExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: false,
        weekendOvertimeEnabled: false,
      );

      // Act - Format end time
      final endTimeFormatted = displayService.formatEndTime(
        extendedState.workTimeInfo.estimatedEndTime,
      );

      // Assert
      expect(endTimeFormatted, isNot(equals('N/A')));
      expect(
          endTimeFormatted, matches(RegExp(r'^\d{2}:\d{2}$'))); // HH:MM format
    });
  });
}
