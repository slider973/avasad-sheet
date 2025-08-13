

import '../entities/timesheet_entry.dart';
import '../repositories/timesheet_repository.dart';

class SaveTimesheetEntryUseCase {
  final TimesheetRepository repository;

  SaveTimesheetEntryUseCase(this.repository);

  Future<int> execute(TimesheetEntry entry) async {
    return await repository.saveTimesheetEntry(entry);
  }
}
