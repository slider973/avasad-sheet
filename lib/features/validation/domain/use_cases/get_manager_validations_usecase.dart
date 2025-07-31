import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import '../entities/validation_request.dart';
import '../repositories/validation_repository.dart';
import './get_employee_validations_usecase.dart';

/// Use case pour récupérer les validations qu'un manager doit traiter
class GetManagerValidationsUseCase implements UseCase<List<ValidationRequest>, String> {
  final ValidationRepository repository;
  
  const GetManagerValidationsUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<ValidationRequest>>> call(String managerId) async {
    if (managerId.isEmpty) {
      return Left(ValidationFailure('L\'ID du manager est requis'));
    }
    
    return await repository.getManagerValidations(managerId);
  }
}