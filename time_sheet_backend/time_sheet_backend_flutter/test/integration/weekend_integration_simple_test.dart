import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../lib/features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import '../../lib/features/preference/data/models/overtime_configuration.dart';
import '../../lib/services/weekend_overtime_calculator.dart';
import '../../lib/services/overtime_configuration_service.dart';
import '../../lib/enum/overtime_type.dart';

void main() {
  group('Weekend Integration Tests', () {
    late Isar isar;
    late WeekendOvertimeCalculator calculator;
    late OvertimeConfigurationService configService;

    setUpAll(() async {
      isar = await Isar.open(
        [TimesheetEntryModelSchema, OvertimeConfigurationSchema],
        directory: '',
        name: 'test_db_${DateTime.now().millisecondsSinceEpoch}',
      );
    });

    setUp(() async {
      await isar.writeTxn(() async {
        await isar.timesheetEntryModels.clear();
        await isar.overtimeConfigurations.clear();
      });

      calculator = WeekendOvertimeCalculator();
      configService = OvertimeConfigurationService(isar);
    });

    tearDownAll(() async {
      await isar.close();
    });

    group('End-to-End Weekend Workflow', () {
      test('Complete weekend workflow with Saturday work', () async {
        // Requirement 1.1: Weekend hours automatically marked as overtime
        final saturdayDate = DateTime(2024, 1, 6); // Saturday

        // Create weekend entry
        final entry = TimesheetEntryModel()
          ..dayDate = saturdayDate
          ..clockInTime = DateTime(2024, 1, 6, 9, 0) // 9:00 AM
          ..clockOutTime = DateTime(2024, 1, 6, 17, 0) // 5:00 PM
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(entry);
        });

        // Verify weekend detection
        expect(entry.isWeekendDay, isTrue);
        expect(entry.overtimeType, equals(OvertimeType.WEEKEND_ONLY));

        // Convert to domain entity and verify calculations
        final domainEntry = entry.toDomain();
        expect(domainEntry.isWeekend, isTrue);
        expect(
            domainEntry.weekendOvertimeHours, equals(const Duration(hours: 8)));
        expect(domainEntry.weekdayOvertimeHours, equals(Duration.zero));
      });

      test('Mixed week with weekend and weekday overtime', () async {
        // Create entries for different scenarios
        final entries = <TimesheetEntryModel>[
          // Monday - Regular day, no overtime
          TimesheetEntryModel()
            ..dayDate = DateTime(2024, 1, 1) // Monday
            ..clockInTime = DateTime(2024, 1, 1, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 1, 17, 0) // 8 hours
            ..isWeekendDay = false
            ..hasOvertimeHours = false
            ..overtimeType = OvertimeType.NONE,

          // Tuesday - Weekday overtime
          TimesheetEntryModel()
            ..dayDate = DateTime(2024, 1, 2) // Tuesday
            ..clockInTime = DateTime(2024, 1, 2, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 2, 19, 0) // 10 hours
            ..isWeekendDay = false
            ..hasOvertimeHours = true
            ..overtimeType = OvertimeType.WEEKDAY_ONLY,

          // Saturday - Weekend work
          TimesheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0) // 8 hours
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,

          // Sunday - Weekend work
          TimesheetEntryModel()
            ..dayDate = DateTime(2024, 1, 7) // Sunday
            ..clockInTime = DateTime(2024, 1, 7, 10, 0)
            ..clockOutTime = DateTime(2024, 1, 7, 16, 0) // 6 hours
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        // Save all entries
        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timesheetEntryModels.put(entry);
          }
        });

        // Calculate weekly summary
        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final summary = calculator.calculateMonthlyOvertime(domainEntries);

        // Verify calculations
        expect(summary.weekdayOvertime,
            equals(const Duration(hours: 2))); // Tuesday overtime
        expect(summary.weekendOvertime,
            equals(const Duration(hours: 14))); // Sat + Sun
        expect(summary.totalOvertime, equals(const Duration(hours: 16)));
      });
    });

    group('Configuration Impact Tests', () {
      test('Disabling weekend overtime affects calculations', () async {
        final saturdayDate = DateTime(2024, 1, 6);

        // Create entry with weekend overtime disabled
        final entry = TimesheetEntryModel()
          ..dayDate = saturdayDate
          ..clockInTime = DateTime(2024, 1, 6, 9, 0)
          ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = false // Disabled
          ..overtimeType = OvertimeType.NONE;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        expect(domainEntry.isWeekend, isTrue);
        expect(domainEntry.weekendOvertimeHours, equals(Duration.zero));
        expect(domainEntry.overtimeType, equals(OvertimeType.NONE));
      });

      test('Configuration changes persist across service instances', () async {
        // Set custom configuration
        await configService.setWeekendOvertimeEnabled(true);
        await configService.setWeekendOvertimeRate(2.0);
        await configService.setWeekdayOvertimeRate(1.5);

        // Create new service instance (simulates app restart)
        final newConfigService = OvertimeConfigurationService(isar);

        // Verify configuration persisted
        expect(await newConfigService.isWeekendOvertimeEnabled(), isTrue);
        expect(await newConfigService.getWeekendOvertimeRate(), equals(2.0));
        expect(await newConfigService.getWeekdayOvertimeRate(), equals(1.5));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('Handles midnight crossing weekend work', () async {
        final saturdayDate = DateTime(2024, 1, 6);

        // Work that crosses midnight (Saturday night to Sunday morning)
        final entry = TimesheetEntryModel()
          ..dayDate = saturdayDate
          ..clockInTime = DateTime(2024, 1, 6, 22, 0) // 10:00 PM Saturday
          ..clockOutTime = DateTime(2024, 1, 7, 6, 0) // 6:00 AM Sunday
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        expect(domainEntry.isWeekend, isTrue);
        expect(
            domainEntry.weekendOvertimeHours, equals(const Duration(hours: 8)));
      });

      test('Handles invalid time entries gracefully', () async {
        final entry = TimesheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6)
          ..clockInTime =
              DateTime(2024, 1, 6, 17, 0) // Clock out before clock in
          ..clockOutTime = DateTime(2024, 1, 6, 9, 0)
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        // Should handle invalid times gracefully
        expect(domainEntry.weekendOvertimeHours, equals(Duration.zero));
      });

      test('Handles null clock out times', () async {
        final entry = TimesheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6)
          ..clockInTime = DateTime(2024, 1, 6, 9, 0)
          ..clockOutTime = null // Still clocked in
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        expect(domainEntry.weekendOvertimeHours, equals(Duration.zero));
      });
    });

    group('Performance and Scale Tests', () {
      test('Handles large datasets efficiently', () async {
        // Create a large number of entries
        final largeDataset = <TimesheetEntryModel>[];

        for (int i = 0; i < 100; i++) {
          final date = DateTime(2024, 1, 1).add(Duration(days: i % 30));
          final isWeekend = date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday;

          largeDataset.add(TimesheetEntryModel()
            ..dayDate = date
            ..clockInTime = DateTime(date.year, date.month, date.day, 9, 0)
            ..clockOutTime = DateTime(date.year, date.month, date.day, 17, 0)
            ..isWeekendDay = isWeekend
            ..isWeekendOvertimeEnabled = isWeekend
            ..overtimeType =
                isWeekend ? OvertimeType.WEEKEND_ONLY : OvertimeType.NONE);
        }

        // Save large dataset
        await isar.writeTxn(() async {
          for (final entry in largeDataset) {
            entry.updateWeekendStatus();
            await isar.timesheetEntryModels.put(entry);
          }
        });

        // Measure calculation performance
        final stopwatch = Stopwatch()..start();
        final domainEntries = largeDataset.map((e) => e.toDomain()).toList();
        final summary = calculator.calculateMonthlyOvertime(domainEntries);
        stopwatch.stop();

        // Verify calculations completed successfully
        expect(summary.totalOvertime.inHours, greaterThan(0));

        // Performance should be reasonable (less than 1 second for 100 entries)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
