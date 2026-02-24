import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

import '../../features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import '../../features/pointage/data/models/anomalies/anomalies.dart';
import '../../features/pointage/data/models/generated_pdf/generated_pdf.dart';
import '../../features/absence/data/models/absence.dart';
import '../../features/preference/data/models/user_preference.dart';
import '../../features/preference/data/models/overtime_configuration.dart';
import '../../features/expense/data/models/expense_model.dart';
import '../database/powersync_database.dart';
import '../services/supabase/supabase_service.dart';

/// One-time migration from Isar (local-only) to PowerSync (synced).
/// This should be called once after the user updates the app.
class IsarToPowerSyncMigration {
  static const String _migrationCompleteKey = 'isar_migration_complete';
  static final _uuid = Uuid();

  /// Check if migration is needed and perform it if so.
  /// Returns true if migration was performed, false if skipped.
  static Future<bool> migrateIfNeeded({
    Function(double progress, String message)? onProgress,
  }) async {
    // Skip on web
    if (kIsWeb) return false;

    // Check if migration was already done
    final db = PowerSyncDatabaseManager.database;
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) return false;

    // Check flag in local storage
    try {
      final existing = await db.getOptional(
        "SELECT * FROM user_preferences_local WHERE key = ?",
        [_migrationCompleteKey],
      );
      if (existing != null) {
        debugPrint('Isar migration already complete, skipping.');
        return false;
      }
    } catch (_) {
      // Table may not exist yet, continue with migration check
    }

    // Check if Isar database files exist
    final isarPath = await _getIsarPath();
    if (isarPath == null || !await _isarDatabaseExists(isarPath)) {
      debugPrint('No Isar database found, skipping migration.');
      return false;
    }

    // Perform migration
    debugPrint('Starting Isar to PowerSync migration...');
    onProgress?.call(0.0, 'Ouverture de la base de données Isar...');

    Isar? isar;
    try {
      isar = await Isar.open(
        [
          TimeSheetEntryModelSchema,
          GeneratedPdfModelSchema,
          UserPreferencesSchema,
          OvertimeConfigurationSchema,
          AbsenceSchema,
          AnomalyModelSchema,
          ExpenseModelSchema,
        ],
        directory: isarPath,
        name: 'default',
      );

      int totalSteps = 8;
      int currentStep = 0;

      // 1. Migrate timesheet entries
      currentStep++;
      onProgress?.call(currentStep / totalSteps, 'Migration des pointages...');
      await _migrateTimesheetEntries(isar, db, userId);

      // 2. Migrate absences
      currentStep++;
      onProgress?.call(currentStep / totalSteps, 'Migration des absences...');
      await _migrateAbsences(isar, db, userId);

      // 3. Migrate anomalies
      currentStep++;
      onProgress?.call(currentStep / totalSteps, 'Migration des anomalies...');
      await _migrateAnomalies(isar, db, userId);

      // 4. Migrate overtime configuration
      currentStep++;
      onProgress?.call(currentStep / totalSteps, 'Migration de la configuration...');
      await _migrateOvertimeConfig(isar, db, userId);

      // 5. Migrate expenses
      currentStep++;
      onProgress?.call(currentStep / totalSteps, 'Migration des dépenses...');
      await _migrateExpenses(isar, db, userId);

      // 6. Migrate generated PDFs metadata
      currentStep++;
      onProgress?.call(currentStep / totalSteps, 'Migration des PDFs...');
      await _migrateGeneratedPdfs(isar, db, userId);

      // 7. Migrate user preferences (signature, firstName, lastName, company, etc.)
      currentStep++;
      onProgress?.call(currentStep / totalSteps, 'Migration des préférences...');
      await _migrateUserPreferences(isar, db);

      // 8. Mark migration as complete
      currentStep++;
      onProgress?.call(currentStep / totalSteps, 'Finalisation...');
      await _markMigrationComplete(db);

      debugPrint('Isar to PowerSync migration complete!');
      onProgress?.call(1.0, 'Migration terminée !');

      return true;
    } catch (e) {
      debugPrint('Migration error: $e');
      onProgress?.call(-1, 'Erreur de migration: $e');
      return false;
    } finally {
      await isar?.close();
    }
  }

  static Future<String?> _getIsarPath() async {
    try {
      if (Platform.isWindows) {
        final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
        return path.join(localAppData, 'TimeSheet', 'Database');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        return dir.path;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<bool> _isarDatabaseExists(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return false;

    // Check for Isar database files
    final files = await dir.list().toList();
    return files.any((f) => f.path.endsWith('.isar'));
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _migrateTimesheetEntries(
    Isar isar,
    PowerSyncDatabase db,
    String userId,
  ) async {
    final entries = await isar.timeSheetEntryModels.where().findAll();
    debugPrint('Migrating ${entries.length} timesheet entries...');

    for (final entry in entries) {
      final uuid = _uuid.v4();
      await db.execute(
        '''INSERT OR IGNORE INTO timesheet_entries
           (id, user_id, day_date, day_of_week, start_morning, end_morning,
            start_afternoon, end_afternoon, absence_reason, period,
            has_overtime_hours, is_weekend_day, is_weekend_overtime_enabled,
            overtime_type)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          uuid,
          userId,
          _formatDate(entry.dayDate),
          entry.dayOfWeekDate,
          entry.startMorning,
          entry.endMorning,
          entry.startAfternoon,
          entry.endAfternoon,
          entry.absenceReason,
          entry.period,
          entry.hasOvertimeHours ? 1 : 0,
          entry.isWeekendDay ? 1 : 0,
          entry.isWeekendOvertimeEnabled ? 1 : 0,
          entry.overtimeType.name,
        ],
      );
    }
  }

  static Future<void> _migrateAbsences(
    Isar isar,
    PowerSyncDatabase db,
    String userId,
  ) async {
    final absences = await isar.absences.where().findAll();
    debugPrint('Migrating ${absences.length} absences...');

    for (final absence in absences) {
      final uuid = _uuid.v4();
      await db.execute(
        '''INSERT OR IGNORE INTO absences
           (id, user_id, start_date, end_date, type, motif)
           VALUES (?, ?, ?, ?, ?, ?)''',
        [
          uuid,
          userId,
          _formatDate(absence.startDate),
          _formatDate(absence.endDate),
          absence.type.name,
          absence.motif,
        ],
      );
    }

    // Link absences to timesheet entries by date matching
    await db.execute('''
      UPDATE absences SET timesheet_entry_id = (
        SELECT te.id FROM timesheet_entries te
        WHERE te.user_id = absences.user_id
        AND te.day_date >= absences.start_date
        AND te.day_date <= absences.end_date
        LIMIT 1
      )
      WHERE absences.timesheet_entry_id IS NULL AND absences.user_id = ?
    ''', [userId]);
    debugPrint('Linked absences to timesheet entries by date.');
  }

  static Future<void> _migrateAnomalies(
    Isar isar,
    PowerSyncDatabase db,
    String userId,
  ) async {
    final anomalies = await isar.anomalyModels.where().findAll();
    debugPrint('Migrating ${anomalies.length} anomalies...');

    for (final anomaly in anomalies) {
      final uuid = _uuid.v4();
      await db.execute(
        '''INSERT OR IGNORE INTO anomalies
           (id, user_id, detected_date, description, is_resolved, type)
           VALUES (?, ?, ?, ?, ?, ?)''',
        [
          uuid,
          userId,
          _formatDate(anomaly.detectedDate),
          anomaly.description,
          anomaly.isResolved ? 1 : 0,
          anomaly.type.name,
        ],
      );
    }
  }

  static Future<void> _migrateOvertimeConfig(
    Isar isar,
    PowerSyncDatabase db,
    String userId,
  ) async {
    final configs = await isar.overtimeConfigurations.where().findAll();
    debugPrint('Migrating ${configs.length} overtime configs...');

    for (final config in configs) {
      final uuid = _uuid.v4();
      await db.execute(
        '''INSERT OR IGNORE INTO overtime_configurations
           (id, user_id, weekend_overtime_enabled, weekend_overtime_rate,
            weekday_overtime_rate, daily_work_threshold_minutes, description)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          uuid,
          userId,
          config.weekendOvertimeEnabled ? 1 : 0,
          config.weekendOvertimeRate,
          config.weekdayOvertimeRate,
          config.dailyWorkThresholdMinutes,
          config.description ?? '',
        ],
      );
    }
  }

  static Future<void> _migrateExpenses(
    Isar isar,
    PowerSyncDatabase db,
    String userId,
  ) async {
    final expenses = await isar.expenseModels.where().findAll();
    debugPrint('Migrating ${expenses.length} expenses...');

    for (final expense in expenses) {
      final uuid = _uuid.v4();
      await db.execute(
        '''INSERT OR IGNORE INTO expenses
           (id, user_id, date, category, description, currency, amount,
            mileage_rate, distance_km, departure_location, arrival_location,
            is_approved)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          uuid,
          userId,
          _formatDate(expense.date),
          expense.category.name,
          expense.description,
          expense.currency,
          expense.amount,
          expense.mileageRate,
          expense.distanceKm,
          expense.departureLocation ?? '',
          expense.arrivalLocation ?? '',
          expense.isApproved ? 1 : 0,
        ],
      );
    }
  }

  static Future<void> _migrateGeneratedPdfs(
    Isar isar,
    PowerSyncDatabase db,
    String userId,
  ) async {
    final pdfs = await isar.generatedPdfModels.where().findAll();
    debugPrint('Migrating ${pdfs.length} generated PDFs...');

    for (final pdf in pdfs) {
      final uuid = _uuid.v4();
      await db.execute(
        '''INSERT OR IGNORE INTO generated_pdfs
           (id, user_id, file_name, file_url, month, year)
           VALUES (?, ?, ?, ?, ?, ?)''',
        [
          uuid,
          userId,
          pdf.fileName,
          pdf.filePath,
          null, // GeneratedPdfModel doesn't have month/year fields
          null,
        ],
      );
    }
  }

  static Future<void> _migrateUserPreferences(
    Isar isar,
    PowerSyncDatabase db,
  ) async {
    final prefs = await isar.userPreferences.where().findAll();
    debugPrint('Migrating ${prefs.length} user preferences...');

    // S'assurer que la table existe
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    for (final pref in prefs) {
      await db.execute(
        'INSERT OR REPLACE INTO user_preferences (key, value) VALUES (?, ?)',
        [pref.key, pref.value],
      );
      debugPrint('Migrated preference: ${pref.key} (${pref.value.length > 50 ? '${pref.value.length} chars' : pref.value})');
    }
  }

  static Future<void> _markMigrationComplete(PowerSyncDatabase db) async {
    // Store flag in a simple way - we check for this at the top
    // Using a direct SQL to avoid dependency on any specific table
    try {
      await db.execute(
        '''CREATE TABLE IF NOT EXISTS user_preferences_local (
           key TEXT PRIMARY KEY,
           value TEXT
         )''',
      );
      await db.execute(
        "INSERT OR REPLACE INTO user_preferences_local (key, value) VALUES (?, ?)",
        [_migrationCompleteKey, 'true'],
      );
    } catch (e) {
      debugPrint('Error marking migration complete: $e');
    }
  }

  /// Delete Isar database files after successful migration.
  /// Call this only after confirming migration was successful.
  static Future<void> cleanupIsarFiles() async {
    try {
      final isarPath = await _getIsarPath();
      if (isarPath == null) return;

      final dir = Directory(isarPath);
      if (!await dir.exists()) return;

      final files = await dir.list().toList();
      for (final file in files) {
        if (file.path.endsWith('.isar') || file.path.endsWith('.isar.lock')) {
          await file.delete();
          debugPrint('Deleted: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up Isar files: $e');
    }
  }
}
