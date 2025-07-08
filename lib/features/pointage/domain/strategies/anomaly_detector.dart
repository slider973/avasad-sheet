
import '../entities/timesheet_entry.dart';

abstract class AnomalyDetector {
  String get id;
  String get name;
  String get description;
  String detect(TimesheetEntry entry);
}