import 'dart:convert';
import '../generated/protocol.dart';

/// Backend service for calculating weekend and weekday overtime hours
///
/// This service provides functionality to:
/// - Calculate weekend overtime hours from timesheet data
/// - Calculate weekday overtime hours
/// - Generate monthly overtime summaries with separation by type
/// - Apply different overtime rates for weekend vs weekday work
class WeekendOvertimeCalculatorService {
  /// Standard work day duration in minutes (8 hours)
  static const int standardWorkDayMinutes = 480;

  /// Default overtime rates
  static const double defaultWeekdayOvertimeRate = 1.25; // 125%
  static const double defaultWeekendOvertimeRate = 1.5; // 150%

  /// Calculates comprehensive overtime summary from timesheet data
  ///
  /// [timesheetData] The timesheet data containing entries
  /// [weekdayRate] Optional custom weekday overtime rate (default: 1.25)
  /// [weekendRate] Optional custom weekend overtime rate (default: 1.5)
  /// Returns an [OvertimeSummaryData] with detailed breakdown
  OvertimeSummaryData calculateOvertimeSummary(
    TimesheetData timesheetData, {
    double? weekdayRate,
    double? weekendRate,
  }) {
    final effectiveWeekdayRate = weekdayRate ?? defaultWeekdayOvertimeRate;
    final effectiveWeekendRate = weekendRate ?? defaultWeekendOvertimeRate;

    // Parse entries from JSON
    final entriesJson = jsonDecode(timesheetData.entries) as List;
    final entries = entriesJson.map((e) => e as Map<String, dynamic>).toList();

    int totalWeekdayOvertimeMinutes = 0;
    int totalWeekendOvertimeMinutes = 0;
    int totalRegularMinutes = 0;

    for (final entry in entries) {
      if (entry['isAbsence'] == true) {
        continue; // Skip absence entries
      }

      final dayDate = entry['dayDate'] as String?;
      if (dayDate == null) continue;

      final isWeekend = _isWeekendDay(dayDate);
      final dailyMinutes = _calculateDailyMinutes(entry);

      if (isWeekend) {
        // Weekend day - all hours are overtime
        totalWeekendOvertimeMinutes += dailyMinutes;
      } else {
        // Weekday - separate regular and overtime hours
        if (dailyMinutes > standardWorkDayMinutes) {
          totalRegularMinutes += standardWorkDayMinutes;
          totalWeekdayOvertimeMinutes +=
              (dailyMinutes - standardWorkDayMinutes);
        } else {
          totalRegularMinutes += dailyMinutes;
        }
      }
    }

    return OvertimeSummaryData(
      weekdayOvertimeMinutes: totalWeekdayOvertimeMinutes,
      weekendOvertimeMinutes: totalWeekendOvertimeMinutes,
      regularMinutes: totalRegularMinutes,
      weekdayOvertimeRate: effectiveWeekdayRate,
      weekendOvertimeRate: effectiveWeekendRate,
    );
  }

  /// Determines if a given date string represents a weekend day
  bool _isWeekendDay(String dayDate) {
    try {
      // Parse date string (assuming format like "2025-01-18" or similar)
      final date = DateTime.parse(dayDate);
      return date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;
    } catch (e) {
      // If parsing fails, assume it's not a weekend
      return false;
    }
  }

  /// Calculates total minutes worked in a day from entry data
  int _calculateDailyMinutes(Map<String, dynamic> entry) {
    try {
      int totalMinutes = 0;

      // Morning session
      final startMorning = entry['startMorning'] as String?;
      final endMorning = entry['endMorning'] as String?;
      if (startMorning != null &&
          endMorning != null &&
          startMorning.isNotEmpty &&
          endMorning.isNotEmpty) {
        totalMinutes += _calculateSessionMinutes(startMorning, endMorning);
      }

      // Afternoon session
      final startAfternoon = entry['startAfternoon'] as String?;
      final endAfternoon = entry['endAfternoon'] as String?;
      if (startAfternoon != null &&
          endAfternoon != null &&
          startAfternoon.isNotEmpty &&
          endAfternoon.isNotEmpty) {
        totalMinutes += _calculateSessionMinutes(startAfternoon, endAfternoon);
      }

      return totalMinutes;
    } catch (e) {
      return 0;
    }
  }

  /// Calculates minutes between two time strings
  int _calculateSessionMinutes(String startTime, String endTime) {
    try {
      final start = _parseTimeString(startTime);
      final end = _parseTimeString(endTime);

      if (start == null || end == null) return 0;

      final difference = end.difference(start);
      return difference.inMinutes;
    } catch (e) {
      return 0;
    }
  }

  /// Parses a time string (e.g., "09:00") into a DateTime
  DateTime? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Use a fixed date, we only care about time
      return DateTime(2025, 1, 1, hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// Formats minutes as hours and minutes string
  String formatMinutesAsHours(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes.toString().padLeft(2, '0')}m';
  }

  /// Formats minutes as decimal hours
  String formatMinutesAsDecimalHours(int minutes) {
    final hours = minutes / 60.0;
    return '${hours.toStringAsFixed(2)}h';
  }
}

/// Summary of overtime hours with detailed breakdown for backend use
class OvertimeSummaryData {
  /// Total overtime minutes worked on weekdays
  final int weekdayOvertimeMinutes;

  /// Total overtime minutes worked on weekends
  final int weekendOvertimeMinutes;

  /// Total regular minutes worked (non-overtime)
  final int regularMinutes;

  /// Overtime rate applied to weekday overtime hours
  final double weekdayOvertimeRate;

  /// Overtime rate applied to weekend overtime hours
  final double weekendOvertimeRate;

  const OvertimeSummaryData({
    required this.weekdayOvertimeMinutes,
    required this.weekendOvertimeMinutes,
    required this.regularMinutes,
    required this.weekdayOvertimeRate,
    required this.weekendOvertimeRate,
  });

  /// Total overtime minutes (weekday + weekend)
  int get totalOvertimeMinutes =>
      weekdayOvertimeMinutes + weekendOvertimeMinutes;

  /// Total minutes worked (regular + overtime)
  int get totalMinutes => regularMinutes + totalOvertimeMinutes;

  /// Returns true if any overtime hours were worked
  bool get hasOvertime => totalOvertimeMinutes > 0;

  /// Returns true if weekend overtime hours were worked
  bool get hasWeekendOvertime => weekendOvertimeMinutes > 0;

  /// Returns true if weekday overtime hours were worked
  bool get hasWeekdayOvertime => weekdayOvertimeMinutes > 0;

  /// Formats minutes as hours and minutes string
  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes.toString().padLeft(2, '0')}m';
  }

  /// Returns a formatted string representation of weekday overtime
  String get formattedWeekdayOvertime => _formatMinutes(weekdayOvertimeMinutes);

  /// Returns a formatted string representation of weekend overtime
  String get formattedWeekendOvertime => _formatMinutes(weekendOvertimeMinutes);

  /// Returns a formatted string representation of total overtime
  String get formattedTotalOvertime => _formatMinutes(totalOvertimeMinutes);

  /// Returns a formatted string representation of regular hours
  String get formattedRegularHours => _formatMinutes(regularMinutes);

  /// Returns a formatted string representation of total hours
  String get formattedTotalHours => _formatMinutes(totalMinutes);

  @override
  String toString() {
    return 'OvertimeSummaryData{'
        'regularHours: $formattedRegularHours, '
        'weekdayOvertime: $formattedWeekdayOvertime (${weekdayOvertimeRate}x), '
        'weekendOvertime: $formattedWeekendOvertime (${weekendOvertimeRate}x), '
        'totalOvertime: $formattedTotalOvertime, '
        'totalHours: $formattedTotalHours'
        '}';
  }
}
