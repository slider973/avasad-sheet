import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../features/pointage/domain/entities/extended_timer_state.dart';
import '../features/pointage/domain/entities/work_time_info.dart';
import 'logger_service.dart';

/// Service responsible for formatting timer data for display in the user interface
///
/// This service provides methods to format durations, times, and calculate
/// display properties like progress percentages and colors for the timer UI.
/// It handles different display states (normal, overtime, weekend) and provides
/// consistent formatting across the application.
class TimerDisplayService {
  static final TimerDisplayService _instance = TimerDisplayService._internal();

  factory TimerDisplayService() {
    return _instance;
  }

  TimerDisplayService._internal();

  /// Formats a duration for display in the timer interface
  ///
  /// [duration] The duration to format
  /// [showSeconds] Whether to include seconds in the display
  /// [compact] Whether to use compact format (e.g., "8:30" vs "8h 30m")
  /// Returns formatted string like "8h 30m", "8:30:15", or "8:30"
  String formatDuration(
    Duration duration, {
    bool showSeconds = false,
    bool compact = false,
  }) {
    try {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      if (compact) {
        if (showSeconds) {
          return '${hours.toString().padLeft(2, '0')}:'
              '${minutes.toString().padLeft(2, '0')}:'
              '${seconds.toString().padLeft(2, '0')}';
        } else {
          return '${hours.toString().padLeft(2, '0')}:'
              '${minutes.toString().padLeft(2, '0')}';
        }
      } else {
        if (showSeconds) {
          return '${hours}h ${minutes.toString().padLeft(2, '0')}m '
              '${seconds.toString().padLeft(2, '0')}s';
        } else {
          return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
        }
      }
    } catch (e, stackTrace) {
      logger.e('[TimerDisplayService] Error formatting duration: $e',
          error: e, stackTrace: stackTrace);
      return '0h 00m';
    }
  }

  /// Formats an end time for display
  ///
  /// [endTime] The DateTime to format, can be null
  /// [format24Hour] Whether to use 24-hour format (default: true)
  /// Returns formatted time string like "17:30" or "5:30 PM", or "N/A" if null
  String formatEndTime(DateTime? endTime, {bool format24Hour = true}) {
    try {
      if (endTime == null) {
        return 'N/A';
      }

      if (format24Hour) {
        return DateFormat('HH:mm').format(endTime);
      } else {
        return DateFormat('h:mm a').format(endTime);
      }
    } catch (e, stackTrace) {
      logger.e('[TimerDisplayService] Error formatting end time: $e',
          error: e, stackTrace: stackTrace);
      return 'N/A';
    }
  }

  /// Formats overtime status for display
  ///
  /// [extendedState] The extended timer state containing overtime information
  /// Returns a formatted string describing the overtime status
  String formatOvertimeStatus(ExtendedTimerState extendedState) {
    try {
      final workTimeInfo = extendedState.workTimeInfo;
      final isWeekend = extendedState.isWeekendDay;
      final weekendOvertimeEnabled = extendedState.weekendOvertimeEnabled;

      if (isWeekend && weekendOvertimeEnabled) {
        if (workTimeInfo.overtimeHours > Duration.zero) {
          return 'Weekend: ${formatDuration(workTimeInfo.overtimeHours)} overtime';
        } else {
          return 'Weekend work (overtime)';
        }
      } else if (workTimeInfo.isOvertimeStarted) {
        return 'Overtime: ${formatDuration(workTimeInfo.overtimeHours)}';
      } else if (workTimeInfo.remainingTime > Duration.zero) {
        return 'Regular time: ${formatDuration(workTimeInfo.remainingTime)} remaining';
      } else {
        return 'Standard work day completed';
      }
    } catch (e, stackTrace) {
      logger.e('[TimerDisplayService] Error formatting overtime status: $e',
          error: e, stackTrace: stackTrace);
      return 'Status unavailable';
    }
  }

  /// Calculates progress percentages for circular display
  ///
  /// [extendedState] The extended timer state
  /// Returns a map with different progress percentages for display segments
  Map<String, double> calculateProgressPercentages(
      ExtendedTimerState extendedState) {
    try {
      final workTimeInfo = extendedState.workTimeInfo;
      final standardWorkDay = extendedState.configuration.standardWorkDay;
      final isWeekend = extendedState.isWeekendDay;
      final weekendOvertimeEnabled = extendedState.weekendOvertimeEnabled;

      // Calculate worked time (standard work day - remaining time)
      final workedTime = standardWorkDay - workTimeInfo.remainingTime;

      // Base progress percentage (0.0 to 1.0)
      double workProgress = 0.0;
      if (standardWorkDay.inMilliseconds > 0) {
        workProgress =
            (workedTime.inMilliseconds / standardWorkDay.inMilliseconds)
                .clamp(0.0, 1.0);
      }

      // Break progress percentage
      double breakProgress = 0.0;
      if (extendedState.elapsedTime.inMilliseconds > 0) {
        breakProgress = (workTimeInfo.breakTime.inMilliseconds /
                extendedState.elapsedTime.inMilliseconds)
            .clamp(0.0, 1.0);
      }

      // Overtime progress percentage (beyond 100%)
      double overtimeProgress = 0.0;
      if (workTimeInfo.isOvertimeStarted &&
          standardWorkDay.inMilliseconds > 0) {
        overtimeProgress = (workTimeInfo.overtimeHours.inMilliseconds /
                standardWorkDay.inMilliseconds)
            .clamp(0.0, 1.0);
      }

      // Weekend special handling
      if (isWeekend && weekendOvertimeEnabled) {
        // On weekends, all work is overtime, so show as overtime progress
        overtimeProgress = workProgress;
        workProgress = 0.0;
      }

      final result = {
        'work': workProgress,
        'break': breakProgress,
        'overtime': overtimeProgress,
        'total': (workProgress + overtimeProgress)
            .clamp(0.0, 2.0), // Can exceed 1.0 for overtime
      };

      logger
          .d('[TimerDisplayService] Calculated progress percentages: $result');
      return result;
    } catch (e, stackTrace) {
      logger.e(
          '[TimerDisplayService] Error calculating progress percentages: $e',
          error: e,
          stackTrace: stackTrace);
      return {
        'work': 0.0,
        'break': 0.0,
        'overtime': 0.0,
        'total': 0.0,
      };
    }
  }

  /// Gets segment colors based on the current timer state
  ///
  /// [extendedState] The extended timer state
  /// Returns a map with color assignments for different display segments
  Map<String, Color> getSegmentColors(ExtendedTimerState extendedState) {
    try {
      final workTimeInfo = extendedState.workTimeInfo;
      final isWeekend = extendedState.isWeekendDay;
      final weekendOvertimeEnabled = extendedState.weekendOvertimeEnabled;
      final currentState = extendedState.currentState;

      // Base colors
      const Color normalWorkColor = Color(0xFF4CAF50); // Green
      const Color breakColor = Color(0xFFFF9800); // Orange
      const Color overtimeColor = Color(0xFFFF5722); // Red-Orange
      const Color weekendColor = Color(0xFF9C27B0); // Purple
      const Color pausedColor = Color(0xFF757575); // Grey
      const Color completedColor = Color(0xFF2196F3); // Blue

      // Determine primary work color
      Color workColor = normalWorkColor;
      if (isWeekend && weekendOvertimeEnabled) {
        workColor = weekendColor;
      } else if (workTimeInfo.isOvertimeStarted) {
        workColor = overtimeColor;
      }

      // Adjust colors based on current state
      if (currentState == 'Pause') {
        workColor = pausedColor;
      } else if (currentState == 'Sortie') {
        workColor = completedColor;
      }

      final result = {
        'work': workColor,
        'break': breakColor,
        'overtime': overtimeColor,
        'weekend': weekendColor,
        'paused': pausedColor,
        'completed': completedColor,
        'background': const Color(0xFFE0E0E0), // Light grey
        'text': const Color(0xFF212121), // Dark grey
        'accent': workColor,
      };

      logger.d(
          '[TimerDisplayService] Generated segment colors for state: $currentState');
      return result;
    } catch (e, stackTrace) {
      logger.e('[TimerDisplayService] Error getting segment colors: $e',
          error: e, stackTrace: stackTrace);
      return {
        'work': const Color(0xFF4CAF50),
        'break': const Color(0xFFFF9800),
        'overtime': const Color(0xFFFF5722),
        'weekend': const Color(0xFF9C27B0),
        'paused': const Color(0xFF757575),
        'completed': const Color(0xFF2196F3),
        'background': const Color(0xFFE0E0E0),
        'text': const Color(0xFF212121),
        'accent': const Color(0xFF4CAF50),
      };
    }
  }

  /// Formats work time summary for display
  ///
  /// [workTimeInfo] The work time information to format
  /// [includeBreakTime] Whether to include break time in the summary
  /// Returns a formatted summary string
  String formatWorkTimeSummary(
    WorkTimeInfo workTimeInfo, {
    bool includeBreakTime = true,
  }) {
    try {
      final List<String> parts = [];

      // Add work time information
      if (workTimeInfo.remainingTime > Duration.zero) {
        parts.add('${formatDuration(workTimeInfo.remainingTime)} remaining');
      } else {
        parts.add('Work day completed');
      }

      // Add overtime information
      if (workTimeInfo.isOvertimeStarted &&
          workTimeInfo.overtimeHours > Duration.zero) {
        parts.add('${formatDuration(workTimeInfo.overtimeHours)} overtime');
      }

      // Add break time information
      if (includeBreakTime && workTimeInfo.breakTime > Duration.zero) {
        parts.add('${formatDuration(workTimeInfo.breakTime)} break');
      }

      return parts.join(' • ');
    } catch (e, stackTrace) {
      logger.e('[TimerDisplayService] Error formatting work time summary: $e',
          error: e, stackTrace: stackTrace);
      return 'Summary unavailable';
    }
  }

  /// Formats time remaining until end of work day
  ///
  /// [endTime] The estimated end time
  /// [showRelative] Whether to show relative time (e.g., "in 2h 30m")
  /// Returns formatted string showing time until end
  String formatTimeUntilEnd(DateTime? endTime, {bool showRelative = true}) {
    try {
      if (endTime == null) {
        return 'End time not available';
      }

      final now = DateTime.now();
      final difference = endTime.difference(now);

      if (difference.isNegative) {
        final overTime = now.difference(endTime);
        if (showRelative) {
          return 'Overtime: ${formatDuration(overTime)} past end time';
        } else {
          return 'Past end time by ${formatDuration(overTime)}';
        }
      } else {
        if (showRelative) {
          return 'Ends in ${formatDuration(difference)}';
        } else {
          return 'Time until end: ${formatDuration(difference)}';
        }
      }
    } catch (e, stackTrace) {
      logger.e('[TimerDisplayService] Error formatting time until end: $e',
          error: e, stackTrace: stackTrace);
      return 'Time calculation unavailable';
    }
  }

  /// Gets display text for the current timer state
  ///
  /// [currentState] The current timer state string
  /// Returns user-friendly display text for the state
  String getStateDisplayText(String currentState) {
    try {
      switch (currentState) {
        case 'Non commencé':
          return 'Not Started';
        case 'Entrée':
          return 'Working';
        case 'Pause':
          return 'On Break';
        case 'Reprise':
          return 'Working';
        case 'Sortie':
          return 'Completed';
        default:
          return currentState;
      }
    } catch (e, stackTrace) {
      logger.e('[TimerDisplayService] Error getting state display text: $e',
          error: e, stackTrace: stackTrace);
      return 'Unknown State';
    }
  }

  /// Formats a complete timer display summary
  ///
  /// [extendedState] The extended timer state
  /// [includeEndTime] Whether to include estimated end time
  /// [includeOvertimeStatus] Whether to include overtime status
  /// Returns a comprehensive formatted summary
  Map<String, String> formatCompleteTimerSummary(
    ExtendedTimerState extendedState, {
    bool includeEndTime = true,
    bool includeOvertimeStatus = true,
  }) {
    try {
      final Map<String, String> summary = {};

      // Current state
      summary['state'] = getStateDisplayText(extendedState.currentState);

      // Elapsed time
      summary['elapsed'] = formatDuration(extendedState.elapsedTime);

      // Work time summary
      summary['workSummary'] =
          formatWorkTimeSummary(extendedState.workTimeInfo);

      // End time
      if (includeEndTime) {
        summary['endTime'] =
            formatEndTime(extendedState.workTimeInfo.estimatedEndTime);
        summary['timeUntilEnd'] = formatTimeUntilEnd(
          extendedState.workTimeInfo.estimatedEndTime,
        );
      }

      // Overtime status
      if (includeOvertimeStatus) {
        summary['overtimeStatus'] = formatOvertimeStatus(extendedState);
      }

      // Break time
      if (extendedState.workTimeInfo.breakTime > Duration.zero) {
        summary['breakTime'] =
            formatDuration(extendedState.workTimeInfo.breakTime);
      }

      logger.d('[TimerDisplayService] Generated complete timer summary');
      return summary;
    } catch (e, stackTrace) {
      logger.e(
          '[TimerDisplayService] Error formatting complete timer summary: $e',
          error: e,
          stackTrace: stackTrace);
      return {
        'state': 'Unknown',
        'elapsed': '0h 00m',
        'workSummary': 'Summary unavailable',
      };
    }
  }

  /// Validates display formatting inputs
  ///
  /// [extendedState] The extended timer state to validate
  /// Returns true if the state is valid for display formatting
  bool validateDisplayInputs(ExtendedTimerState extendedState) {
    try {
      // Check for null or invalid values
      if (extendedState.currentState.isEmpty) {
        logger.w('[TimerDisplayService] Invalid current state: empty');
        return false;
      }

      if (extendedState.elapsedTime.isNegative) {
        logger.w('[TimerDisplayService] Invalid elapsed time: negative');
        return false;
      }

      if (extendedState.workTimeInfo.remainingTime.isNegative) {
        logger.w('[TimerDisplayService] Invalid remaining time: negative');
        return false;
      }

      if (extendedState.workTimeInfo.breakTime.isNegative) {
        logger.w('[TimerDisplayService] Invalid break time: negative');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      logger.e('[TimerDisplayService] Error validating display inputs: $e',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
