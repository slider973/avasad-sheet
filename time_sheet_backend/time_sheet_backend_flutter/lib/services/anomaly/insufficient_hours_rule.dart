import 'package:intl/intl.dart';
import '../../features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import '../../features/pointage/data/models/anomalies/anomalies.dart';
import 'interface_timeSheetValidator.dart';

class InsufficientHoursRule implements ITimeSheetValidator {
  @override
  AnomalyModel? validateAndGenerate(TimeSheetEntryModel entry, DateTime detectedDate) {
    try {
      DateTime startMorning = DateFormat('HH:mm').parse(entry.startMorning);
      DateTime endMorning = DateFormat('HH:mm').parse(entry.endMorning);
      DateTime startAfternoon = DateFormat('HH:mm').parse(entry.startAfternoon);
      DateTime endAfternoon = DateFormat('HH:mm').parse(entry.endAfternoon);

      int totalMinutes = endMorning.difference(startMorning).inMinutes +
          endAfternoon.difference(startAfternoon).inMinutes;

      if (totalMinutes < 498) {
        // Temps insuffisant, créer un modèle d'anomalie
        return AnomalyModel()
          ..detectedDate = detectedDate
          ..description = "Temps de travail insuffisant (${(totalMinutes ~/ 60)}h${(totalMinutes % 60).toString().padLeft(2, '0')} au lieu de 8h18)"
          ..isResolved = false
          ..type = AnomalyType.insufficientHours
          ..timesheetEntry.value = entry; // Lier l'entrée
      }

      return null; // Pas d'anomalie
    } catch (e) {
      // Retourner une anomalie en cas d'erreur de validation
      return AnomalyModel()
        ..detectedDate = detectedDate
        ..description = "Erreur lors de la validation des heures pour ${entry.dayDate}"
        ..isResolved = false
        ..type = AnomalyType.invalidTimes;
    }
  }
}
