import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:powersync/powersync.dart';

import '../../../../core/database/powersync_database.dart';
import '../../../../core/services/supabase/supabase_service.dart';

part 'manager_dashboard_event.dart';
part 'manager_dashboard_state.dart';

class ManagerDashboardBloc extends Bloc<ManagerDashboardEvent, ManagerDashboardState> {
  final PowerSyncDatabase _db;

  ManagerDashboardBloc({PowerSyncDatabase? db})
      : _db = db ?? PowerSyncDatabaseManager.database,
        super(ManagerDashboardInitial()) {
    on<LoadManagerDashboard>(_onLoadDashboard);
    on<RefreshManagerDashboard>(_onRefreshDashboard);
  }

  String get _managerId => SupabaseService.instance.currentUserId ?? '';

  Future<void> _onLoadDashboard(
    LoadManagerDashboard event,
    Emitter<ManagerDashboardState> emit,
  ) async {
    emit(ManagerDashboardLoading());
    await _loadDashboardData(emit);
  }

  Future<void> _onRefreshDashboard(
    RefreshManagerDashboard event,
    Emitter<ManagerDashboardState> emit,
  ) async {
    await _loadDashboardData(emit);
  }

  Future<void> _loadDashboardData(Emitter<ManagerDashboardState> emit) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Get team employees
      final employeeRows = await _db.getAll(
        '''SELECT p.id, p.first_name, p.last_name, p.email
          FROM profiles p
          JOIN manager_employees me ON me.employee_id = p.id
          WHERE me.manager_id = ?''',
        [_managerId],
      );

      // Get today's entries for each employee
      final List<EmployeeStatus> employees = [];
      for (final emp in employeeRows) {
        final empId = emp['id'] as String;

        // Check today's timesheet entry
        final todayEntry = await _db.getOptional(
          'SELECT * FROM timesheet_entries WHERE user_id = ? AND day_date = ?',
          [empId, today],
        );

        // Check for absence
        final absence = await _db.getOptional(
          "SELECT * FROM absences WHERE user_id = ? AND start_date <= ? AND end_date >= ?",
          [empId, today, today],
        );

        final isPresent = todayEntry != null &&
            (todayEntry['start_morning'] as String? ?? '').isNotEmpty;

        employees.add(EmployeeStatus(
          id: empId,
          firstName: emp['first_name'] as String? ?? '',
          lastName: emp['last_name'] as String? ?? '',
          email: emp['email'] as String? ?? '',
          isPresentToday: isPresent,
          lastClockIn: todayEntry?['start_morning'] as String?,
          hasAbsence: absence != null,
          absenceType: absence?['type'] as String?,
        ));
      }

      // Count pending validations
      final pendingValidations = await _db.getOptional(
        "SELECT COUNT(*) as count FROM validation_requests WHERE manager_id = ? AND status = 'pending'",
        [_managerId],
      );

      // Count pending expense approvals
      final pendingExpenses = await _db.getOptional(
        '''SELECT COUNT(*) as count FROM expenses e
          JOIN manager_employees me ON me.employee_id = e.user_id
          WHERE me.manager_id = ? AND e.is_approved = 0''',
        [_managerId],
      );

      // Count team anomalies
      final teamAnomalies = await _db.getOptional(
        '''SELECT COUNT(*) as count FROM anomalies a
          JOIN manager_employees me ON me.employee_id = a.user_id
          WHERE me.manager_id = ? AND a.is_resolved = 0''',
        [_managerId],
      );

      final presentCount = employees.where((e) => e.isPresentToday).length;
      final absentCount = employees.where((e) => e.hasAbsence).length;

      emit(ManagerDashboardLoaded(
        employees: employees,
        pendingValidations: pendingValidations?['count'] as int? ?? 0,
        pendingExpenses: pendingExpenses?['count'] as int? ?? 0,
        teamAnomalies: teamAnomalies?['count'] as int? ?? 0,
        presentCount: presentCount,
        absentCount: absentCount,
      ));
    } catch (e) {
      emit(ManagerDashboardError(e.toString()));
    }
  }
}
