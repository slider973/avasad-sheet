

import '../entities/timesheet_entry.dart';
import '../repositories/timesheet_repository.dart';

class GetTimesheetEntriesForWeekUseCase {
  final TimesheetRepository repository;

  GetTimesheetEntriesForWeekUseCase(this.repository);

  Future<List<TimesheetEntry>> execute(int weekNumber) async {
    return await repository.getTimesheetEntriesForWeek(weekNumber);
  }

  // Ajoutez cette méthode pour récupérer les entrées pour un mois entier
  Future<List<TimesheetEntry>> executeForMonth(int monthNumber) async {
    // Implémentez la logique pour récupérer toutes les entrées du mois
    // Vous devrez peut-être modifier votre repository pour supporter cette fonctionnalité
    return await repository.getTimesheetEntriesForMonth(monthNumber);
  }
}