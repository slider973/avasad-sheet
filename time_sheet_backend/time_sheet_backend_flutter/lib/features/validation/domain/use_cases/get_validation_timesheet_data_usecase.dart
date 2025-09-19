import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import '../repositories/validation_repository.dart';

/// Use case pour récupérer les données timesheet d'une validation
class GetValidationTimesheetDataUseCase
    implements UseCase<Map<String, dynamic>, String> {
  final ValidationRepository repository;

  GetValidationTimesheetDataUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
      String validationId) async {
    return await repository.getValidationTimesheetData(validationId);
  }
}
