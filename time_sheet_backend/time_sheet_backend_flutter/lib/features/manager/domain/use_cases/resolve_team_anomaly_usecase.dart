import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/manager_repository.dart';

/// Use case pour marquer une anomalie d'équipe comme résolue.
class ResolveTeamAnomalyUseCase {
  final ManagerRepository repository;

  ResolveTeamAnomalyUseCase({required this.repository});

  Future<Either<Failure, void>> execute(String anomalyId) {
    if (anomalyId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('ID de l\'anomalie requis')),
      );
    }
    return repository.resolveTeamAnomaly(anomalyId);
  }
}
