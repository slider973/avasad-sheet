
import '../domain/entities/timesheet_entry.dart';
import '../domain/repositories/timesheet_repository.dart';

class GetMonthlyTimesheetEntriesUseCase {
  final TimesheetRepository repository;

  GetMonthlyTimesheetEntriesUseCase(this.repository);

  Future<List<TimesheetEntry>> execute(int month) async {
    final years = DateTime.now().year;
    return await repository.findEntriesFromMonthOf(month, years);
  }
}
