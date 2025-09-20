import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/enum/overtime_type.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/calculate_overtime_hours_use_case.dart';

void main() {
  group('CalculateOvertimeHoursUseCase Weekend Integration', () {
    late CalculateOvertimeHoursUseCase useCase;

    setUp(() {
      useCase = CalculateOvertimeHoursUseCase();
    });

    group('Weekend Overtime Calculation', () {
      test(
          'should return all hours as overtime for weekend day with overtime enabled',
          () async {
        // Arrange
        final weekendEntry = TimesheetEntry(
          dayDate: '06-Jan-24', // Saturday
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          hasOvertimeHours: false, // Not manually marked as overtime
          isWeekendDay: true,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.WEEKEND_ONLY,
        );

        // Act
        final result = await useCase.execute(
          entry: weekendEntry,
          normalHoursThreshold: 8.0,
        );

        // Assert
        expect(
            result, Duration(hours: 7)); // 3h morning + 4h afternoon = 7h total
      });

      test('should return zero overtime for weekend day with overtime disabled',
          () async {
        // Arrange
        final weekendEntry = TimesheetEntry(
          dayDate: '06-Jan-24', // Saturday
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          hasOvertimeHours: false,
          isWeekendDay: true,
          isWeekendOvertimeEnabled: false, // Overtime disabled
          overtimeType: OvertimeType.NONE,
        );

        // Act
        final result = await useCase.execute(
          entry: weekendEntry,
          normalHoursThreshold: 8.0,
        );

        // Assert
        expect(result, Duration.zero);
      });

      test(
          'should calculate weekday overtime correctly when exceeding threshold',
          () async {
        // Arrange
        final weekdayEntry = TimesheetEntry(
          dayDate: '08-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '18:00', // 9 hours total
          hasOvertimeHours: true,
          isWeekendDay: false,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.WEEKDAY_ONLY,
        );

        // Act
        final result = await useCase.execute(
          entry: weekdayEntry,
          normalHoursThreshold: 8.0,
        );

        // Assert
        expect(result, Duration(hours: 1)); // 9h - 8h threshold = 1h overtime
      });

      test('should return zero for weekday without overtime flag', () async {
        // Arrange
        final weekdayEntry = TimesheetEntry(
          dayDate: '08-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '18:00', // 9 hours total
          hasOvertimeHours: false, // Not marked as overtime
          isWeekendDay: false,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.NONE,
        );

        // Act
        final result = await useCase.execute(
          entry: weekdayEntry,
          normalHoursThreshold: 8.0,
        );

        // Assert
        expect(result, Duration.zero);
      });

      test('should handle weekend entry with both weekend and weekday overtime',
          () async {
        // Arrange
        final weekendEntry = TimesheetEntry(
          dayDate: '07-Jan-24', // Sunday
          dayOfWeekDate: 'Sunday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 10 hours total
          hasOvertimeHours: true, // Also marked as weekday overtime
          isWeekendDay: true,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.BOTH,
        );

        // Act
        final result = await useCase.execute(
          entry: weekendEntry,
          normalHoursThreshold: 8.0,
        );

        // Assert
        // For weekend days, all hours are overtime regardless of hasOvertimeHours
        expect(result, Duration(hours: 10)); // All 10 hours are overtime
      });

      test('should handle entries with partial hours correctly', () async {
        // Arrange
        final weekendEntry = TimesheetEntry(
          dayDate: '06-Jan-24', // Saturday
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:30', // 3.5 hours
          startAfternoon: '13:30',
          endAfternoon: '16:00', // 2.5 hours
          hasOvertimeHours: false,
          isWeekendDay: true,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.WEEKEND_ONLY,
        );

        // Act
        final result = await useCase.execute(
          entry: weekendEntry,
          normalHoursThreshold: 8.0,
        );

        // Assert
        expect(result, Duration(hours: 6)); // 3.5h + 2.5h = 6h total
      });

      test('should handle empty weekend entry', () async {
        // Arrange
        final emptyWeekendEntry = TimesheetEntry(
          dayDate: '06-Jan-24', // Saturday
          dayOfWeekDate: 'Saturday',
          startMorning: '',
          endMorning: '',
          startAfternoon: '',
          endAfternoon: '',
          hasOvertimeHours: false,
          isWeekendDay: true,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.NONE,
        );

        // Act
        final result = await useCase.execute(
          entry: emptyWeekendEntry,
          normalHoursThreshold: 8.0,
        );

        // Assert
        expect(result, Duration.zero);
      });

      test('should handle different normal hours thresholds', () async {
        // Arrange
        final weekdayEntry = TimesheetEntry(
          dayDate: '08-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:30', // 8.5 hours total
          hasOvertimeHours: true,
          isWeekendDay: false,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.WEEKDAY_ONLY,
        );

        // Act - Test with 7.5 hour threshold
        final result = await useCase.execute(
          entry: weekdayEntry,
          normalHoursThreshold: 7.5,
        );

        // Assert
        expect(result, Duration(hours: 1)); // 8.5h - 7.5h = 1h overtime
      });
    });
  });
}
