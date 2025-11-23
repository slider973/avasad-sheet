import 'package:intl/intl.dart';
import '../../features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import '../../features/pointage/data/models/anomalies/anomalies.dart';
import 'interface_timeSheetValidator.dart';

/// Règle de détection des pauses déjeuner insuffisantes
class InsufficientBreakRule implements ITimeSheetValidator {
  @override
  AnomalyModel? validateAndGenerate(TimeSheetEntryModel entry, DateTime detectedDate) {
    try {
      DateTime endMorning = DateFormat('HH:mm').parse(entry.endMorning);
      DateTime startAfternoon = DateFormat('HH:mm').parse(entry.startAfternoon);

      int breakMinutes = startAfternoon.difference(endMorning).inMinutes;

      // Moins de 30 min = insuffisant
      if (breakMinutes < 30) {
        return AnomalyModel()
          ..detectedDate = detectedDate
          ..description = "⏰ Pause déjeuner insuffisante: ${breakMinutes} minutes (minimum recommandé: 30 min)"
          ..isResolved = false
          ..type = AnomalyType.invalidTimes
          ..timesheetEntry.value = entry;
      }

      // Plus de 2h = inhabituel
      if (breakMinutes > 120) {
        return AnomalyModel()
          ..detectedDate = detectedDate
          ..description = "⏰ Pause déjeuner inhabituelle: ${breakMinutes} minutes (${breakMinutes ~/ 60}h${breakMinutes % 60})"
          ..isResolved = false
          ..type = AnomalyType.invalidTimes
          ..timesheetEntry.value = entry;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
