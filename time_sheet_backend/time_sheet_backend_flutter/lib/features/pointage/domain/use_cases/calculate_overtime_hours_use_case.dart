import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';

class CalculateOvertimeHoursUseCase {
  Future<Duration> execute({
    required TimesheetEntry entry,
    required double normalHoursThreshold,
  }) async {
    final totalHours = entry.calculateDailyTotal();

    // Pour les weekends avec overtime activé, toutes les heures sont supplémentaires
    if (entry.isWeekendDay && entry.isWeekendOvertimeEnabled) {
      return totalHours;
    }

    // Pour les jours de semaine, vérifier si hasOvertimeHours est activé
    if (!entry.hasOvertimeHours) {
      return Duration.zero;
    }

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
