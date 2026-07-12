part of 'manager_dashboard_bloc.dart';

abstract class ManagerDashboardEvent extends Equatable {
  const ManagerDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadManagerDashboard extends ManagerDashboardEvent {}

class RefreshManagerDashboard extends ManagerDashboardEvent {}
