import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/employee_timesheet_entry.dart';
import '../repositories/manager_repository.dart';

/// Use case pour récupérer les pointages mensuels d'un employé de l'équipe.
class GetEmployeeTimesheetUseCase {
  final ManagerRepository repository;

  GetEmployeeTimesheetUseCase({required this.repository});

  Future<Either<Failure, List<EmployeeTimesheetEntry>>> execute({
    required String employeeId,
    required int month,
    required int year,
  }) {
    if (employeeId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('ID de l\'employé requis')),
      );
    }
    return repository.getEmployeeTimesheet(
      employeeId: employeeId,
      month: month,
      year: year,
    );
  }
}
