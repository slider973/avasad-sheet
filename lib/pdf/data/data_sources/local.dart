import 'package:isar/isar.dart';
import 'package:time_sheet/pdf/data/models/timesheet_entry.dart';

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
}
