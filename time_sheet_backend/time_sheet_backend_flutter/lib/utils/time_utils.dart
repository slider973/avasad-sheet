import 'package:intl/intl.dart';

import '../features/pointage/domain/entities/timesheet_entry.dart';
import '../enum/overtime_type.dart';
import '../services/weekend_detection_service.dart';

class TimeUtils {
  static final WeekendDetectionService _weekendDetectionService =
      WeekendDetectionService();

  /// Standard work day duration (8 hours)
  static const Duration standardWorkDay = Duration(hours: 8);

  Duration calculateTotalHours(TimesheetEntry entry) {
    if (entry.absenceReason != null && entry.absenceReason!.isNotEmpty) {
      // Si c'est une absence, retourner une durée de 0
      return Duration.zero;
    }
    // Parse start and end times to DateTime
    DateTime? startMorning = _parseTime(entry.startMorning);
    DateTime? endMorning = _parseTime(entry.endMorning);
    DateTime? startAfternoon = _parseTime(entry.startAfternoon);
    DateTime? endAfternoon = _parseTime(entry.endAfternoon);

    Duration totalDuration = Duration.zero;

    // Calculate morning duration if both start and end times are available
    if (startMorning != null && endMorning != null) {
      totalDuration += endMorning.difference(startMorning);
    }

    // Calculate afternoon duration if both start and end times are available
    if (startAfternoon != null && endAfternoon != null) {
      totalDuration += endAfternoon.difference(startAfternoon);
    }

    return totalDuration;
  }

  DateTime? _parseTime(String time) {
    if (time.isEmpty) {
      print('Temps vide reçu');
      return null;
    }
    try {
      DateFormat format = DateFormat.Hm(); // Assuming time is in HH:mm format
      return format.parse(time);
    } catch (e) {
      print('Erreur lors du parsing du temps: $time. Erreur: $e');
      return null;
    }
  }

  /// Enhanced calculateTotalHours that takes into account overtime type
  ///
  /// [entry] The timesheet entry to calculate hours for
  /// [includeOvertimeMultiplier] Whether to apply overtime rate multipliers
  /// Returns the total duration, optionally with overtime multipliers applied
  static Duration calculateTotalHoursWithOvertimeType(
    TimesheetEntry entry, {
    bool includeOvertimeMultiplier = false,
  }) {
    if (entry.absenceReason != null && entry.absenceReason!.isNotEmpty) {
      return Duration.zero;
    }

    final baseDuration = entry.calculateDailyTotal();

    if (!includeOvertimeMultiplier) {
      return baseDuration;
    }

    // Apply overtime multipliers based on overtime type
    if (entry.isWeekend) {
      // Weekend hours are all overtime with 1.5x multiplier
      return Duration(
          microseconds: (baseDuration.inMicroseconds * 1.5).round());
    } else if (entry.hasOvertimeHours && baseDuration > standardWorkDay) {
      // Weekday overtime: regular hours + overtime hours with 1.25x multiplier
      final overtimeHours = baseDuration - standardWorkDay;
      final regularHours = standardWorkDay;
      final adjustedOvertimeHours = Duration(
        microseconds: (overtimeHours.inMicroseconds * 1.25).round(),
      );
      return regularHours + adjustedOvertimeHours;
    }

    return baseDuration;
  }

  /// Determines if the given date falls on a weekend
  ///
  /// [date] The date to check
  /// [customWeekendDays] Optional custom weekend days override
  /// Returns true if the date is a weekend day
  static bool isWeekend(DateTime date, {List<int>? customWeekendDays}) {
    return _weekendDetectionService.isWeekend(date,
        customWeekendDays: customWeekendDays);
  }

  /// Calculates total weekend hours from a list of timesheet entries
  ///
  /// [entries] List of timesheet entries to analyze
  /// Returns the total duration of hours worked on weekend days
  static Duration calculateWeekendHours(List<TimesheetEntry> entries) {
    return entries
        .where((entry) => entry.isWeekend && entry.absenceReason == null)
        .fold(Duration.zero,
            (total, entry) => total + entry.calculateDailyTotal());
  }

  /// Calculates weekday overtime hours from a list of timesheet entries
  ///
  /// [entries] List of timesheet entries to analyze
  /// Returns the total duration of overtime hours worked on weekdays
  static Duration calculateWeekdayOvertimeHours(List<TimesheetEntry> entries) {
    return entries
        .where((entry) =>
            !entry.isWeekend &&
            entry.hasOvertimeHours &&
            entry.absenceReason == null)
        .fold(Duration.zero, (total, entry) {
      final dailyTotal = entry.calculateDailyTotal();
      if (dailyTotal > standardWorkDay) {
        return total + (dailyTotal - standardWorkDay);
      }
      return total;
    });
  }

  /// Calculates weekend overtime hours from a list of timesheet entries
  ///
  /// For weekend days, all worked hours are considered overtime
  /// [entries] List of timesheet entries to analyze
  /// Returns the total duration of weekend overtime hours
  static Duration calculateWeekendOvertimeHours(List<TimesheetEntry> entries) {
    return calculateWeekendHours(entries); // All weekend hours are overtime
  }

  /// Calculates regular (non-overtime) hours from a list of timesheet entries
  ///
  /// [entries] List of timesheet entries to analyze
  /// Returns the total duration of regular hours worked
  static Duration calculateRegularHours(List<TimesheetEntry> entries) {
    return entries
        .where((entry) => !entry.isWeekend && entry.absenceReason == null)
        .fold(Duration.zero, (total, entry) {
      final dailyTotal = entry.calculateDailyTotal();
      if (dailyTotal <= standardWorkDay) {
        return total + dailyTotal;
      } else {
        return total + standardWorkDay; // Only count up to standard work day
      }
    });
  }

  /// Calculates total overtime hours (weekday + weekend) from a list of entries
  ///
  /// [entries] List of timesheet entries to analyze
  /// Returns the total duration of all overtime hours
  static Duration calculateTotalOvertimeHours(List<TimesheetEntry> entries) {
    return calculateWeekdayOvertimeHours(entries) +
        calculateWeekendOvertimeHours(entries);
  }

  /// Groups timesheet entries by overtime type
  ///
  /// [entries] List of timesheet entries to group
  /// Returns a map with overtime types as keys and lists of entries as values
  static Map<OvertimeType, List<TimesheetEntry>> groupEntriesByOvertimeType(
    List<TimesheetEntry> entries,
  ) {
    final Map<OvertimeType, List<TimesheetEntry>> grouped = {
      OvertimeType.NONE: [],
      OvertimeType.WEEKDAY_ONLY: [],
      OvertimeType.WEEKEND_ONLY: [],
      OvertimeType.BOTH: [],
    };

    for (final entry in entries) {
      if (entry.absenceReason != null) {
        grouped[OvertimeType.NONE]!.add(entry);
        continue;
      }

      final hasWeekendWork =
          entry.isWeekend && entry.calculateDailyTotal() > Duration.zero;
      final hasWeekdayOvertime =
          !entry.isWeekend && entry.calculateDailyTotal() > standardWorkDay;

      if (hasWeekendWork && hasWeekdayOvertime) {
        grouped[OvertimeType.BOTH]!.add(entry);
      } else if (hasWeekendWork) {
        grouped[OvertimeType.WEEKEND_ONLY]!.add(entry);
      } else if (hasWeekdayOvertime) {
        grouped[OvertimeType.WEEKDAY_ONLY]!.add(entry);
      } else {
        grouped[OvertimeType.NONE]!.add(entry);
      }
    }

    return grouped;
  }

  /// Formats a duration as a human-readable string
  ///
  /// [duration] The duration to format
  /// [showSeconds] Whether to include seconds in the output
  /// Returns a formatted string (e.g., "8h 30m" or "8h 30m 15s")
  static String formatDuration(Duration duration, {bool showSeconds = false}) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (showSeconds) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
  }

  /// Calculates the percentage of overtime hours relative to total hours
  ///
  /// [entries] List of timesheet entries to analyze
  /// Returns the percentage as a double (0.0 to 100.0)
  static double calculateOvertimePercentage(List<TimesheetEntry> entries) {
    final totalHours = entries.fold(
        Duration.zero, (total, entry) => total + entry.calculateDailyTotal());
    final overtimeHours = calculateTotalOvertimeHours(entries);

    if (totalHours == Duration.zero) {
      return 0.0;
    }

    return (overtimeHours.inMinutes / totalHours.inMinutes) * 100.0;
  }
}
