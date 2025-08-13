import '../entities/absence_entity.dart';
import '../repositories/absence_repository.dart';
import '../value_objects/absence_type.dart';

class GetAbsencesUseCase {
  final AbsenceRepository _repository;

  GetAbsencesUseCase(this._repository);

  Future<List<AbsenceEntity>> execute() async {
    return await _repository.getAbsences();
  }

  Future<List<AbsenceEntity>> executeForDateRange(DateTime startDate, DateTime endDate) async {
    return await _repository.getAbsencesForDateRange(startDate, endDate);
  }

  Future<List<AbsenceEntity>> executeByType(AbsenceType type) async {
    return await _repository.getAbsencesByType(type);
  }
}