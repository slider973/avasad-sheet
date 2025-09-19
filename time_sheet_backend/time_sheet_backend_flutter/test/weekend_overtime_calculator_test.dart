import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:time_sheet/services/weekend_overtime_calculator.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/enum/overtime_type.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';

import 'weekend_overtime_calculator_test.mocks.dart';

@GenerateMocks([WeekendDetectionService])
void main() {
  group('WeekendOvertimeCalculator', () {
    late WeekendOvertimeCalculator calculator;
    late MockWeekendDetectionService mockWeekendDetectionService;

    setUp(() {
      mockWeekendDetectionService = MockWeekendDetectionService();
      calculator = WeekendOvertimeCalculator(
        weekendDetectionService: mockWeekendDetectionService,
      );
    });

    group('calculateWeekendOvertime', () {
      test('should return zero for weekday entries', () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '01-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          isWeekendDay: false,
        );

        // Act
        final result = calculator.calculateWeekendOvertime(entry);

        // Assert
        expect(result, equals(Duration.zero));
      });

      test('should return all hours for weekend entries', () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '06-Jan-24', // Saturday
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          isWeekendDay: true,
        );

        // Act
        final result = calculator.calculateWeekendOvertime(entry);

        // Assert
        expect(result,
            equals(const Duration(hours: 7))); // 3h morning + 4h afternoon
      });

      test('should return zero for weekend entries with no hours worked', () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '06-Jan-24', // Saturday
          dayOfWeekDate: 'Saturday',
          startMorning: '',
          endMorning: '',
          startAfternoon: '',
          endAfternoon: '',
          isWeekendDay: true,
        );

        // Act
        final result = calculator.calculateWeekendOvertime(entry);

        // Assert
        expect(result, equals(Duration.zero));
      });
    });

    group('calculateWeekdayOvertime', () {
      test('should return zero for weekend entries', () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '06-Jan-24', // Saturday
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '18:00',
          isWeekendDay: true,
          hasOvertimeHours: true,
        );

        // Act
        final result = calculator.calculateWeekdayOvertime(entry);

        // Assert
        expect(result, equals(Duration.zero));
      });

      test('should return zero for weekday entries without overtime flag', () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '01-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '18:00', // 8 hours total
          isWeekendDay: false,
          hasOvertimeHours: false,
        );

        // Act
        final result = calculator.calculateWeekdayOvertime(entry);

        // Assert
        expect(result, equals(Duration.zero));
      });

      test('should return overtime hours for weekday entries exceeding 8 hours',
          () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '01-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 9 hours total
          isWeekendDay: false,
          hasOvertimeHours: true,
        );

        // Act
        final result = calculator.calculateWeekdayOvertime(entry);

        // Assert
        expect(result,
            equals(const Duration(hours: 1))); // 9 - 8 = 1 hour overtime
      });

      test('should return zero for weekday entries with 8 hours or less', () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '01-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00', // 7 hours total
          isWeekendDay: false,
          hasOvertimeHours: true,
        );

        // Act
        final result = calculator.calculateWeekdayOvertime(entry);

        // Assert
        expect(result, equals(Duration.zero));
      });
    });

    group('calculateMonthlyOvertime', () {
      test('should calculate comprehensive monthly summary', () async {
        // Arrange
        final entries = [
          // Weekday with overtime
          TimesheetEntry(
            dayDate: '01-Jan-24', // Monday
            dayOfWeekDate: 'Monday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 9 hours
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
          // Regular weekday
          TimesheetEntry(
            dayDate: '02-Jan-24', // Tuesday
            dayOfWeekDate: 'Tuesday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 7 hours
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),
          // Weekend day
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '10:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 6 hours
            isWeekendDay: true,
          ),
        ];

        // Mock weekend detection
        when(mockWeekendDetectionService.shouldApplyWeekendOvertime(any))
            .thenAnswer((invocation) async {
          final date = invocation.positionalArguments[0] as DateTime;
          return date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday;
        });

        // Act
        final result = await calculator.calculateMonthlyOvertime(entries);

        // Assert
        expect(result.weekdayOvertime,
            equals(const Duration(hours: 1))); // 9 - 8 = 1
        expect(result.weekendOvertime,
            equals(const Duration(hours: 6))); // All weekend hours
        expect(result.regularHours,
            equals(const Duration(hours: 15))); // 8 + 7 = 15
        expect(result.totalOvertime,
            equals(const Duration(hours: 7))); // 1 + 6 = 7
        expect(result.totalHours,
            equals(const Duration(hours: 22))); // 15 + 7 = 22
        expect(result.weekdayOvertimeRate, equals(1.25));
        expect(result.weekendOvertimeRate, equals(1.5));
      });

      test('should handle entries with absences', () async {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Monday',
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absence: AbsenceEntity(
              id: 1,
              startDate: DateTime(2024, 1, 1),
              endDate: DateTime(2024, 1, 1),
              type: AbsenceType.sickLeave,
              motif: 'Sick',
            ),
            isWeekendDay: false,
          ),
        ];

        // Act
        final result = await calculator.calculateMonthlyOvertime(entries);

        // Assert
        expect(result.weekdayOvertime, equals(Duration.zero));
        expect(result.weekendOvertime, equals(Duration.zero));
        expect(result.regularHours, equals(Duration.zero));
        expect(result.totalOvertime, equals(Duration.zero));
      });

      test('should use custom overtime rates when provided', () async {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '10:00',
            endMorning: '14:00', // 4 hours
            startAfternoon: '',
            endAfternoon: '',
            isWeekendDay: true,
          ),
        ];

        when(mockWeekendDetectionService.shouldApplyWeekendOvertime(any))
            .thenAnswer((_) async => true);

        // Act
        final result = await calculator.calculateMonthlyOvertime(
          entries,
          weekdayRate: 1.3,
          weekendRate: 2.0,
        );

        // Assert
        expect(result.weekdayOvertimeRate, equals(1.3));
        expect(result.weekendOvertimeRate, equals(2.0));
      });
    });

    group('determineOvertimeType', () {
      test('should return NONE for entries with absences', () async {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '',
          endMorning: '',
          startAfternoon: '',
          endAfternoon: '',
          absence: AbsenceEntity(
            id: 1,
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 1),
            type: AbsenceType.sickLeave,
            motif: 'Sick',
          ),
          isWeekendDay: false,
        );

        // Act
        final result = await calculator.determineOvertimeType(entry);

        // Assert
        expect(result, equals(OvertimeType.NONE));
      });

      test('should return WEEKEND_ONLY for weekend work', () async {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '06-Jan-24', // Saturday
          dayOfWeekDate: 'Saturday',
          startMorning: '10:00',
          endMorning: '14:00',
          startAfternoon: '',
          endAfternoon: '',
          isWeekendDay: true,
        );

        when(mockWeekendDetectionService.shouldApplyWeekendOvertime(any))
            .thenAnswer((_) async => true);

        // Act
        final result = await calculator.determineOvertimeType(entry);

        // Assert
        expect(result, equals(OvertimeType.WEEKEND_ONLY));
      });

      test('should return WEEKDAY_ONLY for weekday overtime', () async {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '01-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 9 hours
          isWeekendDay: false,
        );

        when(mockWeekendDetectionService.shouldApplyWeekendOvertime(any))
            .thenAnswer((_) async => false);

        // Act
        final result = await calculator.determineOvertimeType(entry);

        // Assert
        expect(result, equals(OvertimeType.WEEKDAY_ONLY));
      });

      test('should return NONE for regular weekday work', () async {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '01-Jan-24', // Monday
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00', // 7 hours
          isWeekendDay: false,
        );

        when(mockWeekendDetectionService.shouldApplyWeekendOvertime(any))
            .thenAnswer((_) async => false);

        // Act
        final result = await calculator.determineOvertimeType(entry);

        // Assert
        expect(result, equals(OvertimeType.NONE));
      });
    });

    group('calculateTotalCompensatedHours', () {
      test('should calculate total compensated hours with overtime rates', () {
        // Arrange
        const summary = OvertimeSummary(
          regularHours: Duration(hours: 40),
          weekdayOvertime: Duration(hours: 5),
          weekendOvertime: Duration(hours: 8),
          weekdayOvertimeRate: 1.25,
          weekendOvertimeRate: 1.5,
        );

        // Act
        final result = calculator.calculateTotalCompensatedHours(summary);

        // Assert
        // 40 regular + (5 * 1.25) weekday overtime + (8 * 1.5) weekend overtime
        // = 40 + 6.25 + 12 = 58.25
        expect(result, equals(58.25));
      });

      test('should handle zero hours correctly', () {
        // Arrange
        const summary = OvertimeSummary(
          regularHours: Duration.zero,
          weekdayOvertime: Duration.zero,
          weekendOvertime: Duration.zero,
          weekdayOvertimeRate: 1.25,
          weekendOvertimeRate: 1.5,
        );

        // Act
        final result = calculator.calculateTotalCompensatedHours(summary);

        // Assert
        expect(result, equals(0.0));
      });
    });

    group('getOvertimeRates', () {
      test('should return default weekday overtime rate', () {
        // Act
        final result = calculator.getWeekdayOvertimeRate();

        // Assert
        expect(result, equals(1.25));
      });

      test('should return default weekend overtime rate', () {
        // Act
        final result = calculator.getWeekendOvertimeRate();

        // Assert
        expect(result, equals(1.5));
      });
    });
  });

  group('OvertimeSummary', () {
    test('should calculate total overtime correctly', () {
      // Arrange
      const summary = OvertimeSummary(
        regularHours: Duration(hours: 40),
        weekdayOvertime: Duration(hours: 5),
        weekendOvertime: Duration(hours: 8),
        weekdayOvertimeRate: 1.25,
        weekendOvertimeRate: 1.5,
      );

      // Assert
      expect(summary.totalOvertime, equals(const Duration(hours: 13)));
      expect(summary.totalHours, equals(const Duration(hours: 53)));
      expect(summary.hasOvertime, isTrue);
      expect(summary.hasWeekendOvertime, isTrue);
      expect(summary.hasWeekdayOvertime, isTrue);
    });

    test('should format durations correctly', () {
      // Arrange
      const summary = OvertimeSummary(
        regularHours: Duration(hours: 8, minutes: 30),
        weekdayOvertime: Duration(hours: 1, minutes: 15),
        weekendOvertime: Duration(hours: 4, minutes: 45),
        weekdayOvertimeRate: 1.25,
        weekendOvertimeRate: 1.5,
      );

      // Assert
      expect(summary.formattedRegularHours, equals('8h 30m'));
      expect(summary.formattedWeekdayOvertime, equals('1h 15m'));
      expect(summary.formattedWeekendOvertime, equals('4h 45m'));
      expect(summary.formattedTotalOvertime, equals('6h 00m'));
      expect(summary.formattedTotalHours, equals('14h 30m'));
    });

    test('should handle zero durations in formatting', () {
      // Arrange
      const summary = OvertimeSummary(
        regularHours: Duration.zero,
        weekdayOvertime: Duration.zero,
        weekendOvertime: Duration.zero,
        weekdayOvertimeRate: 1.25,
        weekendOvertimeRate: 1.5,
      );

      // Assert
      expect(summary.formattedRegularHours, equals('0h 00m'));
      expect(summary.formattedTotalOvertime, equals('0h 00m'));
      expect(summary.hasOvertime, isFalse);
      expect(summary.hasWeekendOvertime, isFalse);
      expect(summary.hasWeekdayOvertime, isFalse);
    });

    test('should implement equality correctly', () {
      // Arrange
      const summary1 = OvertimeSummary(
        regularHours: Duration(hours: 40),
        weekdayOvertime: Duration(hours: 5),
        weekendOvertime: Duration(hours: 8),
        weekdayOvertimeRate: 1.25,
        weekendOvertimeRate: 1.5,
      );

      const summary2 = OvertimeSummary(
        regularHours: Duration(hours: 40),
        weekdayOvertime: Duration(hours: 5),
        weekendOvertime: Duration(hours: 8),
        weekdayOvertimeRate: 1.25,
        weekendOvertimeRate: 1.5,
      );

      const summary3 = OvertimeSummary(
        regularHours: Duration(hours: 35),
        weekdayOvertime: Duration(hours: 5),
        weekendOvertime: Duration(hours: 8),
        weekdayOvertimeRate: 1.25,
        weekendOvertimeRate: 1.5,
      );

      // Assert
      expect(summary1, equals(summary2));
      expect(summary1, isNot(equals(summary3)));
      expect(summary1.hashCode, equals(summary2.hashCode));
      expect(summary1.hashCode, isNot(equals(summary3.hashCode)));
    });

    test('should provide meaningful toString representation', () {
      // Arrange
      const summary = OvertimeSummary(
        regularHours: Duration(hours: 40),
        weekdayOvertime: Duration(hours: 5),
        weekendOvertime: Duration(hours: 8),
        weekdayOvertimeRate: 1.25,
        weekendOvertimeRate: 1.5,
      );

      // Act
      final result = summary.toString();

      // Assert
      expect(result, contains('regularHours: 40h 00m'));
      expect(result, contains('weekdayOvertime: 5h 00m (1.25x)'));
      expect(result, contains('weekendOvertime: 8h 00m (1.5x)'));
      expect(result, contains('totalOvertime: 13h 00m'));
      expect(result, contains('totalHours: 53h 00m'));
    });
  });
}
