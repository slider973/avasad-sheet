import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/employee_timesheet_entry.dart';
import '../entities/pending_expense.dart';
import '../entities/pending_validation.dart';
import '../entities/team_anomaly.dart';
import '../entities/team_overview.dart';

/// Interface du repository pour l'espace manager (équipe, approbations,
/// anomalies). Le manager courant est résolu par la couche data.
abstract class ManagerRepository {
  /// Vue d'ensemble de l'équipe (membres + compteurs en attente).
  Future<Either<Failure, TeamOverview>> getTeamOverview();

  /// Demandes de validation de timesheet en attente.
  Future<Either<Failure, List<PendingValidation>>> getPendingValidations();

  /// Notes de frais de l'équipe en attente d'approbation.
  Future<Either<Failure, List<PendingExpense>>> getPendingExpenses();

  /// Approuve une note de frais.
  Future<Either<Failure, void>> approveExpense(String expenseId);

  /// Rejette une note de frais.
  Future<Either<Failure, void>> rejectExpense(String expenseId);

  /// Anomalies non résolues de l'équipe.
  Future<Either<Failure, List<TeamAnomaly>>> getTeamAnomalies();

  /// Marque une anomalie comme résolue.
  Future<Either<Failure, void>> resolveTeamAnomaly(String anomalyId);

  /// Pointages d'un employé pour un mois donné.
  Future<Either<Failure, List<EmployeeTimesheetEntry>>> getEmployeeTimesheet({
    required String employeeId,
    required int month,
    required int year,
  });

  /// Rôle de l'utilisateur courant ('employee' par défaut).
  Future<Either<Failure, String>> getCurrentUserRole();
}
