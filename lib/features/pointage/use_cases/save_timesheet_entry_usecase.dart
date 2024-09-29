

import '../domain/entities/timesheet_entry.dart';
import '../domain/repositories/timesheet_repository.dart';

class SaveTimesheetEntryUseCase {
  final TimesheetRepository repository;

  SaveTimesheetEntryUseCase(this.repository);

  Future<int> execute(TimesheetEntry entry) async {
    return await repository.saveTimesheetEntry(entry);
  }
}
