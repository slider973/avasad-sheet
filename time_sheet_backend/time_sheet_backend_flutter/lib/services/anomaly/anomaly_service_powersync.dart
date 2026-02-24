import 'package:intl/intl.dart';
import 'package:powersync/powersync.dart';

import '../../core/services/supabase/supabase_service.dart';
import '../../features/pointage/data/models/anomalies/anomalies.dart';
import '../../features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import 'interface_timeSheetValidator.dart';
import 'insufficient_hours_rule.dart';
import 'excessive_hours_rule.dart';
import 'insufficient_break_rule.dart';
import 'unusual_hours_rule.dart';

/// PowerSync-based AnomalyService. Replaces the Isar-based AnomalyService.
class AnomalyServicePowerSync {
  final PowerSyncDatabase db;

  AnomalyServicePowerSync(this.db);

  String get _userId => SupabaseService.instance.currentUserId ?? '';

  Future<void> createAnomaliesForCurrentMonth() async {
    if (_userId.isEmpty) return;

    final validators = <ITimeSheetValidator>[
      InsufficientHoursRule(),
      ExcessiveHoursRule(),
      InsufficientBreakRule(),
      UnusualHoursRule(),
    ];

    final now = DateTime.now();
    final startOfPeriod = now.day >= 21
        ? DateTime(now.year, now.month, 21)
        : DateTime(now.year, now.month - 1, 21);
    final endOfPeriod = now.day >= 21
        ? DateTime(now.year, now.month + 1, 20)
        : DateTime(now.year, now.month, 20);

    final startStr = DateFormat('yyyy-MM-dd').format(startOfPeriod);
    final endStr = DateFormat('yyyy-MM-dd').format(endOfPeriod);

    // Delete existing anomalies for this period
    await db.execute(
      'DELETE FROM anomalies WHERE user_id = ? AND detected_date >= ? AND detected_date <= ?',
      [_userId, startStr, endStr],
    );

    // Get timesheet entries for the period
    final entries = await db.getAll(
      'SELECT * FROM timesheet_entries WHERE user_id = ? AND day_date >= ? AND day_date <= ? ORDER BY day_date',
      [_userId, startStr, endStr],
    );

    // Build a map of date -> entry for quick lookup
    final entryMap = <String, Map<String, dynamic>>{};
    for (final row in entries) {
      final dayDate = row['day_date'] as String;
      entryMap[dayDate] = row;
    }

    DateTime currentDay = startOfPeriod;

    while (currentDay.isBefore(endOfPeriod) ||
        currentDay.isAtSameMomentAs(endOfPeriod)) {
      // Skip weekends
      if (currentDay.weekday == DateTime.saturday ||
          currentDay.weekday == DateTime.sunday) {
        currentDay = currentDay.add(const Duration(days: 1));
        continue;
      }

      final dayStr = DateFormat('yyyy-MM-dd').format(currentDay);
      final entryRow = entryMap[dayStr];

      if (entryRow != null) {
        final model = _rowToModel(entryRow);
        // Run validators on the entry
        for (final validator in validators) {
          final anomaly = validator.validateAndGenerate(model, currentDay);
          if (anomaly != null) {
            await db.execute(
              '''INSERT INTO anomalies (id, user_id, detected_date, description, is_resolved, type, created_at)
                VALUES (uuid(), ?, ?, ?, 0, ?, ?)''',
              [
                _userId,
                dayStr,
                anomaly.description,
                anomaly.type.name,
                DateTime.now().toIso8601String(),
              ],
            );
          }
        }
      }

      currentDay = currentDay.add(const Duration(days: 1));
    }
  }

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
    model.isWeekendOvertimeEnabled =
        (row['is_weekend_overtime_enabled'] as int? ?? 1) == 1;
    return model;
  }
}
