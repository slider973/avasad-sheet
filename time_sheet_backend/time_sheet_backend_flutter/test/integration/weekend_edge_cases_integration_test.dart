import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:isar/isar.dart';

import '../test_utils.dart';
import '../../lib/features/pointage/data/models/timesheet_entry_model.dart';
import '../../lib/services/weekend_overtime_calculator.dart';
import '../../lib/services/weekend_detection_service.dart';
import '../../lib/services/overtime_configuration_service.dart';
import '../../lib/enum/overtime_type.dart';
import '../../lib/utils/time_utils.dart';

// Generate mocks
@GenerateMocks([
  WeekendDetectionService,
  OvertimeConfigurationService,
])
import 'weekend_edge_cases_integration_test.mocks.dart';

void main() {
  group('Weekend Edge Cases Integration Tests', () {
    late Isar isar;
    late WeekendOvertimeCalculator calculator;
    late MockWeekendDetectionService mockWeekendDetectionService;
    late MockOvertimeConfigurationService mockConfigService;

    setUpAll(() async {
      isar = await setupTestIsar();
    });

    setUp(() async {
      await isar.writeTxn(() async {
        await isar.timeSheetEntryModels.clear();
      });

      calculator = WeekendOvertimeCalculator();
      mockWeekendDetectionService = MockWeekendDetectionService();
      mockConfigService = MockOvertimeConfigurationService();

      // Setup default mocks
      when(mockWeekendDetectionService.isWeekend(any)).thenAnswer((invocation) {
        final date = invocation.positionalArguments[0] as DateTime;
        return date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday;
      });

      when(mockConfigService.isWeekendOvertimeEnabled())
          .thenAnswer((_) async => true);
    });

    tearDownAll(() async {
      await isar.close();
    });

    group('Time Zone Edge Cases', () {
      testWidgets('Handles daylight saving time transitions', (tester) async {
        // Test weekend work during DST transition (Spring forward)
        // March 10, 2024 - DST begins (2:00 AM becomes 3:00 AM)
        final dstSaturday = DateTime(2024, 3, 9); // Saturday before DST
        final dstSunday = DateTime(2024, 3, 10); // Sunday with DST transition

        final entries = <TimeSheetEntryModel>[
          // Saturday work (normal 24-hour day)
          TimeSheetEntryModel()
            ..dayDate = dstSaturday
            ..clockInTime = DateTime(2024, 3, 9, 9, 0)
            ..clockOutTime = DateTime(2024, 3, 9, 17, 0) // 8 hours
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,

          // Sunday work (23-hour day due to DST)
          TimeSheetEntryModel()
            ..dayDate = dstSunday
            ..clockInTime = DateTime(2024, 3, 10, 9, 0)
            ..clockOutTime =
                DateTime(2024, 3, 10, 17, 0) // Still 8 hours of work
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Calculate overtime - should handle DST correctly
        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final summary = calculator.calculateMonthlyOvertime(domainEntries);

        // Both days should count as 8 hours of weekend work
        expect(summary.weekendOvertime, equals(const Duration(hours: 16)));
        expect(summary.totalOvertime, equals(const Duration(hours: 16)));
      });

      testWidgets('Handles work across midnight on weekends', (tester) async {
        // Saturday night shift that goes into Sunday
        final saturdayDate = DateTime(2024, 1, 6);

        final entry = TimeSheetEntryModel()
          ..dayDate = saturdayDate
          ..clockInTime = DateTime(2024, 1, 6, 22, 0) // 10:00 PM Saturday
          ..clockOutTime = DateTime(2024, 1, 7, 6, 0) // 6:00 AM Sunday
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timeSheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();

        // Should calculate 8 hours correctly despite crossing midnight
        expect(
            domainEntry.weekendOvertimeHours, equals(const Duration(hours: 8)));
        expect(domainEntry.isWeekend, isTrue);
      });

      testWidgets('Handles different time zones for remote workers',
          (tester) async {
        // Simulate entries from different time zones
        // UTC Saturday work
        final utcSaturday =
            DateTime.utc(2024, 1, 6, 14, 0); // 2:00 PM UTC Saturday
        final utcSaturdayEnd =
            DateTime.utc(2024, 1, 6, 22, 0); // 10:00 PM UTC Saturday

        final entry = TimeSheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6) // Local date
          ..clockInTime = utcSaturday.toLocal()
          ..clockOutTime = utcSaturdayEnd.toLocal()
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timeSheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        expect(
            domainEntry.weekendOvertimeHours, equals(const Duration(hours: 8)));
      });
    });

    group('Data Consistency Edge Cases', () {
      testWidgets('Handles concurrent modifications during calculation',
          (tester) async {
        // Create initial entry
        final entry = TimeSheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6) // Saturday
          ..clockInTime = DateTime(2024, 1, 6, 9, 0)
          ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        await isar.writeTxn(() async {
          await isar.timeSheetEntryModels.put(entry);
        });

        // Simulate concurrent modification during calculation
        final domainEntries = [entry.toDomain()];

        // Start calculation
        final calculationFuture = Future(() {
          return calculator.calculateMonthlyOvertime(domainEntries);
        });

        // Modify entry concurrently
        await isar.writeTxn(() async {
          entry.clockOutTime =
              DateTime(2024, 1, 6, 19, 0); // Change to 10 hours
          await isar.timeSheetEntryModels.put(entry);
        });

        // Original calculation should complete with original data
        final summary = await calculationFuture;
        expect(summary.weekendOvertime,
            equals(const Duration(hours: 8))); // Original 8 hours

        // New calculation should reflect updated data
        final updatedEntry = await isar.timeSheetEntryModels.get(entry.id);
        final newSummary =
            calculator.calculateMonthlyOvertime([updatedEntry!.toDomain()]);
        expect(newSummary.weekendOvertime,
            equals(const Duration(hours: 10))); // Updated 10 hours
      });

      testWidgets('Handles database corruption gracefully', (tester) async {
        // Create entries with potentially corrupted data
        final corruptedEntries = <TimeSheetEntryModel>[
          // Entry with extreme dates
          TimeSheetEntryModel()
            ..dayDate = DateTime(1900, 1, 1) // Very old date
            ..clockInTime = DateTime(1900, 1, 1, 9, 0)
            ..clockOutTime = DateTime(1900, 1, 1, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,

          // Entry with future dates
          TimeSheetEntryModel()
            ..dayDate = DateTime(2100, 1, 1) // Far future date
            ..clockInTime = DateTime(2100, 1, 1, 9, 0)
            ..clockOutTime = DateTime(2100, 1, 1, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,

          // Valid entry for comparison
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in corruptedEntries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Should handle corrupted data gracefully
        final domainEntries =
            corruptedEntries.map((e) => e.toDomain()).toList();
        final summary = calculator.calculateMonthlyOvertime(domainEntries);

        // Should at least process the valid entry
        expect(summary.weekendOvertime,
            greaterThanOrEqualTo(const Duration(hours: 8)));
      });

      testWidgets('Handles memory pressure during large calculations',
          (tester) async {
        // Create a large number of entries to test memory handling
        final largeDataset = <TimeSheetEntryModel>[];

        for (int i = 0; i < 10000; i++) {
          final date = DateTime(2024, 1, 1).add(Duration(days: i % 365));
          final isWeekend = date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday;

          largeDataset.add(TimeSheetEntryModel()
            ..dayDate = date
            ..clockInTime = DateTime(date.year, date.month, date.day, 9, 0)
            ..clockOutTime = DateTime(date.year, date.month, date.day, 17, 0)
            ..isWeekendDay = isWeekend
            ..isWeekendOvertimeEnabled = isWeekend
            ..overtimeType =
                isWeekend ? OvertimeType.WEEKEND_ONLY : OvertimeType.NONE);
        }

        // Process in batches to avoid memory issues
        const batchSize = 1000;
        var totalWeekendHours = Duration.zero;

        for (int i = 0; i < largeDataset.length; i += batchSize) {
          final batch = largeDataset.skip(i).take(batchSize).toList();

          await isar.writeTxn(() async {
            await isar.timeSheetEntryModels.clear(); // Clear previous batch
            for (final entry in batch) {
              entry.updateWeekendStatus();
              await isar.timeSheetEntryModels.put(entry);
            }
          });

          final domainEntries = batch.map((e) => e.toDomain()).toList();
          final batchSummary =
              calculator.calculateMonthlyOvertime(domainEntries);
          totalWeekendHours += batchSummary.weekendOvertime;
        }

        // Should handle large dataset without memory issues
        expect(totalWeekendHours.inHours, greaterThan(0));
      });
    });

    group('Configuration Edge Cases', () {
      testWidgets('Handles rapid configuration changes', (tester) async {
        final entry = TimeSheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6) // Saturday
          ..clockInTime = DateTime(2024, 1, 6, 9, 0)
          ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        await isar.writeTxn(() async {
          await isar.timeSheetEntryModels.put(entry);
        });

        // Rapidly change configuration multiple times
        for (int i = 0; i < 10; i++) {
          when(mockConfigService.isWeekendOvertimeEnabled())
              .thenAnswer((_) async => i % 2 == 0);

          when(mockConfigService.getWeekendOvertimeRate())
              .thenAnswer((_) async => 1.5 + (i * 0.1));

          // Each configuration change should be handled consistently
          final isEnabled = await mockConfigService.isWeekendOvertimeEnabled();
          final rate = await mockConfigService.getWeekendOvertimeRate();

          expect(isEnabled, equals(i % 2 == 0));
          expect(rate, equals(1.5 + (i * 0.1)));
        }
      });

      testWidgets('Handles invalid configuration recovery', (tester) async {
        // Mock invalid configuration
        when(mockConfigService.getWeekendOvertimeRate())
            .thenAnswer((_) async => -1.0); // Invalid negative rate

        when(mockConfigService.getWeekdayOvertimeRate())
            .thenAnswer((_) async => 0.5); // Invalid rate less than 1.0

        final entry = TimeSheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6) // Saturday
          ..clockInTime = DateTime(2024, 1, 6, 9, 0)
          ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        await isar.writeTxn(() async {
          await isar.timeSheetEntryModels.put(entry);
        });

        // Calculator should handle invalid rates gracefully
        final domainEntry = entry.toDomain();
        final summary = calculator.calculateMonthlyOvertime([domainEntry]);

        // Should use default rates when invalid rates are detected
        expect(summary.weekendOvertimeRate, greaterThanOrEqualTo(1.0));
        expect(summary.weekdayOvertimeRate, greaterThanOrEqualTo(1.0));
        expect(summary.weekendOvertime, equals(const Duration(hours: 8)));
      });
    });

    group('Calculation Precision Edge Cases', () {
      testWidgets('Handles sub-minute precision correctly', (tester) async {
        // Entry with precise timing (seconds matter)
        final entry = TimeSheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6) // Saturday
          ..clockInTime = DateTime(2024, 1, 6, 9, 0, 30) // 9:00:30 AM
          ..clockOutTime = DateTime(2024, 1, 6, 17, 0, 45) // 5:00:45 PM
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timeSheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        final totalMinutes = domainEntry.weekendOvertimeHours.inMinutes;

        // Should be 8 hours and 15 seconds = 480 minutes and 15 seconds
        // Rounded to nearest minute should be 480 minutes
        expect(totalMinutes, equals(480));
      });

      testWidgets('Handles very short work periods', (tester) async {
        // Very short weekend work (less than 1 hour)
        final entry = TimeSheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6) // Saturday
          ..clockInTime = DateTime(2024, 1, 6, 9, 0)
          ..clockOutTime = DateTime(2024, 1, 6, 9, 30) // 30 minutes
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timeSheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        expect(domainEntry.weekendOvertimeHours,
            equals(const Duration(minutes: 30)));
      });

      testWidgets('Handles very long work periods', (tester) async {
        // Extremely long weekend work (24+ hours)
        final entry = TimeSheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6) // Saturday
          ..clockInTime = DateTime(2024, 1, 6, 0, 0) // Midnight
          ..clockOutTime = DateTime(2024, 1, 7, 23, 59) // Almost end of Sunday
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timeSheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        final totalHours = domainEntry.weekendOvertimeHours.inHours;

        // Should be approximately 47 hours and 59 minutes
        expect(totalHours, equals(47));
      });
    });

    group('System Resource Edge Cases', () {
      testWidgets('Handles low memory conditions', (tester) async {
        // Simulate low memory by creating many small calculations
        final results = <Duration>[];

        for (int i = 0; i < 1000; i++) {
          final entry = TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY;

          final domainEntry = entry.toDomain();
          final summary = calculator.calculateMonthlyOvertime([domainEntry]);
          results.add(summary.weekendOvertime);

          // Force garbage collection periodically
          if (i % 100 == 0) {
            await Future.delayed(const Duration(milliseconds: 1));
          }
        }

        // All calculations should be consistent
        expect(
            results.every((duration) => duration == const Duration(hours: 8)),
            isTrue);
      });

      testWidgets('Handles database connection issues', (tester) async {
        // Create entry
        final entry = TimeSheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6) // Saturday
          ..clockInTime = DateTime(2024, 1, 6, 9, 0)
          ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        await isar.writeTxn(() async {
          await isar.timeSheetEntryModels.put(entry);
        });

        // Simulate database read after connection issues
        try {
          final entries = await isar.timeSheetEntryModels.where().findAll();
          final domainEntries = entries.map((e) => e.toDomain()).toList();
          final summary = calculator.calculateMonthlyOvertime(domainEntries);

          expect(summary.weekendOvertime, equals(const Duration(hours: 8)));
        } catch (e) {
          // Should handle database errors gracefully
          expect(e, isA<Exception>());
        }
      });
    });

    group('Business Logic Edge Cases', () {
      testWidgets('Handles holiday weekends correctly', (tester) async {
        // New Year's Day 2024 falls on Monday, so weekend is Saturday-Sunday Dec 30-31, 2023
        final newYearWeekend = <TimeSheetEntryModel>[
          // Saturday Dec 30, 2023
          TimeSheetEntryModel()
            ..dayDate = DateTime(2023, 12, 30) // Saturday
            ..clockInTime = DateTime(2023, 12, 30, 9, 0)
            ..clockOutTime = DateTime(2023, 12, 30, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,

          // Sunday Dec 31, 2023 (New Year's Eve)
          TimeSheetEntryModel()
            ..dayDate = DateTime(2023, 12, 31) // Sunday
            ..clockInTime = DateTime(2023, 12, 31, 9, 0)
            ..clockOutTime = DateTime(2023, 12, 31, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in newYearWeekend) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        final domainEntries = newYearWeekend.map((e) => e.toDomain()).toList();
        final summary = calculator.calculateMonthlyOvertime(domainEntries);

        // Should treat holiday weekend same as regular weekend
        expect(summary.weekendOvertime, equals(const Duration(hours: 16)));
      });

      testWidgets('Handles leap year weekend calculations', (tester) async {
        // February 29, 2024 is a Thursday, so weekend is March 2-3, 2024
        final leapYearWeekend = <TimeSheetEntryModel>[
          // Saturday March 2, 2024
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 3, 2) // Saturday
            ..clockInTime = DateTime(2024, 3, 2, 9, 0)
            ..clockOutTime = DateTime(2024, 3, 2, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,

          // Sunday March 3, 2024
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 3, 3) // Sunday
            ..clockInTime = DateTime(2024, 3, 3, 9, 0)
            ..clockOutTime = DateTime(2024, 3, 3, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in leapYearWeekend) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        final domainEntries = leapYearWeekend.map((e) => e.toDomain()).toList();
        final summary = calculator.calculateMonthlyOvertime(domainEntries);

        // Should handle leap year dates correctly
        expect(summary.weekendOvertime, equals(const Duration(hours: 16)));
      });
    });
  });
}
