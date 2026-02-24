import 'package:intl/intl.dart';
import 'package:powersync/powersync.dart';

import '../../../../core/services/supabase/supabase_service.dart';
import '../models/anomalies/anomalies.dart';
import 'anomaly_repository_impl.dart';

/// PowerSync-based implementation of AnomalyRepository.
/// Uses the `anomalies` table which syncs with PostgreSQL.
class AnomalyRepositoryPowerSyncImpl implements AnomalyRepository {
  final PowerSyncDatabase db;

  AnomalyRepositoryPowerSyncImpl(this.db);

  String get _userId => SupabaseService.instance.currentUserId ?? '';

  @override
  Future<void> markResolved(int anomalyId) async {
    // anomalyId is a hashCode of UUID - find the real UUID
    final rows = await db.getAll(
      'SELECT id FROM anomalies WHERE user_id = ?',
      [_userId],
    );

    for (final row in rows) {
      if ((row['id'] as String).hashCode == anomalyId) {
        await db.execute(
          'UPDATE anomalies SET is_resolved = 1 WHERE id = ?',
          [row['id']],
        );
        return;
      }
    }
  }

  @override
  Future<List<AnomalyModel>> getAnomalies() async {
    final rows = await db.getAll(
      'SELECT * FROM anomalies WHERE user_id = ? ORDER BY detected_date DESC',
      [_userId],
    );
    return rows.map((row) => _rowToModel(row)).toList();
  }

  @override
  Future<void> saveAnomaly(AnomalyModel anomaly) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(anomaly.detectedDate);

    await db.execute(
      '''INSERT INTO anomalies (id, user_id, detected_date, description, is_resolved, type, created_at)
        VALUES (uuid(), ?, ?, ?, ?, ?, ?)''',
      [
        _userId,
        dateStr,
        anomaly.description,
        anomaly.isResolved ? 1 : 0,
        anomaly.type.name,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  AnomalyModel _rowToModel(Map<String, dynamic> row) {
    final model = AnomalyModel();
    model.id = (row['id'] as String).hashCode;
    model.detectedDate =
        DateTime.tryParse(row['detected_date'] as String? ?? '') ??
            DateTime.now();
    model.description = row['description'] as String? ?? '';
    model.isResolved = (row['is_resolved'] as int? ?? 0) == 1;

    final typeStr = row['type'] as String? ?? 'missingEntry';
    model.type = AnomalyType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => AnomalyType.missingEntry,
    );

    return model;
  }
}
