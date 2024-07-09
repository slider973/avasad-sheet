import 'package:time_sheet/features/time_sheet/data/models/generated_pdf/generated_pdf.dart';
import 'package:time_sheet/services/logger_service.dart';

import '../../domain/data_source/time_sheet.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/mapper/timesheetEntry.mapper.dart';
import '../../domain/repositories/timesheet_repository.dart';
import '../utils/time_sheet_utils.dart';

class TimesheetRepositoryImpl implements TimesheetRepository {
  final LocalDataSource datasource;

  TimesheetRepositoryImpl(this.datasource);

  @override
  Future<void> saveTimesheetEntry(TimesheetEntry entry) async {
    logger.i('inserting ${entry.toString()}');
    final entryModel = TimesheetEntryMapper.toModel(entry);
    await datasource.saveTimeSheet(entryModel);
  }

  @override
  Future<List<TimesheetEntry>> getTimesheetEntries() async {
    final entries = await datasource.getTimesheetEntries();
    return entries.map((e) => TimesheetEntryMapper.fromModel(e)).toList();
  }

  @override
  Future<List<TimesheetEntry>> getTimesheetEntriesForWeek(
      int weekNumber) async {
    final allEntries = await datasource.getTimesheetEntries();

    return allEntries
        .where((entry) {
          return TimeSheetUtils.getWeekNumber(entry.dayDate) == weekNumber;
        })
        .map((e) => TimesheetEntryMapper.fromModel(e))
        .toList();
  }

  @override
  Future<List<TimesheetEntry>> findEntriesFromMonthOf(int monthNumber) {
    logger.i('findEntriesFromMonthOf $monthNumber');
    return datasource.findEntriesFromMonthOf(monthNumber).then((entries) {
      return entries.map((e) => TimesheetEntryMapper.fromModel(e)).toList();
    });
  }

  @override
  Future<List<TimesheetEntry>> getTimesheetEntriesForMonth(int monthNumber) {
    final allEntries = datasource.getTimesheetEntries();
    return allEntries.then((entries) {
      return entries
          .where((entry) {
            return TimeSheetUtils.getMonthNumber(entry.dayDate) == monthNumber;
          })
          .map((e) => TimesheetEntryMapper.fromModel(e))
          .toList();
    });
  }

  @override
  Future<List<GeneratedPdfModel>> getGeneratedPdfs() {
   return datasource.getGeneratedPdfs();
  }

  @override
  Future<void> saveGeneratedPdf(GeneratedPdfModel pdf) async {
    await datasource.saveGeneratedPdf(pdf);
  }

  @override
  Future<void> deleteGeneratedPdf(int pdfId) {
    return datasource.deleteGeneratedPdf(pdfId);
  }
}
