import '../entities/timesheet_entry.dart';
import '../repositories/timesheet_repository.dart';

class SaveTimesheetEntryUseCase {
  final TimesheetRepository repository;

  SaveTimesheetEntryUseCase(this.repository);

  Future<void> execute(TimesheetEntry entry) async {
    await repository.saveTimesheetEntry(entry);
  }
}
