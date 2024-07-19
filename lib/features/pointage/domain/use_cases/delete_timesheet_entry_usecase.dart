import '../entities/timesheet_entry.dart';
import '../repositories/timesheet_repository.dart';

class DeleteTimesheetEntryUsecase {
  final TimesheetRepository repository;

  DeleteTimesheetEntryUsecase(this.repository);

  Future<void> execute(TimesheetEntry entry) async {
    await repository.deleteTimeSheet(entry.id!);
  }
}
