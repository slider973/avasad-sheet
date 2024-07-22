import 'package:intl/intl.dart';

import '../features/pointage/domain/entities/timesheet_entry.dart';

class TimeUtils {
  Duration calculateTotalHours(  TimesheetEntry entry) {
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
}