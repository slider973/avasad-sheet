import '../entities/timesheet_entry.dart';
import '../repositories/timesheet_repository.dart';

class FindPointedListUseCase {
  final TimesheetRepository repository;

  FindPointedListUseCase(this.repository);

  Future<List<TimesheetEntry>> execute() async {
    return await repository.getTimesheetEntries();
  }
}