import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/team_anomaly.dart';
import '../../../domain/use_cases/get_team_anomalies_usecase.dart';
import '../../../domain/use_cases/resolve_team_anomaly_usecase.dart';

part 'team_anomalies_event.dart';
part 'team_anomalies_state.dart';

class TeamAnomaliesBloc extends Bloc<TeamAnomaliesEvent, TeamAnomaliesState> {
  final GetTeamAnomaliesUseCase getTeamAnomaliesUseCase;
  final ResolveTeamAnomalyUseCase resolveTeamAnomalyUseCase;

  TeamAnomaliesBloc({
    required this.getTeamAnomaliesUseCase,
    required this.resolveTeamAnomalyUseCase,
  }) : super(const TeamAnomaliesState()) {
    on<LoadTeamAnomalies>(_onLoadAnomalies);
    on<ResolveTeamAnomalyRequested>(_onResolveAnomaly);
  }

  Future<void> _onLoadAnomalies(
    LoadTeamAnomalies event,
    Emitter<TeamAnomaliesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await getTeamAnomaliesUseCase.execute();
    result.fold(
      // Comportement identique à l'ancienne page : en cas d'échec de
      // chargement, on arrête simplement le loader.
      (failure) => emit(state.copyWith(isLoading: false)),
      (anomalies) => emit(state.copyWith(
        anomalies: anomalies,
        isLoading: false,
      )),
    );
  }

  Future<void> _onResolveAnomaly(
    ResolveTeamAnomalyRequested event,
    Emitter<TeamAnomaliesState> emit,
  ) async {
    final result = await resolveTeamAnomalyUseCase.execute(event.anomalyId);
    await result.fold(
      (failure) async => emit(state.copyWith(actionError: failure.message)),
      (_) async => _onLoadAnomalies(LoadTeamAnomalies(), emit),
    );
  }
}
