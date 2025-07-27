import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';

class CalculateOvertimeHoursUseCase {
  Future<Duration> execute({
    required TimesheetEntry entry,
    required double normalHoursThreshold,
  }) async {
    if (!entry.hasOvertimeHours) {
      return Duration.zero;
    }
    
    final totalHours = entry.calculateDailyTotal();
    final thresholdDuration = Duration(
      hours: normalHoursThreshold.floor(),
      minutes: ((normalHoursThreshold % 1) * 60).round(),
    );
    
    if (totalHours > thresholdDuration) {
      return totalHours - thresholdDuration;
    }
    
    return Duration.zero;
  }
}