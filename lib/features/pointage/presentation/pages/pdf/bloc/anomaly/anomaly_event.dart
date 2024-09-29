part of 'anomaly_bloc.dart';

sealed class AnomalyEvent extends Equatable {
  const AnomalyEvent();
}

class DetectAnomalies extends AnomalyEvent {
  final int month;
  final int year;

  const DetectAnomalies(this.month, this.year);

  @override
  List<Object> get props => [month, year];
}
class LoadActiveDetectors extends AnomalyEvent {
  @override
  List<Object?> get props => [];
}

class ToggleDetector extends AnomalyEvent {
  final String detectorId;
  final bool isActive;

  const ToggleDetector(this.detectorId, this.isActive);

  @override
  List<Object> get props => [detectorId, isActive];
}
