part of 'manager_dashboard_bloc.dart';

abstract class ManagerDashboardState extends Equatable {
  const ManagerDashboardState();

  @override
  List<Object?> get props => [];
}

class ManagerDashboardInitial extends ManagerDashboardState {}

class ManagerDashboardLoading extends ManagerDashboardState {}

class ManagerDashboardLoaded extends ManagerDashboardState {
  final List<TeamMemberStatus> employees;
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
