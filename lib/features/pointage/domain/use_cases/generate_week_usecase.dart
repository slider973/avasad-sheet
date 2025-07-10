

import '../entities/timesheet_entry.dart';
import '../entities/timesheet_organizer.dart';
import '../entities/work_week.dart';

class WeekGeneratorUseCase {
  execute(List<TimesheetEntry> timesheetEntryList) {
    if (timesheetEntryList.isNotEmpty) {
      print('WeekGeneratorUseCase.execute() last entry: ${timesheetEntryList.last}');
    } else {
      print('WeekGeneratorUseCase.execute() empty list');
    }
    
    TimesheetOrganizer organizer = TimesheetOrganizer();
    List<WorkWeek> weeks = organizer.organizeIntoWeeks(timesheetEntryList);

    for (var week in weeks) {
      print(
          'Total hours for the week: ${week.calculateTotalWeekHours().toString()}');
    }
    print('WeekGeneratorUseCase.execute() ${weeks.length} weeks generated.');
    return weeks;
  }
}
