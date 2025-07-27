import 'package:time_sheet/features/pointage/domain/repositories/timesheet_repository.dart';

class ToggleOvertimeHoursUseCase {
  final TimesheetRepository repository;

  ToggleOvertimeHoursUseCase(this.repository);

  Future<void> execute({
    required int entryId,
    required bool hasOvertimeHours,
  }) async {
    await repository.toggleOvertimeHours(entryId, hasOvertimeHours);
  }
}