import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../pointage/data/models/anomalies/anomalies.dart';
import '../../../pointage/data/models/anomalies/anomaly_type_db_mapper.dart';
import '../../domain/entities/employee_timesheet_entry.dart';
import '../../domain/entities/pending_expense.dart';
import '../../domain/entities/pending_validation.dart';
import '../../domain/entities/team_anomaly.dart';
import '../../domain/entities/team_member_status.dart';
import '../../domain/entities/team_overview.dart';
import '../../domain/repositories/manager_repository.dart';
import '../data_sources/manager_data_source.dart';

/// Implémentation du repository Manager (PowerSync via [ManagerDataSource]).
class ManagerRepositoryImpl implements ManagerRepository {
  final ManagerDataSource dataSource;

  ManagerRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, TeamOverview>> getTeamOverview() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final employeeRows = await dataSource.getTeamEmployees();

      final List<TeamMemberStatus> members = [];
      for (final emp in employeeRows) {
        final empId = emp['id'] as String;

        final todayEntry = await dataSource.getTodayEntry(empId, today);
        final absence = await dataSource.getCurrentAbsence(empId, today);

        final isPresent = todayEntry != null &&
            (todayEntry['start_morning'] as String? ?? '').isNotEmpty;

        members.add(TeamMemberStatus(
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

      final pendingValidations = await dataSource.countPendingValidations();
      final pendingExpenses = await dataSource.countPendingExpenses();
      final teamAnomalies = await dataSource.countUnresolvedAnomalies();

      return Right(TeamOverview(
        members: members,
        pendingValidations: pendingValidations,
        pendingExpenses: pendingExpenses,
        teamAnomalies: teamAnomalies,
      ));
    } catch (e) {
      return Left(GeneralFailure(
          'Erreur lors du chargement du tableau de bord: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PendingValidation>>>
      getPendingValidations() async {
    try {
      final rows = await dataSource.getPendingValidations();
      final validations = rows
          .map((row) => PendingValidation(
                id: row['id'] as String? ?? '',
                employeeFirstName: row['first_name'] as String? ?? '',
                employeeLastName: row['last_name'] as String? ?? '',
                periodStart: row['period_start'] as String? ?? '',
                periodEnd: row['period_end'] as String? ?? '',
                createdAt: row['created_at'] as String? ?? '',
              ))
          .toList();
      return Right(validations);
    } catch (e) {
      return Left(GeneralFailure(
          'Erreur lors de la récupération des validations en attente: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PendingExpense>>> getPendingExpenses() async {
    try {
      final rows = await dataSource.getPendingExpenses();
      final expenses = rows.map((row) {
        final amount = row['amount'];
        final amountValue = amount is num
            ? amount.toDouble()
            : double.tryParse(amount?.toString() ?? '') ?? 0.0;

        return PendingExpense(
          id: row['id'] as String? ?? '',
          employeeFirstName: row['first_name'] as String? ?? '',
          employeeLastName: row['last_name'] as String? ?? '',
          category: row['category'] as String? ?? '',
          amount: amountValue,
          currency: row['currency'] as String? ?? 'CHF',
          date: row['date'] as String? ?? '',
          description: row['description'] as String? ?? '',
        );
      }).toList();
      return Right(expenses);
    } catch (e) {
      return Left(GeneralFailure(
          'Erreur lors de la récupération des dépenses en attente: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> approveExpense(String expenseId) async {
    try {
      await dataSource.approveExpense(expenseId);
      return const Right(null);
    } catch (e) {
      return Left(
          GeneralFailure('Erreur lors de l\'approbation de la dépense: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> rejectExpense(String expenseId) async {
    try {
      await dataSource.rejectExpense(expenseId);
      return const Right(null);
    } catch (e) {
      return Left(GeneralFailure('Erreur lors du rejet de la dépense: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TeamAnomaly>>> getTeamAnomalies() async {
    try {
      final rows = await dataSource.getTeamAnomalies();
      final anomalies = rows
          .map((row) => TeamAnomaly(
                id: row['id'] as String? ?? '',
                employeeFirstName: row['first_name'] as String? ?? '',
                employeeLastName: row['last_name'] as String? ?? '',
                typeCode: _anomalyTypeCode(row['type'] as String?),
                description: row['description'] as String? ?? '',
                detectedDate: row['detected_date'] as String? ?? '',
              ))
          .toList();
      return Right(anomalies);
    } catch (e) {
      return Left(GeneralFailure(
          'Erreur lors de la récupération des anomalies: $e'));
    }
  }

  /// Normalise `anomalies.type` via le mapper [AnomalyTypeDb].
  ///
  /// Les valeurs camelCase legacy ('insufficientHours', ...) sont converties
  /// en snake_case via [AnomalyTypeDb.fromDb]. Les codes serveur non couverts
  /// par l'enum ('excessive_hours', 'missing_break', ...) sont conservés tels
  /// quels pour ne pas dégrader l'affichage (le mapper les rabattrait sur
  /// 'missing_entry').
  String _anomalyTypeCode(String? raw) {
    if (raw == null) return '';
    final isKnown =
        AnomalyType.values.any((t) => t.dbValue == raw || t.name == raw);
    return isKnown ? AnomalyTypeDb.fromDb(raw).dbValue : raw;
  }

  @override
  Future<Either<Failure, void>> resolveTeamAnomaly(String anomalyId) async {
    try {
      await dataSource.resolveAnomaly(anomalyId);
      return const Right(null);
    } catch (e) {
      return Left(GeneralFailure(
          'Erreur lors de la résolution de l\'anomalie: $e'));
    }
  }

  @override
  Future<Either<Failure, List<EmployeeTimesheetEntry>>> getEmployeeTimesheet({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(DateTime(year, month));
      final endDate =
          DateFormat('yyyy-MM-dd').format(DateTime(year, month + 1, 0));

      final rows =
          await dataSource.getEmployeeTimesheet(employeeId, startDate, endDate);
      final entries = rows
          .map((row) => EmployeeTimesheetEntry(
                dayDate: row['day_date'] as String? ?? '',
                startMorning: row['start_morning'] as String? ?? '',
                endMorning: row['end_morning'] as String? ?? '',
                startAfternoon: row['start_afternoon'] as String? ?? '',
                endAfternoon: row['end_afternoon'] as String? ?? '',
                absenceReason: row['absence_reason'] as String? ?? '',
                isWeekendDay: (row['is_weekend_day'] as int?) == 1,
              ))
          .toList();
      return Right(entries);
    } catch (e) {
      return Left(GeneralFailure(
          'Erreur lors de la récupération des pointages: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getCurrentUserRole() async {
    try {
      final role = await dataSource.getCurrentUserRole();
      return Right(role ?? 'employee');
    } catch (e) {
      return Left(
          GeneralFailure('Erreur lors de la récupération du rôle: $e'));
    }
  }
}
