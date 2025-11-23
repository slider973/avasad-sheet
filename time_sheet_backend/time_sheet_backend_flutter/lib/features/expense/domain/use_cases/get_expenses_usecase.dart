import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

/// Use case pour récupérer les dépenses
class GetExpensesUseCase {
  final ExpenseRepository repository;

  GetExpensesUseCase({required this.repository});

  /// Récupère toutes les dépenses
  Future<Either<Failure, List<Expense>>> getAllExpenses() {
    return repository.getAllExpenses();
  }

  /// Récupère les dépenses d'un mois spécifique
  Future<Either<Failure, List<Expense>>> getExpensesForMonth(
      int month, int year) {
    return repository.getExpensesForMonth(month, year);
  }

  /// Récupère une dépense par son ID
  Future<Either<Failure, Expense>> getExpenseById(int id) {
    return repository.getExpenseById(id);
  }
}
