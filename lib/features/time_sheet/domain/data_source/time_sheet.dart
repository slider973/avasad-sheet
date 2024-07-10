import '../../data/models/generated_pdf/generated_pdf.dart';
import '../../data/models/timesheet_entry/timesheet_entry.dart';
import '../entities/timesheet_entry.dart';

abstract class LocalDataSource {
  Future<void> saveTimeSheet(TimeSheetEntryModel entryModel);

  Future<List<TimeSheetEntryModel>> getTimesheetEntries();

  Future<List<TimeSheetEntryModel>> getTimesheetEntriesForWeek(int weekNumber);

  Future<List<TimeSheetEntryModel>> findEntriesFromMonthOf(int monthNumber);

  Future<void> saveGeneratedPdf(GeneratedPdfModel pdf);

  Future<List<GeneratedPdfModel>> getGeneratedPdfs();

  Future<void> deleteGeneratedPdf(int pdfId);
  Future<TimesheetEntry?> getTimesheetEntryForDate(String date);
}
