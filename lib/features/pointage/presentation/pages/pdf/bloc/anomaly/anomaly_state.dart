part of 'anomaly_bloc.dart';

sealed class AnomalyState extends Equatable {
  const AnomalyState();
}

class AnomalyInitial extends AnomalyState {
  @override
  List<Object?> get props => [];
}

class AnomalyLoading extends AnomalyState {
  @override
  List<Object?> get props => [];
}

class AnomalyDetected extends AnomalyState {
  final List<String> anomalies;

  const AnomalyDetected(this.anomalies);

  @override
  List<Object> get props => [anomalies];
}

class AnomalyError extends AnomalyState {
  final String message;

  const AnomalyError(this.message);

  @override
  List<Object> get props => [message];
}

class ActiveDetectorsLoaded extends AnomalyState {
  final List<String> activeDetectorIds;

  const ActiveDetectorsLoaded(this.activeDetectorIds);

  @override
  List<Object> get props => [activeDetectorIds];
}