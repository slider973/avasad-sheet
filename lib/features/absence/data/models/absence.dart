
import 'package:isar/isar.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence.dart';

import '../../../pointage/data/models/timesheet_entry/timesheet_entry.dart';
part 'absence.g.dart';
@collection
class Absence {
  Id id = Isar.autoIncrement;
  late final DateTime startDate;
  late final DateTime endDate;
  @enumerated
  late final AbsenceType type;
  late final String motif;


  final timesheetEntry = IsarLink<TimeSheetEntryModel>();
}