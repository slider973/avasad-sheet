import 'package:intl/intl.dart';

import '../entities/timesheet_entry.dart';
import '../entities/timesheet_organizer.dart';
import '../entities/work_week.dart';
import 'generate_date_usecase.dart';

class WeekGeneratorUseCase {
  execute() {
    List<String> dates = generateDateListUseCase(2023, 1);
    TimesheetOrganizer organizer = TimesheetOrganizer();
    final timesheetEntryList = dates
        .map((date) => TimesheetEntry(
            date,
            DateFormat('EEEE').format(DateFormat('dd-MMM-yy').parse(date)),
            '08:00',
            '12:00',
            '13:00',
            '17:00'))
        .toList();
    List<WorkWeek> weeks = organizer.organizeIntoWeeks(timesheetEntryList);

    for (var week in weeks) {
      print(
          'Total hours for the week: ${week.calculateTotalWeekHours().toString()}');
    }
  }
}
