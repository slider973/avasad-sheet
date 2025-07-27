import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/repositories/timesheet_repository.dart';

class GetDaysWithOvertimeUseCase {
  final TimesheetRepository repository;

  GetDaysWithOvertimeUseCase(this.repository);

  Future<List<TimesheetEntry>> execute({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final entries = await repository.getAllTimesheetEntryForPeriod(
      startDate: startDate,
      endDate: endDate,
    );
    
    return entries.where((entry) => entry.hasOvertimeHours).toList();
  }
}