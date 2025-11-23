import 'package:intl/intl.dart';
import '../../features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import '../../features/pointage/data/models/anomalies/anomalies.dart';
import 'interface_timeSheetValidator.dart';

/// Règle de détection des heures excessives
class ExcessiveHoursRule implements ITimeSheetValidator {
  @override
  AnomalyModel? validateAndGenerate(TimeSheetEntryModel entry, DateTime detectedDate) {
    try {
      DateTime startMorning = DateFormat('HH:mm').parse(entry.startMorning);
      DateTime endMorning = DateFormat('HH:mm').parse(entry.endMorning);
      DateTime startAfternoon = DateFormat('HH:mm').parse(entry.startAfternoon);
      DateTime endAfternoon = DateFormat('HH:mm').parse(entry.endAfternoon);

      int totalMinutes = endMorning.difference(startMorning).inMinutes +
          endAfternoon.difference(startAfternoon).inMinutes;

      // Plus de 10h = excessif (utilise invalidTimes car pas de type spécifique)
      if (totalMinutes > 600) {
        final hours = totalMinutes ~/ 60;
        final mins = totalMinutes % 60;
        
        return AnomalyModel()
          ..detectedDate = detectedDate
          ..description = "⚠️ Heures excessives: ${hours}h${mins.toString().padLeft(2, '0')} (${((totalMinutes - 498) / 60).toStringAsFixed(1)}h supplémentaires)"
          ..isResolved = false
          ..type = AnomalyType.invalidTimes
          ..timesheetEntry.value = entry;
      }

      return null;
    } catch (e) {
      return null; // Ignorer les erreurs de parsing
    }
  }
}
