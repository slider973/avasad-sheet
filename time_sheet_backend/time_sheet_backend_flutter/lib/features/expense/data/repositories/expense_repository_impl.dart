import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_report.dart';
import '../../domain/repositories/expense_repository.dart';
import '../data_sources/expense_local_data_source.dart';
import '../models/expense_model.dart';

/// Implémentation du repository Expense avec Isar
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;

  ExpenseRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Expense>> createExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      final savedModel = await localDataSource.saveExpense(model);
      return Right(savedModel.toEntity());
    } catch (e) {
      return Left(GeneralFailure('Erreur lors de la création de la dépense: $e'));
    }
  }

  @override
  Future<Either<Failure, Expense>> getExpenseById(int id) async {
    try {
      final model = await localDataSource.getExpenseById(id);
      if (model == null) {
        return Left(GeneralFailure('Dépense non trouvée'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(GeneralFailure('Erreur lors de la récupération de la dépense: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getAllExpenses() async {
    try {
      final models = await localDataSource.getAllExpenses();
      final expenses = models.map((m) => m.toEntity()).toList();
      return Right(expenses);
    } catch (e) {
      return Left(GeneralFailure('Erreur lors de la récupération des dépenses: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesForMonth(
      int month, int year) async {
    try {
      final models = await localDataSource.getExpensesForMonth(month, year);
      final expenses = models.map((m) => m.toEntity()).toList();
      return Right(expenses);
    } catch (e) {
      return Left(GeneralFailure(
          'Erreur lors de la récupération des dépenses du mois: $e'));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    try {
      if (expense.id == null) {
        return Left(ValidationFailure('ID de la dépense requis pour la mise à jour'));
      }

      final updatedExpense = expense.copyWith(updatedAt: DateTime.now());
      final model = ExpenseModel.fromEntity(updatedExpense);
      final savedModel = await localDataSource.saveExpense(model);
      return Right(savedModel.toEntity());
    } catch (e) {
      return Left(GeneralFailure('Erreur lors de la mise à jour de la dépense: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteExpense(int id) async {
    try {
      final success = await localDataSource.deleteExpense(id);
      return Right(success);
    } catch (e) {
      return Left(GeneralFailure('Erreur lors de la suppression de la dépense: $e'));
    }
  }

  @override
  Future<Either<Failure, ExpenseReport>> getMonthlyReport(
      int month, int year) async {
    try {
      final expensesResult = await getExpensesForMonth(month, year);
      return expensesResult.fold(
        (failure) => Left(failure),
        (expenses) {
          final report = ExpenseReport(
            month: month,
            year: year,
            expenses: expenses,
          );
          return Right(report);
        },
      );
    } catch (e) {
      return Left(GeneralFailure('Erreur lors de la génération du rapport: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getUnsyncedExpenses() async {
    try {
      final models = await localDataSource.getUnsyncedExpenses();
      final expenses = models.map((m) => m.toEntity()).toList();
      return Right(expenses);
    } catch (e) {
      return Left(GeneralFailure(
          'Erreur lors de la récupération des dépenses non synchronisées: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> markAsSynced(int id) async {
    try {
      await localDataSource.markAsSynced(id);
      return const Right(true);
    } catch (e) {
      return Left(GeneralFailure(
          'Erreur lors de la synchronisation de la dépense: $e'));
    }
  }
}
