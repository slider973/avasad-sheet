
import 'package:intl/intl.dart';

import '../domain/repositories/timesheet_repository.dart';

class GetRemainingVacationDaysUseCase {
  final TimesheetRepository _repository;

  GetRemainingVacationDaysUseCase(this._repository);

  Future<VacationDaysInfo> execute() async {
    final DateTime now = DateTime.now();
    final DateTime startOfYear = DateTime(now.year, 1, 1);

    // Obtenir les jours utilisés cette année
    int usedVacationDays = await _repository.getVacationDaysCount();

    // Obtenir les jours non utilisés de l'année précédente
    int lastYearRemainingDays = await _repository.getLastYearVacationDaysCount();

    // Total des jours disponibles pour l'année en cours
    int totalVacationDays = 25 + lastYearRemainingDays;

    return VacationDaysInfo(
        currentYearTotal: 25,
        lastYearRemaining: lastYearRemainingDays,
        usedDays: usedVacationDays,
        remainingTotal: totalVacationDays - usedVacationDays
    );
  }
}

class VacationDaysInfo {
  final int currentYearTotal;
  final int lastYearRemaining;
  final int usedDays;
  final int remainingTotal;

  VacationDaysInfo({
    required this.currentYearTotal,
    required this.lastYearRemaining,
    required this.usedDays,
    required this.remainingTotal,
  });
}
