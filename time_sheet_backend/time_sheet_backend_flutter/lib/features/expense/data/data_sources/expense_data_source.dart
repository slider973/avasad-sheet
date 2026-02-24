import '../models/expense_model.dart';

/// Abstract interface for expense data sources.
/// Both the Isar and PowerSync implementations implement this interface.
abstract class ExpenseDataSource {
  Future<ExpenseModel> saveExpense(ExpenseModel expense);
  Future<ExpenseModel?> getExpenseById(int id);
  Future<List<ExpenseModel>> getAllExpenses();
  Future<List<ExpenseModel>> getExpensesForMonth(int month, int year);
  Future<bool> deleteExpense(int id);
  Future<List<ExpenseModel>> getUnsyncedExpenses();
  Future<void> markAsSynced(int id);
}
