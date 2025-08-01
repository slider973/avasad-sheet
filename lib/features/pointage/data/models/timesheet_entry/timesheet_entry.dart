import 'package:isar/isar.dart';

import '../../../../absence/data/models/absence.dart';
import '../anomalies/anomalies.dart';

part 'timesheet_entry.g.dart';

@collection
class TimeSheetEntryModel {
  Id id = Isar.autoIncrement;

  late DateTime dayDate;
  late String dayOfWeekDate;
  late String startMorning;
  late String endMorning;
  late String startAfternoon;
  late String endAfternoon;
  late String absenceReason;
  late String period;
  
  @Index()
  bool hasOvertimeHours = false;
  
  @Backlink(to: 'timesheetEntry')
  final absence = IsarLink<Absence>();

  @Backlink(to: 'timesheetEntry')
  final anomaly = IsarLink<AnomalyModel>();
}