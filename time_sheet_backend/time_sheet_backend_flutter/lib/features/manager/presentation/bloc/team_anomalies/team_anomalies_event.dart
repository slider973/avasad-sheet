part of 'team_anomalies_bloc.dart';

abstract class TeamAnomaliesEvent extends Equatable {
  const TeamAnomaliesEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeamAnomalies extends TeamAnomaliesEvent {}

class ResolveTeamAnomalyRequested extends TeamAnomaliesEvent {
  final String anomalyId;

  const ResolveTeamAnomalyRequested(this.anomalyId);

  @override
  List<Object?> get props => [anomalyId];
}
