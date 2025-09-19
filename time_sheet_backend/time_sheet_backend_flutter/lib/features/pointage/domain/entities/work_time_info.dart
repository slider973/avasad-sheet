/// Information about work time calculations for real-time display
///
/// This class contains calculated information that is not stored in TimesheetEntry
/// but is computed in real-time for the timer interface.
class WorkTimeInfo {
  /// Estimated end time to complete 8 hours of work
  final DateTime? estimatedEndTime;

  /// Remaining time to complete the standard work day
  final Duration remainingTime;

  /// Total break time taken today (calculated from timer gaps)
  final Duration breakTime;

  /// Whether overtime has started (after 8 hours of effective work)
  final bool isOvertimeStarted;

  /// Exact overtime hours worked beyond the standard day
  final Duration overtimeHours;

  const WorkTimeInfo({
    this.estimatedEndTime,
    required this.remainingTime,
    required this.breakTime,
    required this.isOvertimeStarted,
    required this.overtimeHours,
  });

  /// Creates empty work time info for initialization
  factory WorkTimeInfo.empty() {
    return const WorkTimeInfo(
      estimatedEndTime: null,
      remainingTime: Duration(hours: 8),
      breakTime: Duration.zero,
      isOvertimeStarted: false,
      overtimeHours: Duration.zero,
    );
  }

  /// Creates work time info with calculated values
  factory WorkTimeInfo.calculate({
    required Duration workedTime,
    required Duration totalElapsedTime,
    DateTime? workStartTime,
    Duration standardWorkDay = const Duration(hours: 8),
  }) {
    // Calculate break time (total elapsed - actual work time)
    final breakTime = totalElapsedTime - workedTime;

    // Calculate remaining time to complete standard work day
    final remainingTime = standardWorkDay > workedTime
        ? standardWorkDay - workedTime
        : Duration.zero;

    // Check if overtime has started
    final isOvertimeStarted = workedTime > standardWorkDay;

    // Calculate overtime hours
    final overtimeHours =
        isOvertimeStarted ? workedTime - standardWorkDay : Duration.zero;

    // Calculate estimated end time
    DateTime? estimatedEndTime;
    if (workStartTime != null && remainingTime > Duration.zero) {
      // End time = start time + total elapsed time + remaining work time
      estimatedEndTime = workStartTime.add(totalElapsedTime + remainingTime);
    }

    return WorkTimeInfo(
      estimatedEndTime: estimatedEndTime,
      remainingTime: remainingTime,
      breakTime: breakTime,
      isOvertimeStarted: isOvertimeStarted,
      overtimeHours: overtimeHours,
    );
  }

  /// Creates a copy with updated values
  WorkTimeInfo copyWith({
    DateTime? estimatedEndTime,
    Duration? remainingTime,
    Duration? breakTime,
    bool? isOvertimeStarted,
    Duration? overtimeHours,
  }) {
    return WorkTimeInfo(
      estimatedEndTime: estimatedEndTime ?? this.estimatedEndTime,
      remainingTime: remainingTime ?? this.remainingTime,
      breakTime: breakTime ?? this.breakTime,
      isOvertimeStarted: isOvertimeStarted ?? this.isOvertimeStarted,
      overtimeHours: overtimeHours ?? this.overtimeHours,
    );
  }

  /// Returns true if the standard work day is completed
  bool get isWorkDayCompleted => remainingTime == Duration.zero;

  /// Returns the progress percentage towards completing the standard work day
  double get progressPercentage {
    const standardWorkDay = Duration(hours: 8);
    final workedTime = standardWorkDay - remainingTime;
    if (workedTime >= standardWorkDay) return 1.0;
    return workedTime.inMilliseconds / standardWorkDay.inMilliseconds;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkTimeInfo &&
        other.estimatedEndTime == estimatedEndTime &&
        other.remainingTime == remainingTime &&
        other.breakTime == breakTime &&
        other.isOvertimeStarted == isOvertimeStarted &&
        other.overtimeHours == overtimeHours;
  }

  @override
  int get hashCode {
    return Object.hash(
      estimatedEndTime,
      remainingTime,
      breakTime,
      isOvertimeStarted,
      overtimeHours,
    );
  }

  @override
  String toString() {
    return 'WorkTimeInfo('
        'estimatedEndTime: $estimatedEndTime, '
        'remainingTime: $remainingTime, '
        'breakTime: $breakTime, '
        'isOvertimeStarted: $isOvertimeStarted, '
        'overtimeHours: $overtimeHours'
        ')';
  }
}
