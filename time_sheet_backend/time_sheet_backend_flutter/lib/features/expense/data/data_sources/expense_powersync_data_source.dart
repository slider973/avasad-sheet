import 'package:intl/intl.dart';
import 'package:powersync/powersync.dart';

import '../../../../core/services/supabase/supabase_service.dart';
import '../../domain/entities/expense_category.dart';
import '../models/expense_model.dart';

/// PowerSync-based data source for expenses. Replaces the Isar-based ExpenseLocalDataSource.
class ExpensePowerSyncDataSource {
  final PowerSyncDatabase db;

  ExpensePowerSyncDataSource({required this.db});

  String get _userId => SupabaseService.instance.currentUserId ?? '';

  Future<ExpenseModel> saveExpense(ExpenseModel expense) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(expense.date);

    if (expense.uuid != null) {
      // Update existing
      await db.execute(
        '''UPDATE expenses SET date = ?, category = ?, description = ?,
          currency = ?, amount = ?, mileage_rate = ?, distance_km = ?,
          departure_location = ?, arrival_location = ?, attachment_url = ?,
          is_approved = ?, manager_comment = ?
          WHERE id = ?''',
        [
          dateStr, expense.category.name, expense.description ?? '',
          expense.currency, expense.amount, expense.mileageRate,
          expense.distanceKm, expense.departureLocation ?? '',
          expense.arrivalLocation ?? '', expense.attachmentPath ?? '',
          expense.isApproved ? 1 : 0, expense.managerComment ?? '',
          expense.uuid,
        ],
      );
    } else {
      // Insert new
      await db.execute(
        '''INSERT INTO expenses (id, user_id, date, category, description,
          currency, amount, mileage_rate, distance_km, departure_location,
          arrival_location, attachment_url, is_approved, manager_comment)
          VALUES (uuid(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          _userId, dateStr, expense.category.name, expense.description ?? '',
          expense.currency, expense.amount, expense.mileageRate,
          expense.distanceKm, expense.departureLocation ?? '',
          expense.arrivalLocation ?? '', expense.attachmentPath ?? '',
          expense.isApproved ? 1 : 0, expense.managerComment ?? '',
        ],
      );
    }

    return expense;
  }

  Future<ExpenseModel?> getExpenseById(int id) async {
    final rows = await db.getAll(
      'SELECT * FROM expenses WHERE user_id = ?',
      [_userId],
    );

    for (final row in rows) {
      if ((row['id'] as String).hashCode == id) {
        return _rowToModel(row);
      }
    }
    return null;
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    final rows = await db.getAll(
      'SELECT * FROM expenses WHERE user_id = ? ORDER BY date DESC',
      [_userId],
    );
    return rows.map((row) => _rowToModel(row)).toList();
  }

  Future<List<ExpenseModel>> getExpensesForMonth(int month, int year) async {
    final startDate = DateFormat('yyyy-MM-dd').format(DateTime(year, month, 1));
    final endDate = DateFormat('yyyy-MM-dd').format(DateTime(year, month + 1, 0));

    final rows = await db.getAll(
      'SELECT * FROM expenses WHERE user_id = ? AND date >= ? AND date <= ? ORDER BY date',
      [_userId, startDate, endDate],
    );
    return rows.map((row) => _rowToModel(row)).toList();
  }

  Future<bool> deleteExpense(int id) async {
    final rows = await db.getAll(
      'SELECT id FROM expenses WHERE user_id = ?',
      [_userId],
    );

    for (final row in rows) {
      if ((row['id'] as String).hashCode == id) {
        await db.execute('DELETE FROM expenses WHERE id = ?', [row['id']]);
        return true;
      }
    }
    return false;
  }

  Future<List<ExpenseModel>> getUnsyncedExpenses() async {
    // With PowerSync, all data syncs automatically. Return empty.
    return [];
  }

  Future<void> markAsSynced(int id) async {
    // No-op with PowerSync - sync is automatic
  }

  ExpenseModel _rowToModel(Map<String, dynamic> row) {
    final model = ExpenseModel();
    model.id = (row['id'] as String).hashCode;
    model.uuid = row['id'] as String;
    model.date = DateTime.parse(row['date'] as String);
    model.category = ExpenseCategory.values.firstWhere(
      (e) => e.name == (row['category'] as String? ?? 'other'),
      orElse: () => ExpenseCategory.other,
    );
    model.description = row['description'] as String? ?? '';
    model.currency = row['currency'] as String? ?? 'CHF';
    model.amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
    model.mileageRate = (row['mileage_rate'] as num?)?.toDouble();
    model.distanceKm = row['distance_km'] as int?;
    model.departureLocation = row['departure_location'] as String?;
    model.arrivalLocation = row['arrival_location'] as String?;
    model.attachmentPath = row['attachment_url'] as String?;
    model.isApproved = (row['is_approved'] as int? ?? 0) == 1;
    model.managerComment = row['manager_comment'] as String?;
    model.isSynced = true; // Always synced with PowerSync
    return model;
  }
}
