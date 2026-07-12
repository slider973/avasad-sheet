import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/pending_expense.dart';
import '../repositories/manager_repository.dart';

/// Use case pour récupérer les notes de frais en attente d'approbation.
class GetPendingExpensesUseCase {
  final ManagerRepository repository;

  GetPendingExpensesUseCase({required this.repository});

  Future<Either<Failure, List<PendingExpense>>> execute() {
    return repository.getPendingExpenses();
  }
}
