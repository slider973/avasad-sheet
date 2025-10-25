import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:time_sheet/enum/overtime_type.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/calculate_overtime_hours_use_case.dart';
import 'package:time_sheet/features/preference/domain/entities/user.dart';
import 'package:time_sheet/services/overtime_configuration_service.dart';

void main() {
  group('Normal Hours Threshold Integration', () {
    late CalculateOvertimeHoursUseCase calculateOvertimeUseCase;
    late OvertimeConfigurationService configService;

    setUp(() {
      calculateOvertimeUseCase = CalculateOvertimeHoursUseCase();
      configService = OvertimeConfigurationService();
    });

    group('User Entity Default Threshold', () {
      test('should use 8.3 hours (8h18) as default threshold', () {
        // Arrange & Act
        final user = User(
          firstName: 'Test',
          lastName: 'User',
          company: 'Test Company',
          isDeliveryManager: false,
        );

        // Assert
        expect(user.normalHoursThreshold, 8.3);
      });

      test('should allow custom threshold override', () {
        // Arrange & Act
        final user = User(
          firstName: 'Test',
          lastName: 'User',
          company: 'Test Company',
          isDeliveryManager: false,
          normalHoursThreshold: 7.5,
        );

        // Assert
        expect(user.normalHoursThreshold, 7.5);
      });
    });

    group('Overtime Calculation with 8h18 Threshold', () {
      test('should calculate overtime correctly with 8h18 threshold', () async {
        // Arrange
        final entry = TimesheetEntry(
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
        final result = await calculateOvertimeUseCase.execute(
          entry: entry,
          normalHoursThreshold: 8.3, // 8h18
        );

        // Assert
        expect(
            result, Duration(minutes: 42)); // 9h - 8h18 = 42 minutes overtime
      });

      test('should return zero overtime when under 8h18 threshold', () async {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '08-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00', // 7 hours total
          hasOvertimeHours: true,
          isWeekendDay: false,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.WEEKDAY_ONLY,
        );

        // Act
        final result = await calculateOvertimeUseCase.execute(
          entry: entry,
          normalHoursThreshold: 8.3, // 8h18
        );

        // Assert
        expect(result, Duration.zero); // Under threshold, no overtime
      });

      test('should calculate exact threshold correctly', () async {
        // Arrange - exactly 8h18
        final entry = TimesheetEntry(
          dayDate: '08-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:18', // Exactly 8h18
          hasOvertimeHours: true,
          isWeekendDay: false,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.WEEKDAY_ONLY,
        );

        // Act
        final result = await calculateOvertimeUseCase.execute(
          entry: entry,
          normalHoursThreshold: 8.3, // 8h18
        );

        // Assert
        expect(result, Duration.zero); // Exactly at threshold, no overtime
      });

      test('should calculate small overtime correctly', () async {
        // Arrange - 8h20 (2 minutes over threshold)
        final entry = TimesheetEntry(
          dayDate: '08-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:20', // 8h20
          hasOvertimeHours: true,
          isWeekendDay: false,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.WEEKDAY_ONLY,
        );

        // Act
        final result = await calculateOvertimeUseCase.execute(
          entry: entry,
          normalHoursThreshold: 8.3, // 8h18
        );

        // Assert
        expect(
            result, Duration(minutes: 2)); // 8h20 - 8h18 = 2 minutes overtime
      });
    });

    group('Weekend Overtime (Not Affected by Threshold)', () {
      test(
          'should return all hours as overtime for weekend regardless of threshold',
          () async {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '06-Jan-24', // Saturday
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // Only 6 hours (under threshold)
          hasOvertimeHours: false,
          isWeekendDay: true,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.WEEKEND_ONLY,
        );

        // Act
        final result = await calculateOvertimeUseCase.execute(
          entry: entry,
          normalHoursThreshold: 8.3, // 8h18
        );

        // Assert
        expect(
            result, Duration(hours: 6)); // All 6 hours are overtime for weekend
      });
    });

    group('Configuration Service Integration', () {
      test('should use 8h18 as default daily work threshold', () async {
        // Act
        final threshold = await configService.getDailyWorkThreshold();

        // Assert
        expect(threshold, Duration(hours: 8, minutes: 18));
      });

      test('should allow setting custom threshold', () async {
        // Arrange
        final customThreshold = Duration(hours: 7, minutes: 30);

        // Act
        await configService.setDailyWorkThreshold(customThreshold);
        final retrievedThreshold = await configService.getDailyWorkThreshold();

        // Assert
        expect(retrievedThreshold, customThreshold);
      });
    });

    group('Threshold Conversion', () {
      test('should convert 8h18 to 8.3 decimal hours correctly', () {
        // Arrange
        const duration = Duration(hours: 8, minutes: 18);

        // Act
        final decimalHours = duration.inMinutes / 60.0;

        // Assert
        expect(decimalHours, 8.3);
      });

      test('should convert decimal hours back to duration correctly', () {
        // Arrange
        const decimalHours = 8.3;

        // Act
        final duration = Duration(
          hours: decimalHours.floor(),
          minutes: ((decimalHours % 1) * 60).round(),
        );

        // Assert
        expect(duration, Duration(hours: 8, minutes: 18));
      });

      test('should handle various threshold values correctly', () {
        // Test cases for different thresholds
        final testCases = [
          {'decimal': 7.5, 'duration': Duration(hours: 7, minutes: 30)},
          {'decimal': 8.0, 'duration': Duration(hours: 8, minutes: 0)},
          {'decimal': 8.25, 'duration': Duration(hours: 8, minutes: 15)},
          {'decimal': 8.3, 'duration': Duration(hours: 8, minutes: 18)},
          {'decimal': 8.5, 'duration': Duration(hours: 8, minutes: 30)},
          {'decimal': 9.0, 'duration': Duration(hours: 9, minutes: 0)},
        ];

        for (final testCase in testCases) {
          final decimal = testCase['decimal'] as double;
          final expectedDuration = testCase['duration'] as Duration;

          // Convert decimal to duration
          final convertedDuration = Duration(
            hours: decimal.floor(),
            minutes: ((decimal % 1) * 60).round(),
          );

          expect(convertedDuration, expectedDuration,
              reason: 'Failed for decimal $decimal');

          // Convert duration back to decimal
          final convertedDecimal = convertedDuration.inMinutes / 60.0;
          expect(convertedDecimal, decimal,
              reason: 'Failed reverse conversion for $expectedDuration');
        }
      });
    });
  });
}
