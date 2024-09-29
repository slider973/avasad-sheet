

import '../domain/entities/timesheet_entry.dart';
import '../domain/repositories/timesheet_repository.dart';

class GetTimesheetEntriesForWeekUseCase {
  final TimesheetRepository repository;

  GetTimesheetEntriesForWeekUseCase(this.repository);

  Future<List<TimesheetEntry>> execute(int weekNumber) async {
    return await repository.getTimesheetEntriesForWeek(weekNumber);
  }
}
