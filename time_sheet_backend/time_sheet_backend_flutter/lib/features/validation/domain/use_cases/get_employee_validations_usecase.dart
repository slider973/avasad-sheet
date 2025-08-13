import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import '../entities/validation_request.dart';
import '../repositories/validation_repository.dart';

/// Use case pour récupérer les validations d'un employé
class GetEmployeeValidationsUseCase implements UseCase<List<ValidationRequest>, String> {
  final ValidationRepository repository;
  
  const GetEmployeeValidationsUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<ValidationRequest>>> call(String employeeId) async {
    if (employeeId.isEmpty) {
      return Left(ValidationFailure('L\'ID de l\'employé est requis'));
    }
    
    return await repository.getEmployeeValidations(employeeId);
  }
}

