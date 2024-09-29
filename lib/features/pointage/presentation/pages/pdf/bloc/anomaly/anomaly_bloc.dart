import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../services/anomaly_detector_config.dart';
import '../../../../../../preference/presentation/manager/preferences_bloc.dart';
import '../../../../../factory/anomaly_detector_factory.dart';
import '../../../../../strategies/anomaly_detector.dart';
import '../../../../../use_cases/detect_anomalies_usecase.dart';

part 'anomaly_event.dart';
part 'anomaly_state.dart';

class AnomalyBloc extends Bloc<AnomalyEvent, AnomalyState> {
  final DetectAnomaliesUseCase detectAnomaliesUseCase;
  final PreferencesBloc preferencesBloc;
  final Map<String, AnomalyDetector> allDetectors;

  AnomalyBloc({
    required this.detectAnomaliesUseCase,
    required this.preferencesBloc,
    required this.allDetectors,
  }) : super(AnomalyInitial()) {
    on<DetectAnomalies>(_onDetectAnomalies);
    on<LoadActiveDetectors>(_onLoadActiveDetectors);
    on<ToggleDetector>(_onToggleDetector);
  }

  Future<void> _onDetectAnomalies(DetectAnomalies event, Emitter<AnomalyState> emit) async {
    emit(AnomalyLoading());
    try {
      final activeDetectorIds = await AnomalyDetectorConfig.getActiveDetectors(preferencesBloc);
      final activeDetectors = activeDetectorIds
          .where((id) => allDetectors.containsKey(id))
          .map((id) => allDetectors[id]!)
          .toList();

      // Mettre à jour la liste des détecteurs dans le use case
      detectAnomaliesUseCase.detectors = activeDetectors;

      final anomalies = await detectAnomaliesUseCase.execute(event.month, event.year);
      emit(AnomalyDetected(anomalies));
    } catch (e) {
      emit(AnomalyError("Erreur lors de la détection des anomalies : $e"));
    }
  }

  Future<void> _onLoadActiveDetectors(LoadActiveDetectors event, Emitter<AnomalyState> emit) async {
    try {
      final activeDetectorIds = await AnomalyDetectorConfig.getActiveDetectors(preferencesBloc);
      emit(ActiveDetectorsLoaded(activeDetectorIds));
    } catch (e) {
      emit(AnomalyError("Erreur lors du chargement des détecteurs actifs : $e"));
    }
  }

  Future<void> _onToggleDetector(ToggleDetector event, Emitter<AnomalyState> emit) async {
    try {
      if (event.isActive) {
        await AnomalyDetectorConfig.addDetector(preferencesBloc, event.detectorId);
      } else {
        await AnomalyDetectorConfig.removeDetector(preferencesBloc, event.detectorId);
      }
      add(LoadActiveDetectors());
    } catch (e) {
      emit(AnomalyError("Erreur lors de la modification des détecteurs actifs : $e"));
    }
  }
}