import '../../entities/anomaly_result.dart';
import '../../entities/timesheet_entry.dart';
import '../../value_objects/anomaly_type.dart';
import '../../value_objects/anomaly_severity.dart';
import '../anomaly_rule.dart';

/// Règle qui détecte les incohérences dans les horaires de travail.
/// 
/// Vérifie la cohérence des horaires sur plusieurs aspects :
/// - Horaires de début et fin dans des plages raisonnables
/// - Cohérence avec les horaires standards de l'entreprise
/// - Détection d'horaires inhabituels (très tôt/très tard)
class ScheduleConsistencyRule extends AnomalyRule {
  @override
  String get id => 'schedule_consistency';

  @override
  String get name => 'Cohérence des horaires';

  @override
  String get description => 
      'Détecte les incohérences dans les horaires de travail (horaires inhabituels, hors plages standard)';

  @override
  Map<String, dynamic> get defaultConfiguration => {
    'earliestStartTime': '06:00',    // Heure de début la plus tôt
    'latestEndTime': '22:00',        // Heure de fin la plus tard
    'standardStartTime': '08:00',    // Heure de début standard
    'standardEndTime': '17:00',      // Heure de fin standard
    'toleranceMinutes': 30,          // Tolérance en minutes
    'flagUnusualHours': true,        // Signaler les horaires inhabituels
  };

  @override
  Future<AnomalyResult?> validate(
    TimesheetEntry entry,
    Map<String, dynamic> config,
  ) async {
    final mergedConfig = mergeConfiguration(config);
    
    final earliestStart = mergedConfig['earliestStartTime'] as String;
    final latestEnd = mergedConfig['latestEndTime'] as String;
    final standardStart = mergedConfig['standardStartTime'] as String;
    final standardEnd = mergedConfig['standardEndTime'] as String;
    final toleranceMinutes = mergedConfig['toleranceMinutes'] as int;
    final flagUnusualHours = mergedConfig['flagUnusualHours'] as bool;
    
    final issues = <String>[];
    
    // Vérifier les horaires de début de matinée
    if (entry.startMorning.isNotEmpty) {
      final startMinutes = _timeStringToMinutes(entry.startMorning);
      final earliestMinutes = _timeStringToMinutes(earliestStart);
      final standardStartMinutes = _timeStringToMinutes(standardStart);
      
      if (startMinutes < earliestMinutes) {
        issues.add('Début trop tôt: ${entry.startMorning} (avant ${earliestStart})');
      } else if (flagUnusualHours && 
                 (startMinutes < standardStartMinutes - toleranceMinutes || 
                  startMinutes > standardStartMinutes + toleranceMinutes)) {
        issues.add('Horaire de début inhabituel: ${entry.startMorning}');
      }
    }
    
    // Vérifier les horaires de fin d'après-midi
    if (entry.endAfternoon.isNotEmpty) {
      final endMinutes = _timeStringToMinutes(entry.endAfternoon);
      final latestMinutes = _timeStringToMinutes(latestEnd);
      final standardEndMinutes = _timeStringToMinutes(standardEnd);
      
      if (endMinutes > latestMinutes) {
        issues.add('Fin trop tard: ${entry.endAfternoon} (après ${latestEnd})');
      } else if (flagUnusualHours && 
                 (endMinutes < standardEndMinutes - toleranceMinutes || 
                  endMinutes > standardEndMinutes + toleranceMinutes)) {
        issues.add('Horaire de fin inhabituel: ${entry.endAfternoon}');
      }
    }
    
    // Vérifier les horaires de pause (ne doivent pas être en dehors des heures de travail)
    if (entry.endMorning.isNotEmpty && entry.startAfternoon.isNotEmpty) {
      final pauseStart = _timeStringToMinutes(entry.endMorning);
      final pauseEnd = _timeStringToMinutes(entry.startAfternoon);
      
      // Pause typique entre 11h30 et 14h30
      if (pauseStart < _timeStringToMinutes('11:00') || pauseStart > _timeStringToMinutes('14:00')) {
        issues.add('Début de pause inhabituel: ${entry.endMorning}');
      }
      
      if (pauseEnd < _timeStringToMinutes('12:00') || pauseEnd > _timeStringToMinutes('15:00')) {
        issues.add('Fin de pause inhabituelle: ${entry.startAfternoon}');
      }
    }
    
    // Vérifier les journées fragmentées (plusieurs pauses non prévues)
    if (_hasFragmentedSchedule(entry)) {
      issues.add('Horaire fragmenté détecté');
    }
    
    if (issues.isNotEmpty) {
      AnomalySeverity severity;
      if (issues.any((issue) => issue.contains('trop tôt') || issue.contains('trop tard'))) {
        severity = AnomalySeverity.high;
      } else if (issues.length >= 2) {
        severity = AnomalySeverity.medium;
      } else {
        severity = AnomalySeverity.low;
      }
      
      return AnomalyResult(
        ruleId: id,
        ruleName: name,
        type: AnomalyType.scheduleInconsistency,
        severity: severity,
        description: 'Incohérences horaires: ${issues.join(', ')}',
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

  /// Détecte si l'horaire est fragmenté (indication de plusieurs pauses ou interruptions)
  bool _hasFragmentedSchedule(TimesheetEntry entry) {
    // Logique simple: si l'une des périodes est vide alors qu'il y a d'autres pointages
    final hasStartMorning = entry.startMorning.isNotEmpty;
    final hasEndMorning = entry.endMorning.isNotEmpty;
    final hasStartAfternoon = entry.startAfternoon.isNotEmpty;
    final hasEndAfternoon = entry.endAfternoon.isNotEmpty;
    
    // Fragmentation: commencé le matin mais pas fini l'après-midi, ou gaps inhabituels
    if (hasStartMorning && hasEndMorning && hasStartAfternoon && !hasEndAfternoon) {
      return false; // Journée en cours, pas fragmentée
    }
    
    if (hasStartMorning && !hasEndMorning && hasStartAfternoon) {
      return true; // A sauté la fin de matinée
    }
    
    return false;
  }

  @override
  bool isConfigurationValid(Map<String, dynamic> config) {
    final requiredKeys = [
      'earliestStartTime', 'latestEndTime', 'standardStartTime', 
      'standardEndTime', 'toleranceMinutes', 'flagUnusualHours'
    ];
    
    for (final key in requiredKeys) {
      if (!config.containsKey(key)) return false;
    }
    
    final toleranceMinutes = config['toleranceMinutes'];
    final flagUnusualHours = config['flagUnusualHours'];
    
    return toleranceMinutes is int && toleranceMinutes >= 0 && toleranceMinutes <= 120 &&
           flagUnusualHours is bool &&
           _isValidTimeFormat(config['earliestStartTime'] as String) &&
           _isValidTimeFormat(config['latestEndTime'] as String) &&
           _isValidTimeFormat(config['standardStartTime'] as String) &&
           _isValidTimeFormat(config['standardEndTime'] as String);
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
}