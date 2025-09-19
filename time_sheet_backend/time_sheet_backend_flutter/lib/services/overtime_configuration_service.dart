import 'package:get_it/get_it.dart';

import '../features/preference/domain/repositories/overtime_configuration_repository.dart';
import '../features/preference/data/models/overtime_configuration.dart';

/// Service responsible for managing overtime configuration settings
///
/// This service provides functionality to:
/// - Configure weekend overtime settings (enabled/disabled)
/// - Manage custom weekend days configuration
/// - Set and retrieve overtime rates for weekend vs weekday
/// - Configure daily work thresholds
/// - Store and retrieve all overtime-related preferences using Isar database
class OvertimeConfigurationService {
  // Default values
  static const bool defaultWeekendOvertimeEnabled = true;
  static const List<int> defaultWeekendDays = [
    DateTime.saturday,
    DateTime.sunday
  ];
  static const double defaultWeekendOvertimeRate = 1.5; // 150%
  static const double defaultWeekdayOvertimeRate = 1.25; // 125%
  static const int defaultDailyWorkThresholdMinutes = 480; // 8 hours

  /// Singleton instance
  static final OvertimeConfigurationService _instance =
      OvertimeConfigurationService._internal();
  factory OvertimeConfigurationService() => _instance;
  OvertimeConfigurationService._internal();

  /// Repository for managing overtime configuration
  OvertimeConfigurationRepository get _repository =>
      GetIt.instance<OvertimeConfigurationRepository>();

  /// Cache for configuration
  OvertimeConfiguration? _cachedConfiguration;

  /// Gets the current weekend overtime enabled setting
  ///
  /// Returns true if weekend overtime is enabled
  Future<bool> isWeekendOvertimeEnabled() async {
    final config = await _getConfiguration();
    return config.weekendOvertimeEnabled;
  }

  /// Sets the weekend overtime enabled setting
  ///
  /// [enabled] Whether weekend overtime should be enabled
  Future<void> setWeekendOvertimeEnabled(bool enabled) async {
    await _updateConfiguration(weekendOvertimeEnabled: enabled);
  }

  /// Gets the currently configured weekend days
  ///
  /// Returns a list of integers representing weekend days (1=Monday, 7=Sunday)
  Future<List<int>> getWeekendDays() async {
    final config = await _getConfiguration();
    return List.from(config.weekendDays);
  }

  /// Sets the weekend days configuration
  ///
  /// [days] List of integers representing weekend days (1=Monday, 7=Sunday)
  /// Throws [ArgumentError] if invalid weekend days are provided
  Future<void> setWeekendDays(List<int> days) async {
    await _updateConfiguration(weekendDays: days);
  }

  /// Gets the current weekend overtime rate
  ///
  /// Returns the multiplier for weekend overtime hours (e.g., 1.5 for 150%)
  Future<double> getWeekendOvertimeRate() async {
    final config = await _getConfiguration();
    return config.weekendOvertimeRate;
  }

  /// Sets the weekend overtime rate
  ///
  /// [rate] The multiplier for weekend overtime hours (must be >= 1.0)
  /// Throws [ArgumentError] if rate is invalid
  Future<void> setWeekendOvertimeRate(double rate) async {
    await _updateConfiguration(weekendOvertimeRate: rate);
  }

  /// Gets the current weekday overtime rate
  ///
  /// Returns the multiplier for weekday overtime hours (e.g., 1.25 for 125%)
  Future<double> getWeekdayOvertimeRate() async {
    final config = await _getConfiguration();
    return config.weekdayOvertimeRate;
  }

  /// Sets the weekday overtime rate
  ///
  /// [rate] The multiplier for weekday overtime hours (must be >= 1.0)
  /// Throws [ArgumentError] if rate is invalid
  Future<void> setWeekdayOvertimeRate(double rate) async {
    await _updateConfiguration(weekdayOvertimeRate: rate);
  }

  /// Gets the daily work threshold
  ///
  /// Returns the duration after which work is considered overtime
  Future<Duration> getDailyWorkThreshold() async {
    final config = await _getConfiguration();
    return config.dailyWorkThreshold;
  }

  /// Sets the daily work threshold
  ///
  /// [threshold] The duration after which work is considered overtime
  /// Throws [ArgumentError] if threshold is invalid
  Future<void> setDailyWorkThreshold(Duration threshold) async {
    await _updateConfiguration(dailyWorkThresholdMinutes: threshold.inMinutes);
  }

  /// Resets all overtime configuration to default values
  Future<void> resetToDefaults() async {
    await _repository.resetToDefault();
    _cachedConfiguration = null;
  }

  /// Clears the cached configuration
  ///
  /// This forces the service to reload configuration from the database
  /// on the next access
  void clearCache() {
    _cachedConfiguration = null;
  }

  /// Gets all configuration values as a map
  ///
  /// Useful for debugging or displaying current settings
  Future<Map<String, dynamic>> getAllConfiguration() async {
    final config = await _getConfiguration();
    return config.toMap();
  }

  /// Gets the current configuration, creating a default one if none exists
  Future<OvertimeConfiguration> _getConfiguration() async {
    if (_cachedConfiguration != null) {
      return _cachedConfiguration!;
    }

    _cachedConfiguration = await _repository.getOrCreateDefaultConfiguration();
    return _cachedConfiguration!;
  }

  /// Updates the configuration with the provided values
  Future<void> _updateConfiguration({
    bool? weekendOvertimeEnabled,
    List<int>? weekendDays,
    double? weekendOvertimeRate,
    double? weekdayOvertimeRate,
    int? dailyWorkThresholdMinutes,
    String? description,
  }) async {
    await _repository.updateConfiguration(
      weekendOvertimeEnabled: weekendOvertimeEnabled,
      weekendDays: weekendDays,
      weekendOvertimeRate: weekendOvertimeRate,
      weekdayOvertimeRate: weekdayOvertimeRate,
      dailyWorkThresholdMinutes: dailyWorkThresholdMinutes,
      description: description,
    );

    // Clear cache to force reload on next access
    _cachedConfiguration = null;
  }

  /// Gets the full configuration object
  ///
  /// Useful for advanced operations or when multiple values are needed
  Future<OvertimeConfiguration> getConfigurationObject() async {
    return await _getConfiguration();
  }

  /// Saves a complete configuration object
  ///
  /// [configuration] The configuration to save
  Future<void> saveConfiguration(OvertimeConfiguration configuration) async {
    await _repository.saveConfiguration(configuration);
    _cachedConfiguration = null;
  }

  /// Exports configuration for backup purposes
  Future<Map<String, dynamic>?> exportConfiguration() async {
    return await _repository.exportConfiguration();
  }

  /// Imports configuration from backup
  Future<void> importConfiguration(Map<String, dynamic> configMap) async {
    await _repository.importConfiguration(configMap);
    _cachedConfiguration = null;
  }
}
