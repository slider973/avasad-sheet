

import '../domain/entities/timesheet_entry.dart';
import '../strategies/anomaly_detector.dart';

class InsufficientHoursDetector implements AnomalyDetector {
  @override
  String get id => 'insufficient_hours';

  @override
  String get name => 'Heures insuffisantes';

  @override
  String get description => 'Détecte si le temps de travail est inférieur à 8h18 par jour';

  @override
  String detect(TimesheetEntry entry) {
    final totalHours = entry.calculateDailyTotal();
    if (totalHours.inMinutes < 8 * 60 + 18) {
      return "Le ${entry.dayDate} : Temps de travail insuffisant (${_formatDuration(totalHours)} au lieu de 8h18)";
    }
    return '';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${duration.inHours}h$twoDigitMinutes";
  }
}