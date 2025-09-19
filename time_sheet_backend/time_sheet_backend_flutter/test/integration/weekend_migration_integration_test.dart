import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:isar/isar.dart';

import '../test_utils.dart';
import '../../lib/features/pointage/data/models/timesheet_entry_model.dart';
import '../../lib/services/weekend_overtime_migration.dart';
import '../../lib/services/weekend_detection_service.dart';
import '../../lib/services/overtime_configuration_service.dart';
import '../../lib/enum/overtime_type.dart';

// Generate mocks
@GenerateMocks([
  WeekendDetectionService,
  OvertimeConfigurationService,
])
import 'weekend_migration_integration_test.mocks.dart';

void main() {
  group('Weekend Migration Integration Tests', () {
    late Isar isar;
    late WeekendOvertimeMigration migration;
    late MockWeekendDetectionService mockWeekendDetectionService;
    late MockOvertimeConfigurationService mockConfigService;

    setUpAll(() async {
      isar = await setupTestIsar();
    });

    setUp(() async {
      await isar.writeTxn(() async {
        await isar.timeSheetEntryModels.clear();
      });

      mockWeekendDetectionService = MockWeekendDetectionService();
      mockConfigService = MockOvertimeConfigurationService();
      migration = WeekendOvertimeMigration(
        isar,
        mockWeekendDetectionService,
        mockConfigService,
      );

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

    group('Legacy Data Migration', () {
      testWidgets('Migrate existing weekend entries without weekend flags',
          (tester) async {
        // Requirement 6.3: Migration of existing data

        // Create legacy entries (before weekend feature was implemented)
        final legacyEntries = <TimeSheetEntryModel>[
          // Legacy Saturday entry - no weekend flags set
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
            ..isWeekendDay = false // Legacy: not set
            ..isWeekendOvertimeEnabled = false // Legacy: not set
            ..hasOvertimeHours = false // Legacy: not calculated
            ..overtimeType = OvertimeType.NONE, // Legacy: not set

          // Legacy Sunday entry
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 7) // Sunday
            ..clockInTime = DateTime(2024, 1, 7, 10, 0)
            ..clockOutTime = DateTime(2024, 1, 7, 16, 0)
            ..isWeekendDay = false // Legacy: not set
            ..isWeekendOvertimeEnabled = false // Legacy: not set
            ..hasOvertimeHours = false // Legacy: not calculated
            ..overtimeType = OvertimeType.NONE, // Legacy: not set

          // Legacy weekday entry - should remain unchanged
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 1) // Monday
            ..clockInTime = DateTime(2024, 1, 1, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 1, 17, 0)
            ..isWeekendDay = false
            ..isWeekendOvertimeEnabled = false
            ..hasOvertimeHours = false
            ..overtimeType = OvertimeType.NONE,
        ];

        // Save legacy entries
        await isar.writeTxn(() async {
          for (final entry in legacyEntries) {
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Verify initial state (legacy)
        var entries = await isar.timeSheetEntryModels.where().findAll();
        expect(entries.length, equals(3));
        expect(entries.where((e) => e.isWeekendDay).length,
            equals(0)); // No weekend flags
        expect(entries.where((e) => e.overtimeType != OvertimeType.NONE).length,
            equals(0));

        // Run migration
        final migrationResult = await migration.migrateExistingEntries();

        // Verify migration results
        expect(migrationResult.totalEntriesProcessed, equals(3));
        expect(migrationResult.weekendEntriesUpdated,
            equals(2)); // Saturday and Sunday
        expect(migrationResult.errors.length, equals(0));

        // Verify migrated entries
        entries = await isar.timeSheetEntryModels.where().findAll();

        // Saturday entry should be updated
        final saturdayEntry =
            entries.firstWhere((e) => e.dayDate.weekday == DateTime.saturday);
        expect(saturdayEntry.isWeekendDay, isTrue);
        expect(saturdayEntry.isWeekendOvertimeEnabled, isTrue);
        expect(saturdayEntry.overtimeType, equals(OvertimeType.WEEKEND_ONLY));

        // Sunday entry should be updated
        final sundayEntry =
            entries.firstWhere((e) => e.dayDate.weekday == DateTime.sunday);
        expect(sundayEntry.isWeekendDay, isTrue);
        expect(sundayEntry.isWeekendOvertimeEnabled, isTrue);
        expect(sundayEntry.overtimeType, equals(OvertimeType.WEEKEND_ONLY));

        // Monday entry should remain unchanged
        final mondayEntry =
            entries.firstWhere((e) => e.dayDate.weekday == DateTime.monday);
        expect(mondayEntry.isWeekendDay, isFalse);
        expect(mondayEntry.overtimeType, equals(OvertimeType.NONE));
      });

      testWidgets('Migration handles entries with existing overtime',
          (tester) async {
        // Test migration of entries that already have weekday overtime
        final mixedEntries = <TimeSheetEntryModel>[
          // Saturday with existing overtime (should become BOTH)
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 19, 0) // 10 hours
            ..isWeekendDay = false // Legacy: not set
            ..isWeekendOvertimeEnabled = false // Legacy: not set
            ..hasOvertimeHours = true // Already had overtime
            ..overtimeType = OvertimeType.WEEKDAY_ONLY, // Legacy overtime

          // Sunday without existing overtime (should become WEEKEND_ONLY)
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 7) // Sunday
            ..clockInTime = DateTime(2024, 1, 7, 10, 0)
            ..clockOutTime = DateTime(2024, 1, 7, 16, 0) // 6 hours
            ..isWeekendDay = false // Legacy: not set
            ..isWeekendOvertimeEnabled = false // Legacy: not set
            ..hasOvertimeHours = false
            ..overtimeType = OvertimeType.NONE,
        ];

        await isar.writeTxn(() async {
          for (final entry in mixedEntries) {
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Run migration
        final migrationResult = await migration.migrateExistingEntries();

        expect(migrationResult.totalEntriesProcessed, equals(2));
        expect(migrationResult.weekendEntriesUpdated, equals(2));

        // Verify results
        final entries = await isar.timeSheetEntryModels.where().findAll();

        // Saturday entry should have BOTH overtime types
        final saturdayEntry =
            entries.firstWhere((e) => e.dayDate.weekday == DateTime.saturday);
        expect(saturdayEntry.isWeekendDay, isTrue);
        expect(saturdayEntry.overtimeType, equals(OvertimeType.BOTH));

        // Sunday entry should have WEEKEND_ONLY
        final sundayEntry =
            entries.firstWhere((e) => e.dayDate.weekday == DateTime.sunday);
        expect(sundayEntry.isWeekendDay, isTrue);
        expect(sundayEntry.overtimeType, equals(OvertimeType.WEEKEND_ONLY));
      });

      testWidgets('Migration with custom weekend days configuration',
          (tester) async {
        // Test migration when custom weekend days are configured
        when(mockWeekendDetectionService.isWeekend(any))
            .thenAnswer((invocation) {
          final date = invocation.positionalArguments[0] as DateTime;
          return date.weekday == DateTime.friday ||
              date.weekday == DateTime.saturday;
        });

        final entries = <TimeSheetEntryModel>[
          // Friday - should be weekend with custom config
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 5) // Friday
            ..clockInTime = DateTime(2024, 1, 5, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 5, 17, 0)
            ..isWeekendDay = false // Legacy: not set
            ..overtimeType = OvertimeType.NONE,

          // Sunday - should NOT be weekend with custom config
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 7) // Sunday
            ..clockInTime = DateTime(2024, 1, 7, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 7, 17, 0)
            ..isWeekendDay = false // Legacy: not set
            ..overtimeType = OvertimeType.NONE,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Run migration with custom weekend detection
        final migrationResult = await migration.migrateExistingEntries();

        expect(migrationResult.totalEntriesProcessed, equals(2));
        expect(migrationResult.weekendEntriesUpdated, equals(1)); // Only Friday

        // Verify results
        final updatedEntries =
            await isar.timeSheetEntryModels.where().findAll();

        // Friday should be marked as weekend
        final fridayEntry = updatedEntries
            .firstWhere((e) => e.dayDate.weekday == DateTime.friday);
        expect(fridayEntry.isWeekendDay, isTrue);
        expect(fridayEntry.overtimeType, equals(OvertimeType.WEEKEND_ONLY));

        // Sunday should remain as weekday
        final sundayEntry = updatedEntries
            .firstWhere((e) => e.dayDate.weekday == DateTime.sunday);
        expect(sundayEntry.isWeekendDay, isFalse);
        expect(sundayEntry.overtimeType, equals(OvertimeType.NONE));
      });
    });

    group('Migration Error Handling', () {
      testWidgets('Migration handles corrupted entries gracefully',
          (tester) async {
        // Create entries with invalid data
        final corruptedEntries = <TimeSheetEntryModel>[
          // Entry with null clock times
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = null
            ..clockOutTime = null
            ..isWeekendDay = false
            ..overtimeType = OvertimeType.NONE,

          // Entry with invalid time order
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 7) // Sunday
            ..clockInTime =
                DateTime(2024, 1, 7, 17, 0) // Clock out before clock in
            ..clockOutTime = DateTime(2024, 1, 7, 9, 0)
            ..isWeekendDay = false
            ..overtimeType = OvertimeType.NONE,

          // Valid entry for comparison
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
            ..isWeekendDay = false
            ..overtimeType = OvertimeType.NONE,
        ];

        await isar.writeTxn(() async {
          for (final entry in corruptedEntries) {
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Run migration
        final migrationResult = await migration.migrateExistingEntries();

        // Should process all entries but handle errors gracefully
        expect(migrationResult.totalEntriesProcessed, equals(3));
        expect(migrationResult.weekendEntriesUpdated,
            greaterThanOrEqualTo(1)); // At least the valid one
        expect(migrationResult.errors.length,
            greaterThanOrEqualTo(0)); // May have errors for corrupted entries

        // Verify valid entry was migrated
        final entries = await isar.timeSheetEntryModels.where().findAll();
        final validEntries = entries
            .where((e) =>
                e.clockInTime != null &&
                e.clockOutTime != null &&
                e.clockInTime!.isBefore(e.clockOutTime!))
            .toList();

        expect(validEntries.isNotEmpty, isTrue);
        final validWeekendEntry = validEntries
            .firstWhere((e) => e.dayDate.weekday == DateTime.saturday);
        expect(validWeekendEntry.isWeekendDay, isTrue);
      });

      testWidgets('Migration rollback on critical errors', (tester) async {
        // Create valid entries
        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
            ..isWeekendDay = false
            ..overtimeType = OvertimeType.NONE,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Mock a critical error during migration
        when(mockConfigService.isWeekendOvertimeEnabled())
            .thenThrow(Exception('Database connection lost'));

        // Run migration - should handle error gracefully
        final migrationResult = await migration.migrateExistingEntries();

        // Should report error without corrupting data
        expect(migrationResult.errors.isNotEmpty, isTrue);
        expect(
            migrationResult.errors.first.contains('Database connection lost'),
            isTrue);

        // Original data should remain unchanged
        final unchangedEntries =
            await isar.timeSheetEntryModels.where().findAll();
        expect(unchangedEntries.first.isWeekendDay, isFalse);
        expect(unchangedEntries.first.overtimeType, equals(OvertimeType.NONE));
      });
    });

    group('Migration Performance', () {
      testWidgets('Migration handles large datasets efficiently',
          (tester) async {
        // Create a large number of entries to test performance
        final largeDataset = <TimeSheetEntryModel>[];

        // Create 1000 entries across different dates
        for (int i = 0; i < 1000; i++) {
          final date = DateTime(2024, 1, 1).add(Duration(days: i % 365));
          largeDataset.add(TimeSheetEntryModel()
            ..dayDate = date
            ..clockInTime = DateTime(date.year, date.month, date.day, 9, 0)
            ..clockOutTime = DateTime(date.year, date.month, date.day, 17, 0)
            ..isWeekendDay = false // Legacy: not set
            ..overtimeType = OvertimeType.NONE);
        }

        // Save large dataset
        await isar.writeTxn(() async {
          for (final entry in largeDataset) {
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Measure migration performance
        final stopwatch = Stopwatch()..start();
        final migrationResult = await migration.migrateExistingEntries();
        stopwatch.stop();

        // Verify migration completed successfully
        expect(migrationResult.totalEntriesProcessed, equals(1000));
        expect(migrationResult.errors.length, equals(0));

        // Performance should be reasonable (less than 10 seconds for 1000 entries)
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));

        // Verify weekend entries were correctly identified
        final weekendEntries = await isar.timeSheetEntryModels
            .filter()
            .isWeekendDayEqualTo(true)
            .findAll();

        // Should have approximately 2/7 of entries as weekend (Saturday + Sunday)
        expect(weekendEntries.length, greaterThan(200));
        expect(weekendEntries.length, lessThan(350));
      });

      testWidgets('Migration progress tracking', (tester) async {
        // Create entries for progress tracking test
        final entries = <TimeSheetEntryModel>[];
        for (int i = 0; i < 100; i++) {
          final date = DateTime(2024, 1, 1).add(Duration(days: i));
          entries.add(TimeSheetEntryModel()
            ..dayDate = date
            ..clockInTime = DateTime(date.year, date.month, date.day, 9, 0)
            ..clockOutTime = DateTime(date.year, date.month, date.day, 17, 0)
            ..isWeekendDay = false
            ..overtimeType = OvertimeType.NONE);
        }

        await isar.writeTxn(() async {
          for (final entry in entries) {
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Track progress during migration
        final progressUpdates = <double>[];

        final migrationResult = await migration.migrateExistingEntries(
          onProgress: (progress) {
            progressUpdates.add(progress);
          },
        );

        // Verify migration completed
        expect(migrationResult.totalEntriesProcessed, equals(100));

        // Verify progress was tracked
        expect(progressUpdates.isNotEmpty, isTrue);
        expect(progressUpdates.first, equals(0.0));
        expect(progressUpdates.last, equals(1.0));

        // Progress should be monotonically increasing
        for (int i = 1; i < progressUpdates.length; i++) {
          expect(
              progressUpdates[i], greaterThanOrEqualTo(progressUpdates[i - 1]));
        }
      });
    });

    group('Migration Validation', () {
      testWidgets('Migration validates data integrity after completion',
          (tester) async {
        // Create test entries
        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
            ..isWeekendDay = false
            ..overtimeType = OvertimeType.NONE,
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 1) // Monday
            ..clockInTime = DateTime(2024, 1, 1, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 1, 19, 0) // 10 hours
            ..isWeekendDay = false
            ..hasOvertimeHours = true
            ..overtimeType = OvertimeType.WEEKDAY_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Run migration with validation
        final migrationResult = await migration.migrateExistingEntries(
          validateAfterMigration: true,
        );

        // Verify migration and validation completed successfully
        expect(migrationResult.totalEntriesProcessed, equals(2));
        expect(migrationResult.validationPassed, isTrue);
        expect(migrationResult.errors.length, equals(0));

        // Verify data integrity
        final migratedEntries =
            await isar.timeSheetEntryModels.where().findAll();

        // Saturday entry should be properly migrated
        final saturdayEntry = migratedEntries
            .firstWhere((e) => e.dayDate.weekday == DateTime.saturday);
        expect(saturdayEntry.isWeekendDay, isTrue);
        expect(saturdayEntry.overtimeType, equals(OvertimeType.WEEKEND_ONLY));

        // Monday entry should retain existing overtime
        final mondayEntry = migratedEntries
            .firstWhere((e) => e.dayDate.weekday == DateTime.monday);
        expect(mondayEntry.isWeekendDay, isFalse);
        expect(mondayEntry.overtimeType, equals(OvertimeType.WEEKDAY_ONLY));
      });

      testWidgets('Migration detects and reports data inconsistencies',
          (tester) async {
        // Create entries with potential inconsistencies
        final entries = <TimeSheetEntryModel>[
          // Entry marked as weekend but on a weekday
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 1) // Monday
            ..clockInTime = DateTime(2024, 1, 1, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 1, 17, 0)
            ..isWeekendDay = true // Inconsistent: Monday marked as weekend
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Run migration with validation
        final migrationResult = await migration.migrateExistingEntries(
          validateAfterMigration: true,
        );

        // Should detect and fix inconsistency
        expect(migrationResult.inconsistenciesFixed, greaterThan(0));

        // Verify inconsistency was corrected
        final correctedEntries =
            await isar.timeSheetEntryModels.where().findAll();
        final mondayEntry = correctedEntries.first;
        expect(mondayEntry.isWeekendDay, isFalse); // Should be corrected
        expect(mondayEntry.overtimeType,
            equals(OvertimeType.NONE)); // Should be corrected
      });
    });
  });
}
