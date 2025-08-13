import '../../features/pointage/data/models/anomalies/anomalies.dart';
import '../../features/pointage/data/models/timesheet_entry/timesheet_entry.dart';

abstract class ITimeSheetValidator {
  AnomalyModel? validateAndGenerate(TimeSheetEntryModel entry, DateTime detectedDate);
}