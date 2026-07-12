import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/team_anomaly.dart';
import '../repositories/manager_repository.dart';

/// Use case pour récupérer les anomalies non résolues de l'équipe.
class GetTeamAnomaliesUseCase {
  final ManagerRepository repository;

  GetTeamAnomaliesUseCase({required this.repository});

  Future<Either<Failure, List<TeamAnomaly>>> execute() {
    return repository.getTeamAnomalies();
  }
}
