part of 'manager_dashboard_bloc.dart';

class EmployeeStatus {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isPresentToday;
  final String? lastClockIn;
  final bool hasAbsence;
  final String? absenceType;

  const EmployeeStatus({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.isPresentToday = false,
    this.lastClockIn,
    this.hasAbsence = false,
    this.absenceType,
  });

  String get fullName => '$firstName $lastName';
}

abstract class ManagerDashboardState extends Equatable {
  const ManagerDashboardState();

  @override
  List<Object?> get props => [];
}

class ManagerDashboardInitial extends ManagerDashboardState {}

class ManagerDashboardLoading extends ManagerDashboardState {}

class ManagerDashboardLoaded extends ManagerDashboardState {
  final List<EmployeeStatus> employees;
  final int pendingValidations;
  final int pendingExpenses;
  final int teamAnomalies;
  final int presentCount;
  final int absentCount;

  const ManagerDashboardLoaded({
    required this.employees,
    required this.pendingValidations,
    required this.pendingExpenses,
    required this.teamAnomalies,
    required this.presentCount,
    required this.absentCount,
  });

  @override
  List<Object?> get props => [
        employees,
        pendingValidations,
        pendingExpenses,
        teamAnomalies,
        presentCount,
        absentCount,
      ];
}

class ManagerDashboardError extends ManagerDashboardState {
  final String message;

  const ManagerDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
