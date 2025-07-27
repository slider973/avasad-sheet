import '../../data/models/generated_pdf/generated_pdf.dart';
import '../../data/models/timesheet_entry/timesheet_entry.dart';
import '../../domain/entities/timesheet_entry.dart';

abstract class LocalDataSource {
  Future<int> saveTimeSheet(TimeSheetEntryModel entryModel);

  Future<List<TimeSheetEntryModel>> getTimesheetEntries();

  Future<List<TimeSheetEntryModel>> getTimesheetEntriesForWeek(int weekNumber);

  Future<List<TimeSheetEntryModel>> findEntriesFromMonthOf(int monthNumber, int year);

  Future<void> saveGeneratedPdf(GeneratedPdfModel pdf);

  Future<List<GeneratedPdfModel>> getGeneratedPdfs();

  Future<void> deleteGeneratedPdf(int pdfId);
  Future<TimesheetEntry?> getTimesheetEntryForDate(String date);

  Future<void> deleteTimeSheet(int id) async {}
  Future<int> getLastYearVacationDaysCount();

  getTimesheetEntry(String formattedDate) {}
  getTimesheetEntryWhitFrenchFormat(String formattedDate) {}
  Future<int> getVacationDaysCount();
  
  // Nouvelles méthodes pour les heures supplémentaires
  Future<TimeSheetEntryModel?> getTimesheetEntryById(int id);
  Future<void> updateTimesheetEntry(TimeSheetEntryModel entry);
  Future<List<TimeSheetEntryModel>> getTimesheetEntriesForPeriod(DateTime startDate, DateTime endDate);
}
