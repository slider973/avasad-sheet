import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/expense_repository.dart';

/// Use case pour supprimer une dépense
class DeleteExpenseUseCase {
  final ExpenseRepository repository;

  DeleteExpenseUseCase({required this.repository});

  Future<Either<Failure, bool>> execute(int id) {
    return repository.deleteExpense(id);
  }
}
