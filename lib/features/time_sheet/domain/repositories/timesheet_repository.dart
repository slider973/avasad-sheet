import '../../data/models/generated_pdf/generated_pdf.dart';
import '../entities/timesheet_entry.dart';

abstract class TimesheetRepository {
  Future<void> saveTimesheetEntry(TimesheetEntry entry);

  Future<List<TimesheetEntry>> getTimesheetEntries();

  Future<List<TimesheetEntry>> getTimesheetEntriesForWeek(int weekNumber);

  Future<List<TimesheetEntry>> findEntriesFromMonthOf(int monthNumber);

  Future<List<TimesheetEntry>> getTimesheetEntriesForMonth(int monthNumber);

  Future<void> saveGeneratedPdf(GeneratedPdfModel pdf);

  Future<List<GeneratedPdfModel>> getGeneratedPdfs();

  Future<void> deleteGeneratedPdf(int pdfId);
}
