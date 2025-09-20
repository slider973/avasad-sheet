import '../features/pointage/domain/entities/timesheet_entry.dart';
import '../enum/overtime_type.dart';
import 'weekend_detection_service.dart';

/// Service responsible for calculating weekend and weekday overtime hours
///
/// This service provides functionality to:
/// - Calculate weekend overtime hours
/// - Calculate weekday overtime hours
/// - Generate monthly overtime summaries with separation by type
/// - Apply different overtime rates for weekend vs weekday work
class WeekendOvertimeCalculator {
  final WeekendDetectionService _weekendDetectionService;

  /// Standard work day duration (8 hours)
  static const Duration standardWorkDay = Duration(hours: 8);

  /// Default overtime rates
  static const double defaultWeekdayOvertimeRate = 1.25; // 125%
  static const double defaultWeekendOvertimeRate = 1.5; // 150%

  WeekendOvertimeCalculator({
    WeekendDetectionService? weekendDetectionService,
  }) : _weekendDetectionService =
            weekendDetectionService ?? WeekendDetectionService();

  /// Calculates overtime hours for weekend work
  ///
  /// For weekend days, all worked hours are considered overtime
  /// [entry] The timesheet entry to calculate weekend overtime for
  /// Returns the duration of weekend overtime hours
  Duration calculateWeekendOvertime(TimesheetEntry entry) {
    if (!entry.isWeekend) {
      return Duration.zero;
    }

    // For weekend work, all hours are considered overtime
    return entry.calculateDailyTotal();
  }

  /// Calculates overtime hours for weekday work
  ///
  /// For weekdays, only hours exceeding the standard work day are overtime
  /// [entry] The timesheet entry to calculate weekday overtime for
  /// Returns the duration of weekday overtime hours
  Duration calculateWeekdayOvertime(TimesheetEntry entry) {
    if (entry.isWeekend || !entry.hasOvertimeHours) {
      return Duration.zero;
    }

    final totalHours = entry.calculateDailyTotal();
    if (totalHours > standardWorkDay) {
      return totalHours - standardWorkDay;
    }

    return Duration.zero;
  }

  /// Calculates comprehensive monthly overtime summary
  ///
  /// [entries] List of timesheet entries for the month
  /// [weekdayRate] Optional custom weekday overtime rate (default: 1.25)
  /// [weekendRate] Optional custom weekend overtime rate (default: 1.5)
  /// Returns an [OvertimeSummary] with detailed breakdown
  Future<OvertimeSummary> calculateMonthlyOvertime(
    List<TimesheetEntry> entries, {
    double? weekdayRate,
    double? weekendRate,
  }) async {
    Duration totalWeekdayOvertime = Duration.zero;
    Duration totalWeekendOvertime = Duration.zero;
    Duration totalRegularHours = Duration.zero;

    final effectiveWeekdayRate = weekdayRate ?? defaultWeekdayOvertimeRate;
    final effectiveWeekendRate = weekendRate ?? defaultWeekendOvertimeRate;

    for (final entry in entries) {
      if (entry.absence != null) {
        continue; // Skip absence entries
      }

      final dailyTotal = entry.calculateDailyTotal();

      // Utiliser les informations de weekend stockées dans l'entrée si disponibles
      bool isWeekendWithOvertime = false;

      if (entry.isWeekendDay && entry.isWeekendOvertimeEnabled) {
        isWeekendWithOvertime = true;
      } else if (entry.date != null) {
        // Fallback: utiliser le service de détection si les informations ne sont pas stockées
        isWeekendWithOvertime = await _weekendDetectionService
            .shouldApplyWeekendOvertime(entry.date!);
      }

      if (isWeekendWithOvertime) {
        // Weekend day with overtime enabled - all hours are overtime
        totalWeekendOvertime += dailyTotal;
      } else {
        // Weekday OR weekend without overtime - separate regular and overtime hours
        if (entry.hasOvertimeHours && dailyTotal > standardWorkDay) {
          totalRegularHours += standardWorkDay;
          totalWeekdayOvertime += (dailyTotal - standardWorkDay);
        } else {
          totalRegularHours += dailyTotal;
        }
      }
    }

    return OvertimeSummary(
      weekdayOvertime: totalWeekdayOvertime,
      weekendOvertime: totalWeekendOvertime,
      regularHours: totalRegularHours,
      weekdayOvertimeRate: effectiveWeekdayRate,
      weekendOvertimeRate: effectiveWeekendRate,
    );
  }

  /// Gets the current weekday overtime rate
  ///
  /// Returns the multiplier for weekday overtime compensation
  double getWeekdayOvertimeRate() {
    // TODO: This should be configurable via settings
    return defaultWeekdayOvertimeRate;
  }

  /// Gets the current weekend overtime rate
  ///
  /// Returns the multiplier for weekend overtime compensation
  double getWeekendOvertimeRate() {
    // TODO: This should be configurable via settings
    return defaultWeekendOvertimeRate;
  }

  /// Calculates the total compensated hours including overtime rates
  ///
  /// [summary] The overtime summary to calculate compensation for
  /// Returns the total compensated hours as a double
  double calculateTotalCompensatedHours(OvertimeSummary summary) {
    final regularHours = summary.regularHours.inMinutes / 60.0;
    final weekdayOvertimeHours = summary.weekdayOvertime.inMinutes / 60.0;
    final weekendOvertimeHours = summary.weekendOvertime.inMinutes / 60.0;

    return regularHours +
        (weekdayOvertimeHours * summary.weekdayOvertimeRate) +
        (weekendOvertimeHours * summary.weekendOvertimeRate);
  }

  /// Determines the overtime type for a given entry
  ///
  /// [entry] The timesheet entry to analyze
  /// Returns the appropriate [OvertimeType]
  Future<OvertimeType> determineOvertimeType(TimesheetEntry entry) async {
    if (entry.absence != null) {
      return OvertimeType.NONE;
    }

    final hasWeekendOvertime = await _weekendDetectionService
            .shouldApplyWeekendOvertime(entry.date!) &&
        entry.calculateDailyTotal() > Duration.zero;

    final hasWeekdayOvertime =
        !entry.isWeekend && entry.calculateDailyTotal() > standardWorkDay;

    if (hasWeekendOvertime && hasWeekdayOvertime) {
      return OvertimeType.BOTH;
    } else if (hasWeekendOvertime) {
      return OvertimeType.WEEKEND_ONLY;
    } else if (hasWeekdayOvertime) {
      return OvertimeType.WEEKDAY_ONLY;
    } else {
      return OvertimeType.NONE;
    }
  }
}

/// Summary of overtime hours with detailed breakdown
///
/// Contains comprehensive information about overtime hours worked
/// during a specific period, separated by weekday and weekend work
class OvertimeSummary {
  /// Total overtime hours worked on weekdays
  final Duration weekdayOvertime;

  /// Total overtime hours worked on weekends
  final Duration weekendOvertime;

  /// Total regular hours worked (non-overtime)
  final Duration regularHours;

  /// Overtime rate applied to weekday overtime hours
  final double weekdayOvertimeRate;

  /// Overtime rate applied to weekend overtime hours
  final double weekendOvertimeRate;

  const OvertimeSummary({
    required this.weekdayOvertime,
    required this.weekendOvertime,
    required this.regularHours,
    required this.weekdayOvertimeRate,
    required this.weekendOvertimeRate,
  });

  /// Total overtime hours (weekday + weekend)
  Duration get totalOvertime => weekdayOvertime + weekendOvertime;

  /// Total hours worked (regular + overtime)
  Duration get totalHours => regularHours + totalOvertime;

  /// Returns true if any overtime hours were worked
  bool get hasOvertime => totalOvertime > Duration.zero;

  /// Returns true if weekend overtime hours were worked
  bool get hasWeekendOvertime => weekendOvertime > Duration.zero;

  /// Returns true if weekday overtime hours were worked
  bool get hasWeekdayOvertime => weekdayOvertime > Duration.zero;

  /// Formats duration as hours and minutes string
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  /// Returns a formatted string representation of weekday overtime
  String get formattedWeekdayOvertime => _formatDuration(weekdayOvertime);

  /// Returns a formatted string representation of weekend overtime
  String get formattedWeekendOvertime => _formatDuration(weekendOvertime);

  /// Returns a formatted string representation of total overtime
  String get formattedTotalOvertime => _formatDuration(totalOvertime);

  /// Returns a formatted string representation of regular hours
  String get formattedRegularHours => _formatDuration(regularHours);

  /// Returns a formatted string representation of total hours
  String get formattedTotalHours => _formatDuration(totalHours);

  @override
  String toString() {
    return 'OvertimeSummary{'
        'regularHours: $formattedRegularHours, '
        'weekdayOvertime: $formattedWeekdayOvertime (${weekdayOvertimeRate}x), '
        'weekendOvertime: $formattedWeekendOvertime (${weekendOvertimeRate}x), '
        'totalOvertime: $formattedTotalOvertime, '
        'totalHours: $formattedTotalHours'
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OvertimeSummary &&
          runtimeType == other.runtimeType &&
          weekdayOvertime == other.weekdayOvertime &&
          weekendOvertime == other.weekendOvertime &&
          regularHours == other.regularHours &&
          weekdayOvertimeRate == other.weekdayOvertimeRate &&
          weekendOvertimeRate == other.weekendOvertimeRate;

  @override
  int get hashCode =>
      weekdayOvertime.hashCode ^
      weekendOvertime.hashCode ^
      regularHours.hashCode ^
      weekdayOvertimeRate.hashCode ^
      weekendOvertimeRate.hashCode;
}
