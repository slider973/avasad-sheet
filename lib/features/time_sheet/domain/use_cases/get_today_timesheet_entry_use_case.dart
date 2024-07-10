import 'package:intl/intl.dart';

import '../entities/timesheet_entry.dart';
import '../repositories/timesheet_repository.dart';

class GetTodayTimesheetEntryUseCase {
  final TimesheetRepository repository;

  GetTodayTimesheetEntryUseCase(this.repository);

  Future<TimesheetEntry?> execute() async {
    final today = DateFormat("dd-MMM-yy").format(DateTime.now());
    return await repository.getTimesheetEntryForDate(today);
  }
}