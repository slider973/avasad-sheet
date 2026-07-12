import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/features/manager/domain/entities/employee_timesheet_entry.dart';
import 'package:time_sheet/features/manager/domain/entities/pending_expense.dart';
import 'package:time_sheet/features/manager/domain/entities/pending_validation.dart';
import 'package:time_sheet/features/manager/domain/entities/team_anomaly.dart';
import 'package:time_sheet/features/manager/domain/entities/team_member_status.dart';
import 'package:time_sheet/features/manager/domain/entities/team_overview.dart';
import 'package:time_sheet/features/manager/domain/repositories/manager_repository.dart';
import 'package:time_sheet/features/manager/domain/use_cases/approve_expense_usecase.dart';
import 'package:time_sheet/features/manager/domain/use_cases/get_employee_timesheet_usecase.dart';
import 'package:time_sheet/features/manager/domain/use_cases/get_pending_expenses_usecase.dart';
import 'package:time_sheet/features/manager/domain/use_cases/get_pending_validations_usecase.dart';
import 'package:time_sheet/features/manager/domain/use_cases/get_team_anomalies_usecase.dart';
import 'package:time_sheet/features/manager/domain/use_cases/get_team_overview_usecase.dart';
import 'package:time_sheet/features/manager/domain/use_cases/get_user_role_usecase.dart';
import 'package:time_sheet/features/manager/domain/use_cases/reject_expense_usecase.dart';
import 'package:time_sheet/features/manager/domain/use_cases/resolve_team_anomaly_usecase.dart';

/// Fake repository configurable pour tester les use cases.
class FakeManagerRepository implements ManagerRepository {
  bool shouldFail = false;
  final Failure failure = const GeneralFailure('Erreur test');

  // Traces des appels
  String? approvedExpenseId;
  String? rejectedExpenseId;
  String? resolvedAnomalyId;
  String? requestedEmployeeId;
  int? requestedMonth;
  int? requestedYear;

  final teamOverview = const TeamOverview(
    members: [
      TeamMemberStatus(
        id: 'emp-1',
        firstName: 'Alice',
        lastName: 'Martin',
        email: 'alice@example.com',
        isPresentToday: true,
        lastClockIn: '08:30',
      ),
      TeamMemberStatus(
        id: 'emp-2',
        firstName: 'Bob',
        lastName: 'Durand',
        email: 'bob@example.com',
        hasAbsence: true,
        absenceType: 'vacation',
      ),
    ],
    pendingValidations: 2,
    pendingExpenses: 3,
    teamAnomalies: 4,
  );

  final pendingValidations = const [
    PendingValidation(
      id: 'val-1',
      employeeFirstName: 'Alice',
      employeeLastName: 'Martin',
      periodStart: '2026-06-01',
      periodEnd: '2026-06-30',
      createdAt: '2026-07-01T10:00:00',
    ),
  ];

  final pendingExpenses = const [
    PendingExpense(
      id: 'exp-1',
      employeeFirstName: 'Bob',
      employeeLastName: 'Durand',
      category: 'meals',
      amount: 24.5,
      currency: 'CHF',
      date: '2026-07-05',
      description: 'Repas client',
    ),
  ];

  final teamAnomalies = const [
    TeamAnomaly(
      id: 'ano-1',
      employeeFirstName: 'Alice',
      employeeLastName: 'Martin',
      typeCode: 'insufficient_hours',
      description: 'Temps de travail insuffisant',
      detectedDate: '2026-07-08',
    ),
  ];

  final timesheetEntries = const [
    EmployeeTimesheetEntry(
      dayDate: '2026-07-06',
      startMorning: '08:00',
      endMorning: '12:00',
      startAfternoon: '13:00',
      endAfternoon: '17:00',
      absenceReason: '',
      isWeekendDay: false,
    ),
  ];

  String role = 'manager';

  @override
  Future<Either<Failure, TeamOverview>> getTeamOverview() async {
    if (shouldFail) return Left(failure);
    return Right(teamOverview);
  }

  @override
  Future<Either<Failure, List<PendingValidation>>>
      getPendingValidations() async {
    if (shouldFail) return Left(failure);
    return Right(pendingValidations);
  }

  @override
  Future<Either<Failure, List<PendingExpense>>> getPendingExpenses() async {
    if (shouldFail) return Left(failure);
    return Right(pendingExpenses);
  }

  @override
  Future<Either<Failure, void>> approveExpense(String expenseId) async {
    if (shouldFail) return Left(failure);
    approvedExpenseId = expenseId;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> rejectExpense(String expenseId) async {
    if (shouldFail) return Left(failure);
    rejectedExpenseId = expenseId;
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<TeamAnomaly>>> getTeamAnomalies() async {
    if (shouldFail) return Left(failure);
    return Right(teamAnomalies);
  }

  @override
  Future<Either<Failure, void>> resolveTeamAnomaly(String anomalyId) async {
    if (shouldFail) return Left(failure);
    resolvedAnomalyId = anomalyId;
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<EmployeeTimesheetEntry>>> getEmployeeTimesheet({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    if (shouldFail) return Left(failure);
    requestedEmployeeId = employeeId;
    requestedMonth = month;
    requestedYear = year;
    return Right(timesheetEntries);
  }

  @override
  Future<Either<Failure, String>> getCurrentUserRole() async {
    if (shouldFail) return Left(failure);
    return Right(role);
  }
}

void main() {
  late FakeManagerRepository repository;

  setUp(() {
    repository = FakeManagerRepository();
  });

  group('GetTeamOverviewUseCase', () {
    test('retourne la vue d\'ensemble de l\'équipe', () async {
      final useCase = GetTeamOverviewUseCase(repository: repository);

      final result = await useCase.execute();

      expect(result.isRight(), isTrue);
      final overview = result.getOrElse((_) => throw StateError('failure'));
      expect(overview.members.length, 2);
      expect(overview.pendingValidations, 2);
      expect(overview.pendingExpenses, 3);
      expect(overview.teamAnomalies, 4);
    });

    test('les compteurs présents/absents sont dérivés des membres', () async {
      final useCase = GetTeamOverviewUseCase(repository: repository);

      final result = await useCase.execute();

      final overview = result.getOrElse((_) => throw StateError('failure'));
      expect(overview.presentCount, 1);
      expect(overview.absentCount, 1);
    });

    test('propage le Failure du repository', () async {
      repository.shouldFail = true;
      final useCase = GetTeamOverviewUseCase(repository: repository);

      final result = await useCase.execute();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<GeneralFailure>()),
        (_) => fail('Un Left était attendu'),
      );
    });
  });

  group('GetPendingValidationsUseCase', () {
    test('retourne les validations en attente', () async {
      final useCase = GetPendingValidationsUseCase(repository: repository);

      final result = await useCase.execute();

      expect(result.isRight(), isTrue);
      final validations = result.getOrElse((_) => []);
      expect(validations.length, 1);
      expect(validations.first.id, 'val-1');
      expect(validations.first.employeeFirstName, 'Alice');
    });

    test('propage le Failure du repository', () async {
      repository.shouldFail = true;
      final useCase = GetPendingValidationsUseCase(repository: repository);

      final result = await useCase.execute();

      expect(result.isLeft(), isTrue);
    });
  });

  group('GetPendingExpensesUseCase', () {
    test('retourne les dépenses en attente', () async {
      final useCase = GetPendingExpensesUseCase(repository: repository);

      final result = await useCase.execute();

      expect(result.isRight(), isTrue);
      final expenses = result.getOrElse((_) => []);
      expect(expenses.length, 1);
      expect(expenses.first.id, 'exp-1');
      expect(expenses.first.amount, 24.5);
      expect(expenses.first.category, 'meals');
    });

    test('propage le Failure du repository', () async {
      repository.shouldFail = true;
      final useCase = GetPendingExpensesUseCase(repository: repository);

      final result = await useCase.execute();

      expect(result.isLeft(), isTrue);
    });
  });

  group('ApproveExpenseUseCase', () {
    test('approuve la dépense via le repository', () async {
      final useCase = ApproveExpenseUseCase(repository: repository);

      final result = await useCase.execute('exp-1');

      expect(result.isRight(), isTrue);
      expect(repository.approvedExpenseId, 'exp-1');
    });

    test('refuse un identifiant vide sans appeler le repository', () async {
      final useCase = ApproveExpenseUseCase(repository: repository);

      final result = await useCase.execute('');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Un Left était attendu'),
      );
      expect(repository.approvedExpenseId, isNull);
    });

    test('propage le Failure du repository', () async {
      repository.shouldFail = true;
      final useCase = ApproveExpenseUseCase(repository: repository);

      final result = await useCase.execute('exp-1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('RejectExpenseUseCase', () {
    test('rejette la dépense via le repository', () async {
      final useCase = RejectExpenseUseCase(repository: repository);

      final result = await useCase.execute('exp-1');

      expect(result.isRight(), isTrue);
      expect(repository.rejectedExpenseId, 'exp-1');
    });

    test('refuse un identifiant vide sans appeler le repository', () async {
      final useCase = RejectExpenseUseCase(repository: repository);

      final result = await useCase.execute('');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Un Left était attendu'),
      );
      expect(repository.rejectedExpenseId, isNull);
    });

    test('propage le Failure du repository', () async {
      repository.shouldFail = true;
      final useCase = RejectExpenseUseCase(repository: repository);

      final result = await useCase.execute('exp-1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('GetTeamAnomaliesUseCase', () {
    test('retourne les anomalies de l\'équipe', () async {
      final useCase = GetTeamAnomaliesUseCase(repository: repository);

      final result = await useCase.execute();

      expect(result.isRight(), isTrue);
      final anomalies = result.getOrElse((_) => []);
      expect(anomalies.length, 1);
      expect(anomalies.first.typeCode, 'insufficient_hours');
    });

    test('propage le Failure du repository', () async {
      repository.shouldFail = true;
      final useCase = GetTeamAnomaliesUseCase(repository: repository);

      final result = await useCase.execute();

      expect(result.isLeft(), isTrue);
    });
  });

  group('ResolveTeamAnomalyUseCase', () {
    test('résout l\'anomalie via le repository', () async {
      final useCase = ResolveTeamAnomalyUseCase(repository: repository);

      final result = await useCase.execute('ano-1');

      expect(result.isRight(), isTrue);
      expect(repository.resolvedAnomalyId, 'ano-1');
    });

    test('refuse un identifiant vide sans appeler le repository', () async {
      final useCase = ResolveTeamAnomalyUseCase(repository: repository);

      final result = await useCase.execute('');

      expect(result.isLeft(), isTrue);
      expect(repository.resolvedAnomalyId, isNull);
    });

    test('propage le Failure du repository', () async {
      repository.shouldFail = true;
      final useCase = ResolveTeamAnomalyUseCase(repository: repository);

      final result = await useCase.execute('ano-1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('GetEmployeeTimesheetUseCase', () {
    test('retourne les pointages du mois demandé', () async {
      final useCase = GetEmployeeTimesheetUseCase(repository: repository);

      final result = await useCase.execute(
        employeeId: 'emp-1',
        month: 7,
        year: 2026,
      );

      expect(result.isRight(), isTrue);
      final entries = result.getOrElse((_) => []);
      expect(entries.length, 1);
      expect(entries.first.dayDate, '2026-07-06');
      expect(repository.requestedEmployeeId, 'emp-1');
      expect(repository.requestedMonth, 7);
      expect(repository.requestedYear, 2026);
    });

    test('refuse un identifiant employé vide', () async {
      final useCase = GetEmployeeTimesheetUseCase(repository: repository);

      final result = await useCase.execute(
        employeeId: '',
        month: 7,
        year: 2026,
      );

      expect(result.isLeft(), isTrue);
      expect(repository.requestedEmployeeId, isNull);
    });

    test('propage le Failure du repository', () async {
      repository.shouldFail = true;
      final useCase = GetEmployeeTimesheetUseCase(repository: repository);

      final result = await useCase.execute(
        employeeId: 'emp-1',
        month: 7,
        year: 2026,
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('GetUserRoleUseCase', () {
    test('retourne le rôle de l\'utilisateur courant', () async {
      repository.role = 'org_admin';
      final useCase = GetUserRoleUseCase(repository: repository);

      final result = await useCase.execute();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => ''), 'org_admin');
    });

    test('propage le Failure du repository', () async {
      repository.shouldFail = true;
      final useCase = GetUserRoleUseCase(repository: repository);

      final result = await useCase.execute();

      expect(result.isLeft(), isTrue);
    });
  });
}
