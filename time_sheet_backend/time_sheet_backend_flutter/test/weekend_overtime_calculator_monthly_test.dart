import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:time_sheet/enum/overtime_type.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';
import 'package:time_sheet/services/weekend_overtime_calculator.dart';

import 'weekend_overtime_calculator_monthly_test.mocks.dart';

@GenerateMocks([WeekendDetectionService])
void main() {
  group('WeekendOvertimeCalculator Monthly Summary', () {
    late WeekendOvertimeCalculator calculator;
    late MockWeekendDetectionService mockWeekendService;

    setUp(() {
      mockWeekendService = MockWeekendDetectionService();
      calculator = WeekendOvertimeCalculator(
        weekendDetectionService: mockWeekendService,
      );
    });

    group('calculateMonthlyOvertime', () {
      test('should correctly calculate mixed weekday and weekend overtime',
          () async {
        // Arrange
        final entries = [
          // Weekday with overtime (9 hours = 1 hour overtime)
          TimesheetEntry(
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
          ),

          // Weekend with overtime enabled (7 hours = 7 hours overtime)
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 7 hours total
            hasOvertimeHours: false,
            isWeekendDay: true,
            isWeekendOvertimeEnabled: true,
            overtimeType: OvertimeType.WEEKEND_ONLY,
          ),

          // Regular weekday (8 hours = 0 overtime)
          TimesheetEntry(
            dayDate: '09-Jan-24', // Tuesday
            dayOfWeekDate: 'Tuesday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '18:00', // 8 hours total
            hasOvertimeHours: false,
            isWeekendDay: false,
            isWeekendOvertimeEnabled: true,
            overtimeType: OvertimeType.NONE,
          ),

          // Weekend without overtime enabled (6 hours = 0 overtime)
          TimesheetEntry(
            dayDate: '07-Jan-24', // Sunday
            dayOfWeekDate: 'Sunday',
            startMorning: '10:00',
            endMorning: '13:00',
            startAfternoon: '14:00',
            endAfternoon: '17:00', // 6 hours total
            hasOvertimeHours: false,
            isWeekendDay: true,
            isWeekendOvertimeEnabled: false, // Overtime disabled
            overtimeType: OvertimeType.NONE,
          ),
        ];

        // Act
        final result = await calculator.calculateMonthlyOvertime(entries);

        // Assert
        expect(result.weekdayOvertime, Duration(hours: 1)); // 9h - 8h = 1h
        expect(
            result.weekendOvertime, Duration(hours: 7)); // All 7h from Saturday
        expect(result.totalOvertime, Duration(hours: 8)); // 1h + 7h = 8h
        expect(
            result.regularHours,
            Duration(
                hours: 22)); // 8h (Monday) + 8h (Tuesday) + 6h (Sunday) = 22h
        expect(result.totalHours,
            Duration(hours: 30)); // 22h regular + 8h overtime = 30h
      });

      test('should handle entries without weekend information using fallback',
          () async {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 7 hours total
            hasOvertimeHours: false,
            // No weekend information stored
            isWeekendDay: false,
            isWeekendOvertimeEnabled: false,
            overtimeType: OvertimeType.NONE,
          ),
        ];

        // Mock the fallback service call
        when(mockWeekendService.shouldApplyWeekendOvertime(any))
            .thenAnswer((_) async => true);

        // Act
        final result = await calculator.calculateMonthlyOvertime(entries);

        // Assert
        expect(
            result.weekendOvertime, Duration(hours: 7)); // Should use fallback
        expect(result.weekdayOvertime, Duration.zero);
        expect(result.regularHours, Duration.zero);

        // Verify fallback was called
        verify(mockWeekendService.shouldApplyWeekendOvertime(any)).called(1);
      });

      test('should skip absence entries', () async {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '08-Jan-24',
            dayOfWeekDate: 'Monday',
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            hasOvertimeHours: false,
            isWeekendDay: false,
            isWeekendOvertimeEnabled: true,
            overtimeType: OvertimeType.NONE,
            // This would be set for absence entries
            // absence: AbsenceEntity(...),
          ),
        ];

        // Act
        final result = await calculator.calculateMonthlyOvertime(entries);

        // Assert
        expect(result.weekdayOvertime, Duration.zero);
        expect(result.weekendOvertime, Duration.zero);
        expect(result.regularHours, Duration.zero);
        expect(result.totalOvertime, Duration.zero);
      });

      test('should handle empty entries list', () async {
        // Arrange
        final entries = <TimesheetEntry>[];

        // Act
        final result = await calculator.calculateMonthlyOvertime(entries);

        // Assert
        expect(result.weekdayOvertime, Duration.zero);
        expect(result.weekendOvertime, Duration.zero);
        expect(result.regularHours, Duration.zero);
        expect(result.totalOvertime, Duration.zero);
        expect(result.hasOvertime, false);
      });

      test('should apply custom overtime rates', () async {
        // Arrange
        final entries = [
          TimesheetEntry(
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
          ),
        ];

        // Act
        final result = await calculator.calculateMonthlyOvertime(
          entries,
          weekdayRate: 1.5,
          weekendRate: 2.0,
        );

        // Assert
        expect(result.weekdayOvertimeRate, 1.5);
        expect(result.weekendOvertimeRate, 2.0);
        expect(result.weekdayOvertime, Duration(hours: 1));
      });

      test('should handle weekend with both overtime types', () async {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 10 hours total
            hasOvertimeHours: true, // Also marked as weekday overtime
            isWeekendDay: true,
            isWeekendOvertimeEnabled: true,
            overtimeType: OvertimeType.BOTH,
          ),
        ];

        // Act
        final result = await calculator.calculateMonthlyOvertime(entries);

        // Assert
        // For weekend days, all hours should be weekend overtime
        expect(result.weekendOvertime, Duration(hours: 10));
        expect(result.weekdayOvertime, Duration.zero);
        expect(result.regularHours, Duration.zero);
      });

      test('should correctly format durations', () async {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '08-Jan-24',
            dayOfWeekDate: 'Monday',
            startMorning: '08:00',
            endMorning: '12:30', // 4.5 hours
            startAfternoon: '13:30',
            endAfternoon: '18:00', // 4.5 hours = 9 total
            hasOvertimeHours: true,
            isWeekendDay: false,
            isWeekendOvertimeEnabled: true,
            overtimeType: OvertimeType.WEEKDAY_ONLY,
          ),
        ];

        // Act
        final result = await calculator.calculateMonthlyOvertime(entries);

        // Assert
        expect(result.formattedWeekdayOvertime, '1h 00m'); // 9h - 8h = 1h
        expect(result.formattedRegularHours, '8h 00m');
        expect(result.formattedTotalOvertime, '1h 00m');
        expect(result.formattedTotalHours, '9h 00m');
      });
    });
  });
}
