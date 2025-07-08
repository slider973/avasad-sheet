import '../../entities/anomaly_result.dart';
import '../../entities/timesheet_entry.dart';
import '../../value_objects/anomaly_type.dart';
import '../../value_objects/anomaly_severity.dart';
import '../anomaly_rule.dart';

/// Règle qui détecte l'absence de pause obligatoire.
/// 
/// Vérifie qu'une pause d'au moins la durée minimale requise
/// a été prise lors de journées de travail longues.
/// Configurable via les paramètres :
/// - minWorkHoursForBreak : nombre d'heures minimum avant pause obligatoire
/// - minBreakDuration : durée minimum de pause en minutes
class MissingBreakRule extends AnomalyRule {
  @override
  String get id => 'missing_break';

  @override
  String get name => 'Pause manquante';

  @override
  String get description => 
      'Détecte l\'absence de pause obligatoire lors de journées de travail longues';

  @override
  Map<String, dynamic> get defaultConfiguration => {
    'minWorkHoursForBreak': 6,   // 6 heures avant pause obligatoire
    'minBreakDuration': 30,      // Pause minimum de 30 minutes
  };

  @override
  Future<AnomalyResult?> validate(
    TimesheetEntry entry,
    Map<String, dynamic> config,
  ) async {
    final mergedConfig = mergeConfiguration(config);
    final minWorkHoursForBreak = mergedConfig['minWorkHoursForBreak'] as int;
    final minBreakDuration = mergedConfig['minBreakDuration'] as int;
    
    // Calculer le temps de travail total
    final totalWorkMinutes = entry.calculateDailyTotal().inMinutes;
    final minWorkMinutesForBreak = minWorkHoursForBreak * 60;
    
    // Si le temps de travail ne nécessite pas de pause, pas d'anomalie
    if (totalWorkMinutes < minWorkMinutesForBreak) {
      return null;
    }
    
    // Vérifier si une pause a été prise
    final hasBreak = entry.endMorning.isNotEmpty && entry.startAfternoon.isNotEmpty;
    
    if (!hasBreak) {
      // Aucune pause détectée
      final workHours = totalWorkMinutes ~/ 60;
      final workMins = totalWorkMinutes % 60;
      
      return AnomalyResult(
        ruleId: id,
        ruleName: name,
        type: AnomalyType.missingBreak,
        severity: AnomalySeverity.medium,
        description: 'Aucune pause détectée pour une journée de ${workHours}h${workMins.toString().padLeft(2, '0')}min',
        detectedDate: DateTime.now(),
        timesheetEntryId: entry.id?.toString() ?? '',
        metadata: {
          'totalWorkMinutes': totalWorkMinutes,
          'minWorkHoursForBreak': minWorkHoursForBreak,
          'config': mergedConfig,
        },
      );
    }
    
    // Calculer la durée de la pause
    final endMorningMinutes = _timeStringToMinutes(entry.endMorning);
    final startAfternoonMinutes = _timeStringToMinutes(entry.startAfternoon);
    final breakDuration = startAfternoonMinutes - endMorningMinutes;
    
    // Vérifier si la pause est suffisamment longue
    if (breakDuration < minBreakDuration) {
      return AnomalyResult(
        ruleId: id,
        ruleName: name,
        type: AnomalyType.missingBreak,
        severity: AnomalySeverity.low,
        description: 'Pause trop courte: ${breakDuration}min (minimum ${minBreakDuration}min requis)',
        detectedDate: DateTime.now(),
        timesheetEntryId: entry.id?.toString() ?? '',
        metadata: {
          'breakDuration': breakDuration,
          'minBreakDuration': minBreakDuration,
          'totalWorkMinutes': totalWorkMinutes,
          'config': mergedConfig,
        },
      );
    }
    
    return null;
  }

  /// Convertit une chaîne d'heure "HH:mm" en minutes depuis minuit
  int _timeStringToMinutes(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return 0;
      
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      
      return (hours * 60) + minutes;
    } catch (e) {
      return 0;
    }
  }

  @override
  bool isConfigurationValid(Map<String, dynamic> config) {
    if (!config.containsKey('minWorkHoursForBreak') || 
        !config.containsKey('minBreakDuration')) {
      return false;
    }
    
    final minWorkHoursForBreak = config['minWorkHoursForBreak'];
    final minBreakDuration = config['minBreakDuration'];
    
    return minWorkHoursForBreak is int && minWorkHoursForBreak >= 4 && minWorkHoursForBreak <= 12 &&
           minBreakDuration is int && minBreakDuration >= 15 && minBreakDuration <= 180;
  }
}