import 'package:isar/isar.dart';

import '../../../../absence/data/models/absence.dart';
import '../anomalies/anomalies.dart';
import '../../../../../enum/overtime_type.dart';
import '../../../../../services/weekend_detection_service.dart';

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

  @Index()
  bool isWeekendDay = false;

  @Index()
  bool isWeekendOvertimeEnabled = true;

  @Enumerated(EnumType.name)
  OvertimeType overtimeType = OvertimeType.NONE;

  @Backlink(to: 'timesheetEntry')
  final absence = IsarLink<Absence>();

  @Backlink(to: 'timesheetEntry')
  final anomaly = IsarLink<AnomalyModel>();

  /// Updates weekend status and overtime type based on the entry date and configuration
  void updateWeekendStatus() {
    // Detect if this is a weekend day
    isWeekendDay = WeekendDetectionService().isWeekend(dayDate);

    // Determine overtime type based on weekend status and existing overtime hours
    if (isWeekendDay && isWeekendOvertimeEnabled) {
      if (hasOvertimeHours) {
        overtimeType = OvertimeType.BOTH;
      } else {
        overtimeType = OvertimeType.WEEKEND_ONLY;
      }
    } else if (hasOvertimeHours) {
      overtimeType = OvertimeType.WEEKDAY_ONLY;
    } else {
      overtimeType = OvertimeType.NONE;
    }
  }
}
