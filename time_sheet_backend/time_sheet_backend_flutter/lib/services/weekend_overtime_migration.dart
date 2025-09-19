import 'package:intl/intl.dart';
import 'package:time_sheet/enum/overtime_type.dart';
import 'package:time_sheet/features/pointage/data/data_sources/local.dart';
import 'package:time_sheet/features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';

/// Service responsible for migrating existing timesheet entries to support weekend overtime tracking
///
/// This service provides functionality to:
/// - Identify existing timesheet entries that were created on weekend days
/// - Convert weekend entries to use the new weekend overtime system
/// - Update weekend status and overtime type for all existing entries
/// - Provide validation and logging for the migration process
class WeekendOvertimeMigration {
  final LocalDatasourceImpl _dataSource;
  final WeekendDetectionService _weekendDetectionService;

  /// Migration statistics
  int _totalEntriesProcessed = 0;
  int _weekendEntriesFound = 0;
  int _weekendEntriesConverted = 0;
  int _errorsEncountered = 0;
  final List<String> _migrationLogs = [];

  WeekendOvertimeMigration(this._dataSource, this._weekendDetectionService);

  /// Performs the complete migration of existing timesheet entries
  ///
  /// This method will:
  /// 1. Retrieve all existing timesheet entries
  /// 2. Identify entries that fall on weekend days
  /// 3. Update weekend status and overtime type for each entry
  /// 4. Save the updated entries back to the database
  /// 5. Generate a migration report
  ///
  /// Returns a [MigrationResult] containing statistics and logs
  Future<MigrationResult> migrateExistingEntries() async {
    logger
        .i('[WeekendOvertimeMigration] Starting migration of existing entries');
    _resetStatistics();

    try {
      // Get all existing timesheet entries
      final entries = await _dataSource.getTimesheetEntries();
      logger.i(
          '[WeekendOvertimeMigration] Found ${entries.length} entries to process');

      _totalEntriesProcessed = entries.length;
      _addLog('Migration started with ${entries.length} entries to process');

      // Process each entry
      for (final entry in entries) {
        await _processEntry(entry);
      }

      // Generate final report
      final result = _generateMigrationResult();
      logger.i('[WeekendOvertimeMigration] Migration completed successfully');
      logger.i('[WeekendOvertimeMigration] ${result.summary}');

      return result;
    } catch (e, stackTrace) {
      logger.e('[WeekendOvertimeMigration] Migration failed: $e',
          error: e, stackTrace: stackTrace);
      _errorsEncountered++;
      _addLog('Migration failed with error: $e');

      return _generateMigrationResult();
    }
  }

  /// Processes a single timesheet entry for weekend migration
  ///
  /// [entry] The timesheet entry to process
  Future<void> _processEntry(TimeSheetEntryModel entry) async {
    try {
      final entryDate = entry.dayDate;
      final formattedDate = DateFormat('dd-MMM-yy').format(entryDate);

      logger.d(
          '[WeekendOvertimeMigration] Processing entry for date: $formattedDate');

      // Check if this entry is on a weekend day
      final isWeekendDay = _weekendDetectionService.isWeekend(entryDate);

      if (isWeekendDay) {
        _weekendEntriesFound++;
        _addLog('Weekend entry found for $formattedDate');

        // Update weekend status
        final wasUpdated = await _updateWeekendStatus(entry, isWeekendDay);

        if (wasUpdated) {
          _weekendEntriesConverted++;
          _addLog('Successfully converted weekend entry for $formattedDate');
        }
      } else {
        // For weekday entries, ensure weekend status is correct
        if (entry.isWeekendDay) {
          // This entry was incorrectly marked as weekend, fix it
          await _updateWeekendStatus(entry, false);
          _addLog('Fixed incorrectly marked weekend entry for $formattedDate');
        }
      }
    } catch (e, stackTrace) {
      _errorsEncountered++;
      final formattedDate = DateFormat('dd-MMM-yy').format(entry.dayDate);
      logger.e(
          '[WeekendOvertimeMigration] Error processing entry for $formattedDate: $e',
          error: e,
          stackTrace: stackTrace);
      _addLog('Error processing entry for $formattedDate: $e');
    }
  }

  /// Updates the weekend status and overtime type for a timesheet entry
  ///
  /// [entry] The timesheet entry to update
  /// [isWeekendDay] Whether this entry is on a weekend day
  ///
  /// Returns true if the entry was updated and saved successfully
  Future<bool> _updateWeekendStatus(
      TimeSheetEntryModel entry, bool isWeekendDay) async {
    try {
      // Store original values for comparison
      final originalIsWeekendDay = entry.isWeekendDay;
      final originalOvertimeType = entry.overtimeType;

      // Update weekend status
      entry.isWeekendDay = isWeekendDay;

      // Determine if weekend overtime should be enabled (default to true for migration)
      final weekendOvertimeEnabled =
          await _weekendDetectionService.isWeekendOvertimeEnabled();
      entry.isWeekendOvertimeEnabled = weekendOvertimeEnabled;

      // Calculate if this entry has any work hours
      final hasWorkHours = _hasWorkHours(entry);

      // Update overtime type based on weekend status and work hours
      if (isWeekendDay && weekendOvertimeEnabled && hasWorkHours) {
        if (entry.hasOvertimeHours) {
          entry.overtimeType = OvertimeType.BOTH;
        } else {
          entry.overtimeType = OvertimeType.WEEKEND_ONLY;
        }
      } else if (entry.hasOvertimeHours && !isWeekendDay) {
        entry.overtimeType = OvertimeType.WEEKDAY_ONLY;
      } else {
        entry.overtimeType = OvertimeType.NONE;
      }

      // Only save if something actually changed
      if (originalIsWeekendDay != entry.isWeekendDay ||
          originalOvertimeType != entry.overtimeType) {
        await _dataSource.updateTimesheetEntry(entry);

        final formattedDate = DateFormat('dd-MMM-yy').format(entry.dayDate);
        logger.d('[WeekendOvertimeMigration] Updated entry for $formattedDate: '
            'isWeekendDay=$isWeekendDay, overtimeType=${entry.overtimeType}');

        return true;
      }

      return false;
    } catch (e, stackTrace) {
      logger.e('[WeekendOvertimeMigration] Error updating weekend status: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Checks if a timesheet entry has any work hours recorded
  ///
  /// [entry] The timesheet entry to check
  ///
  /// Returns true if the entry has any time recorded
  bool _hasWorkHours(TimeSheetEntryModel entry) {
    return entry.startMorning.isNotEmpty ||
        entry.endMorning.isNotEmpty ||
        entry.startAfternoon.isNotEmpty ||
        entry.endAfternoon.isNotEmpty;
  }

  /// Validates the migration results by checking a sample of entries
  ///
  /// This method performs post-migration validation to ensure the migration
  /// was successful and data integrity is maintained.
  ///
  /// Returns a [ValidationResult] with validation status and any issues found
  Future<ValidationResult> validateMigration() async {
    logger.i('[WeekendOvertimeMigration] Starting migration validation');

    try {
      final entries = await _dataSource.getTimesheetEntries();
      int validatedEntries = 0;
      int validationErrors = 0;
      final List<String> validationIssues = [];

      // Take a sample of entries for validation (max 100 or 10% of total)
      final sampleSize = (entries.length * 0.1).ceil().clamp(1, 100);
      final sampleEntries = entries.take(sampleSize).toList();

      for (final entry in sampleEntries) {
        validatedEntries++;

        final entryDate = entry.dayDate;
        final isActuallyWeekend = _weekendDetectionService.isWeekend(entryDate);

        // Validate weekend day detection
        if (entry.isWeekendDay != isActuallyWeekend) {
          validationErrors++;
          final formattedDate = DateFormat('dd-MMM-yy').format(entryDate);
          validationIssues.add('Weekend day mismatch for $formattedDate: '
              'stored=${entry.isWeekendDay}, actual=$isActuallyWeekend');
        }

        // Validate overtime type consistency
        if (entry.isWeekendDay &&
            entry.isWeekendOvertimeEnabled &&
            _hasWorkHours(entry)) {
          if (entry.overtimeType == OvertimeType.NONE) {
            validationErrors++;
            final formattedDate = DateFormat('dd-MMM-yy').format(entryDate);
            validationIssues.add(
                'Weekend entry should have overtime type but has NONE for $formattedDate');
          }
        }
      }

      final result = ValidationResult(
        totalValidated: validatedEntries,
        errorsFound: validationErrors,
        issues: validationIssues,
        isValid: validationErrors == 0,
      );

      logger.i(
          '[WeekendOvertimeMigration] Validation completed: ${result.summary}');
      return result;
    } catch (e, stackTrace) {
      logger.e('[WeekendOvertimeMigration] Validation failed: $e',
          error: e, stackTrace: stackTrace);
      return ValidationResult(
        totalValidated: 0,
        errorsFound: 1,
        issues: ['Validation failed with error: $e'],
        isValid: false,
      );
    }
  }

  /// Resets migration statistics for a new migration run
  void _resetStatistics() {
    _totalEntriesProcessed = 0;
    _weekendEntriesFound = 0;
    _weekendEntriesConverted = 0;
    _errorsEncountered = 0;
    _migrationLogs.clear();
  }

  /// Adds a log entry to the migration logs
  void _addLog(String message) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    _migrationLogs.add('[$timestamp] $message');
  }

  /// Generates the final migration result
  MigrationResult _generateMigrationResult() {
    return MigrationResult(
      totalEntriesProcessed: _totalEntriesProcessed,
      weekendEntriesFound: _weekendEntriesFound,
      weekendEntriesConverted: _weekendEntriesConverted,
      errorsEncountered: _errorsEncountered,
      migrationLogs: List.from(_migrationLogs),
      isSuccessful: _errorsEncountered == 0,
    );
  }
}

/// Result of the weekend overtime migration process
class MigrationResult {
  final int totalEntriesProcessed;
  final int weekendEntriesFound;
  final int weekendEntriesConverted;
  final int errorsEncountered;
  final List<String> migrationLogs;
  final bool isSuccessful;

  MigrationResult({
    required this.totalEntriesProcessed,
    required this.weekendEntriesFound,
    required this.weekendEntriesConverted,
    required this.errorsEncountered,
    required this.migrationLogs,
    required this.isSuccessful,
  });

  /// Returns a summary of the migration results
  String get summary {
    return 'Migration ${isSuccessful ? 'completed successfully' : 'completed with errors'}: '
        '$totalEntriesProcessed entries processed, '
        '$weekendEntriesFound weekend entries found, '
        '$weekendEntriesConverted entries converted, '
        '$errorsEncountered errors encountered';
  }

  /// Returns detailed migration report
  String get detailedReport {
    final buffer = StringBuffer();
    buffer.writeln('=== Weekend Overtime Migration Report ===');
    buffer.writeln(
        'Status: ${isSuccessful ? 'SUCCESS' : 'COMPLETED WITH ERRORS'}');
    buffer.writeln('Total entries processed: $totalEntriesProcessed');
    buffer.writeln('Weekend entries found: $weekendEntriesFound');
    buffer.writeln('Weekend entries converted: $weekendEntriesConverted');
    buffer.writeln('Errors encountered: $errorsEncountered');
    buffer.writeln('');
    buffer.writeln('=== Migration Logs ===');
    for (final log in migrationLogs) {
      buffer.writeln(log);
    }
    return buffer.toString();
  }
}

/// Result of the migration validation process
class ValidationResult {
  final int totalValidated;
  final int errorsFound;
  final List<String> issues;
  final bool isValid;

  ValidationResult({
    required this.totalValidated,
    required this.errorsFound,
    required this.issues,
    required this.isValid,
  });

  /// Returns a summary of the validation results
  String get summary {
    return 'Validation ${isValid ? 'passed' : 'failed'}: '
        '$totalValidated entries validated, '
        '$errorsFound errors found';
  }

  /// Returns detailed validation report
  String get detailedReport {
    final buffer = StringBuffer();
    buffer.writeln('=== Migration Validation Report ===');
    buffer.writeln('Status: ${isValid ? 'VALID' : 'INVALID'}');
    buffer.writeln('Total entries validated: $totalValidated');
    buffer.writeln('Errors found: $errorsFound');
    buffer.writeln('');
    if (issues.isNotEmpty) {
      buffer.writeln('=== Validation Issues ===');
      for (final issue in issues) {
        buffer.writeln('- $issue');
      }
    }
    return buffer.toString();
  }
}
