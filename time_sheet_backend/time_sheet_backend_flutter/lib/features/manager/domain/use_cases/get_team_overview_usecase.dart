import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/team_overview.dart';
import '../repositories/manager_repository.dart';

/// Use case pour récupérer la vue d'ensemble de l'équipe du manager.
class GetTeamOverviewUseCase {
  final ManagerRepository repository;

  GetTeamOverviewUseCase({required this.repository});

  Future<Either<Failure, TeamOverview>> execute() {
    return repository.getTeamOverview();
  }
}
