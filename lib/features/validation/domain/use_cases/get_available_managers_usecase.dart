import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import '../repositories/validation_repository.dart';
import './get_employee_validations_usecase.dart';

/// Use case pour récupérer les managers disponibles pour un employé
class GetAvailableManagersUseCase implements UseCase<List<Manager>, String> {
  final ValidationRepository repository;
  
  const GetAvailableManagersUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<Manager>>> call(String employeeId) async {
    if (employeeId.isEmpty) {
      return Left(ValidationFailure('L\'ID de l\'employé est requis'));
    }
    
    return await repository.getAvailableManagers(employeeId);
  }
}