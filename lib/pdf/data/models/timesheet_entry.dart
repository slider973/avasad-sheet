import 'package:isar/isar.dart';

part 'timesheet_entry.g.dart';

@Collection()
class TimeSheetEntryModel {
  Id id = Isar.autoIncrement;

  late DateTime dayDate;
  late String dayOfWeekDate;
  late String startMorning;
  late String endMorning;
  late String startAfternoon;
  late String endAfternoon;
}