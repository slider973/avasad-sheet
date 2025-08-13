import '../../entities/anomaly_result.dart';
import '../../entities/timesheet_entry.dart';
import '../../value_objects/anomaly_type.dart';
import '../../value_objects/anomaly_severity.dart';
import '../anomaly_rule.dart';

/// Règle qui détecte les incohérences dans les heures de pointage.
/// 
/// Vérifie la logique temporelle :
/// - Heure de fin après heure de début
/// - Heures de pause cohérentes
/// - Chevauchements temporels
class InvalidTimesRule extends AnomalyRule {
  @override
  String get id => 'invalid_times';

  @override
  String get name => 'Heures invalides';

  @override
  String get description => 
      'Détecte les incohérences dans les heures de pointage (fin avant début, pauses invalides, etc.)';

  @override
  Map<String, dynamic> get defaultConfiguration => {
    'checkPauseLogic': true,     // Vérifier la logique des pauses
    'maxBreakDuration': 120,     // Pause maximum de 2h
    'minBreakDuration': 15,      // Pause minimum de 15min
  };

  @override
  Future<AnomalyResult?> validate(
    TimesheetEntry entry,
    Map<String, dynamic> config,
  ) async {
    final mergedConfig = mergeConfiguration(config);
    final checkPauseLogic = mergedConfig['checkPauseLogic'] as bool;
    final maxBreakDuration = mergedConfig['maxBreakDuration'] as int;
    final minBreakDuration = mergedConfig['minBreakDuration'] as int;
    
    final issues = <String>[];
    
    // Vérifier que l'heure de fin est après l'heure de début
    if (entry.endMorning.isNotEmpty && entry.startMorning.isNotEmpty) {
      if (_timeStringToMinutes(entry.endMorning) <= _timeStringToMinutes(entry.startMorning)) {
        issues.add('Fin de matinée avant ou égale au début');
      }
    }
    
    if (entry.endAfternoon.isNotEmpty && entry.startAfternoon.isNotEmpty) {
      if (_timeStringToMinutes(entry.endAfternoon) <= _timeStringToMinutes(entry.startAfternoon)) {
        issues.add('Fin d\'après-midi avant ou égale au début');
      }
    }
    
    // Vérifier la logique des pauses si activée
    if (checkPauseLogic) {
      if (entry.endMorning.isNotEmpty && entry.startAfternoon.isNotEmpty) {
        final finMatin = _timeStringToMinutes(entry.endMorning);
        final debutApresMidi = _timeStringToMinutes(entry.startAfternoon);
        final pauseDuration = debutApresMidi - finMatin;
        
        if (pauseDuration < minBreakDuration) {
          issues.add('Pause trop courte: ${pauseDuration}min (minimum ${minBreakDuration}min)');
        } else if (pauseDuration > maxBreakDuration) {
          issues.add('Pause trop longue: ${pauseDuration}min (maximum ${maxBreakDuration}min)');
        }
      }
    }
    
    // Vérifier les heures aberrantes (24h+)
    for (final time in [
      entry.startMorning,
      entry.endMorning,
      entry.startAfternoon,
      entry.endAfternoon,
    ]) {
      if (time.isNotEmpty && !_isValidTimeFormat(time)) {
        issues.add('Format d\'heure invalide: $time');
      }
    }
    
    if (issues.isNotEmpty) {
      AnomalySeverity severity;
      if (issues.length >= 3) {
        severity = AnomalySeverity.high;
      } else if (issues.length == 2) {
        severity = AnomalySeverity.medium;
      } else {
        severity = AnomalySeverity.low;
      }
      
      return AnomalyResult(
        ruleId: id,
        ruleName: name,
        type: AnomalyType.invalidTimes,
        severity: severity,
        description: 'Heures invalides: ${issues.join(', ')}',
        detectedDate: DateTime.now(),
        timesheetEntryId: entry.id?.toString() ?? '',
        metadata: {
          'issues': issues,
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

  /// Vérifie si le format d'heure est valide
  bool _isValidTimeFormat(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return false;
      
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      
      return hours >= 0 && hours < 24 && minutes >= 0 && minutes < 60;
    } catch (e) {
      return false;
    }
  }

  @override
  bool isConfigurationValid(Map<String, dynamic> config) {
    if (!config.containsKey('checkPauseLogic') || 
        !config.containsKey('maxBreakDuration') || 
        !config.containsKey('minBreakDuration')) {
      return false;
    }
    
    final checkPauseLogic = config['checkPauseLogic'];
    final maxBreakDuration = config['maxBreakDuration'];
    final minBreakDuration = config['minBreakDuration'];
    
    return checkPauseLogic is bool &&
           maxBreakDuration is int && maxBreakDuration > 0 && maxBreakDuration <= 480 &&
           minBreakDuration is int && minBreakDuration > 0 && minBreakDuration < maxBreakDuration;
  }
}