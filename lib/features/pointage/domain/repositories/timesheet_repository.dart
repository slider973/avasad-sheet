import '../../data/models/generated_pdf/generated_pdf.dart';
import '../../use_cases/get_remaining_vacation_days_usecase.dart';
import '../entities/timesheet_entry.dart';

abstract class TimesheetRepository {
  Future<int> saveTimesheetEntry(TimesheetEntry entry);

  Future<List<TimesheetEntry>> getTimesheetEntries();
  Future<void> deleteTimeSheet(int id);

  Future<List<TimesheetEntry>> getTimesheetEntriesForWeek(int weekNumber);

  Future<List<TimesheetEntry>> findEntriesFromMonthOf(int monthNumber, int? year);

  Future<List<TimesheetEntry>> getTimesheetEntriesForMonth(int monthNumber);

  Future<void> saveGeneratedPdf(GeneratedPdfModel pdf);

  Future<List<GeneratedPdfModel>> getGeneratedPdfs();

  Future<void> deleteGeneratedPdf(int pdfId);
  Future<TimesheetEntry?> getTimesheetEntryForDate(String date);
  Future<TimesheetEntry?> getTimesheetEntry(String formattedDate);
  Future<TimesheetEntry?> getTimesheetEntryWhitFrenchFormat(String formattedDate);
  Future<int> getVacationDaysCount();
  Future<int> getLastYearVacationDaysCount();
  Future<VacationDaysInfo> getVacationDaysInfo();
}
