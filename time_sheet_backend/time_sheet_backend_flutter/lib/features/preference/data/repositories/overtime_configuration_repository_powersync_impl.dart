import 'dart:convert';

import 'package:powersync/powersync.dart';

import '../../../../core/services/supabase/supabase_service.dart';
import '../../domain/repositories/overtime_configuration_repository.dart';
import '../models/overtime_configuration.dart';

/// PowerSync-based implementation of OvertimeConfigurationRepository.
/// Uses the `overtime_configurations` table which syncs with PostgreSQL.
class OvertimeConfigurationRepositoryPowerSyncImpl
    implements OvertimeConfigurationRepository {
  final PowerSyncDatabase db;

  OvertimeConfigurationRepositoryPowerSyncImpl(this.db);

  String get _userId => SupabaseService.instance.currentUserId ?? '';

  @override
  Future<OvertimeConfiguration?> getConfiguration() async {
    final row = await db.getOptional(
      'SELECT * FROM overtime_configurations WHERE user_id = ? LIMIT 1',
      [_userId],
    );
    if (row == null) return null;
    return _rowToConfig(row);
  }

  @override
  Future<void> saveConfiguration(OvertimeConfiguration configuration) async {
    configuration.validate();
    configuration.touch();

    final existing = await db.getOptional(
      'SELECT id FROM overtime_configurations WHERE user_id = ? LIMIT 1',
      [_userId],
    );

    final weekendDaysJson = jsonEncode(configuration.weekendDays);

    if (existing != null) {
      await db.execute(
        '''UPDATE overtime_configurations SET
          weekend_overtime_enabled = ?, weekend_days = ?,
          weekend_overtime_rate = ?, weekday_overtime_rate = ?,
          daily_work_threshold_minutes = ?, description = ?,
          updated_at = ?
          WHERE id = ?''',
        [
          configuration.weekendOvertimeEnabled ? 1 : 0,
          weekendDaysJson,
          configuration.weekendOvertimeRate,
          configuration.weekdayOvertimeRate,
          configuration.dailyWorkThresholdMinutes,
          configuration.description ?? '',
          DateTime.now().toIso8601String(),
          existing['id'],
        ],
      );
    } else {
      await db.execute(
        '''INSERT INTO overtime_configurations
          (id, user_id, weekend_overtime_enabled, weekend_days,
           weekend_overtime_rate, weekday_overtime_rate,
           daily_work_threshold_minutes, description, created_at, updated_at)
          VALUES (uuid(), ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          _userId,
          configuration.weekendOvertimeEnabled ? 1 : 0,
          weekendDaysJson,
          configuration.weekendOvertimeRate,
          configuration.weekdayOvertimeRate,
          configuration.dailyWorkThresholdMinutes,
          configuration.description ?? '',
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );
    }
  }

  @override
  Future<OvertimeConfiguration> getOrCreateDefaultConfiguration() async {
    final existing = await getConfiguration();
    if (existing != null) return existing;

    final defaultConfig = OvertimeConfiguration.defaultConfig();
    await saveConfiguration(defaultConfig);
    return defaultConfig;
  }

  @override
  Future<void> resetToDefault() async {
    final defaultConfig = OvertimeConfiguration.defaultConfig();
    await saveConfiguration(defaultConfig);
  }

  @override
  Future<void> deleteConfiguration() async {
    await db.execute(
      'DELETE FROM overtime_configurations WHERE user_id = ?',
      [_userId],
    );
  }

  @override
  Future<bool> hasConfiguration() async {
    final result = await db.getOptional(
      'SELECT COUNT(*) as count FROM overtime_configurations WHERE user_id = ?',
      [_userId],
    );
    return (result?['count'] as int? ?? 0) > 0;
  }

  @override
  Future<void> updateConfiguration({
    bool? weekendOvertimeEnabled,
    List<int>? weekendDays,
    double? weekendOvertimeRate,
    double? weekdayOvertimeRate,
    int? dailyWorkThresholdMinutes,
    String? description,
  }) async {
    final existing = await getOrCreateDefaultConfiguration();

    final updated = existing.copyWith(
      weekendOvertimeEnabled: weekendOvertimeEnabled,
      weekendDays: weekendDays,
      weekendOvertimeRate: weekendOvertimeRate,
      weekdayOvertimeRate: weekdayOvertimeRate,
      dailyWorkThresholdMinutes: dailyWorkThresholdMinutes,
      description: description,
    );

    await saveConfiguration(updated);
  }

  @override
  Future<Map<String, dynamic>?> exportConfiguration() async {
    final config = await getConfiguration();
    return config?.toMap();
  }

  @override
  Future<void> importConfiguration(Map<String, dynamic> configMap) async {
    final config = OvertimeConfiguration.fromMap(configMap);
    await saveConfiguration(config);
  }

  OvertimeConfiguration _rowToConfig(Map<String, dynamic> row) {
    final config = OvertimeConfiguration();
    config.id = (row['id'] as String).hashCode;
    config.weekendOvertimeEnabled =
        (row['weekend_overtime_enabled'] as int? ?? 1) == 1;

    // Parse weekend_days - stored as JSON array string
    final weekendDaysStr = row['weekend_days'] as String?;
    if (weekendDaysStr != null && weekendDaysStr.isNotEmpty) {
      try {
        config.weekendDays = List<int>.from(jsonDecode(weekendDaysStr));
      } catch (_) {
        config.weekendDays = [DateTime.saturday, DateTime.sunday];
      }
    }

    config.weekendOvertimeRate =
        (row['weekend_overtime_rate'] as num?)?.toDouble() ?? 1.5;
    config.weekdayOvertimeRate =
        (row['weekday_overtime_rate'] as num?)?.toDouble() ?? 1.25;
    config.dailyWorkThresholdMinutes =
        row['daily_work_threshold_minutes'] as int? ?? 480;
    config.description = row['description'] as String?;

    final updatedAt = row['updated_at'] as String?;
    config.lastUpdated = updatedAt != null
        ? (DateTime.tryParse(updatedAt) ?? DateTime.now())
        : DateTime.now();

    return config;
  }
}
