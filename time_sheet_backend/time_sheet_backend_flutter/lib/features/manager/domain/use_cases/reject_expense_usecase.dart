import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/manager_repository.dart';

/// Use case pour rejeter une note de frais d'un membre de l'équipe.
class RejectExpenseUseCase {
  final ManagerRepository repository;

  RejectExpenseUseCase({required this.repository});

  Future<Either<Failure, void>> execute(String expenseId) {
    if (expenseId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('ID de la dépense requis')),
      );
    }
    return repository.rejectExpense(expenseId);
  }
}
