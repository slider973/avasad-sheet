import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../services/anomaly_detector_config.dart';
import '../../../../../../preference/presentation/manager/preferences_bloc.dart';
import '../../../../../data/models/anomalies/anomalies.dart';
import '../../../../../data/repositories/anomaly_repository_impl.dart';
import '../../../../../domain/strategies/anomaly_detector.dart';
import '../../../../../domain/use_cases/detect_anomalies_usecase.dart';
import '../../../../../domain/use_cases/detect_anomalies_with_compensation_usecase.dart';
import '../../../../../domain/entities/anomaly.dart';
import '../../../../../domain/services/anomaly_detection_service.dart';
import '../../../../../domain/repositories/timesheet_repository.dart';
import '../../../../../../../services/anomaly/anomaly_service.dart';

part 'anomaly_event.dart';
part 'anomaly_state.dart';

class AnomalyBloc extends Bloc<AnomalyEvent, AnomalyState> {
  final DetectAnomaliesUseCase detectAnomaliesUseCase;
  final DetectAnomaliesWithCompensationUseCase? detectAnomaliesWithCompensationUseCase;
  final PreferencesBloc preferencesBloc;
  final Map<String, AnomalyDetector> allDetectors;
  final AnomalyRepository anomalyRepository; // Ajout du repository
  final AnomalyDetectionService newAnomalyDetectionService;
  final TimesheetRepository timesheetRepository;
  final AnomalyService anomalyService;

  AnomalyBloc({
    required this.detectAnomaliesUseCase,
    this.detectAnomaliesWithCompensationUseCase,
    required this.preferencesBloc,
    required this.allDetectors,
    required this.anomalyRepository,
    required this.newAnomalyDetectionService,
    required this.timesheetRepository,
    required this.anomalyService,
  }) : super(AnomalyInitial()) {
    on<DetectAnomalies>(_onDetectAnomalies);
    on<LoadActiveDetectors>(_onLoadActiveDetectors);
    on<ToggleDetector>(_onToggleDetector);
    on<MarkAnomalyResolved>(_onMarkResolved);
    on<CheckAnomaliesForPdfGeneration>(_onCheckAnomaliesForPdfGeneration);
    on<DetectAnomaliesWithCompensation>(_onDetectAnomaliesWithCompensation);
  }
  Future<void> _onMarkResolved(MarkAnomalyResolved event, Emitter<AnomalyState> emit) async {
    try {
      // Marque l'anomalie comme résolue et rafraîchit la liste
      await anomalyRepository.markResolved(event.anomalyId);
      add(const DetectAnomalies(forceRegenerate: true));
    } catch (e) {
      emit(AnomalyError("Erreur lors de la résolution de l'anomalie : ${e.toString()}"));
    }
  }

  Future<void> _onDetectAnomalies(DetectAnomalies event, Emitter<AnomalyState> emit) async {
    // Utiliser directement le nouveau système avec compensation
    final now = DateTime.now();
    // Ajuster le mois selon la logique de la période (21 au 20)
    final month = now.day > 20 ? now.month + 1 : now.month;
    final year = now.day > 20 && now.month == 12 ? now.year + 1 : now.year;
    
    print('AnomalyBloc: Current date ${now.day}/${now.month}, detecting anomalies for period of month $month/$year');
    add(DetectAnomaliesWithCompensation(month: month, year: year));
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

  /// Nouvelle méthode pour vérifier les anomalies avant génération PDF
  Future<void> _onCheckAnomaliesForPdfGeneration(
    CheckAnomaliesForPdfGeneration event, 
    Emitter<AnomalyState> emit
  ) async {
    emit(AnomalyLoading());
    try {
      // Récupérer les entrées du mois spécifié
      final entries = await timesheetRepository.findEntriesFromMonthOf(event.month, event.year);
      
      // Détecter les anomalies avec compensation hebdomadaire
      final anomaliesResults = await newAnomalyDetectionService.detectAnomaliesWithWeeklyCompensation(entries);
      
      // Rassembler toutes les anomalies
      final allAnomalies = <String>[];
      final criticalAnomalies = <String>[];
      final minorAnomalies = <String>[];
      
      for (final entryAnomalies in anomaliesResults.values) {
        for (final anomaly in entryAnomalies) {
          final message = '${anomaly.type.displayName}: ${anomaly.description}';
          allAnomalies.add(message);
          
          if (anomaly.severity.priority >= 3) { // high et critical
            criticalAnomalies.add(message);
          } else {
            minorAnomalies.add(message);
          }
        }
      }
      
      emit(PdfAnomalyCheckCompleted(
        criticalAnomaliesMessages: criticalAnomalies,
        minorAnomaliesMessages: minorAnomalies,
        month: event.month,
        year: event.year,
      ));
      
    } catch (e) {
      emit(AnomalyError("Erreur lors de la vérification des anomalies : $e"));
    }
  }

  Future<void> _onDetectAnomaliesWithCompensation(
    DetectAnomaliesWithCompensation event,
    Emitter<AnomalyState> emit,
  ) async {
    emit(AnomalyLoading());
    try {
      if (detectAnomaliesWithCompensationUseCase == null) {
        // Fallback sur l'ancien système si le nouveau n'est pas disponible
        add(const DetectAnomalies());
        return;
      }

      final anomalies = await detectAnomaliesWithCompensationUseCase!.execute(
        event.month,
        event.year,
      );

      // Calculer les statistiques hebdomadaires
      final weeklyStats = _calculateWeeklyStats(anomalies);

      emit(AnomaliesWithCompensationLoaded(
        anomalies: anomalies,
        weeklyStats: weeklyStats,
      ));
    } catch (e) {
      emit(AnomalyError("Erreur lors de la détection des anomalies avec compensation : $e"));
    }
  }

  Map<String, dynamic> _calculateWeeklyStats(List<Anomaly> anomalies) {
    final stats = <String, dynamic>{};
    final weekGroups = <String, List<Anomaly>>{};
    
    // Grouper par semaine
    for (var anomaly in anomalies) {
      final weekKey = anomaly.weekReference ?? _getWeekReference(anomaly.date);
      weekGroups.putIfAbsent(weekKey, () => []);
      weekGroups[weekKey]!.add(anomaly);
    }

    // Calculer les statistiques
    int totalWeeks = weekGroups.length;
    int compensatedWeeks = 0;
    int activeWeeks = 0;
    int activeCount = 0;
    int compensatedCount = 0;

    for (var week in weekGroups.entries) {
      bool hasActiveAnomaly = week.value.any((a) => !a.isCompensated);
      if (hasActiveAnomaly) {
        activeWeeks++;
      } else {
        compensatedWeeks++;
      }
    }
    
    // Compter le nombre total d'anomalies
    activeCount = anomalies.where((a) => !a.isCompensated).length;
    compensatedCount = anomalies.where((a) => a.isCompensated).length;

    stats['totalWeeks'] = totalWeeks;
    stats['compensatedWeeks'] = compensatedWeeks;
    stats['activeWeeks'] = activeWeeks;
    stats['activeCount'] = activeCount;
    stats['compensatedCount'] = compensatedCount;
    stats['weekDetails'] = weekGroups;

    return stats;
  }

  String _getWeekReference(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return '${monday.year}-${monday.weekOfYear.toString().padLeft(2, '0')}';
  }
}

extension DateTimeExtension on DateTime {
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysSinceFirstDay = difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }
}