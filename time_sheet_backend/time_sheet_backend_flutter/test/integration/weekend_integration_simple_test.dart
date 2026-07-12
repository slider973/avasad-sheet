import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/services/weekend_overtime_calculator.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';
import 'package:time_sheet/enum/overtime_type.dart';

/// Tests d'intégration weekend au niveau domaine.
///
/// Réécrits après la migration Isar -> PowerSync : l'ancienne version
/// persistait des TimesheetEntryModel dans une base Isar qui n'existe plus.
/// La logique métier testée (détection weekend + calcul des heures
/// supplémentaires) vit toujours dans WeekendDetectionService et
/// WeekendOvertimeCalculator.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Weekend Integration Tests', () {
    late WeekendOvertimeCalculator calculator;
    late WeekendDetectionService detectionService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      detectionService = WeekendDetectionService();
      await detectionService.setWeekendOvertimeEnabled(true);
      calculator = WeekendOvertimeCalculator(
        weekendDetectionService: detectionService,
      );
    });

    group('End-to-End Weekend Workflow', () {
      test('Complete weekend workflow with Saturday work', () async {
        // Requirement 1.1: Weekend hours automatically marked as overtime
        final entry = TimesheetEntry(
          dayDate: '06-Jan-24', // Saturday
          dayOfWeekDate: 'Samedi',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '18:00', // 8h total
          isWeekendDay: true,
          isWeekendOvertimeEnabled: true,
          overtimeType: OvertimeType.WEEKEND_ONLY,
        );

        // Verify weekend detection
        expect(entry.isWeekend, isTrue);
        expect(entry.overtimeType, equals(OvertimeType.WEEKEND_ONLY));

        // Verify calculations on the domain entity
        expect(entry.weekendOvertimeHours, equals(const Duration(hours: 8)));
        expect(entry.weekdayOvertimeHours, equals(Duration.zero));
      });

      test('Mixed week with weekend and weekday overtime', () async {
        final entries = <TimesheetEntry>[
          // Monday - Regular day, no overtime (8h)
          TimesheetEntry(
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '18:00',
            isWeekendDay: false,
            hasOvertimeHours: false,
            overtimeType: OvertimeType.NONE,
          ),
          // Tuesday - Weekday overtime (10h)
          TimesheetEntry(
            dayDate: '02-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '20:00',
            isWeekendDay: false,
            hasOvertimeHours: true,
            overtimeType: OvertimeType.WEEKDAY_ONLY,
          ),
          // Saturday - Weekend work (8h)
          TimesheetEntry(
            dayDate: '06-Jan-24',
            dayOfWeekDate: 'Samedi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '18:00',
            isWeekendDay: true,
            isWeekendOvertimeEnabled: true,
            overtimeType: OvertimeType.WEEKEND_ONLY,
          ),
          // Sunday - Weekend work (6h)
          TimesheetEntry(
            dayDate: '07-Jan-24',
            dayOfWeekDate: 'Dimanche',
            startMorning: '10:00',
            endMorning: '13:00',
            startAfternoon: '14:00',
            endAfternoon: '17:00',
            isWeekendDay: true,
            isWeekendOvertimeEnabled: true,
            overtimeType: OvertimeType.WEEKEND_ONLY,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Tuesday: 10h - 8h18 threshold = 1h42 weekday overtime
        expect(summary.weekdayOvertime,
            equals(const Duration(hours: 1, minutes: 42)));
        // Saturday 8h + Sunday 6h
        expect(summary.weekendOvertime, equals(const Duration(hours: 14)));
        expect(summary.totalOvertime,
            equals(const Duration(hours: 15, minutes: 42)));
      });
    });

    group('Configuration Impact Tests', () {
      test('Disabling weekend overtime affects detection service', () async {
        await detectionService.setWeekendOvertimeEnabled(false);

        final saturday = DateTime(2024, 1, 6);
        expect(detectionService.isWeekend(saturday), isTrue);
        expect(
            await detectionService.shouldApplyWeekendOvertime(saturday),
            isFalse);

        // Re-enable for the other tests (singleton with cache)
        await detectionService.setWeekendOvertimeEnabled(true);
        expect(
            await detectionService.shouldApplyWeekendOvertime(saturday),
            isTrue);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('Handles entries with no hours gracefully', () async {
        final entry = TimesheetEntry(
          dayDate: '06-Jan-24', // Saturday
          dayOfWeekDate: 'Samedi',
          startMorning: '',
          endMorning: '',
          startAfternoon: '',
          endAfternoon: '',
          isWeekendDay: true,
          isWeekendOvertimeEnabled: true,
        );

        final summary = await calculator.calculateMonthlyOvertime([entry]);
        expect(summary.weekendOvertime, equals(Duration.zero));
        expect(summary.totalOvertime, equals(Duration.zero));
      });
    });

    group('Performance and Scale Tests', () {
      test('Handles large datasets efficiently', () async {
        final monthNames = {
          1: 'Jan',
          2: 'Feb',
          3: 'Mar',
          4: 'Apr',
          5: 'May',
          6: 'Jun',
          7: 'Jul',
          8: 'Aug',
          9: 'Sep',
          10: 'Oct',
          11: 'Nov',
          12: 'Dec',
        };

        final largeDataset = <TimesheetEntry>[];
        for (int i = 0; i < 100; i++) {
          final date = DateTime(2024, 1, 1).add(Duration(days: i % 30));
          final isWeekend = date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday;

          largeDataset.add(TimesheetEntry(
            dayDate: '${date.day.toString().padLeft(2, '0')}-'
                '${monthNames[date.month]}-'
                '${date.year.toString().substring(2)}',
            dayOfWeekDate: 'Jour',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '18:00', // 8h
            isWeekendDay: isWeekend,
            isWeekendOvertimeEnabled: isWeekend,
            hasOvertimeHours: false,
            overtimeType:
                isWeekend ? OvertimeType.WEEKEND_ONLY : OvertimeType.NONE,
          ));
        }

        final stopwatch = Stopwatch()..start();
        final summary = await calculator.calculateMonthlyOvertime(largeDataset);
        stopwatch.stop();

        // Verify calculations completed successfully
        expect(summary.totalOvertime.inHours, greaterThan(0));

        // Performance should be reasonable (less than 1 second for 100 entries)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
