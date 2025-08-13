import '../../entities/anomaly_result.dart';
import '../../entities/timesheet_entry.dart';
import '../../value_objects/anomaly_type.dart';
import '../../value_objects/anomaly_severity.dart';
import '../anomaly_rule.dart';

/// Règle de compensation hebdomadaire qui annule les anomalies d'heures insuffisantes
/// si le total hebdomadaire est conforme.
/// 
/// Cette règle vérifie si une journée avec des heures insuffisantes peut être
/// compensée par des heures supplémentaires effectuées les autres jours de la même semaine.
/// 
/// Configuration:
/// - weeklyRequiredMinutes : total d'heures requis par semaine (défaut: 2490 min = 41h30)
/// - compensationTolerance : tolérance en minutes pour la compensation (défaut: 15 min)
/// - maxDailyCompensation : compensation maximum par jour en minutes (défaut: 120 min = 2h)
class WeeklyCompensationRule extends AnomalyRule {
  @override
  String get id => 'weekly_compensation';

  @override
  String get name => 'Compensation hebdomadaire';

  @override
  String get description => 
      'Annule les anomalies d\'heures insuffisantes si elles sont compensées dans la semaine';

  @override
  Map<String, dynamic> get defaultConfiguration => {
    'weeklyRequiredMinutes': 2490,   // 41h30 par semaine (5 jours × 8h18)
    'compensationTolerance': 15,     // Tolérance de 15 minutes
    'maxDailyCompensation': 120,     // Max 2h de compensation par jour
    'minDailyHours': 6,              // Minimum 6h par jour même avec compensation
  };

  @override
  Future<AnomalyResult?> validate(
    TimesheetEntry entry,
    Map<String, dynamic> config,
  ) async {
    // Cette règle ne valide pas les entrées individuelles
    // Elle est utilisée dans le contexte de validation hebdomadaire
    return null;
  }

  /// Valide un groupe d'entrées pour une semaine et retourne les anomalies
  /// après application de la compensation hebdomadaire
  Future<List<AnomalyResult>> validateWeek(
    List<TimesheetEntry> weekEntries,
    List<AnomalyResult> existingAnomalies,
    Map<String, dynamic> config,
  ) async {
    final mergedConfig = mergeConfiguration(config);
    
    final weeklyRequiredMinutes = mergedConfig['weeklyRequiredMinutes'] as int;
    final compensationTolerance = mergedConfig['compensationTolerance'] as int;
    final maxDailyCompensation = mergedConfig['maxDailyCompensation'] as int;
    final minDailyHours = mergedConfig['minDailyHours'] as int;
    
    // Calculer le total hebdomadaire effectif
    final totalWorkedMinutes = weekEntries
        .map((entry) => entry.calculateDailyTotal().inMinutes)
        .fold(0, (sum, minutes) => sum + minutes);
    
    // Vérifier si le total hebdomadaire est suffisant
    final weeklyTarget = weeklyRequiredMinutes - compensationTolerance;
    
    if (totalWorkedMinutes < weeklyTarget) {
      // Insuffisant au niveau hebdomadaire, garder toutes les anomalies
      return existingAnomalies;
    }
    
    // Le total hebdomadaire est suffisant, analyser les compensations possibles
    final compensatedAnomalies = <AnomalyResult>[];
    final insufficientHoursAnomalies = existingAnomalies
        .where((anomaly) => anomaly.type == AnomalyType.insufficientHours)
        .toList();
    
    // Calculer les heures supplémentaires disponibles pour compensation
    final dailyTargetMinutes = (weeklyRequiredMinutes / weekEntries.length).round();
    final surplusMinutes = <String, int>{}; // entry.id -> surplus minutes
    
    for (final entry in weekEntries) {
      final workedMinutes = entry.calculateDailyTotal().inMinutes;
      final minDailyMinutes = minDailyHours * 60;
      
      if (workedMinutes > dailyTargetMinutes && workedMinutes >= minDailyMinutes) {
        final surplus = workedMinutes - dailyTargetMinutes;
        final availableForCompensation = surplus.clamp(0, maxDailyCompensation);
        if (availableForCompensation > 0) {
          surplusMinutes[entry.id?.toString() ?? ''] = availableForCompensation;
        }
      }
    }
    
    // Calculer le total de compensation disponible
    final totalCompensationAvailable = surplusMinutes.values
        .fold(0, (sum, surplus) => sum + surplus);
    
    // Calculer le déficit total des anomalies d'heures insuffisantes
    int totalDeficit = 0;
    for (final anomaly in insufficientHoursAnomalies) {
      final deficitMinutes = anomaly.metadata['shortfallMinutes'] as int? ?? 0;
      totalDeficit += deficitMinutes;
    }
    
    // Si la compensation couvre le déficit, annuler les anomalies
    if (totalCompensationAvailable >= totalDeficit) {
      // Créer des anomalies compensées (informatives)
      for (final anomaly in insufficientHoursAnomalies) {
        final deficitMinutes = anomaly.metadata['shortfallMinutes'] as int? ?? 0;
        final deficitHours = deficitMinutes ~/ 60;
        final deficitMins = deficitMinutes % 60;
        
        String compensationDescription;
        if (deficitHours > 0) {
          compensationDescription = 'Heures insuffisantes (${deficitHours}h${deficitMins.toString().padLeft(2, '0')}min) compensées par la semaine';
        } else {
          compensationDescription = 'Heures insuffisantes (${deficitMins}min) compensées par la semaine';
        }
        
        final compensatedAnomaly = AnomalyResult(
          ruleId: id,
          ruleName: name,
          type: AnomalyType.insufficientHours,
          severity: AnomalySeverity.low, // Réduit à low car compensé
          description: compensationDescription,
          detectedDate: DateTime.now(),
          timesheetEntryId: anomaly.timesheetEntryId,
          metadata: {
            'originalAnomalyId': anomaly.ruleId,
            'compensated': true,
            'originalDeficit': deficitMinutes,
            'weeklyTotal': totalWorkedMinutes,
            'weeklyTarget': weeklyRequiredMinutes,
            'compensationUsed': deficitMinutes,
            'surplusDistribution': surplusMinutes,
          },
        );
        
        compensatedAnomalies.add(compensatedAnomaly);
      }
      
      // Ajouter les autres anomalies (non liées aux heures insuffisantes)
      final otherAnomalies = existingAnomalies
          .where((anomaly) => anomaly.type != AnomalyType.insufficientHours)
          .toList();
      
      return [...compensatedAnomalies, ...otherAnomalies];
    }
    
    // Pas assez de compensation, garder les anomalies originales
    return existingAnomalies;
  }

  @override
  bool isConfigurationValid(Map<String, dynamic> config) {
    if (!config.containsKey('weeklyRequiredMinutes') || 
        !config.containsKey('compensationTolerance') || 
        !config.containsKey('maxDailyCompensation') ||
        !config.containsKey('minDailyHours')) {
      return false;
    }
    
    final weeklyRequiredMinutes = config['weeklyRequiredMinutes'];
    final compensationTolerance = config['compensationTolerance'];
    final maxDailyCompensation = config['maxDailyCompensation'];
    final minDailyHours = config['minDailyHours'];
    
    return weeklyRequiredMinutes is int && weeklyRequiredMinutes > 0 &&
           compensationTolerance is int && compensationTolerance >= 0 &&
           maxDailyCompensation is int && maxDailyCompensation >= 0 &&
           minDailyHours is int && minDailyHours >= 0 && minDailyHours <= 12;
  }
}