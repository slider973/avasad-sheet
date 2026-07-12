import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/manager/data/data_sources/manager_data_source.dart';
import 'package:time_sheet/features/manager/data/repositories/manager_repository_impl.dart';

/// Fake data source configurable pour tester le mapping du repository.
class FakeManagerDataSource implements ManagerDataSource {
  List<Map<String, dynamic>> teamEmployees = [];
  Map<String, Map<String, dynamic>?> todayEntries = {};
  Map<String, Map<String, dynamic>?> absences = {};
  int pendingValidationsCount = 0;
  int pendingExpensesCount = 0;
  int unresolvedAnomaliesCount = 0;
  List<Map<String, dynamic>> pendingValidations = [];
  List<Map<String, dynamic>> pendingExpenses = [];
  List<Map<String, dynamic>> teamAnomalies = [];
  List<Map<String, dynamic>> timesheetRows = [];
  String? role;
  bool shouldThrow = false;

  String? approvedExpenseId;
  String? rejectedExpenseId;
  String? resolvedAnomalyId;
  String? timesheetEmployeeId;
  String? timesheetStartDate;
  String? timesheetEndDate;

  void _maybeThrow() {
    if (shouldThrow) throw Exception('boom');
  }

  @override
  Future<List<Map<String, dynamic>>> getTeamEmployees() async {
    _maybeThrow();
    return teamEmployees;
  }

  @override
  Future<Map<String, dynamic>?> getTodayEntry(
      String employeeId, String today) async {
    _maybeThrow();
    return todayEntries[employeeId];
  }

  @override
  Future<Map<String, dynamic>?> getCurrentAbsence(
      String employeeId, String today) async {
    _maybeThrow();
    return absences[employeeId];
  }

  @override
  Future<int> countPendingValidations() async {
    _maybeThrow();
    return pendingValidationsCount;
  }

  @override
  Future<int> countPendingExpenses() async {
    _maybeThrow();
    return pendingExpensesCount;
  }

  @override
  Future<int> countUnresolvedAnomalies() async {
    _maybeThrow();
    return unresolvedAnomaliesCount;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingValidations() async {
    _maybeThrow();
    return pendingValidations;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingExpenses() async {
    _maybeThrow();
    return pendingExpenses;
  }

  @override
  Future<void> approveExpense(String expenseId) async {
    _maybeThrow();
    approvedExpenseId = expenseId;
  }

  @override
  Future<void> rejectExpense(String expenseId) async {
    _maybeThrow();
    rejectedExpenseId = expenseId;
  }

  @override
  Future<List<Map<String, dynamic>>> getTeamAnomalies() async {
    _maybeThrow();
    return teamAnomalies;
  }

  @override
  Future<void> resolveAnomaly(String anomalyId) async {
    _maybeThrow();
    resolvedAnomalyId = anomalyId;
  }

  @override
  Future<List<Map<String, dynamic>>> getEmployeeTimesheet(
      String employeeId, String startDate, String endDate) async {
    _maybeThrow();
    timesheetEmployeeId = employeeId;
    timesheetStartDate = startDate;
    timesheetEndDate = endDate;
    return timesheetRows;
  }

  @override
  Future<String?> getCurrentUserRole() async {
    _maybeThrow();
    return role;
  }
}

void main() {
  late FakeManagerDataSource dataSource;
  late ManagerRepositoryImpl repository;

  setUp(() {
    dataSource = FakeManagerDataSource();
    repository = ManagerRepositoryImpl(dataSource: dataSource);
  });

  group('getTeamOverview', () {
    test('assemble les statuts des membres et les compteurs', () async {
      dataSource.teamEmployees = [
        {
          'id': 'emp-1',
          'first_name': 'Alice',
          'last_name': 'Martin',
          'email': 'alice@example.com',
        },
        {
          'id': 'emp-2',
          'first_name': 'Bob',
          'last_name': 'Durand',
          'email': 'bob@example.com',
        },
      ];
      dataSource.todayEntries = {
        'emp-1': {'start_morning': '08:30'},
        'emp-2': null,
      };
      dataSource.absences = {
        'emp-2': {'type': 'vacation'},
      };
      dataSource.pendingValidationsCount = 1;
      dataSource.pendingExpensesCount = 2;
      dataSource.unresolvedAnomaliesCount = 3;

      final result = await repository.getTeamOverview();

      expect(result.isRight(), isTrue);
      final overview = result.getOrElse((_) => throw StateError('failure'));
      expect(overview.members.length, 2);

      final alice = overview.members[0];
      expect(alice.isPresentToday, isTrue);
      expect(alice.lastClockIn, '08:30');
      expect(alice.hasAbsence, isFalse);

      final bob = overview.members[1];
      expect(bob.isPresentToday, isFalse);
      expect(bob.hasAbsence, isTrue);
      expect(bob.absenceType, 'vacation');

      expect(overview.pendingValidations, 1);
      expect(overview.pendingExpenses, 2);
      expect(overview.teamAnomalies, 3);
      expect(overview.presentCount, 1);
      expect(overview.absentCount, 1);
    });

    test('une entrée avec start_morning vide n\'est pas comptée présente',
        () async {
      dataSource.teamEmployees = [
        {
          'id': 'emp-1',
          'first_name': 'Alice',
          'last_name': 'Martin',
          'email': 'alice@example.com',
        },
      ];
      dataSource.todayEntries = {
        'emp-1': {'start_morning': ''},
      };

      final result = await repository.getTeamOverview();

      final overview = result.getOrElse((_) => throw StateError('failure'));
      expect(overview.members.first.isPresentToday, isFalse);
    });

    test('retourne un GeneralFailure en cas d\'exception', () async {
      dataSource.shouldThrow = true;

      final result = await repository.getTeamOverview();

      expect(result.isLeft(), isTrue);
    });
  });

  group('getPendingExpenses', () {
    test('mappe les lignes en entités avec montant numérique', () async {
      dataSource.pendingExpenses = [
        {
          'id': 'exp-1',
          'first_name': 'Bob',
          'last_name': 'Durand',
          'category': 'meals',
          'amount': 24.5,
          'currency': 'CHF',
          'date': '2026-07-05',
          'description': 'Repas client',
        },
      ];

      final result = await repository.getPendingExpenses();

      final expenses = result.getOrElse((_) => []);
      expect(expenses.length, 1);
      expect(expenses.first.amount, 24.5);
      expect(expenses.first.category, 'meals');
    });

    test('tolère un montant stocké en texte', () async {
      dataSource.pendingExpenses = [
        {
          'id': 'exp-2',
          'first_name': 'Bob',
          'last_name': 'Durand',
          'category': 'other',
          'amount': '12.30',
          'currency': 'CHF',
          'date': '2026-07-05',
          'description': '',
        },
      ];

      final result = await repository.getPendingExpenses();

      final expenses = result.getOrElse((_) => []);
      expect(expenses.first.amount, 12.30);
    });
  });

  group('approveExpense / rejectExpense', () {
    test('approveExpense délègue au data source', () async {
      final result = await repository.approveExpense('exp-1');

      expect(result.isRight(), isTrue);
      expect(dataSource.approvedExpenseId, 'exp-1');
    });

    test('rejectExpense délègue au data source', () async {
      final result = await repository.rejectExpense('exp-1');

      expect(result.isRight(), isTrue);
      expect(dataSource.rejectedExpenseId, 'exp-1');
    });

    test('retourne un Failure en cas d\'exception', () async {
      dataSource.shouldThrow = true;

      final approve = await repository.approveExpense('exp-1');
      final reject = await repository.rejectExpense('exp-1');

      expect(approve.isLeft(), isTrue);
      expect(reject.isLeft(), isTrue);
    });
  });

  group('getTeamAnomalies', () {
    test('conserve les codes serveur non couverts par l\'enum', () async {
      dataSource.teamAnomalies = [
        _anomalyRow('ano-1', 'excessive_hours'),
        _anomalyRow('ano-2', 'missing_break'),
        _anomalyRow('ano-3', 'schedule_inconsistency'),
        _anomalyRow('ano-4', 'weekly_compensation'),
      ];

      final result = await repository.getTeamAnomalies();

      final anomalies = result.getOrElse((_) => []);
      expect(anomalies.map((a) => a.typeCode), [
        'excessive_hours',
        'missing_break',
        'schedule_inconsistency',
        'weekly_compensation',
      ]);
    });

    test('normalise les valeurs camelCase legacy en snake_case', () async {
      dataSource.teamAnomalies = [
        _anomalyRow('ano-1', 'insufficientHours'),
        _anomalyRow('ano-2', 'missingEntry'),
        _anomalyRow('ano-3', 'invalidTimes'),
      ];

      final result = await repository.getTeamAnomalies();

      final anomalies = result.getOrElse((_) => []);
      expect(anomalies.map((a) => a.typeCode), [
        'insufficient_hours',
        'missing_entry',
        'invalid_times',
      ]);
    });

    test('conserve les codes snake_case connus tels quels', () async {
      dataSource.teamAnomalies = [
        _anomalyRow('ano-1', 'insufficient_hours'),
      ];

      final result = await repository.getTeamAnomalies();

      final anomalies = result.getOrElse((_) => []);
      expect(anomalies.first.typeCode, 'insufficient_hours');
    });
  });

  group('resolveTeamAnomaly', () {
    test('délègue au data source', () async {
      final result = await repository.resolveTeamAnomaly('ano-1');

      expect(result.isRight(), isTrue);
      expect(dataSource.resolvedAnomalyId, 'ano-1');
    });
  });

  group('getEmployeeTimesheet', () {
    test('calcule les bornes du mois et mappe les entrées', () async {
      dataSource.timesheetRows = [
        {
          'day_date': '2026-02-10',
          'start_morning': '08:00',
          'end_morning': '12:00',
          'start_afternoon': '13:00',
          'end_afternoon': '17:00',
          'absence_reason': '',
          'is_weekend_day': 0,
        },
      ];

      final result = await repository.getEmployeeTimesheet(
        employeeId: 'emp-1',
        month: 2,
        year: 2026,
      );

      expect(result.isRight(), isTrue);
      expect(dataSource.timesheetEmployeeId, 'emp-1');
      expect(dataSource.timesheetStartDate, '2026-02-01');
      expect(dataSource.timesheetEndDate, '2026-02-28');

      final entries = result.getOrElse((_) => []);
      expect(entries.first.dayDate, '2026-02-10');
      expect(entries.first.isWeekendDay, isFalse);
    });
  });

  group('getCurrentUserRole', () {
    test('retourne le rôle du data source', () async {
      dataSource.role = 'manager';

      final result = await repository.getCurrentUserRole();

      expect(result.getOrElse((_) => ''), 'manager');
    });

    test('retombe sur employee si aucun rôle trouvé', () async {
      dataSource.role = null;

      final result = await repository.getCurrentUserRole();

      expect(result.getOrElse((_) => ''), 'employee');
    });
  });
}

Map<String, dynamic> _anomalyRow(String id, String type) {
  return {
    'id': id,
    'first_name': 'Alice',
    'last_name': 'Martin',
    'type': type,
    'description': 'desc',
    'detected_date': '2026-07-08',
  };
}
