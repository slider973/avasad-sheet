import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_configuration.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';

import 'package:time_sheet/services/logger_service.dart';

/// Service responsible for calculating work time information in real-time
///
/// This service integrates with TimerService to provide calculated information
/// such as estimated end time, remaining work time, and overtime detection.
/// It handles break tracking and applies configurable work time parameters.
class WorkTimeCalculatorService {
  static final WorkTimeCalculatorService _instance =
      WorkTimeCalculatorService._internal();

  factory WorkTimeCalculatorService() {
    return _instance;
  }

  WorkTimeCalculatorService._internal();

  WorkTimeConfiguration _configuration = WorkTimeConfiguration.defaultConfig();

  // Break tracking
  final List<BreakPeriod> _breaks = [];
  DateTime? _currentBreakStart;

  /// Gets the current work time configuration
  WorkTimeConfiguration get configuration => _configuration;

  /// Updates the work time configuration
  void updateConfiguration(WorkTimeConfiguration newConfiguration) {
    _configuration = newConfiguration;
    logger.d(
        '[WorkTimeCalculatorService] Configuration updated: $newConfiguration');
  }

  /// Calculates comprehensive work time information from provided timer data
  WorkTimeInfo calculateWorkTimeInfo({
    required String currentState,
    required Duration elapsedTime,
    DateTime? startTime,
    required bool isWeekend,
    required bool weekendOvertimeEnabled,
  }) {
    try {
      final timerState = currentState;
      final elapsedTimeParam = elapsedTime;
      final startTimeParam = startTime;
      final isWeekendParam = isWeekend;
      final weekendOvertimeEnabledParam = weekendOvertimeEnabled;

      // Calculate effective work time (excluding breaks)
      final effectiveWorkTime =
          _calculateEffectiveWorkTime(elapsedTimeParam, timerState);

      // Calculate break time
      final breakTime = _calculateTotalBreakTime();

      // Add current break time if on break
      Duration totalBreakTime = breakTime;
      if (timerState == 'Pause' && _currentBreakStart != null) {
        totalBreakTime += DateTime.now().difference(_currentBreakStart!);
      }

      // Calculate remaining time to complete standard work day
      final remainingTime = _calculateRemainingWorkTime(effectiveWorkTime);

      // Determine if overtime has started
      final isOvertimeStarted = _shouldStartOvertime(
        effectiveWorkTime,
        isWeekendParam,
        weekendOvertimeEnabledParam,
      );

      // Calculate overtime hours
      final overtimeHours = _calculateOvertimeHours(
        effectiveWorkTime,
        isWeekendParam,
        weekendOvertimeEnabledParam,
      );

      // Calculate estimated end time
      final estimatedEndTime = _calculateEstimatedEndTime(
        startTimeParam,
        effectiveWorkTime,
        totalBreakTime,
        remainingTime,
      );

      final workTimeInfo = WorkTimeInfo(
        estimatedEndTime: estimatedEndTime,
        remainingTime: remainingTime,
        breakTime: totalBreakTime,
        isOvertimeStarted: isOvertimeStarted,
        overtimeHours: overtimeHours,
      );

      logger.d(
          '[WorkTimeCalculatorService] Calculated work time info: $workTimeInfo');
      return workTimeInfo;
    } catch (e, stackTrace) {
      logger.e(
          '[WorkTimeCalculatorService] Error calculating work time info: $e',
          error: e,
          stackTrace: stackTrace);
      return WorkTimeInfo.empty();
    }
  }

  /// Generates an ExtendedTimerState combining provided timer data with calculated work time info
  ExtendedTimerState generateExtendedTimerState({
    required String currentState,
    required Duration elapsedTime,
    DateTime? startTime,
    required bool isWeekendDay,
    required bool weekendOvertimeEnabled,
  }) {
    try {
      final workTimeInfo = calculateWorkTimeInfo(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekend: isWeekendDay,
        weekendOvertimeEnabled: weekendOvertimeEnabled,
      );

      return ExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: isWeekendDay,
        weekendOvertimeEnabled: weekendOvertimeEnabled,
        workTimeInfo: workTimeInfo,
        configuration: _configuration,
      );
    } catch (e, stackTrace) {
      logger.e(
          '[WorkTimeCalculatorService] Error generating extended timer state: $e',
          error: e,
          stackTrace: stackTrace);

      // Return a safe default state
      return ExtendedTimerState(
        currentState: currentState,
        elapsedTime: elapsedTime,
        startTime: startTime,
        isWeekendDay: isWeekendDay,
        weekendOvertimeEnabled: weekendOvertimeEnabled,
        workTimeInfo: WorkTimeInfo.empty(),
        configuration: _configuration,
      );
    }
  }

  /// Calculates effective work time by excluding break periods
  Duration _calculateEffectiveWorkTime(
      Duration totalElapsedTime, String currentState) {
    // Calculate total break time from tracked breaks
    final totalBreakTime = _calculateTotalBreakTime();

    // If currently on break, add the current break duration
    Duration currentBreakDuration = Duration.zero;
    if (currentState == 'Pause' && _currentBreakStart != null) {
      currentBreakDuration = DateTime.now().difference(_currentBreakStart!);
    }

    // Effective work time = total elapsed time - completed breaks - current break
    final effectiveTime =
        totalElapsedTime - totalBreakTime - currentBreakDuration;

    // Ensure effective work time is not negative
    return effectiveTime.isNegative ? Duration.zero : effectiveTime;
  }

  /// Calculates total break time from tracked breaks
  Duration _calculateTotalBreakTime() {
    Duration totalBreakTime = Duration.zero;

    // Sum up all completed break periods
    for (final breakPeriod in _breaks) {
      totalBreakTime += breakPeriod.duration;
    }

    // Cap break time at a reasonable maximum (e.g., 4 hours)
    const maxBreakTime = Duration(hours: 4);
    return totalBreakTime > maxBreakTime ? maxBreakTime : totalBreakTime;
  }

  /// Calculates remaining time to complete the standard work day
  Duration _calculateRemainingWorkTime(Duration effectiveWorkTime) {
    if (effectiveWorkTime >= _configuration.standardWorkDay) {
      return Duration.zero;
    }
    return _configuration.standardWorkDay - effectiveWorkTime;
  }

  /// Determines if overtime should start based on work time and configuration
  bool _shouldStartOvertime(
    Duration effectiveWorkTime,
    bool isWeekend,
    bool weekendOvertimeEnabled,
  ) {
    // Weekend overtime logic
    if (isWeekend && weekendOvertimeEnabled) {
      return effectiveWorkTime > Duration.zero;
    }

    // Weekday overtime logic - after standard work day
    return effectiveWorkTime > _configuration.standardWorkDay;
  }

  /// Calculates overtime hours based on effective work time and day type
  Duration _calculateOvertimeHours(
    Duration effectiveWorkTime,
    bool isWeekend,
    bool weekendOvertimeEnabled,
  ) {
    if (isWeekend && weekendOvertimeEnabled) {
      // All weekend work is overtime when enabled
      return effectiveWorkTime;
    }

    // Weekday overtime - only time beyond standard work day
    if (effectiveWorkTime > _configuration.standardWorkDay) {
      return effectiveWorkTime - _configuration.standardWorkDay;
    }

    return Duration.zero;
  }

  /// Calculates estimated end time to complete the standard work day
  DateTime? _calculateEstimatedEndTime(
    DateTime? startTime,
    Duration effectiveWorkTime,
    Duration breakTime,
    Duration remainingTime,
  ) {
    if (startTime == null || remainingTime == Duration.zero) {
      return null;
    }

    try {
      // Base calculation: start time + effective work time + break time + remaining time
      final baseEndTime =
          startTime.add(effectiveWorkTime + breakTime + remainingTime);

      // Apply break adjustment if configured
      final breakAdjustment =
          _configuration.calculateBreakAdjustment(breakTime);
      final adjustedEndTime = baseEndTime.add(breakAdjustment);

      logger.d(
          '[WorkTimeCalculatorService] Calculated end time: $adjustedEndTime '
          '(start: $startTime, effective: $effectiveWorkTime, break: $breakTime, '
          'remaining: $remainingTime, adjustment: $breakAdjustment)');

      return adjustedEndTime;
    } catch (e, stackTrace) {
      logger.e(
          '[WorkTimeCalculatorService] Error calculating estimated end time: $e',
          error: e,
          stackTrace: stackTrace);
      return null;
    }
  }

  /// Tracks the start of a break period
  void startBreak() {
    if (_currentBreakStart == null) {
      _currentBreakStart = DateTime.now();
      logger.d(
          '[WorkTimeCalculatorService] Break started at $_currentBreakStart');
    }
  }

  /// Tracks the end of a break period
  void endBreak() {
    if (_currentBreakStart != null) {
      final breakEnd = DateTime.now();
      final breakDuration = breakEnd.difference(_currentBreakStart!);

      // Only track significant breaks
      if (_configuration.isSignificantBreak(breakDuration)) {
        _breaks.add(BreakPeriod(
          start: _currentBreakStart!,
          end: breakEnd,
          duration: breakDuration,
        ));
        logger.d(
            '[WorkTimeCalculatorService] Break ended: duration=$breakDuration');
      }

      _currentBreakStart = null;
    }
  }

  /// Gets all tracked break periods for the current day
  List<BreakPeriod> getBreakPeriods() {
    return List.unmodifiable(_breaks);
  }

  /// Clears all tracked break periods (typically called at start of new day)
  void clearBreakPeriods() {
    _breaks.clear();
    _currentBreakStart = null;
    logger.d('[WorkTimeCalculatorService] Break periods cleared');
  }

  /// Gets the current break duration if on break
  Duration? getCurrentBreakDuration() {
    if (_currentBreakStart != null) {
      return DateTime.now().difference(_currentBreakStart!);
    }
    return null;
  }

  /// Validates work time calculations for consistency
  bool validateCalculations(WorkTimeInfo workTimeInfo) {
    try {
      // Check for negative durations
      if (workTimeInfo.remainingTime.isNegative ||
          workTimeInfo.breakTime.isNegative ||
          workTimeInfo.overtimeHours.isNegative) {
        logger.w(
            '[WorkTimeCalculatorService] Validation failed: negative durations found');
        return false;
      }

      // Check for unreasonable values
      const maxWorkDay = Duration(hours: 16);
      const maxBreakTime = Duration(hours: 8);

      if (workTimeInfo.breakTime > maxBreakTime) {
        logger.w(
            '[WorkTimeCalculatorService] Validation failed: excessive break time');
        return false;
      }

      if (workTimeInfo.overtimeHours > maxWorkDay) {
        logger.w(
            '[WorkTimeCalculatorService] Validation failed: excessive overtime');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      logger.e('[WorkTimeCalculatorService] Error validating calculations: $e',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Resets the service state (typically called at start of new day)
  void reset() {
    clearBreakPeriods();
    logger.d('[WorkTimeCalculatorService] Service reset');
  }

  /// Sets a custom minimum break duration for testing purposes
  void setMinimumBreakDurationForTesting(Duration duration) {
    _configuration = _configuration.copyWith(minimumBreakDuration: duration);
  }
}

/// Represents a break period with start, end, and duration
class BreakPeriod {
  final DateTime start;
  final DateTime end;
  final Duration duration;

  const BreakPeriod({
    required this.start,
    required this.end,
    required this.duration,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BreakPeriod &&
        other.start == start &&
        other.end == end &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(start, end, duration);

  @override
  String toString() {
    return 'BreakPeriod(start: $start, end: $end, duration: $duration)';
  }
}
