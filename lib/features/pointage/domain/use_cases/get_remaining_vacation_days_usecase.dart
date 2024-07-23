import '../repositories/timesheet_repository.dart';
import 'package:intl/intl.dart';

class GetRemainingVacationDaysUseCase {
  final TimesheetRepository _repository;

  GetRemainingVacationDaysUseCase(this._repository);

  Future<int> execute() async {
    final DateTime now = DateTime.now();
    final DateTime startOfYear = DateTime(now.year, 1, 1);
    int usedVacationDays = await _repository.getVacationDaysCount();

    // Supposons un total de 25 jours de congés par an (à ajuster selon vos règles)
    int totalVacationDays = 25;
    return totalVacationDays - usedVacationDays;
  }
}
