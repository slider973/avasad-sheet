import '../repositories/absence_repository.dart';
import '../value_objects/absence_type.dart';

class GetAbsenceStatisticsUseCase {
  final AbsenceRepository _repository;

  GetAbsenceStatisticsUseCase(this._repository);

  Future<int> getVacationDaysUsedThisYear() async {
    final currentYear = DateTime.now().year;
    return await _repository.getAbsenceCountForYear(currentYear, AbsenceType.vacation);
  }

  Future<int> getSickLeaveDaysUsedThisYear() async {
    final currentYear = DateTime.now().year;
    return await _repository.getAbsenceCountForYear(currentYear, AbsenceType.sickLeave);
  }

  Future<Map<AbsenceType, int>> getAbsenceStatisticsForYear(int year) async {
    final statistics = <AbsenceType, int>{};
    
    for (final type in AbsenceType.values) {
      final count = await _repository.getAbsenceCountForYear(year, type);
      statistics[type] = count;
    }
    
    return statistics;
  }
}