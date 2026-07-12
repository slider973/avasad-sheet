import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/pending_validation.dart';
import '../repositories/manager_repository.dart';

/// Use case pour récupérer les validations de timesheet en attente.
class GetPendingValidationsUseCase {
  final ManagerRepository repository;

  GetPendingValidationsUseCase({required this.repository});

  Future<Either<Failure, List<PendingValidation>>> execute() {
    return repository.getPendingValidations();
  }
}
