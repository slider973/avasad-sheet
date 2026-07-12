import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/team_member_status.dart';
import '../../domain/use_cases/get_team_overview_usecase.dart';

part 'manager_dashboard_event.dart';
part 'manager_dashboard_state.dart';

class ManagerDashboardBloc
    extends Bloc<ManagerDashboardEvent, ManagerDashboardState> {
  final GetTeamOverviewUseCase getTeamOverviewUseCase;

  ManagerDashboardBloc({required this.getTeamOverviewUseCase})
      : super(ManagerDashboardInitial()) {
    on<LoadManagerDashboard>(_onLoadDashboard);
    on<RefreshManagerDashboard>(_onRefreshDashboard);
  }

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
    final result = await getTeamOverviewUseCase.execute();

    result.fold(
      (failure) => emit(ManagerDashboardError(failure.message)),
      (overview) => emit(ManagerDashboardLoaded(
        employees: overview.members,
        pendingValidations: overview.pendingValidations,
        pendingExpenses: overview.pendingExpenses,
        teamAnomalies: overview.teamAnomalies,
        presentCount: overview.presentCount,
        absentCount: overview.absentCount,
      )),
    );
  }
}
