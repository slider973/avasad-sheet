import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';

import '../../../../enum/absence_period.dart';

class Workday {
  TimesheetEntry entry;
  bool isEnabled = true;

  Workday(this.entry);

  // Helper function to parse time string to DateTime
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

  Duration calculateTotalHours() {
    // Si c'est une absence complète, retourner une durée de 0
    if (entry.absenceReason != null && entry.absenceReason!.isNotEmpty && entry.period == AbsencePeriod.fullDay.value) {
      return Duration.zero;
    }
    // Parse start and end times to DateTime
    DateTime? startMorning = _parseTime(entry.startMorning);
    DateTime? endMorning = _parseTime(entry.endMorning);
    DateTime? startAfternoon = _parseTime(entry.startAfternoon);
    DateTime? endAfternoon = _parseTime(entry.endAfternoon);

    Duration totalDuration = Duration.zero;
    // Si c'est une demi-journée, calculer seulement pour la partie travaillée
    if (entry.period == AbsencePeriod.halfDay.value) {
      if (startMorning != null && endMorning != null) {
        totalDuration += endMorning.difference(startMorning);
      } else if (startAfternoon != null && endAfternoon != null) {
        totalDuration += endAfternoon.difference(startAfternoon);
      }
    } else {
      // Pour une journée complète ou si le period n'est pas spécifié, calculer pour toute la journée
      if (startMorning != null && endMorning != null) {
        totalDuration += endMorning.difference(startMorning);
      }
      if (startAfternoon != null && endAfternoon != null) {
        totalDuration += endAfternoon.difference(startAfternoon);
      }
    }
    return totalDuration;
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "$hours:$minutes";
  }
  bool isAbsence() {
    return entry.absence != null;
  }

  Workday disable() {
    isEnabled = false;
    return this;
  }
}
