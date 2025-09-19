/// Configuration parameters for work time calculations
///
/// This class contains all configurable parameters that affect how work time
/// is calculated, including standard work day duration, break limits, and overtime rates.
class WorkTimeConfiguration {
  /// Standard work day duration (default: 8 hours)
  final Duration standardWorkDay;

  /// Maximum break time before affecting end time calculation (default: 1 hour)
  final Duration maxBreakTime;

  /// Whether overtime is enabled for weekend days
  final bool weekendOvertimeEnabled;

  /// Overtime rate multiplier for weekdays (default: 1.25 = 125%)
  final double weekdayOvertimeRate;

  /// Overtime rate multiplier for weekend days (default: 1.5 = 150%)
  final double weekendOvertimeRate;

  /// Minimum break duration to be considered a break (default: 5 minutes)
  final Duration minimumBreakDuration;

  /// Whether to automatically adjust end time based on break duration
  final bool autoAdjustEndTime;

  const WorkTimeConfiguration({
    this.standardWorkDay = const Duration(hours: 8),
    this.maxBreakTime = const Duration(hours: 1),
    this.weekendOvertimeEnabled = true,
    this.weekdayOvertimeRate = 1.25,
    this.weekendOvertimeRate = 1.5,
    this.minimumBreakDuration = const Duration(minutes: 5),
    this.autoAdjustEndTime = true,
  });

  /// Creates a default configuration with standard Swiss work parameters
  factory WorkTimeConfiguration.defaultConfig() {
    return const WorkTimeConfiguration();
  }

  /// Creates a configuration for part-time work
  factory WorkTimeConfiguration.partTime({
    required Duration workDayDuration,
    double overtimeRate = 1.25,
  }) {
    return WorkTimeConfiguration(
      standardWorkDay: workDayDuration,
      weekdayOvertimeRate: overtimeRate,
      weekendOvertimeRate: overtimeRate,
    );
  }

  /// Creates a copy of this configuration with updated values
  WorkTimeConfiguration copyWith({
    Duration? standardWorkDay,
    Duration? maxBreakTime,
    bool? weekendOvertimeEnabled,
    double? weekdayOvertimeRate,
    double? weekendOvertimeRate,
    Duration? minimumBreakDuration,
    bool? autoAdjustEndTime,
  }) {
    return WorkTimeConfiguration(
      standardWorkDay: standardWorkDay ?? this.standardWorkDay,
      maxBreakTime: maxBreakTime ?? this.maxBreakTime,
      weekendOvertimeEnabled:
          weekendOvertimeEnabled ?? this.weekendOvertimeEnabled,
      weekdayOvertimeRate: weekdayOvertimeRate ?? this.weekdayOvertimeRate,
      weekendOvertimeRate: weekendOvertimeRate ?? this.weekendOvertimeRate,
      minimumBreakDuration: minimumBreakDuration ?? this.minimumBreakDuration,
      autoAdjustEndTime: autoAdjustEndTime ?? this.autoAdjustEndTime,
    );
  }

  /// Returns the appropriate overtime rate for the given day type
  double getOvertimeRate(bool isWeekend) {
    return isWeekend ? weekendOvertimeRate : weekdayOvertimeRate;
  }

  /// Returns true if the given break duration exceeds the maximum allowed
  bool isBreakExcessive(Duration breakDuration) {
    return breakDuration > maxBreakTime;
  }

  /// Returns true if the given break duration is significant enough to track
  bool isSignificantBreak(Duration breakDuration) {
    return breakDuration >= minimumBreakDuration;
  }

  /// Calculates the additional time to add to end time based on break duration
  Duration calculateBreakAdjustment(Duration breakDuration) {
    if (!autoAdjustEndTime) return Duration.zero;

    // If break exceeds max allowed, add the excess to end time
    if (breakDuration > maxBreakTime) {
      return breakDuration - maxBreakTime;
    }

    return Duration.zero;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkTimeConfiguration &&
        other.standardWorkDay == standardWorkDay &&
        other.maxBreakTime == maxBreakTime &&
        other.weekendOvertimeEnabled == weekendOvertimeEnabled &&
        other.weekdayOvertimeRate == weekdayOvertimeRate &&
        other.weekendOvertimeRate == weekendOvertimeRate &&
        other.minimumBreakDuration == minimumBreakDuration &&
        other.autoAdjustEndTime == autoAdjustEndTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      standardWorkDay,
      maxBreakTime,
      weekendOvertimeEnabled,
      weekdayOvertimeRate,
      weekendOvertimeRate,
      minimumBreakDuration,
      autoAdjustEndTime,
    );
  }

  @override
  String toString() {
    return 'WorkTimeConfiguration('
        'standardWorkDay: $standardWorkDay, '
        'maxBreakTime: $maxBreakTime, '
        'weekendOvertimeEnabled: $weekendOvertimeEnabled, '
        'weekdayOvertimeRate: $weekdayOvertimeRate, '
        'weekendOvertimeRate: $weekendOvertimeRate, '
        'minimumBreakDuration: $minimumBreakDuration, '
        'autoAdjustEndTime: $autoAdjustEndTime'
        ')';
  }
}
