import '../entities/timesheet_entry.dart';

abstract class TimesheetRepository {
  Future<void> saveTimesheetEntry(TimesheetEntry entry);
  Future<List<TimesheetEntry>> getTimesheetEntries();
  Future<List<TimesheetEntry>> getTimesheetEntriesForWeek(int weekNumber);
  Future<List<TimesheetEntry>> findEntriesFromMonthOf(int monthNumber);
}
