import 'package:intl/intl.dart';
import '../../features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import '../../features/pointage/data/models/anomalies/anomalies.dart';
import 'interface_timeSheetValidator.dart';

/// Règle de détection des horaires inhabituels
class UnusualHoursRule implements ITimeSheetValidator {
  @override
  AnomalyModel? validateAndGenerate(TimeSheetEntryModel entry, DateTime detectedDate) {
    try {
      DateTime startMorning = DateFormat('HH:mm').parse(entry.startMorning);
      DateTime endAfternoon = DateFormat('HH:mm').parse(entry.endAfternoon);

      // Début très tôt (avant 6h)
      if (startMorning.hour < 6) {
        return AnomalyModel()
          ..detectedDate = detectedDate
          ..description = "🌅 Début de journée inhabituel: ${entry.startMorning} (avant 6h)"
          ..isResolved = false
          ..type = AnomalyType.invalidTimes
          ..timesheetEntry.value = entry;
      }

      // Fin très tard (après 20h)
      if (endAfternoon.hour >= 20) {
        return AnomalyModel()
          ..detectedDate = detectedDate
          ..description = "🌙 Fin de journée tardive: ${entry.endAfternoon} (après 20h)"
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
