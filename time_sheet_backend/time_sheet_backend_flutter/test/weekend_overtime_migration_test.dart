import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/enum/overtime_type.dart';
import 'package:time_sheet/features/pointage/data/data_sources/local.dart';
import 'package:time_sheet/features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';
import 'package:time_sheet/services/weekend_overtime_migration.dart';

import 'weekend_overtime_migration_test.mocks.dart';

@GenerateMocks([LocalDatasourceImpl, WeekendDetectionService])
void main() {
  group('WeekendOvertimeMigration', () {
    late WeekendOvertimeMigration migration;
    late MockLocalDatasourceImpl mockDataSource;
    late MockWeekendDetectionService mockWeekendService;

    setUp(() {
      mockDataSource = MockLocalDatasourceImpl();
      mockWeekendService = MockWeekendDetectionService();
      migration = WeekendOvertimeMigration(mockDataSource, mockWeekendService);
    });

    group('migrateExistingEntries', () {
      test('should successfully migrate weekend entries', () async {
        // Arrange
        final weekendDate = DateTime(2024, 1, 6); // Saturday
        final weekdayDate = DateTime(2024, 1, 8); // Monday

        final weekendEntry = TimeSheetEntryModel()
          ..id = 1
          ..dayDate = weekendDate
          ..dayOfWeekDate = 'Saturday'
          ..startMorning = '09:00'
          ..endMorning = '12:00'
          ..startAfternoon = '13:00'
          ..endAfternoon = '17:00'
          ..isWeekendDay = false // Not yet migrated
          ..hasOvertimeHours = false
          ..overtimeType = OvertimeType.NONE;

        final weekdayEntry = TimeSheetEntryModel()
          ..id = 2
          ..dayDate = weekdayDate
          ..dayOfWeekDate = 'Monday'
          ..startMorning = '09:00'
          ..endMorning = '12:00'
          ..startAfternoon = '13:00'
          ..endAfternoon = '18:00' // 9 hours = 1 hour overtime
          ..isWeekendDay = false
          ..hasOvertimeHours = true
          ..overtimeType = OvertimeType.NONE;

        when(mockDataSource.getTimesheetEntries())
            .thenAnswer((_) async => [weekendEntry, weekdayEntry]);

        when(mockWeekendService.isWeekend(weekendDate)).thenReturn(true);
        when(mockWeekendService.isWeekend(weekdayDate)).thenReturn(false);
        when(mockWeekendService.isWeekendOvertimeEnabled())
            .thenAnswer((_) async => true);

        when(mockDataSource.updateTimesheetEntry(any)).thenAnswer((_) async {});

        // Act
        final result = await migration.migrateExistingEntries();

        // Assert
        expect(result.isSuccessful, true);
        expect(result.totalEntriesProcessed, 2);
        expect(result.weekendEntriesFound, 1);
        expect(result.weekendEntriesConverted, 1);
        expect(result.errorsEncountered, 0);

        // Verify that updateTimesheetEntry was called (only weekend entry needs update)
        verify(mockDataSource.updateTimesheetEntry(any)).called(1);
      });

      test('should handle entries with both weekend and weekday overtime',
          () async {
        // Arrange
        final weekendDate = DateTime(2024, 1, 7); // Sunday

        final weekendEntryWithOvertime = TimeSheetEntryModel()
          ..id = 1
          ..dayDate = weekendDate
          ..dayOfWeekDate = 'Sunday'
          ..startMorning = '09:00'
          ..endMorning = '12:00'
          ..startAfternoon = '13:00'
          ..endAfternoon = '18:00' // 8 hours + weekend = both types
          ..isWeekendDay = false
          ..hasOvertimeHours = true // Already marked as overtime
          ..overtimeType = OvertimeType.NONE;

        when(mockDataSource.getTimesheetEntries())
            .thenAnswer((_) async => [weekendEntryWithOvertime]);

        when(mockWeekendService.isWeekend(weekendDate)).thenReturn(true);
        when(mockWeekendService.isWeekendOvertimeEnabled())
            .thenAnswer((_) async => true);

        when(mockDataSource.updateTimesheetEntry(any)).thenAnswer((_) async {});

        // Act
        final result = await migration.migrateExistingEntries();

        // Assert
        expect(result.isSuccessful, true);
        expect(result.weekendEntriesFound, 1);
        expect(result.weekendEntriesConverted, 1);

        // Verify entry was updated
        verify(mockDataSource.updateTimesheetEntry(any)).called(1);
      });

      test('should handle empty timesheet entries', () async {
        // Arrange
        when(mockDataSource.getTimesheetEntries()).thenAnswer((_) async => []);

        // Act
        final result = await migration.migrateExistingEntries();

        // Assert
        expect(result.isSuccessful, true);
        expect(result.totalEntriesProcessed, 0);
        expect(result.weekendEntriesFound, 0);
        expect(result.weekendEntriesConverted, 0);
        expect(result.errorsEncountered, 0);
      });

      test('should handle database errors gracefully', () async {
        // Arrange
        when(mockDataSource.getTimesheetEntries())
            .thenThrow(Exception('Database connection failed'));

        // Act
        final result = await migration.migrateExistingEntries();

        // Assert
        expect(result.isSuccessful, false);
        expect(result.errorsEncountered, 1);
        expect(
            result.migrationLogs
                .any((log) => log.contains('Database connection failed')),
            true);
      });

      test('should not update entries that are already correctly migrated',
          () async {
        // Arrange
        final weekendDate = DateTime(2024, 1, 6); // Saturday

        final alreadyMigratedEntry = TimeSheetEntryModel()
          ..id = 1
          ..dayDate = weekendDate
          ..dayOfWeekDate = 'Saturday'
          ..startMorning = '09:00'
          ..endMorning = '12:00'
          ..startAfternoon = '13:00'
          ..endAfternoon = '17:00'
          ..isWeekendDay = true // Already correctly set
          ..hasOvertimeHours = false
          ..overtimeType = OvertimeType.WEEKEND_ONLY; // Already correctly set

        when(mockDataSource.getTimesheetEntries())
            .thenAnswer((_) async => [alreadyMigratedEntry]);

        when(mockWeekendService.isWeekend(weekendDate)).thenReturn(true);
        when(mockWeekendService.isWeekendOvertimeEnabled())
            .thenAnswer((_) async => true);

        // Act
        final result = await migration.migrateExistingEntries();

        // Assert
        expect(result.isSuccessful, true);
        expect(result.totalEntriesProcessed, 1);
        expect(result.weekendEntriesFound, 1);
        expect(result.weekendEntriesConverted, 0); // No conversion needed

        // Verify no update was called since entry was already correct
        verifyNever(mockDataSource.updateTimesheetEntry(any));
      });

      test('should handle entries with no work hours', () async {
        // Arrange
        final weekendDate = DateTime(2024, 1, 6); // Saturday

        final emptyWeekendEntry = TimeSheetEntryModel()
          ..id = 1
          ..dayDate = weekendDate
          ..dayOfWeekDate = 'Saturday'
          ..startMorning = ''
          ..endMorning = ''
          ..startAfternoon = ''
          ..endAfternoon = ''
          ..isWeekendDay = false
          ..hasOvertimeHours = false
          ..overtimeType = OvertimeType.NONE;

        when(mockDataSource.getTimesheetEntries())
            .thenAnswer((_) async => [emptyWeekendEntry]);

        when(mockWeekendService.isWeekend(weekendDate)).thenReturn(true);
        when(mockWeekendService.isWeekendOvertimeEnabled())
            .thenAnswer((_) async => true);

        when(mockDataSource.updateTimesheetEntry(any)).thenAnswer((_) async {});

        // Act
        final result = await migration.migrateExistingEntries();

        // Assert
        expect(result.isSuccessful, true);
        expect(result.weekendEntriesFound, 1);
        expect(result.weekendEntriesConverted, 1);

        // Verify entry was updated
        verify(mockDataSource.updateTimesheetEntry(any)).called(1);
      });
    });

    group('validateMigration', () {
      test('should validate migration successfully', () async {
        // Arrange
        final weekendDate = DateTime(2024, 1, 6); // Saturday
        final weekdayDate = DateTime(2024, 1, 8); // Monday

        final validWeekendEntry = TimeSheetEntryModel()
          ..id = 1
          ..dayDate = weekendDate
          ..dayOfWeekDate = 'Saturday'
          ..startMorning = '09:00'
          ..endMorning = '12:00'
          ..isWeekendDay = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        final validWeekdayEntry = TimeSheetEntryModel()
          ..id = 2
          ..dayDate = weekdayDate
          ..dayOfWeekDate = 'Monday'
          ..startMorning = '09:00'
          ..endMorning = '12:00'
          ..isWeekendDay = false
          ..hasOvertimeHours = true
          ..overtimeType = OvertimeType.WEEKDAY_ONLY;

        when(mockDataSource.getTimesheetEntries())
            .thenAnswer((_) async => [validWeekendEntry, validWeekdayEntry]);

        when(mockWeekendService.isWeekend(weekendDate)).thenReturn(true);
        when(mockWeekendService.isWeekend(weekdayDate)).thenReturn(false);

        // Act
        final result = await migration.validateMigration();

        // Assert
        expect(result.isValid, true);
        expect(result.totalValidated,
            1); // Only validates a sample, not all entries
        expect(result.errorsFound, 0);
        expect(result.issues, isEmpty);
      });

      test('should detect validation errors', () async {
        // Arrange
        final weekendDate = DateTime(2024, 1, 6); // Saturday

        final invalidEntry = TimeSheetEntryModel()
          ..id = 1
          ..dayDate = weekendDate
          ..dayOfWeekDate = 'Saturday'
          ..startMorning = '09:00'
          ..endMorning = '12:00'
          ..isWeekendDay = false // Incorrect - should be true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType =
              OvertimeType.NONE; // Incorrect - should have overtime

        when(mockDataSource.getTimesheetEntries())
            .thenAnswer((_) async => [invalidEntry]);

        when(mockWeekendService.isWeekend(weekendDate)).thenReturn(true);

        // Act
        final result = await migration.validateMigration();

        // Assert
        expect(result.isValid, false);
        expect(result.totalValidated, 1);
        expect(result.errorsFound, 1); // Only weekend day mismatch detected
        expect(result.issues.length, 1);
        expect(
            result.issues
                .any((issue) => issue.contains('Weekend day mismatch')),
            true);
      });

      test('should handle validation errors gracefully', () async {
        // Arrange
        when(mockDataSource.getTimesheetEntries())
            .thenThrow(Exception('Database error during validation'));

        // Act
        final result = await migration.validateMigration();

        // Assert
        expect(result.isValid, false);
        expect(result.errorsFound, 1);
        expect(
            result.issues
                .any((issue) => issue.contains('Validation failed with error')),
            true);
      });
    });

    group('MigrationResult', () {
      test('should generate correct summary for successful migration', () {
        // Arrange
        final result = MigrationResult(
          totalEntriesProcessed: 100,
          weekendEntriesFound: 25,
          weekendEntriesConverted: 25,
          errorsEncountered: 0,
          migrationLogs: ['Test log'],
          isSuccessful: true,
        );

        // Act & Assert
        expect(result.summary, contains('completed successfully'));
        expect(result.summary, contains('100 entries processed'));
        expect(result.summary, contains('25 weekend entries found'));
        expect(result.summary, contains('25 entries converted'));
        expect(result.summary, contains('0 errors encountered'));
      });

      test('should generate correct summary for failed migration', () {
        // Arrange
        final result = MigrationResult(
          totalEntriesProcessed: 50,
          weekendEntriesFound: 10,
          weekendEntriesConverted: 8,
          errorsEncountered: 2,
          migrationLogs: ['Error log 1', 'Error log 2'],
          isSuccessful: false,
        );

        // Act & Assert
        expect(result.summary, contains('completed with errors'));
        expect(result.summary, contains('2 errors encountered'));
        expect(result.detailedReport, contains('COMPLETED WITH ERRORS'));
        expect(result.detailedReport, contains('Error log 1'));
        expect(result.detailedReport, contains('Error log 2'));
      });
    });

    group('ValidationResult', () {
      test('should generate correct summary for valid results', () {
        // Arrange
        final result = ValidationResult(
          totalValidated: 50,
          errorsFound: 0,
          issues: [],
          isValid: true,
        );

        // Act & Assert
        expect(result.summary, contains('passed'));
        expect(result.summary, contains('50 entries validated'));
        expect(result.summary, contains('0 errors found'));
        expect(result.detailedReport, contains('VALID'));
      });

      test('should generate correct summary for invalid results', () {
        // Arrange
        final result = ValidationResult(
          totalValidated: 30,
          errorsFound: 5,
          issues: ['Issue 1', 'Issue 2'],
          isValid: false,
        );

        // Act & Assert
        expect(result.summary, contains('failed'));
        expect(result.summary, contains('5 errors found'));
        expect(result.detailedReport, contains('INVALID'));
        expect(result.detailedReport, contains('Issue 1'));
        expect(result.detailedReport, contains('Issue 2'));
      });
    });
  });
}
