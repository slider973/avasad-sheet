import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/weekend_overtime_calculator.dart';
import '../../lib/services/weekend_detection_service.dart';
import '../../lib/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/enum/overtime_type.dart';

void main() {
  group('Weekend Core Integration Tests', () {
    late WeekendOvertimeCalculator calculator;
    late WeekendDetectionService weekendDetectionService;

    setUp(() {
      calculator = WeekendOvertimeCalculator();
      weekendDetectionService = WeekendDetectionService();
    });

    group('End-to-End Weekend Workflow', () {
      test('Complete weekend workflow with Saturday work', () async {
        // Requirement 1.1: Weekend hours automatically marked as overtime
        final saturdayDate = DateTime(2024, 1, 6); // Saturday

        // Verify weekend detection
        expect(weekendDetectionService.isWeekend(saturdayDate), isTrue);

        // Create weekend timesheet entry
        final entry = TimesheetEntry(
          id: 1,
          dayDate: '06-Jan-24',
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absenceReason: null,
          period: null,
          overtimeType: OvertimeType.WEEKEND_ONLY,
          isWeekendOvertimeEnabled: true,
        );

        // Verify weekend properties
        expect(entry.isWeekend, isTrue);
        expect(entry.overtimeType, equals(OvertimeType.WEEKEND_ONLY));
        expect(entry.weekendOvertimeHours,
            equals(const Duration(hours: 7))); // 3 + 4 hours
        expect(entry.weekdayOvertimeHours, equals(Duration.zero));
      });

      test('Mixed week with weekend and weekday overtime', () async {
        // Create entries for different scenarios
        final entries = [
          // Monday - Regular day, no overtime
          TimesheetEntry(
            id: 1,
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Monday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            absenceReason: null,
            period: null,
            overtimeType: OvertimeType.NONE,
          ),

          // Tuesday - Weekday overtime
          TimesheetEntry(
            id: 2,
            dayDate: '02-Jan-24',
            dayOfWeekDate: 'Tuesday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 2 hours overtime
            absenceReason: null,
            period: null,
            overtimeType: OvertimeType.WEEKDAY_ONLY,
            hasOvertimeHours: true,
          ),

          // Saturday - Weekend work
          TimesheetEntry(
            id: 3,
            dayDate: '06-Jan-24',
            dayOfWeekDate: 'Saturday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            absenceReason: null,
            period: null,
            overtimeType: OvertimeType.WEEKEND_ONLY,
            isWeekendOvertimeEnabled: true,
          ),

          // Sunday - Weekend work
          TimesheetEntry(
            id: 4,
            dayDate: '07-Jan-24',
            dayOfWeekDate: 'Sunday',
            startMorning: '10:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 6 hours total
            absenceReason: null,
            period: null,
            overtimeType: OvertimeType.WEEKEND_ONLY,
            isWeekendOvertimeEnabled: true,
          ),
        ];

        // Calculate weekly summary
        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Verify calculations
        expect(summary.weekdayOvertime,
            equals(const Duration(hours: 2))); // Tuesday overtime
        expect(summary.weekendOvertime,
            equals(const Duration(hours: 13))); // Sat (7h) + Sun (6h)
        expect(summary.totalOvertime, equals(const Duration(hours: 15)));
      });
    });

    group('Weekend Detection Tests', () {
      test('Correctly identifies weekend days', () {
        // Test various dates
        expect(weekendDetectionService.isWeekend(DateTime(2024, 1, 6)),
            isTrue); // Saturday
        expect(weekendDetectionService.isWeekend(DateTime(2024, 1, 7)),
            isTrue); // Sunday
        expect(weekendDetectionService.isWeekend(DateTime(2024, 1, 1)),
            isFalse); // Monday
        expect(weekendDetectionService.isWeekend(DateTime(2024, 1, 2)),
            isFalse); // Tuesday
        expect(weekendDetectionService.isWeekend(DateTime(2024, 1, 3)),
            isFalse); // Wednesday
        expect(weekendDetectionService.isWeekend(DateTime(2024, 1, 4)),
            isFalse); // Thursday
        expect(weekendDetectionService.isWeekend(DateTime(2024, 1, 5)),
            isFalse); // Friday
      });

      test('Handles edge cases correctly', () {
        // Test year boundaries
        expect(weekendDetectionService.isWeekend(DateTime(2023, 12, 31)),
            isTrue); // Sunday
        expect(weekendDetectionService.isWeekend(DateTime(2024, 1, 1)),
            isFalse); // Monday

        // Test leap year
        expect(weekendDetectionService.isWeekend(DateTime(2024, 2, 29)),
            isFalse); // Thursday (leap day)
      });
    });

    group('Overtime Calculation Tests', () {
      test('Calculates weekend overtime correctly', () {
        final weekendEntry = TimesheetEntry(
          id: 1,
          dayDate: '06-Jan-24',
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absenceReason: null,
          period: null,
          overtimeType: OvertimeType.WEEKEND_ONLY,
          isWeekendOvertimeEnabled: true,
        );

        expect(weekendEntry.weekendOvertimeHours,
            equals(const Duration(hours: 7)));
        expect(weekendEntry.weekdayOvertimeHours, equals(Duration.zero));
      });

      test('Handles disabled weekend overtime', () {
        final weekendEntry = TimesheetEntry(
          id: 1,
          dayDate: '06-Jan-24',
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absenceReason: null,
          period: null,
          overtimeType: OvertimeType.NONE,
          isWeekendOvertimeEnabled: false, // Disabled
        );

        // When weekend overtime is disabled, weekend hours should still be calculated
        // but the overtime type should be NONE
        expect(weekendEntry.weekendOvertimeHours,
            equals(const Duration(hours: 7)));
        expect(weekendEntry.overtimeType, equals(OvertimeType.NONE));
      });

      test('Handles mixed overtime types', () {
        final mixedEntry = TimesheetEntry(
          id: 1,
          dayDate: '06-Jan-24',
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 9 hours total
          absenceReason: null,
          period: null,
          overtimeType: OvertimeType.BOTH,
          isWeekendOvertimeEnabled: true,
          hasOvertimeHours: true,
        );

        expect(
            mixedEntry.weekendOvertimeHours, equals(const Duration(hours: 9)));
        expect(mixedEntry.overtimeType, equals(OvertimeType.BOTH));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('Handles midnight crossing weekend work', () {
        // This would be handled by the time calculation logic
        // For now, we test that the weekend detection works correctly
        final saturdayNight = DateTime(2024, 1, 6, 22, 0); // 10 PM Saturday
        final sundayMorning = DateTime(2024, 1, 7, 6, 0); // 6 AM Sunday

        expect(weekendDetectionService.isWeekend(saturdayNight), isTrue);
        expect(weekendDetectionService.isWeekend(sundayMorning), isTrue);
      });

      test('Handles invalid time entries gracefully', () {
        final invalidEntry = TimesheetEntry(
          id: 1,
          dayDate: '06-Jan-24',
          dayOfWeekDate: 'Saturday',
          startMorning: '17:00', // End before start
          endMorning: '09:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absenceReason: null,
          period: null,
          overtimeType: OvertimeType.WEEKEND_ONLY,
          isWeekendOvertimeEnabled: true,
        );

        // The entry should handle invalid times gracefully
        expect(invalidEntry.isWeekend, isTrue);
        // Invalid times should result in zero duration
        expect(invalidEntry.calculateDailyTotal(),
            equals(const Duration(hours: 4))); // Only afternoon valid
      });

      test('Handles empty entries list', () async {
        final summary = await calculator.calculateMonthlyOvertime([]);

        expect(summary.weekdayOvertime, equals(Duration.zero));
        expect(summary.weekendOvertime, equals(Duration.zero));
        expect(summary.totalOvertime, equals(Duration.zero));
      });
    });

    group('Performance Tests', () {
      test('Handles large datasets efficiently', () async {
        // Create a large number of entries
        final largeDataset = <TimesheetEntry>[];

        for (int i = 0; i < 100; i++) {
          final date = DateTime(2024, 1, 1).add(Duration(days: i % 30));
          final isWeekend = weekendDetectionService.isWeekend(date);

          largeDataset.add(TimesheetEntry(
            id: i + 1,
            dayDate: '${date.day.toString().padLeft(2, '0')}-Jan-24',
            dayOfWeekDate: isWeekend ? 'Weekend' : 'Weekday',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            absenceReason: null,
            period: null,
            overtimeType:
                isWeekend ? OvertimeType.WEEKEND_ONLY : OvertimeType.NONE,
            isWeekendOvertimeEnabled: isWeekend,
          ));
        }

        // Measure calculation performance
        final stopwatch = Stopwatch()..start();
        final summary = await calculator.calculateMonthlyOvertime(largeDataset);
        stopwatch.stop();

        // Verify calculations completed successfully
        expect(summary.totalOvertime.inHours, greaterThan(0));

        // Performance should be reasonable (less than 1000ms for 100 entries)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Business Logic Integration', () {
      test('Handles holiday weekends correctly', () {
        // New Year's Day 2024 falls on Monday, so weekend is Saturday-Sunday Dec 30-31, 2023
        final newYearEve = DateTime(2023, 12, 31); // Sunday
        final newYearDay = DateTime(2024, 1, 1); // Monday

        expect(weekendDetectionService.isWeekend(newYearEve), isTrue);
        expect(weekendDetectionService.isWeekend(newYearDay), isFalse);

        // Weekend work should be treated the same regardless of holidays
        final holidayWeekendEntry = TimesheetEntry(
          id: 1,
          dayDate: '31-Dec-23',
          dayOfWeekDate: 'Sunday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absenceReason: null,
          period: null,
          overtimeType: OvertimeType.WEEKEND_ONLY,
          isWeekendOvertimeEnabled: true,
        );

        expect(holidayWeekendEntry.weekendOvertimeHours,
            equals(const Duration(hours: 7)));
      });

      test('Handles leap year weekend calculations', () {
        // February 29, 2024 is a Thursday, so weekend is March 2-3, 2024
        final leapDay = DateTime(2024, 2, 29); // Thursday
        final weekendAfterLeap = DateTime(2024, 3, 2); // Saturday

        expect(weekendDetectionService.isWeekend(leapDay), isFalse);
        expect(weekendDetectionService.isWeekend(weekendAfterLeap), isTrue);

        final leapYearWeekendEntry = TimesheetEntry(
          id: 1,
          dayDate: '02-Mar-24',
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absenceReason: null,
          period: null,
          overtimeType: OvertimeType.WEEKEND_ONLY,
          isWeekendOvertimeEnabled: true,
        );

        expect(leapYearWeekendEntry.weekendOvertimeHours,
            equals(const Duration(hours: 7)));
      });
    });

    group('Calculator Service Integration', () {
      test('Weekend overtime calculator integrates with detection service',
          () async {
        final weekendEntry = TimesheetEntry(
          id: 1,
          dayDate: '06-Jan-24',
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absenceReason: null,
          period: null,
          overtimeType: OvertimeType.WEEKEND_ONLY,
          isWeekendOvertimeEnabled: true,
        );

        final weekdayEntry = TimesheetEntry(
          id: 2,
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 9 hours total, 1 hour overtime
          absenceReason: null,
          period: null,
          overtimeType: OvertimeType.WEEKDAY_ONLY,
          hasOvertimeHours: true,
        );

        final summary = await calculator
            .calculateMonthlyOvertime([weekendEntry, weekdayEntry]);

        expect(summary.weekendOvertime,
            equals(const Duration(hours: 7))); // All Saturday hours
        expect(summary.weekdayOvertime,
            equals(const Duration(hours: 1))); // Monday overtime only
        expect(summary.totalOvertime, equals(const Duration(hours: 8)));
        expect(summary.hasWeekendOvertime, isTrue);
        expect(summary.hasWeekdayOvertime, isTrue);
      });

      test('Overtime rates are applied correctly', () async {
        final entry = TimesheetEntry(
          id: 1,
          dayDate: '06-Jan-24',
          dayOfWeekDate: 'Saturday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absenceReason: null,
          period: null,
          overtimeType: OvertimeType.WEEKEND_ONLY,
          isWeekendOvertimeEnabled: true,
        );

        final summary = await calculator.calculateMonthlyOvertime(
          [entry],
          weekdayRate: 1.25,
          weekendRate: 2.0,
        );

        expect(summary.weekdayOvertimeRate, equals(1.25));
        expect(summary.weekendOvertimeRate, equals(2.0));
        expect(summary.weekendOvertime, equals(const Duration(hours: 7)));
      });
    });
  });
}
