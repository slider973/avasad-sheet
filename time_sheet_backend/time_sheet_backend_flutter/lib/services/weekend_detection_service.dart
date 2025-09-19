import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for detecting weekend days and managing weekend configuration
///
/// This service provides functionality to:
/// - Detect if a given date falls on a weekend
/// - Configure custom weekend days
/// - Manage weekend overtime settings
/// - Store and retrieve weekend configuration preferences
class WeekendDetectionService {
  static const String _weekendDaysKey = 'weekend_days';
  static const String _weekendOvertimeEnabledKey = 'weekend_overtime_enabled';

  /// Default weekend days (Saturday = 6, Sunday = 7)
  static const List<int> DEFAULT_WEEKEND_DAYS = [
    DateTime.saturday,
    DateTime.sunday
  ];

  /// Singleton instance
  static final WeekendDetectionService _instance =
      WeekendDetectionService._internal();
  factory WeekendDetectionService() => _instance;
  WeekendDetectionService._internal();

  /// Cached weekend days configuration
  List<int>? _cachedWeekendDays;

  /// Cached weekend overtime enabled setting
  bool? _cachedWeekendOvertimeEnabled;

  /// Determines if the given date falls on a weekend day
  ///
  /// [date] The date to check
  /// [customWeekendDays] Optional custom weekend days override
  /// Returns true if the date is a weekend day
  bool isWeekend(DateTime date, {List<int>? customWeekendDays}) {
    final weekendDays =
        customWeekendDays ?? _cachedWeekendDays ?? DEFAULT_WEEKEND_DAYS;
    return weekendDays.contains(date.weekday);
  }

  /// Gets the currently configured weekend days
  ///
  /// Returns a list of integers representing weekend days (1=Monday, 7=Sunday)
  Future<List<int>> getConfiguredWeekendDays() async {
    if (_cachedWeekendDays != null) {
      return _cachedWeekendDays!;
    }

    final prefs = await SharedPreferences.getInstance();
    final weekendDaysString = prefs.getStringList(_weekendDaysKey);

    if (weekendDaysString != null) {
      _cachedWeekendDays =
          weekendDaysString.map((day) => int.parse(day)).toList();
    } else {
      _cachedWeekendDays = List.from(DEFAULT_WEEKEND_DAYS);
    }

    return _cachedWeekendDays!;
  }

  /// Updates the weekend days configuration
  ///
  /// [weekendDays] List of integers representing weekend days (1=Monday, 7=Sunday)
  /// Throws [ArgumentError] if invalid weekend days are provided
  Future<void> updateWeekendConfiguration(List<int> weekendDays) async {
    _validateWeekendDays(weekendDays);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _weekendDaysKey, weekendDays.map((day) => day.toString()).toList());

    _cachedWeekendDays = List.from(weekendDays);
  }

  /// Determines if weekend overtime should be applied for the given date
  ///
  /// [date] The date to check
  /// Returns true if weekend overtime rules should be applied
  Future<bool> shouldApplyWeekendOvertime(DateTime date) async {
    final overtimeEnabled = await isWeekendOvertimeEnabled();
    final isWeekendDay = await _isWeekendDay(date);

    return overtimeEnabled && isWeekendDay;
  }

  /// Gets the current weekend overtime enabled setting
  ///
  /// Returns true if weekend overtime is enabled
  Future<bool> isWeekendOvertimeEnabled() async {
    if (_cachedWeekendOvertimeEnabled != null) {
      return _cachedWeekendOvertimeEnabled!;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedWeekendOvertimeEnabled =
        prefs.getBool(_weekendOvertimeEnabledKey) ?? true;

    return _cachedWeekendOvertimeEnabled!;
  }

  /// Sets the weekend overtime enabled setting
  ///
  /// [enabled] Whether weekend overtime should be enabled
  Future<void> setWeekendOvertimeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weekendOvertimeEnabledKey, enabled);

    _cachedWeekendOvertimeEnabled = enabled;
  }

  /// Resets weekend configuration to default values
  Future<void> resetToDefaults() async {
    await updateWeekendConfiguration(DEFAULT_WEEKEND_DAYS);
    await setWeekendOvertimeEnabled(true);
  }

  /// Clears the cached configuration values
  ///
  /// This forces the service to reload configuration from SharedPreferences
  /// on the next access
  void clearCache() {
    _cachedWeekendDays = null;
    _cachedWeekendOvertimeEnabled = null;
  }

  /// Internal method to check if a date is a weekend day using current configuration
  Future<bool> _isWeekendDay(DateTime date) async {
    final weekendDays = await getConfiguredWeekendDays();
    return weekendDays.contains(date.weekday);
  }

  /// Validates that weekend days are within valid range (1-7)
  void _validateWeekendDays(List<int> weekendDays) {
    if (weekendDays.isEmpty) {
      throw ArgumentError('Weekend days cannot be empty');
    }

    for (final day in weekendDays) {
      if (day < 1 || day > 7) {
        throw ArgumentError(
            'Invalid weekend day: $day. Must be between 1 (Monday) and 7 (Sunday)');
      }
    }

    // Ensure no duplicates
    final uniqueDays = weekendDays.toSet();
    if (uniqueDays.length != weekendDays.length) {
      throw ArgumentError('Duplicate weekend days are not allowed');
    }

    // Ensure at least one working day remains
    if (weekendDays.length >= 7) {
      throw ArgumentError(
          'Cannot set all days as weekend days. At least one working day must remain');
    }
  }
}
