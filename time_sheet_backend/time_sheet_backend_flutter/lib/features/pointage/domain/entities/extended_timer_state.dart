import 'work_time_info.dart';
import 'work_time_configuration.dart';

/// Extended timer state that combines TimerService data with calculated work time info
///
/// This is a simple wrapper that combines the existing timer state with
/// the calculated work time information for display purposes.
class ExtendedTimerState {
  /// Current state from TimerService ('Non commencé', 'Entrée', 'Pause', 'Reprise', 'Sortie')
  final String currentState;

  /// Total elapsed time from TimerService
  final Duration elapsedTime;

  /// Start time of the work day
  final DateTime? startTime;

  /// Whether this is a weekend day
  final bool isWeekendDay;

  /// Whether weekend overtime is enabled
  final bool weekendOvertimeEnabled;

  /// Calculated work time information
  final WorkTimeInfo workTimeInfo;

  /// Configuration used for calculations
  final WorkTimeConfiguration configuration;

  const ExtendedTimerState({
    required this.currentState,
    required this.elapsedTime,
    this.startTime,
    required this.isWeekendDay,
    required this.weekendOvertimeEnabled,
    required this.workTimeInfo,
    required this.configuration,
  });

  /// Creates an ExtendedTimerState from TimerService data
  factory ExtendedTimerState.fromTimerService({
    required String currentState,
    required Duration elapsedTime,
    DateTime? startTime,
    required bool isWeekendDay,
    required bool weekendOvertimeEnabled,
    WorkTimeConfiguration? configuration,
  }) {
    final config = configuration ?? WorkTimeConfiguration.defaultConfig();

    // For now, assume all elapsed time is work time (break tracking will be added later)
    final workTimeInfo = WorkTimeInfo.calculate(
      workedTime: elapsedTime,
      totalElapsedTime: elapsedTime,
      workStartTime: startTime,
      standardWorkDay: config.standardWorkDay,
    );

    return ExtendedTimerState(
      currentState: currentState,
      elapsedTime: elapsedTime,
      startTime: startTime,
      isWeekendDay: isWeekendDay,
      weekendOvertimeEnabled: weekendOvertimeEnabled,
      workTimeInfo: workTimeInfo,
      configuration: config,
    );
  }

  /// Creates a copy with updated values
  ExtendedTimerState copyWith({
    String? currentState,
    Duration? elapsedTime,
    DateTime? startTime,
    bool? isWeekendDay,
    bool? weekendOvertimeEnabled,
    WorkTimeInfo? workTimeInfo,
    WorkTimeConfiguration? configuration,
  }) {
    return ExtendedTimerState(
      currentState: currentState ?? this.currentState,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      startTime: startTime ?? this.startTime,
      isWeekendDay: isWeekendDay ?? this.isWeekendDay,
      weekendOvertimeEnabled:
          weekendOvertimeEnabled ?? this.weekendOvertimeEnabled,
      workTimeInfo: workTimeInfo ?? this.workTimeInfo,
      configuration: configuration ?? this.configuration,
    );
  }

  /// Returns true if currently in an active work state
  bool get isActivelyWorking =>
      currentState == 'Entrée' || currentState == 'Reprise';

  /// Returns true if currently on break
  bool get isOnBreak => currentState == 'Pause';

  /// Returns true if work day is completed
  bool get isWorkDayCompleted => currentState == 'Sortie';

  /// Returns true if work has not started
  bool get isNotStarted => currentState == 'Non commencé';

  /// Returns true if currently in overtime (weekend or after 8 hours)
  bool get isCurrentlyInOvertime {
    if (isWeekendDay && weekendOvertimeEnabled) return true;
    return workTimeInfo.isOvertimeStarted;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtendedTimerState &&
        other.currentState == currentState &&
        other.elapsedTime == elapsedTime &&
        other.startTime == startTime &&
        other.isWeekendDay == isWeekendDay &&
        other.weekendOvertimeEnabled == weekendOvertimeEnabled &&
        other.workTimeInfo == workTimeInfo &&
        other.configuration == configuration;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentState,
      elapsedTime,
      startTime,
      isWeekendDay,
      weekendOvertimeEnabled,
      workTimeInfo,
      configuration,
    );
  }

  @override
  String toString() {
    return 'ExtendedTimerState('
        'currentState: $currentState, '
        'elapsedTime: $elapsedTime, '
        'startTime: $startTime, '
        'isWeekendDay: $isWeekendDay, '
        'workTimeInfo: $workTimeInfo'
        ')';
  }
}
