import 'package:isar/isar.dart';
import 'package:time_sheet/features/pointage/data/models/timesheet_entry/timesheet_entry.dart';

import '../../../../services/logger_service.dart';
import '../../domain/mapper/timesheetEntry.mapper.dart';
import 'test_data.dart';


class TestDataInserter {
  final Isar isar;

  TestDataInserter(this.isar);

  // Future<void> insertTestData() async {
  //   await isar.writeTxn(() async {
  //     for (var entry in testData) {
  //       logger.i('inserting $entry');
  //       final entryModel = TimesheetEntryMapper.toModel(entry);
  //     await isar.timeSheetEntryModels.put(entryModel); // insert & update
  //     }
  //   });
  // }
}
