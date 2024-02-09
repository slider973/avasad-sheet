import 'package:isar/isar.dart';
import 'package:time_sheet/pdf/data/models/timesheet_entry.dart';
import 'package:time_sheet/services/logger_service.dart';

import '../../domain/data_source/time_sheet.dart';

class LocalDatasourceImpl implements LocalDataSource {
  Isar isar;

  LocalDatasourceImpl(this.isar);

  @override
  Future<void> saveTimeSheet(TimeSheetEntryModel entryModel) async {
    isar.writeTxn(
      () async => await isar.timeSheetEntryModels.put(entryModel),
    );
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
}
