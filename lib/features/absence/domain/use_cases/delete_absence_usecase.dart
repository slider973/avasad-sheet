import '../repositories/absence_repository.dart';

class DeleteAbsenceUseCase {
  final AbsenceRepository _repository;

  DeleteAbsenceUseCase(this._repository);

  Future<void> execute(int absenceId) async {
    if (absenceId <= 0) {
      throw ArgumentError('Invalid absence ID');
    }
    
    await _repository.deleteAbsence(absenceId);
  }
}