import 'package:isar/isar.dart';

import '../../../../absence/data/models/absence.dart';

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
  final absence = IsarLink<Absence>();
}