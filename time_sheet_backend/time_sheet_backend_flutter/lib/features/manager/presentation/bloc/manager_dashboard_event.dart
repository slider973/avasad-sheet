part of 'manager_dashboard_bloc.dart';

abstract class ManagerDashboardEvent extends Equatable {
  const ManagerDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadManagerDashboard extends ManagerDashboardEvent {}

class RefreshManagerDashboard extends ManagerDashboardEvent {}

class LoadTeamTimesheet extends ManagerDashboardEvent {
  final String employeeId;
  final int month;
  final int year;

  const LoadTeamTimesheet({
    required this.employeeId,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [employeeId, month, year];
}
