import '../../data/models/timesheet_entry.dart';

abstract class LocalDataSource {
  Future<void> saveTimeSheet(TimeSheetEntryModel entryModel);
  Future<List<TimeSheetEntryModel>> getTimesheetEntries();
  Future<List<TimeSheetEntryModel>> getTimesheetEntriesForWeek(int weekNumber);
  Future<List<TimeSheetEntryModel>> findEntriesFromMonthOf(int monthNumber);

}