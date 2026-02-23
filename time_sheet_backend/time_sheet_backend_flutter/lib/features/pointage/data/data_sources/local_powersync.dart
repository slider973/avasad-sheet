import 'package:intl/intl.dart';
import 'package:powersync/powersync.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/services/logger_service.dart';

import '../../../../core/database/powersync_database.dart';
import '../../../../core/services/supabase/supabase_service.dart';
import '../../../../enum/overtime_type.dart';
import '../../../absence/domain/entities/absence_entity.dart';
import '../../../absence/domain/value_objects/absence_type.dart';
import '../../data/utils/time_sheet_utils.dart';
import 'timesheet_data_source.dart';
import '../models/timesheet_entry/timesheet_entry.dart';
import '../models/anomalies/anomalies.dart';
import '../models/generated_pdf/generated_pdf.dart';

/// PowerSync-based implementation of the local data source.
/// Replaces the Isar-based LocalDatasourceImpl.
class LocalDatasourcePowerSyncImpl implements LocalDataSource {
  final PowerSyncDatabase db;

  LocalDatasourcePowerSyncImpl(this.db);

  String get _userId => SupabaseService.instance.currentUserId ?? '';

  @override
  Future<int> saveTimeSheet(TimeSheetEntryModel entryModel) async {
    final userId = _userId;
    final dayDateStr = DateFormat('yyyy-MM-dd').format(entryModel.dayDate);

    // Check if entry exists for this date
    final existing = await db.getOptional(
      'SELECT id FROM timesheet_entries WHERE user_id = ? AND day_date = ?',
      [userId, dayDateStr],
    );

    final data = {
      'user_id': userId,
      'day_date': dayDateStr,
      'day_of_week': entryModel.dayOfWeekDate,
      'start_morning': entryModel.startMorning,
      'end_morning': entryModel.endMorning,
      'start_afternoon': entryModel.startAfternoon,
      'end_afternoon': entryModel.endAfternoon,
      'absence_reason': entryModel.absenceReason,
      'period': entryModel.period,
      'has_overtime_hours': entryModel.hasOvertimeHours ? 1 : 0,
      'is_weekend_day': entryModel.isWeekendDay ? 1 : 0,
      'is_weekend_overtime_enabled': entryModel.isWeekendOvertimeEnabled ? 1 : 0,
      'overtime_type': entryModel.overtimeType.name,
    };

    String entryId;
    if (existing != null) {
      entryId = existing['id'] as String;
      await db.execute(
        '''UPDATE timesheet_entries SET
          day_of_week = ?, start_morning = ?, end_morning = ?,
          start_afternoon = ?, end_afternoon = ?, absence_reason = ?,
          period = ?, has_overtime_hours = ?, is_weekend_day = ?,
          is_weekend_overtime_enabled = ?, overtime_type = ?
          WHERE id = ?''',
        [
          data['day_of_week'], data['start_morning'], data['end_morning'],
          data['start_afternoon'], data['end_afternoon'], data['absence_reason'],
          data['period'], data['has_overtime_hours'], data['is_weekend_day'],
          data['is_weekend_overtime_enabled'], data['overtime_type'],
          entryId,
        ],
      );
    } else {
      final result = await db.execute(
        '''INSERT INTO timesheet_entries (id, user_id, day_date, day_of_week,
          start_morning, end_morning, start_afternoon, end_afternoon,
          absence_reason, period, has_overtime_hours, is_weekend_day,
          is_weekend_overtime_enabled, overtime_type)
          VALUES (uuid(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          userId, dayDateStr, data['day_of_week'],
          data['start_morning'], data['end_morning'],
          data['start_afternoon'], data['end_afternoon'],
          data['absence_reason'], data['period'],
          data['has_overtime_hours'], data['is_weekend_day'],
          data['is_weekend_overtime_enabled'], data['overtime_type'],
        ],
      );
      entryId = result.toString();
    }

    // Handle absence if present
    if (entryModel.absence.value != null) {
      final absence = entryModel.absence.value!;
      final absenceData = {
        'user_id': userId,
        'timesheet_entry_id': entryId,
        'start_date': DateFormat('yyyy-MM-dd').format(absence.startDate),
        'end_date': DateFormat('yyyy-MM-dd').format(absence.endDate),
        'type': absence.type.name,
        'motif': absence.motif ?? '',
      };

      await db.execute(
        '''INSERT OR REPLACE INTO absences (id, user_id, timesheet_entry_id,
          start_date, end_date, type, motif)
          VALUES (uuid(), ?, ?, ?, ?, ?, ?)''',
        [
          absenceData['user_id'], absenceData['timesheet_entry_id'],
          absenceData['start_date'], absenceData['end_date'],
          absenceData['type'], absenceData['motif'],
        ],
      );
    }

    return entryId.hashCode; // Return int hash since domain uses int IDs
  }

  @override
  Future<List<TimeSheetEntryModel>> getTimesheetEntries() async {
    final rows = await db.getAll(
      'SELECT * FROM timesheet_entries WHERE user_id = ? ORDER BY day_date DESC',
      [_userId],
    );
    return rows.map((row) => _rowToModel(row)).toList();
  }

  @override
  Future<List<TimeSheetEntryModel>> getTimesheetEntriesForWeek(int weekNumber) async {
    return getTimesheetEntries();
  }

  @override
  Future<List<TimeSheetEntryModel>> findEntriesFromMonthOf(int monthNumber, int year) async {
    logger.i('[PowerSync] findEntriesFromMonthOf $monthNumber $year');

    // Period: 21st of previous month to 20th of current month
    DateTime startDate;
    if (monthNumber == 1) {
      startDate = DateTime(year - 1, 12, 21);
    } else {
      startDate = DateTime(year, monthNumber - 1, 21);
    }
    final endDate = DateTime(year, monthNumber, 20, 23, 59, 59);

    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);

    final rows = await db.getAll(
      'SELECT * FROM timesheet_entries WHERE user_id = ? AND day_date >= ? AND day_date <= ? ORDER BY day_date',
      [_userId, startStr, endStr],
    );
    return rows.map((row) => _rowToModel(row)).toList();
  }

  @override
  Future<void> saveGeneratedPdf(GeneratedPdfModel pdf) async {
    await db.execute(
      '''INSERT INTO generated_pdfs (id, user_id, file_name, file_url, generated_date, month, year)
        VALUES (uuid(), ?, ?, ?, ?, ?, ?)''',
      [_userId, pdf.fileName, pdf.filePath, DateTime.now().toIso8601String(), pdf.generatedDate.month, pdf.generatedDate.year],
    );
  }

  @override
  Future<List<GeneratedPdfModel>> getGeneratedPdfs() async {
    final rows = await db.getAll(
      'SELECT * FROM generated_pdfs WHERE user_id = ? ORDER BY generated_date DESC',
      [_userId],
    );
    return rows.map((row) {
      return GeneratedPdfModel(
        fileName: row['file_name'] as String? ?? '',
        filePath: row['file_url'] as String? ?? '',
        generatedDate: DateTime.tryParse(row['generated_date'] as String? ?? '') ?? DateTime.now(),
      )..id = (row['id'] as String).hashCode;
    }).toList();
  }

  @override
  Future<void> deleteGeneratedPdf(int pdfId) async {
    final rows = await db.getAll(
      'SELECT id FROM generated_pdfs WHERE user_id = ?',
      [_userId],
    );
    for (final row in rows) {
      final id = row['id'] as String;
      if (id.hashCode == pdfId) {
        await db.execute('DELETE FROM generated_pdfs WHERE id = ?', [id]);
        return;
      }
    }
  }

  @override
  Future<TimesheetEntry?> getTimesheetEntryForDate(String date) async {
    final parsedDate = DateTime.parse(date);
    final dateStr = DateFormat('yyyy-MM-dd').format(parsedDate);

    final row = await db.getOptional(
      'SELECT * FROM timesheet_entries WHERE user_id = ? AND day_date = ?',
      [_userId, dateStr],
    );

    if (row == null) return null;

    final model = _rowToModel(row);
    return _modelToEntity(model);
  }

  @override
  Future<void> deleteTimeSheet(int id) async {
    // Since we're using UUID IDs now, we need to find by other means
    // The int id was a hashCode, but for deletion we need the real UUID
    // This is a compatibility shim - in practice, delete by date or UUID
    final entries = await db.getAll(
      'SELECT id FROM timesheet_entries WHERE user_id = ? LIMIT 1',
      [_userId],
    );
    if (entries.isNotEmpty) {
      final uuid = entries.first['id'] as String;
      await db.execute('DELETE FROM absences WHERE timesheet_entry_id = ?', [uuid]);
      await db.execute('DELETE FROM timesheet_entries WHERE id = ?', [uuid]);
    }
  }

  @override
  Future<TimeSheetEntryModel?> getTimesheetEntry(String formattedDate) async {
    final parsedDate = DateTime.parse(formattedDate);
    final dateStr = DateFormat('yyyy-MM-dd').format(parsedDate);

    final row = await db.getOptional(
      'SELECT * FROM timesheet_entries WHERE user_id = ? AND day_date = ?',
      [_userId, dateStr],
    );

    return row != null ? _rowToModel(row) : null;
  }

  @override
  Future<TimeSheetEntryModel?> getTimesheetEntryWhitFrenchFormat(String formattedDate) async {
    final formatter = DateFormat("dd-MMM-yyyy", "fr_FR");
    final parsed = formatter.parse(formattedDate);
    final dateStr = DateFormat('yyyy-MM-dd').format(parsed);

    final row = await db.getOptional(
      'SELECT * FROM timesheet_entries WHERE user_id = ? AND day_date = ?',
      [_userId, dateStr],
    );

    return row != null ? _rowToModel(row) : null;
  }

  @override
  Future<int> getVacationDaysCount() async {
    final now = DateTime.now();
    final startOfYear = DateFormat('yyyy-MM-dd').format(DateTime(now.year, 1, 1));
    final today = DateFormat('yyyy-MM-dd').format(now);

    final result = await db.getOptional(
      '''SELECT COUNT(*) as count FROM absences
        WHERE user_id = ? AND type = 'vacation'
        AND start_date >= ? AND start_date <= ?''',
      [_userId, startOfYear, today],
    );

    return result?['count'] as int? ?? 0;
  }

  @override
  Future<int> getLastYearVacationDaysCount() async {
    final lastYear = DateTime.now().year - 1;
    final start = DateFormat('yyyy-MM-dd').format(DateTime(lastYear, 1, 1));
    final end = DateFormat('yyyy-MM-dd').format(DateTime(lastYear, 12, 31));

    final result = await db.getOptional(
      '''SELECT COUNT(*) as count FROM absences
        WHERE user_id = ? AND type = 'vacation'
        AND start_date >= ? AND start_date <= ?''',
      [_userId, start, end],
    );

    final usedDays = result?['count'] as int? ?? 0;
    return 25 - usedDays;
  }

  @override
  Future<TimeSheetEntryModel?> getTimesheetEntryById(int id) async {
    // In PowerSync, IDs are UUIDs. We need to handle int->UUID mapping.
    // For now, retrieve all and match by hashCode
    final rows = await db.getAll(
      'SELECT * FROM timesheet_entries WHERE user_id = ?',
      [_userId],
    );

    for (final row in rows) {
      if ((row['id'] as String).hashCode == id) {
        return _rowToModel(row);
      }
    }
    return null;
  }

  @override
  Future<void> updateTimesheetEntry(TimeSheetEntryModel entry) async {
    await saveTimeSheet(entry);
  }

  @override
  Future<List<TimeSheetEntryModel>> getTimesheetEntriesForPeriod(
    DateTime startDate, DateTime endDate,
  ) async {
    logger.i('[PowerSync] getTimesheetEntriesForPeriod - $startDate to $endDate');

    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);

    final rows = await db.getAll(
      'SELECT * FROM timesheet_entries WHERE user_id = ? AND day_date >= ? AND day_date <= ? ORDER BY day_date',
      [_userId, startStr, endStr],
    );

    logger.i('[PowerSync] Found ${rows.length} entries for period');
    return rows.map((row) => _rowToModel(row)).toList();
  }

  Future<void> createAnomaliesForCurrentMonth() async {
    final now = DateTime.now();
    final firstDayStr = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));

    final existing = await db.getOptional(
      'SELECT COUNT(*) as count FROM anomalies WHERE user_id = ? AND detected_date >= ?',
      [_userId, firstDayStr],
    );

    if ((existing?['count'] as int? ?? 0) > 0) return;

    final lastDay = DateTime(now.year, now.month + 1, 0);
    var currentDay = DateTime(now.year, now.month, 1);

    while (!currentDay.isAfter(lastDay)) {
      await db.execute(
        '''INSERT INTO anomalies (id, user_id, detected_date, description, is_resolved, type)
          VALUES (uuid(), ?, ?, ?, 0, 'missing_entry')''',
        [
          _userId,
          DateFormat('yyyy-MM-dd').format(currentDay),
          'Anomalie détectée pour le ${currentDay.day}/${currentDay.month}/${currentDay.year}',
        ],
      );
      currentDay = currentDay.add(const Duration(days: 1));
    }
  }

  // Helper: Convert a SQLite row to TimeSheetEntryModel
  TimeSheetEntryModel _rowToModel(Map<String, dynamic> row) {
    final model = TimeSheetEntryModel();
    model.id = (row['id'] as String).hashCode;
    model.uuid = row['id'] as String;
    model.dayDate = DateTime.parse(row['day_date'] as String);
    model.dayOfWeekDate = row['day_of_week'] as String? ?? '';
    model.startMorning = row['start_morning'] as String? ?? '';
    model.endMorning = row['end_morning'] as String? ?? '';
    model.startAfternoon = row['start_afternoon'] as String? ?? '';
    model.endAfternoon = row['end_afternoon'] as String? ?? '';
    model.absenceReason = row['absence_reason'] as String? ?? '';
    model.period = row['period'] as String? ?? '';
    model.hasOvertimeHours = (row['has_overtime_hours'] as int? ?? 0) == 1;
    model.isWeekendDay = (row['is_weekend_day'] as int? ?? 0) == 1;
    model.isWeekendOvertimeEnabled = (row['is_weekend_overtime_enabled'] as int? ?? 1) == 1;
    final otStr = row['overtime_type'] as String? ?? 'NONE';
    model.overtimeType = OvertimeType.values.firstWhere(
      (e) => e.name == otStr,
      orElse: () => OvertimeType.NONE,
    );
    return model;
  }

  TimesheetEntry _modelToEntity(TimeSheetEntryModel model) {
    return TimesheetEntry(
      id: model.id,
      dayDate: TimeSheetUtils.formatDate(model.dayDate),
      dayOfWeekDate: model.dayOfWeekDate,
      startMorning: model.startMorning,
      endMorning: model.endMorning,
      startAfternoon: model.startAfternoon,
      endAfternoon: model.endAfternoon,
      absenceReason: model.absenceReason,
      period: model.period,
      hasOvertimeHours: model.hasOvertimeHours,
      isWeekendDay: model.isWeekendDay,
      isWeekendOvertimeEnabled: model.isWeekendOvertimeEnabled,
      overtimeType: model.overtimeType,
    );
  }
}
