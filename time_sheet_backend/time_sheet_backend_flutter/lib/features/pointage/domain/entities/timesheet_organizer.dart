import 'package:intl/intl.dart';

import 'timesheet_entry.dart';
import 'work_week.dart';
import 'work_day.dart';

class TimesheetOrganizer {
  List<WorkWeek> organizeIntoWeeks(List<TimesheetEntry> timesheetEntryList) {
    List<WorkWeek> weeks = [];
    List<Workday> currentWeekDays = [];
    timesheetEntryList.sort((a, b) {
      DateTime dateA = DateFormat("dd-MMM-yy").parse(a.dayDate, true);
      DateTime dateB = DateFormat("dd-MMM-yy").parse(b.dayDate, true);
      return dateA.compareTo(dateB);
    });
    for (var timeSheetEntry in timesheetEntryList) {
      currentWeekDays.add(Workday(timeSheetEntry));
      final currentWeekDay = DateFormat("dd-MMM-yy").parse(timeSheetEntry.dayDate, true);
      if (currentWeekDay.weekday == DateTime.friday && currentWeekDays.isNotEmpty) {
        weeks.add(WorkWeek(List.from(currentWeekDays)));
        currentWeekDays = [];
      }
    }

    // Add any remaining days as a week
    if (currentWeekDays.isNotEmpty) {
      weeks.add(WorkWeek(currentWeekDays));
    }

    return weeks;
  }
}
