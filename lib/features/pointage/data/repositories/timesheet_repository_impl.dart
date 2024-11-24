import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/data/models/generated_pdf/generated_pdf.dart';
import 'package:time_sheet/features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
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
  Future<int> saveTimesheetEntry(TimesheetEntry entry) async {
    logger.i('inserting ${entry.toString()}');
    final entryModel = TimesheetEntryMapper.toModel(entry);
    return await datasource.saveTimeSheet(entryModel);
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

  @override
  Future<TimesheetEntry?> getTimesheetEntryForDate(String date) async {
    final entries = await datasource.getTimesheetEntries();
    final TimeSheetEntryModel entry = entries.firstWhere(
      (entry) => DateFormat("dd-MMM-yy").format(entry.dayDate) == date,
      orElse: () {
        final model = TimeSheetEntryModel()
          ..dayDate = DateTime.now()
          ..dayOfWeekDate = '';
        return model;
      },
    );

    // Si l'entrée est celle par défaut, retourne null
    if (DateFormat("dd-MMM-yy").format(entry.dayDate) != date) {
      return null;
    }
    if (entry.dayOfWeekDate.isEmpty) {
      return null;
    }

    return TimesheetEntryMapper.fromModel(entry);
  }

  @override
  Future<void> deleteTimeSheet(int id) {
    return datasource.deleteTimeSheet(id);
  }

  @override
  Future<TimesheetEntry?> getTimesheetEntry(String formattedDate) {
    return datasource.getTimesheetEntry(formattedDate).then((entry) {
      if (entry == null) {
        return null;
      }
      return TimesheetEntryMapper.fromModel(entry);
    });
  }

  @override
  Future<TimesheetEntry?> getTimesheetEntryWhitFrenchFormat(String formattedDate) async {
    final entry = await datasource.getTimesheetEntryWhitFrenchFormat(formattedDate);
    if (entry == null) {
      return null;
    }
    return TimesheetEntryMapper.fromModel(entry);
  }

  @override
  Future<int> getVacationDaysCount() {
    return datasource.getVacationDaysCount();
  }
}
