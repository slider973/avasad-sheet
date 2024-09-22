import 'package:isar/isar.dart';

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

  TimeSheetEntryModel({
    required this.dayDate,
    required this.dayOfWeekDate,
    this.startMorning = '',
    this.endMorning = '',
    this.startAfternoon = '',
    this.endAfternoon = '',
    this.absenceReason = '',
     this.period = '',
  });
}