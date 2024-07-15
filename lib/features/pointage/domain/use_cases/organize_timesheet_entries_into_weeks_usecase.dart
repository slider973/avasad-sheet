import 'package:intl/intl.dart';

import '../entities/timesheet_entry.dart';
import '../entities/work_day.dart';
import '../entities/work_week.dart';

class OrganizeTimesheetEntriesIntoWeeksUseCase {
 static List<WorkWeek> execute(List<TimesheetEntry> entries) {
    // Triez d'abord toutes les entrées par date
    entries.sort((a, b) {
      final dateA = DateFormat("dd-MMM-yy").parse(a.dayDate);
      final dateB = DateFormat("dd-MMM-yy").parse(b.dayDate);
      return dateA.compareTo(dateB);
    });

    // Organisez les entrées en semaines
    List<WorkWeek> weeks = [];
    WorkWeek currentWeek = WorkWeek([]);

    for (var entry in entries) {
      if (currentWeek.workday.isEmpty || _isSameWeek(currentWeek.workday.first.entry.dayDate, entry.dayDate)) {
        currentWeek.workday.add(Workday(entry));
      } else {
        weeks.add(currentWeek);
        currentWeek = WorkWeek([Workday(entry)]);
      }
    }

    if (currentWeek.workday.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return weeks;
  }

 static bool _isSameWeek(String date1, String date2) {
    final d1 = DateFormat("dd-MMM-yy").parse(date1);
    final d2 = DateFormat("dd-MMM-yy").parse(date2);
    return d1.difference(d2).inDays.abs() < 7 && d1.weekday <= d2.weekday;
  }
}