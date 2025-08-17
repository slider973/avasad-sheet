import 'package:isar/isar.dart';

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
