

import '../domain/entities/timesheet_entry.dart';
import '../domain/repositories/timesheet_repository.dart';

class DeleteTimesheetEntryUsecase {
  final TimesheetRepository repository;

  DeleteTimesheetEntryUsecase(this.repository);

  Future<void> execute(TimesheetEntry entry) async {
    await repository.deleteTimeSheet(entry.id!);
  }
}
