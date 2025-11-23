import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense.dart';
import '../entities/expense_report.dart';

/// Interface du repository pour la gestion des dépenses
abstract class ExpenseRepository {
  /// Crée une nouvelle dépense
  Future<Either<Failure, Expense>> createExpense(Expense expense);

  /// Récupère une dépense par son ID
  Future<Either<Failure, Expense>> getExpenseById(int id);

  /// Récupère toutes les dépenses d'un mois
  Future<Either<Failure, List<Expense>>> getExpensesForMonth(
      int month, int year);

  /// Récupère toutes les dépenses
  Future<Either<Failure, List<Expense>>> getAllExpenses();

  /// Met à jour une dépense existante
  Future<Either<Failure, Expense>> updateExpense(Expense expense);

  /// Supprime une dépense
  Future<Either<Failure, bool>> deleteExpense(int id);

  /// Génère un rapport mensuel de frais
  Future<Either<Failure, ExpenseReport>> getMonthlyReport(int month, int year);

  /// Récupère les dépenses non synchronisées
  Future<Either<Failure, List<Expense>>> getUnsyncedExpenses();

  /// Marque une dépense comme synchronisée
  Future<Either<Failure, bool>> markAsSynced(int id);
}
