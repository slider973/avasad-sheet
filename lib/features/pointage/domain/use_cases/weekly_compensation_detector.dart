import '../entities/timesheet_entry.dart';
import '../strategies/anomaly_detector.dart';

class WeeklyCompensationDetector implements AnomalyDetector {
  static const Duration weeklyTarget = Duration(hours: 41, minutes: 30);
  
  @override
  String get id => 'weekly_compensation';

  @override
  String get name => 'Compensation hebdomadaire';

  @override
  String get description => 'Vérifie si le total hebdomadaire compense les anomalies journalières';

  @override
  String detect(TimesheetEntry entry) {
    // Ce détecteur fonctionne différemment - il a besoin du contexte hebdomadaire
    return '';
  }

  Map<String, dynamic> detectWeekly(List<TimesheetEntry> weekEntries) {
    Duration totalWeekDuration = Duration.zero;
    List<String> dailyAnomalies = [];
    
    for (var entry in weekEntries) {
      final dailyTotal = entry.calculateDailyTotal();
      totalWeekDuration += dailyTotal;
      
      // 8h18 = 498 minutes
      if (dailyTotal.inMinutes < 498) {
        dailyAnomalies.add(entry.dayDate);
      }
    }
    
    bool isWeekCompensated = totalWeekDuration >= weeklyTarget;
    
    return {
      'totalDuration': totalWeekDuration,
      'isCompensated': isWeekCompensated,
      'dailyAnomalies': dailyAnomalies,
      'message': isWeekCompensated 
        ? 'Objectif hebdomadaire atteint (${_formatDuration(totalWeekDuration)})'
        : 'Manque ${_formatDuration(weeklyTarget - totalWeekDuration)} sur la semaine'
    };
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${duration.inHours}h$twoDigitMinutes";
  }
}