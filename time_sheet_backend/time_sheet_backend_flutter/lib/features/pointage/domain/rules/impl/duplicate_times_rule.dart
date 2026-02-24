import '../../entities/anomaly_result.dart';
import '../../entities/timesheet_entry.dart';
import '../../value_objects/anomaly_type.dart';
import '../../value_objects/anomaly_severity.dart';
import '../anomaly_rule.dart';

/// Règle qui détecte les journées où les 4 heures de pointage sont identiques.
///
/// Quand un utilisateur met la même heure pour début matin, fin matin,
/// début après-midi et fin après-midi, c'est clairement une erreur de saisie.
class DuplicateTimesRule extends AnomalyRule {
  @override
  String get id => 'duplicate_times';

  @override
  String get name => 'Heures identiques';

  @override
  String get description =>
      'Détecte les journées où les heures de pointage sont toutes identiques (erreur de saisie)';

  @override
  Map<String, dynamic> get defaultConfiguration => {
    'minDuplicateCount': 3, // Minimum d'heures identiques pour déclencher
  };

  @override
  Future<AnomalyResult?> validate(
    TimesheetEntry entry,
    Map<String, dynamic> config,
  ) async {
    final mergedConfig = mergeConfiguration(config);
    final minDuplicateCount = mergedConfig['minDuplicateCount'] as int;

    // Collecter les heures non vides
    final times = <String>[
      if (entry.startMorning.isNotEmpty) entry.startMorning,
      if (entry.endMorning.isNotEmpty) entry.endMorning,
      if (entry.startAfternoon.isNotEmpty) entry.startAfternoon,
      if (entry.endAfternoon.isNotEmpty) entry.endAfternoon,
    ];

    if (times.length < 2) return null;

    // Compter les occurrences de chaque heure
    final counts = <String, int>{};
    for (final time in times) {
      counts[time] = (counts[time] ?? 0) + 1;
    }

    // Trouver le maximum de doublons
    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
    final duplicateTime = counts.entries.firstWhere((e) => e.value == maxCount).key;

    if (maxCount >= minDuplicateCount) {
      AnomalySeverity severity;
      String description;

      if (maxCount == 4) {
        severity = AnomalySeverity.critical;
        description =
            'Les 4 heures de pointage sont identiques ($duplicateTime) — erreur de saisie probable';
      } else if (maxCount == 3) {
        severity = AnomalySeverity.high;
        description =
            '3 heures de pointage sur 4 sont identiques ($duplicateTime) — vérifiez la saisie';
      } else {
        severity = AnomalySeverity.medium;
        description =
            '$maxCount heures de pointage sont identiques ($duplicateTime)';
      }

      return AnomalyResult(
        ruleId: id,
        ruleName: name,
        type: AnomalyType.invalidTimes,
        severity: severity,
        description: description,
        detectedDate: DateTime.now(),
        timesheetEntryId: entry.id?.toString() ?? '',
        metadata: {
          'duplicateTime': duplicateTime,
          'duplicateCount': maxCount,
          'times': {
            'startMorning': entry.startMorning,
            'endMorning': entry.endMorning,
            'startAfternoon': entry.startAfternoon,
            'endAfternoon': entry.endAfternoon,
          },
          'config': mergedConfig,
        },
      );
    }

    return null;
  }

  @override
  bool isConfigurationValid(Map<String, dynamic> config) {
    if (!config.containsKey('minDuplicateCount')) return false;
    final minDuplicateCount = config['minDuplicateCount'];
    return minDuplicateCount is int && minDuplicateCount >= 2 && minDuplicateCount <= 4;
  }
}
