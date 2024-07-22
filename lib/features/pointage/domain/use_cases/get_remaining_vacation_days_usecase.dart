import '../repositories/timesheet_repository.dart';
import 'package:intl/intl.dart';

class GetRemainingVacationDaysUseCase {
  final TimesheetRepository _repository;

  GetRemainingVacationDaysUseCase(this._repository);

  Future<int> execute() async {
    final DateTime now = DateTime.now();
    final DateTime startOfYear = DateTime(now.year, 1, 1);
    int usedVacationDays = 0;

    for (DateTime date = startOfYear; date.isBefore(now); date = date.add(const Duration(days: 1))) {
      final entry = await _repository.getTimesheetEntry(DateFormat("dd-MMM-yy").format(date));
      if (entry != null && entry.absenceReason?.toLowerCase().contains('congé') == true) {
        usedVacationDays++;
      }
    }

    // Supposons un total de 25 jours de congés par an (à ajuster selon vos règles)
    int totalVacationDays = 25;
    return totalVacationDays - usedVacationDays;
  }
}