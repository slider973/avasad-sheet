import '../../data/models/overtime_configuration.dart';

/// Repository interface for managing overtime configuration
abstract class OvertimeConfigurationRepository {
  /// Gets the current overtime configuration
  /// Returns null if no configuration exists
  Future<OvertimeConfiguration?> getConfiguration();

  /// Saves or updates the overtime configuration
  Future<void> saveConfiguration(OvertimeConfiguration configuration);

  /// Gets the configuration or creates a default one if none exists
  Future<OvertimeConfiguration> getOrCreateDefaultConfiguration();

  /// Resets the configuration to default values
  Future<void> resetToDefault();

  /// Deletes the current configuration
  Future<void> deleteConfiguration();

  /// Checks if a configuration exists
  Future<bool> hasConfiguration();

  /// Updates specific fields of the configuration
  Future<void> updateConfiguration({
    bool? weekendOvertimeEnabled,
    List<int>? weekendDays,
    double? weekendOvertimeRate,
    double? weekdayOvertimeRate,
    int? dailyWorkThresholdMinutes,
    String? description,
  });

  /// Exports configuration as Map for backup purposes
  Future<Map<String, dynamic>?> exportConfiguration();

  /// Imports configuration from Map (for restore purposes)
  Future<void> importConfiguration(Map<String, dynamic> configMap);
}
