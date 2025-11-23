import 'package:isar/isar.dart';
import '../models/expense_model.dart';

/// Data source local pour les dépenses (Isar)
class ExpenseLocalDataSource {
  final Isar isar;

  ExpenseLocalDataSource({required this.isar});

  /// Sauvegarde une dépense
  Future<ExpenseModel> saveExpense(ExpenseModel expense) async {
    await isar.writeTxn(() async {
      await isar.expenseModels.put(expense);
    });
    return expense;
  }

  /// Récupère une dépense par ID
  Future<ExpenseModel?> getExpenseById(int id) async {
    return await isar.expenseModels.get(id);
  }

  /// Récupère toutes les dépenses
  Future<List<ExpenseModel>> getAllExpenses() async {
    return await isar.expenseModels.where().sortByDateDesc().findAll();
  }

  /// Récupère les dépenses d'un mois spécifique
  Future<List<ExpenseModel>> getExpensesForMonth(int month, int year) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return await isar.expenseModels
        .filter()
        .dateBetween(startDate, endDate)
        .sortByDate()
        .findAll();
  }

  /// Supprime une dépense
  Future<bool> deleteExpense(int id) async {
    return await isar.writeTxn(() async {
      return await isar.expenseModels.delete(id);
    });
  }

  /// Récupère les dépenses non synchronisées
  Future<List<ExpenseModel>> getUnsyncedExpenses() async {
    return await isar.expenseModels
        .filter()
        .isSyncedEqualTo(false)
        .sortByDate()
        .findAll();
  }

  /// Marque une dépense comme synchronisée
  Future<void> markAsSynced(int id) async {
    await isar.writeTxn(() async {
      final expense = await isar.expenseModels.get(id);
      if (expense != null) {
        expense.isSynced = true;
        await isar.expenseModels.put(expense);
      }
    });
  }
}
