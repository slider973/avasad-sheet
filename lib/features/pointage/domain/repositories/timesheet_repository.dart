import '../entities/timesheet_entry.dart';
import '../entities/generated_pdf.dart';
import '../value_objects/vacation_days_info.dart';

abstract class TimesheetRepository {
  Future<int> saveTimesheetEntry(TimesheetEntry entry);

  Future<List<TimesheetEntry>> getTimesheetEntries();
  Future<void> deleteTimeSheet(int id);

  Future<List<TimesheetEntry>> getTimesheetEntriesForWeek(int weekNumber);

  Future<List<TimesheetEntry>> findEntriesFromMonthOf(int monthNumber, int? year);

  Future<List<TimesheetEntry>> getTimesheetEntriesForMonth(int monthNumber);

  Future<void> saveGeneratedPdf(GeneratedPdf pdf);

  Future<List<GeneratedPdf>> getGeneratedPdfs();

  Future<void> deleteGeneratedPdf(int pdfId);
  Future<TimesheetEntry?> getTimesheetEntryForDate(String date);
  Future<TimesheetEntry?> getTimesheetEntry(String formattedDate);
  Future<TimesheetEntry?> getTimesheetEntryWhitFrenchFormat(String formattedDate);
  Future<int> getVacationDaysCount();
  Future<int> getLastYearVacationDaysCount();
  Future<VacationDaysInfo> getVacationDaysInfo();
}
