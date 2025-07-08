import '../../entities/anomaly_result.dart';
import '../../entities/timesheet_entry.dart';
import '../../value_objects/anomaly_type.dart';
import '../../value_objects/anomaly_severity.dart';
import '../anomaly_rule.dart';

/// Règle qui détecte les journées avec un nombre d'heures excessif.
/// 
/// Vérifie que le temps de travail ne dépasse pas un maximum raisonnable.
/// Configurable via les paramètres :
/// - maxHours : nombre d'heures maximum autorisé
/// - maxMinutes : minutes supplémentaires maximum
/// - toleranceMinutes : tolérance avant de déclencher l'anomalie
class ExcessiveHoursRule extends AnomalyRule {
  @override
  String get id => 'excessive_hours';

  @override
  String get name => 'Heures excessives';

  @override
  String get description => 
      'Détecte les journées où le temps de travail dépasse le maximum autorisé';

  @override
  Map<String, dynamic> get defaultConfiguration => {
    'maxHours': 12,          // 12 heures maximum
    'maxMinutes': 0,         // 0 minutes supplémentaires
    'toleranceMinutes': 15,  // Tolérance de 15 minutes
  };

  @override
  Future<AnomalyResult?> validate(
    TimesheetEntry entry,
    Map<String, dynamic> config,
  ) async {
    final mergedConfig = mergeConfiguration(config);
    
    final maxHours = mergedConfig['maxHours'] as int;
    final maxMinutes = mergedConfig['maxMinutes'] as int;
    final toleranceMinutes = mergedConfig['toleranceMinutes'] as int;
    
    final maxAllowedMinutes = (maxHours * 60) + maxMinutes;
    final workedMinutes = entry.calculateDailyTotal().inMinutes;
    final maximumWithTolerance = maxAllowedMinutes + toleranceMinutes;
    
    if (workedMinutes > maximumWithTolerance) {
      final excess = workedMinutes - maxAllowedMinutes;
      final excessHours = excess ~/ 60;
      final excessMins = excess % 60;
      
      // Sévérité selon l'excès
      AnomalySeverity severity;
      if (excess >= 180) { // 3h ou plus
        severity = AnomalySeverity.critical;
      } else if (excess >= 120) { // 2h ou plus
        severity = AnomalySeverity.high;
      } else if (excess >= 60) { // 1h ou plus
        severity = AnomalySeverity.medium;
      } else {
        severity = AnomalySeverity.low;
      }
      
      String description;
      if (excessHours > 0) {
        description = 'Temps de travail excessif: ${excessHours}h${excessMins.toString().padLeft(2, '0')}min de trop';
      } else {
        description = 'Temps de travail excessif: ${excessMins}min de trop';
      }
      
      return AnomalyResult(
        ruleId: id,
        ruleName: name,
        type: AnomalyType.excessiveHours,
        severity: severity,
        description: description,
        detectedDate: DateTime.now(),
        timesheetEntryId: entry.id?.toString() ?? '',
        metadata: {
          'workedMinutes': workedMinutes,
          'maxAllowedMinutes': maxAllowedMinutes,
          'excessMinutes': excess,
          'config': mergedConfig,
        },
      );
    }
    
    return null;
  }

  @override
  bool isConfigurationValid(Map<String, dynamic> config) {
    if (!config.containsKey('maxHours') || 
        !config.containsKey('maxMinutes') || 
        !config.containsKey('toleranceMinutes')) {
      return false;
    }
    
    final maxHours = config['maxHours'];
    final maxMinutes = config['maxMinutes'];
    final toleranceMinutes = config['toleranceMinutes'];
    
    return maxHours is int && maxHours >= 8 && maxHours <= 24 &&
           maxMinutes is int && maxMinutes >= 0 && maxMinutes < 60 &&
           toleranceMinutes is int && toleranceMinutes >= 0 && toleranceMinutes <= 60;
  }
}