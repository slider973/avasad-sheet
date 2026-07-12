import 'package:powersync/powersync.dart';

import '../../../../core/services/supabase/supabase_service.dart';
import 'manager_data_source.dart';

/// Data source PowerSync pour l'espace manager.
///
/// Regroupe les requêtes SQL auparavant dispersées dans le
/// `ManagerDashboardBloc` et les pages manager.
class ManagerPowerSyncDataSource implements ManagerDataSource {
  final PowerSyncDatabase db;

  ManagerPowerSyncDataSource({required this.db});

  String get _managerId => SupabaseService.instance.currentUserId ?? '';

  @override
  Future<List<Map<String, dynamic>>> getTeamEmployees() {
    return db.getAll(
      '''SELECT p.id, p.first_name, p.last_name, p.email
          FROM profiles p
          JOIN manager_employees me ON me.employee_id = p.id
          WHERE me.manager_id = ?''',
      [_managerId],
    );
  }

  @override
  Future<Map<String, dynamic>?> getTodayEntry(
      String employeeId, String today) {
    return db.getOptional(
      'SELECT * FROM timesheet_entries WHERE user_id = ? AND day_date = ?',
      [employeeId, today],
    );
  }

  @override
  Future<Map<String, dynamic>?> getCurrentAbsence(
      String employeeId, String today) {
    return db.getOptional(
      "SELECT * FROM absences WHERE user_id = ? AND start_date <= ? AND end_date >= ?",
      [employeeId, today, today],
    );
  }

  @override
  Future<int> countPendingValidations() async {
    final row = await db.getOptional(
      "SELECT COUNT(*) as count FROM validation_requests WHERE manager_id = ? AND status = 'pending'",
      [_managerId],
    );
    return row?['count'] as int? ?? 0;
  }

  @override
  Future<int> countPendingExpenses() async {
    final row = await db.getOptional(
      '''SELECT COUNT(*) as count FROM expenses e
          JOIN manager_employees me ON me.employee_id = e.user_id
          WHERE me.manager_id = ? AND e.is_approved = 0 AND e.approved_at IS NULL''',
      [_managerId],
    );
    return row?['count'] as int? ?? 0;
  }

  @override
  Future<int> countUnresolvedAnomalies() async {
    final row = await db.getOptional(
      '''SELECT COUNT(*) as count FROM anomalies a
          JOIN manager_employees me ON me.employee_id = a.user_id
          WHERE me.manager_id = ? AND a.is_resolved = 0''',
      [_managerId],
    );
    return row?['count'] as int? ?? 0;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingValidations() {
    return db.getAll(
      '''SELECT vr.*, p.first_name, p.last_name
         FROM validation_requests vr
         JOIN profiles p ON p.id = vr.employee_id
         WHERE vr.manager_id = ? AND vr.status = 'pending'
         ORDER BY vr.created_at DESC''',
      [_managerId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingExpenses() {
    // NB : `approved_at IS NULL` exclut les notes déjà traitées. La table
    // n'a pas de colonne `status` : un rejet est encodé is_approved = 0 +
    // approved_at renseigné (voir [rejectExpense]).
    return db.getAll(
      '''SELECT e.*, p.first_name, p.last_name
         FROM expenses e
         JOIN manager_employees me ON me.employee_id = e.user_id
         JOIN profiles p ON p.id = e.user_id
         WHERE me.manager_id = ? AND e.is_approved = 0 AND e.approved_at IS NULL
         ORDER BY e.date DESC''',
      [_managerId],
    );
  }

  @override
  Future<void> approveExpense(String expenseId) async {
    await db.execute(
      'UPDATE expenses SET is_approved = 1, approved_by = ?, approved_at = ? WHERE id = ?',
      [_managerId, DateTime.now().toIso8601String(), expenseId],
    );
  }

  @override
  Future<void> rejectExpense(String expenseId) async {
    // La table expenses n'a pas de colonne `status` (voir schema.dart et
    // migration 00001) : le rejet est tracé par symétrie avec l'approbation
    // (approved_by = manager, approved_at = date de décision) en laissant
    // is_approved à 0. Les requêtes "en attente" filtrent sur
    // approved_at IS NULL pour exclure les notes traitées.
    await db.execute(
      'UPDATE expenses SET is_approved = 0, approved_by = ?, approved_at = ? WHERE id = ?',
      [_managerId, DateTime.now().toIso8601String(), expenseId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getTeamAnomalies() {
    return db.getAll(
      '''SELECT a.*, p.first_name, p.last_name
         FROM anomalies a
         JOIN manager_employees me ON me.employee_id = a.user_id
         JOIN profiles p ON p.id = a.user_id
         WHERE me.manager_id = ? AND a.is_resolved = 0
         ORDER BY a.detected_date DESC''',
      [_managerId],
    );
  }

  @override
  Future<void> resolveAnomaly(String anomalyId) async {
    // Même UPDATE qu'avant le refactor : la policy RLS 00016 autorise
    // désormais ce PATCH côté serveur pour les managers.
    await db.execute(
      'UPDATE anomalies SET is_resolved = 1 WHERE id = ?',
      [anomalyId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getEmployeeTimesheet(
      String employeeId, String startDate, String endDate) {
    return db.getAll(
      '''SELECT * FROM timesheet_entries
         WHERE user_id = ? AND day_date >= ? AND day_date <= ?
         ORDER BY day_date ASC''',
      [employeeId, startDate, endDate],
    );
  }

  @override
  Future<String?> getCurrentUserRole() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) return null;

    final row = await db.getOptional(
      'SELECT role FROM profiles WHERE id = ?',
      [userId],
    );
    return row?['role'] as String?;
  }
}
