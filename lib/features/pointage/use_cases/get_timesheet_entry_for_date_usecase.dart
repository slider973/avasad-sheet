

import '../domain/entities/timesheet_entry.dart';
import '../domain/repositories/timesheet_repository.dart';

class GetTimesheetEntryForDateUseCase {
  final TimesheetRepository repository;

  GetTimesheetEntryForDateUseCase(this.repository);

  Future<TimesheetEntry?> execute(String date) async {
    return await repository.getTimesheetEntryForDate(date);
  }
}