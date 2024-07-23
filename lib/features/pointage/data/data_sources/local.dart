import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:time_sheet/features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/services/logger_service.dart';

import '../../domain/data_source/time_sheet.dart';
import '../../domain/mapper/timesheetEntry.mapper.dart';
import '../models/generated_pdf/generated_pdf.dart';

class LocalDatasourceImpl implements LocalDataSource {
  Isar isar;

  LocalDatasourceImpl(this.isar);

  @override
  Future<int> saveTimeSheet(TimeSheetEntryModel entryModel) async {
    int id = await isar.writeTxn(
      () async => await isar.timeSheetEntryModels.put(entryModel),
    );
    return id;
  }

  @override
  Future<List<TimeSheetEntryModel>> getTimesheetEntries() async {
    return isar.timeSheetEntryModels.where().findAll();
  }

  @override
  Future<List<TimeSheetEntryModel>> getTimesheetEntriesForWeek(int weekNumber) {
    return isar.timeSheetEntryModels.where().findAll();
  }

  @override
  Future<List<TimeSheetEntryModel>> findEntriesFromMonthOf(int monthNumber) {
    logger.i('findEntriesFromMonthOf $monthNumber');
    DateTime now = DateTime.now();

    // Calcul de l'année et du mois précédent
    int previousYear;
    int previousMonth;
    if (monthNumber == 1) {
      previousYear = now.year - 1;
      previousMonth = 12;
    } else {
      previousYear = now.year;
      previousMonth = monthNumber - 1;
    }

    final datePreviousMonth = DateTime(previousYear, previousMonth, 21);
    logger.i(
        'datePreviousMonth $datePreviousMonth with year ${datePreviousMonth.year}');

    // Ajouter un jour pour inclure tout le 20
    final dateCurrentMonth = DateTime(now.year, monthNumber, 21);
    logger.i('dateCurrentMonth $dateCurrentMonth');

    return isar.timeSheetEntryModels
        .filter()
        .dayDateBetween(datePreviousMonth, dateCurrentMonth)
        .findAll();
  }

  @override
  Future<void> saveGeneratedPdf(GeneratedPdfModel pdf) async {
    await isar.writeTxn(() async {
      await isar.generatedPdfModels.put(pdf);
    });
  }

  @override
  Future<List<GeneratedPdfModel>> getGeneratedPdfs() async {
    return await isar.generatedPdfModels.where().findAll();
  }

  @override
  Future<void> deleteGeneratedPdf(int pdfId) {
    return isar.writeTxn(() async {
      await isar.generatedPdfModels.delete(pdfId);
    });
  }

  @override
  Future<TimesheetEntry?> getTimesheetEntryForDate(String date) {
    return isar.timeSheetEntryModels
        .filter()
        .dayDateEqualTo(DateTime.parse(date))
        .findFirst()
        .then((value) =>
            value == null ? null : TimesheetEntryMapper.fromModel(value));
  }

  @override
  Future<void> deleteTimeSheet(int id) {
    return isar.writeTxn(() async {
      await isar.timeSheetEntryModels.delete(id);
    });
  }

  @override
  Future<TimesheetEntry?> getTimesheetEntry(String formattedDate) {
    print(6);
    return isar.timeSheetEntryModels
        .filter()
        .dayDateEqualTo(DateTime.parse(formattedDate))
        .findFirst()
        .then((value) =>
            value == null ? null : TimesheetEntryMapper.fromModel(value));
  }

  @override
  Future<TimesheetEntry?> getTimesheetEntryWhitFrenchFormat(String formattedDate) async {
    final DateFormat formatter = DateFormat("dd-MMM-yyyy", "fr_FR");
    final model = await isar.timeSheetEntryModels
        .filter()
        .dayDateEqualTo(formatter.parse(formattedDate))
        .findFirst();
    return model != null ? TimesheetEntryMapper.fromModel(model) : null;
  }
  @override
  Future<int> getVacationDaysCount() async {
    final DateTime now = DateTime.now();
    final DateTime startOfYear = DateTime(now.year, 1, 1);
    int usedVacationDays = 0;
    final entries = await isar.timeSheetEntryModels
        .filter()
        .dayDateBetween(startOfYear, now)
        .findAll();

    for (var entry in entries) {
      if (entry.absenceReason.toLowerCase().contains('congé')) {
        usedVacationDays++;
      }
    }

    return usedVacationDays;
  }
}
