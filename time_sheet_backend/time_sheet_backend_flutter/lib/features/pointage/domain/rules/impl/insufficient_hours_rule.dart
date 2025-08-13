import '../../entities/anomaly_result.dart';
import '../../entities/timesheet_entry.dart';
import '../../value_objects/anomaly_type.dart';
import '../../value_objects/anomaly_severity.dart';
import '../anomaly_rule.dart';

/// Règle qui détecte les journées avec un nombre d'heures insuffisant.
/// 
/// Par défaut, vérifie que le temps de travail est d'au moins 8h18 (498 minutes).
/// Cette règle est configurable via les paramètres :
/// - minHours : nombre d'heures minimum requis
/// - minMinutes : minutes supplémentaires minimum
/// - toleranceMinutes : tolérance en minutes avant de déclencher l'anomalie
class InsufficientHoursRule extends AnomalyRule {
  @override
  String get id => 'insufficient_hours';

  @override
  String get name => 'Heures insuffisantes';

  @override
  String get description => 
      'Détecte les journées où le temps de travail est inférieur au minimum requis';

  @override
  Map<String, dynamic> get defaultConfiguration => {
    'minHours': 8,           // 8 heures minimum
    'minMinutes': 18,        // + 18 minutes (pause légale)
    'toleranceMinutes': 5,   // Tolérance de 5 minutes
  };

  @override
  Future<AnomalyResult?> validate(
    TimesheetEntry entry,
    Map<String, dynamic> config,
  ) async {
    // Fusionner avec la configuration par défaut
    final mergedConfig = mergeConfiguration(config);
    
    // Extraire les paramètres
    final minHours = mergedConfig['minHours'] as int;
    final minMinutes = mergedConfig['minMinutes'] as int;
    final toleranceMinutes = mergedConfig['toleranceMinutes'] as int;
    
    // Calculer le temps minimum requis en minutes
    final requiredMinutes = (minHours * 60) + minMinutes;
    
    // Calculer le temps de travail effectif
    final workedMinutes = entry.calculateDailyTotal().inMinutes;
    
    // Appliquer la tolérance
    final minimumWithTolerance = requiredMinutes - toleranceMinutes;
    
    // Vérifier si le temps est insuffisant
    if (workedMinutes < minimumWithTolerance) {
      final shortfall = requiredMinutes - workedMinutes;
      final shortfallHours = shortfall ~/ 60;
      final shortfallMins = shortfall % 60;
      
      // Déterminer la sévérité selon l'écart
      AnomalySeverity severity;
      if (shortfall >= 120) { // 2h ou plus
        severity = AnomalySeverity.high;
      } else if (shortfall >= 60) { // 1h ou plus
        severity = AnomalySeverity.medium;
      } else {
        severity = AnomalySeverity.low;
      }
      
      // Créer le message descriptif
      String description;
      if (shortfallHours > 0) {
        description = 'Temps de travail insuffisant: il manque ${shortfallHours}h${shortfallMins.toString().padLeft(2, '0')}min';
      } else {
        description = 'Temps de travail insuffisant: il manque ${shortfallMins}min';
      }
      
      return AnomalyResult(
        ruleId: id,
        ruleName: name,
        type: AnomalyType.insufficientHours,
        severity: severity,
        description: description,
        detectedDate: DateTime.now(),
        timesheetEntryId: entry.id?.toString() ?? '',
        metadata: {
          'workedMinutes': workedMinutes,
          'requiredMinutes': requiredMinutes,
          'shortfallMinutes': shortfall,
          'config': mergedConfig,
        },
      );
    }
    
    return null; // Pas d'anomalie détectée
  }

  @override
  bool isConfigurationValid(Map<String, dynamic> config) {
    // Vérifier que les paramètres requis sont présents et valides
    if (!config.containsKey('minHours') || 
        !config.containsKey('minMinutes') || 
        !config.containsKey('toleranceMinutes')) {
      return false;
    }
    
    final minHours = config['minHours'];
    final minMinutes = config['minMinutes'];
    final toleranceMinutes = config['toleranceMinutes'];
    
    // Vérifier les types et valeurs
    return minHours is int && minHours >= 0 && minHours <= 24 &&
           minMinutes is int && minMinutes >= 0 && minMinutes < 60 &&
           toleranceMinutes is int && toleranceMinutes >= 0 && toleranceMinutes <= 60;
  }
}