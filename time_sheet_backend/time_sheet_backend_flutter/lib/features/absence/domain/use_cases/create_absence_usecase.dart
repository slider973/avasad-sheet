import '../entities/absence_entity.dart';
import '../repositories/absence_repository.dart';

class CreateAbsenceUseCase {
  final AbsenceRepository _repository;

  CreateAbsenceUseCase(this._repository);

  Future<int> execute(AbsenceEntity absence) async {
    if (absence.startDate.isAfter(absence.endDate)) {
      throw ArgumentError('Start date must be before or equal to end date');
    }
    
    return await _repository.saveAbsence(absence);
  }
}