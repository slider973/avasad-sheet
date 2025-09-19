import 'package:isar/isar.dart';

import '../../domain/repositories/overtime_configuration_repository.dart';
import '../models/overtime_configuration.dart';

/// Implementation of OvertimeConfigurationRepository using Isar database
class OvertimeConfigurationRepositoryImpl
    implements OvertimeConfigurationRepository {
  final Isar isar;

  OvertimeConfigurationRepositoryImpl(this.isar);

  @override
  Future<OvertimeConfiguration?> getConfiguration() async {
    return await isar.overtimeConfigurations.where().findFirst();
  }

  @override
  Future<void> saveConfiguration(OvertimeConfiguration configuration) async {
    // Validate configuration before saving
    configuration.validate();
    configuration.touch(); // Update lastUpdated timestamp

    await isar.writeTxn(() async {
      // Delete any existing configuration (we only want one)
      await isar.overtimeConfigurations.clear();

      // Save the new configuration
      await isar.overtimeConfigurations.put(configuration);
    });
  }

  @override
  Future<OvertimeConfiguration> getOrCreateDefaultConfiguration() async {
    final existing = await getConfiguration();
    if (existing != null) {
      return existing;
    }

    // Create and save default configuration
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
    await isar.writeTxn(() async {
      await isar.overtimeConfigurations.clear();
    });
  }

  @override
  Future<bool> hasConfiguration() async {
    final count = await isar.overtimeConfigurations.count();
    return count > 0;
  }

  /// Gets configuration by ID (for future use if multiple configs are needed)
  Future<OvertimeConfiguration?> getConfigurationById(Id id) async {
    return await isar.overtimeConfigurations.get(id);
  }

  /// Updates specific fields of the configuration
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

  /// Gets all configurations (for debugging or migration purposes)
  Future<List<OvertimeConfiguration>> getAllConfigurations() async {
    return await isar.overtimeConfigurations.where().findAll();
  }

  /// Exports configuration as Map for backup purposes
  Future<Map<String, dynamic>?> exportConfiguration() async {
    final config = await getConfiguration();
    return config?.toMap();
  }

  /// Imports configuration from Map (for restore purposes)
  Future<void> importConfiguration(Map<String, dynamic> configMap) async {
    final config = OvertimeConfiguration.fromMap(configMap);
    await saveConfiguration(config);
  }
}
