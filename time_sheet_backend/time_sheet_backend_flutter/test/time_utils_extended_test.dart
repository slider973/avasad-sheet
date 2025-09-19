import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/utils/time_utils.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/enum/overtime_type.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';

void main() {
  group('TimeUtils Extended Weekend Functionality', () {
    group('isWeekend', () {
      test('should return true for Saturday', () {
        // Arrange
        final saturday = DateTime(2024, 1, 6); // Saturday

        // Act
        final result = TimeUtils.isWeekend(saturday);

        // Assert
        expect(result, isTrue);
      });

      test('should return true for Sunday', () {
        // Arrange
        final sunday = DateTime(2024, 1, 7); // Sunday

        // Act
        final result = TimeUtils.isWeekend(sunday);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for weekdays', () {
        // Arrange
        final monday = DateTime(2024, 1, 1); // Monday
        final tuesday = DateTime(2024, 1, 2); // Tuesday
        final wednesday = DateTime(2024, 1, 3); // Wednesday
        final thursday = DateTime(2024, 1, 4); // Thursday
        final friday = DateTime(2024, 1, 5); // Friday

        // Act & Assert
        expect(TimeUtils.isWeekend(monday), isFalse);
        expect(TimeUtils.isWeekend(tuesday), isFalse);
        expect(TimeUtils.isWeekend(wednesday), isFalse);
        expect(TimeUtils.isWeekend(thursday), isFalse);
        expect(TimeUtils.isWeekend(friday), isFalse);
      });

      test('should respect custom weekend days', () {
        // Arrange
        final friday = DateTime(2024, 1, 5); // Friday
        final saturday = DateTime(2024, 1, 6); // Saturday
        final customWeekendDays = [DateTime.friday, DateTime.saturday];

        // Act & Assert
        expect(
            TimeUtils.isWeekend(friday, customWeekendDays: customWeekendDays),
            isTrue);
        expect(
            TimeUtils.isWeekend(saturday, customWeekendDays: customWeekendDays),
            isTrue);
        expect(
            TimeUtils.isWeekend(DateTime(2024, 1, 7),
                customWeekendDays: customWeekendDays),
            isFalse); // Sunday
      });
    });

    group('calculateWeekendHours', () {
      test('should calculate total weekend hours correctly', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '01-Jan-24', // Monday
            dayOfWeekDate: 'Monday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 7 hours
            isWeekendDay: false,
          ),
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '10:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 6 hours
            isWeekendDay: true,
          ),
          TimesheetEntry(
            dayDate: '07-Jan-24', // Sunday
            dayOfWeekDate: 'Sunday',
            startMorning: '10:00',
            endMorning: '14:00',
            startAfternoon: '',
            endAfternoon: '', // 4 hours
            isWeekendDay: true,
          ),
        ];

        // Act
        final result = TimeUtils.calculateWeekendHours(entries);

        // Assert
        expect(result, equals(const Duration(hours: 10))); // 6 + 4 = 10 hours
      });

      test('should exclude absence entries from weekend hours', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absenceReason: 'Sick',
            isWeekendDay: true,
          ),
          TimesheetEntry(
            dayDate: '07-Jan-24', // Sunday
            dayOfWeekDate: 'Sunday',
            startMorning: '10:00',
            endMorning: '14:00',
            startAfternoon: '',
            endAfternoon: '', // 4 hours
            isWeekendDay: true,
          ),
        ];

        // Act
        final result = TimeUtils.calculateWeekendHours(entries);

        // Assert
        expect(result, equals(const Duration(hours: 4))); // Only Sunday hours
      });

      test('should return zero when no weekend entries exist', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '01-Jan-24', // Monday
            dayOfWeekDate: 'Monday',
            startMorning: '09:00',
            endMorning: '17:00',
            startAfternoon: '',
            endAfternoon: '',
            isWeekendDay: false,
          ),
        ];

        // Act
        final result = TimeUtils.calculateWeekendHours(entries);

        // Assert
        expect(result, equals(Duration.zero));
      });
    });

    group('calculateWeekdayOvertimeHours', () {
      test('should calculate weekday overtime hours correctly', () {
        // Arrange
        final entries = [
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
          TimesheetEntry(
            dayDate: '02-Jan-24', // Tuesday
            dayOfWeekDate: 'Tuesday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '18:30', // 8.5 hours
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '10:00',
            endMorning: '18:00',
            startAfternoon: '',
            endAfternoon: '', // 8 hours
            isWeekendDay: true,
            hasOvertimeHours: true,
          ),
        ];

        // Act
        final result = TimeUtils.calculateWeekdayOvertimeHours(entries);

        // Assert
        expect(
            result,
            equals(const Duration(
                hours: 1, minutes: 30))); // (9-8) + (8.5-8) = 1.5 hours
      });

      test('should exclude entries without overtime flag', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '01-Jan-24', // Monday
            dayOfWeekDate: 'Monday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 9 hours
            isWeekendDay: false,
            hasOvertimeHours: false, // No overtime flag
          ),
        ];

        // Act
        final result = TimeUtils.calculateWeekdayOvertimeHours(entries);

        // Assert
        expect(result, equals(Duration.zero));
      });

      test('should return zero for entries with 8 hours or less', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '01-Jan-24', // Monday
            dayOfWeekDate: 'Monday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 7 hours
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
        ];

        // Act
        final result = TimeUtils.calculateWeekdayOvertimeHours(entries);

        // Assert
        expect(result, equals(Duration.zero));
      });
    });

    group('calculateWeekendOvertimeHours', () {
      test('should return same as calculateWeekendHours', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '10:00',
            endMorning: '14:00',
            startAfternoon: '',
            endAfternoon: '', // 4 hours
            isWeekendDay: true,
          ),
        ];

        // Act
        final weekendHours = TimeUtils.calculateWeekendHours(entries);
        final weekendOvertimeHours =
            TimeUtils.calculateWeekendOvertimeHours(entries);

        // Assert
        expect(weekendOvertimeHours, equals(weekendHours));
        expect(weekendOvertimeHours, equals(const Duration(hours: 4)));
      });
    });

    group('calculateRegularHours', () {
      test('should calculate regular hours correctly', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '01-Jan-24', // Monday
            dayOfWeekDate: 'Monday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 7 hours
            isWeekendDay: false,
          ),
          TimesheetEntry(
            dayDate: '02-Jan-24', // Tuesday
            dayOfWeekDate: 'Tuesday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 9 hours (1 hour overtime)
            isWeekendDay: false,
          ),
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '10:00',
            endMorning: '14:00',
            startAfternoon: '',
            endAfternoon: '', // 4 hours (should be excluded)
            isWeekendDay: true,
          ),
        ];

        // Act
        final result = TimeUtils.calculateRegularHours(entries);

        // Assert
        expect(
            result,
            equals(const Duration(
                hours: 15))); // 7 + 8 = 15 hours (weekend excluded)
      });

      test('should exclude absence entries', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '01-Jan-24', // Monday
            dayOfWeekDate: 'Monday',
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absenceReason: 'Sick',
            isWeekendDay: false,
          ),
          TimesheetEntry(
            dayDate: '02-Jan-24', // Tuesday
            dayOfWeekDate: 'Tuesday',
            startMorning: '09:00',
            endMorning: '17:00',
            startAfternoon: '',
            endAfternoon: '', // 8 hours
            isWeekendDay: false,
          ),
        ];

        // Act
        final result = TimeUtils.calculateRegularHours(entries);

        // Assert
        expect(result, equals(const Duration(hours: 8))); // Only Tuesday hours
      });
    });

    group('calculateTotalOvertimeHours', () {
      test('should combine weekday and weekend overtime hours', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '01-Jan-24', // Monday
            dayOfWeekDate: 'Monday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 9 hours (1 hour overtime)
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '10:00',
            endMorning: '16:00',
            startAfternoon: '',
            endAfternoon: '', // 6 hours (all overtime)
            isWeekendDay: true,
          ),
        ];

        // Act
        final result = TimeUtils.calculateTotalOvertimeHours(entries);

        // Assert
        expect(result, equals(const Duration(hours: 7))); // 1 + 6 = 7 hours
      });
    });

    group('groupEntriesByOvertimeType', () {
      test('should group entries correctly by overtime type', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '01-Jan-24', // Monday - regular
            dayOfWeekDate: 'Monday',
            startMorning: '09:00',
            endMorning: '17:00',
            startAfternoon: '',
            endAfternoon: '', // 8 hours
            isWeekendDay: false,
          ),
          TimesheetEntry(
            dayDate: '02-Jan-24', // Tuesday - weekday overtime
            dayOfWeekDate: 'Tuesday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 9 hours
            isWeekendDay: false,
          ),
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday - weekend
            dayOfWeekDate: 'Saturday',
            startMorning: '10:00',
            endMorning: '14:00',
            startAfternoon: '',
            endAfternoon: '', // 4 hours
            isWeekendDay: true,
          ),
          TimesheetEntry(
            dayDate: '03-Jan-24', // Wednesday - absence
            dayOfWeekDate: 'Wednesday',
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absenceReason: 'Sick',
            isWeekendDay: false,
          ),
        ];

        // Act
        final result = TimeUtils.groupEntriesByOvertimeType(entries);

        // Assert
        expect(result[OvertimeType.NONE]!.length,
            equals(2)); // Regular Monday + Absence Wednesday
        expect(result[OvertimeType.WEEKDAY_ONLY]!.length, equals(1)); // Tuesday
        expect(
            result[OvertimeType.WEEKEND_ONLY]!.length, equals(1)); // Saturday
        expect(result[OvertimeType.BOTH]!.length, equals(0));
      });

      test('should handle entries with weekend work only', () {
        // Arrange - Weekend entries are always WEEKEND_ONLY since they can't have weekday overtime
        final entries = [
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 9 hours (all weekend overtime)
            isWeekendDay: true,
          ),
        ];

        // Act
        final result = TimeUtils.groupEntriesByOvertimeType(entries);

        // Assert
        expect(result[OvertimeType.WEEKEND_ONLY]!.length, equals(1));
        expect(result[OvertimeType.BOTH]!.length,
            equals(0)); // BOTH is not possible in practice
      });
    });

    group('formatDuration', () {
      test('should format duration without seconds by default', () {
        // Arrange
        const duration = Duration(hours: 8, minutes: 30, seconds: 45);

        // Act
        final result = TimeUtils.formatDuration(duration);

        // Assert
        expect(result, equals('8h 30m'));
      });

      test('should format duration with seconds when requested', () {
        // Arrange
        const duration = Duration(hours: 8, minutes: 30, seconds: 45);

        // Act
        final result = TimeUtils.formatDuration(duration, showSeconds: true);

        // Assert
        expect(result, equals('8h 30m 45s'));
      });

      test('should pad minutes and seconds with leading zeros', () {
        // Arrange
        const duration = Duration(hours: 8, minutes: 5, seconds: 3);

        // Act
        final result = TimeUtils.formatDuration(duration, showSeconds: true);

        // Assert
        expect(result, equals('8h 05m 03s'));
      });

      test('should handle zero duration', () {
        // Arrange
        const duration = Duration.zero;

        // Act
        final result = TimeUtils.formatDuration(duration);

        // Assert
        expect(result, equals('0h 00m'));
      });

      test('should handle durations over 24 hours', () {
        // Arrange
        const duration = Duration(hours: 25, minutes: 30);

        // Act
        final result = TimeUtils.formatDuration(duration);

        // Assert
        expect(result, equals('25h 30m'));
      });
    });

    group('calculateOvertimePercentage', () {
      test('should calculate overtime percentage correctly', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '01-Jan-24', // Monday
            dayOfWeekDate: 'Monday',
            startMorning: '09:00',
            endMorning: '17:00',
            startAfternoon: '',
            endAfternoon: '', // 8 hours
            isWeekendDay: false,
          ),
          TimesheetEntry(
            dayDate: '02-Jan-24', // Tuesday
            dayOfWeekDate: 'Tuesday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 9 hours (1 hour overtime)
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
          TimesheetEntry(
            dayDate: '06-Jan-24', // Saturday
            dayOfWeekDate: 'Saturday',
            startMorning: '10:00',
            endMorning: '13:00',
            startAfternoon: '',
            endAfternoon: '', // 3 hours (all overtime)
            isWeekendDay: true,
          ),
        ];

        // Act
        final result = TimeUtils.calculateOvertimePercentage(entries);

        // Assert
        // Total hours: 8 + 9 + 3 = 20 hours
        // Overtime hours: 1 + 3 = 4 hours
        // Percentage: (4 / 20) * 100 = 20%
        expect(result, equals(20.0));
      });

      test('should return zero for entries with no hours', () {
        // Arrange
        final entries = <TimesheetEntry>[];

        // Act
        final result = TimeUtils.calculateOvertimePercentage(entries);

        // Assert
        expect(result, equals(0.0));
      });

      test('should return zero when total hours is zero', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Monday',
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absenceReason: 'Sick',
            isWeekendDay: false,
          ),
        ];

        // Act
        final result = TimeUtils.calculateOvertimePercentage(entries);

        // Assert
        expect(result, equals(0.0));
      });
    });

    group('calculateTotalHoursWithOvertimeType', () {
      test('should return base duration when overtime multiplier is disabled',
          () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 9 hours
          isWeekendDay: false,
          hasOvertimeHours: true,
        );

        // Act
        final result = TimeUtils.calculateTotalHoursWithOvertimeType(entry);

        // Assert
        expect(result, equals(const Duration(hours: 9)));
      });

      test('should apply weekend multiplier for weekend entries', () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '06-Jan-24',
          dayOfWeekDate: 'Saturday',
          startMorning: '10:00',
          endMorning: '14:00',
          startAfternoon: '',
          endAfternoon: '', // 4 hours
          isWeekendDay: true,
        );

        // Act
        final result = TimeUtils.calculateTotalHoursWithOvertimeType(
          entry,
          includeOvertimeMultiplier: true,
        );

        // Assert
        // 4 hours * 1.5 = 6 hours
        expect(result, equals(const Duration(hours: 6)));
      });

      test('should apply weekday overtime multiplier correctly', () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 9 hours
          isWeekendDay: false,
          hasOvertimeHours: true,
        );

        // Act
        final result = TimeUtils.calculateTotalHoursWithOvertimeType(
          entry,
          includeOvertimeMultiplier: true,
        );

        // Assert
        // 8 regular hours + (1 overtime hour * 1.25) = 8 + 1.25 = 9.25 hours
        expect(result, equals(const Duration(hours: 9, minutes: 15)));
      });

      test('should return zero for absence entries', () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '',
          endMorning: '',
          startAfternoon: '',
          endAfternoon: '',
          absenceReason: 'Sick',
          isWeekendDay: false,
        );

        // Act
        final result = TimeUtils.calculateTotalHoursWithOvertimeType(
          entry,
          includeOvertimeMultiplier: true,
        );

        // Assert
        expect(result, equals(Duration.zero));
      });

      test(
          'should not apply multiplier for weekday entries with 8 hours or less',
          () {
        // Arrange
        final entry = TimesheetEntry(
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '17:00',
          startAfternoon: '',
          endAfternoon: '', // 8 hours
          isWeekendDay: false,
          hasOvertimeHours: false,
        );

        // Act
        final result = TimeUtils.calculateTotalHoursWithOvertimeType(
          entry,
          includeOvertimeMultiplier: true,
        );

        // Assert
        expect(result, equals(const Duration(hours: 8)));
      });
    });
  });
}
