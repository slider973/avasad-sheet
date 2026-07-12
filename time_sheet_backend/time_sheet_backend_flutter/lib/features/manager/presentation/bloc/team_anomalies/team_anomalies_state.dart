part of 'team_anomalies_bloc.dart';

class TeamAnomaliesState extends Equatable {
  final List<TeamAnomaly> anomalies;
  final bool isLoading;

  /// Message d'erreur ponctuel (résolution), consommé par un [BlocListener]
  /// pour afficher un snackbar. Remis à null à chaque nouvelle émission.
  final String? actionError;

  const TeamAnomaliesState({
    this.anomalies = const [],
    this.isLoading = true,
    this.actionError,
  });

  TeamAnomaliesState copyWith({
    List<TeamAnomaly>? anomalies,
    bool? isLoading,
    String? actionError,
  }) {
    return TeamAnomaliesState(
      anomalies: anomalies ?? this.anomalies,
      isLoading: isLoading ?? this.isLoading,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [anomalies, isLoading, actionError];
}
