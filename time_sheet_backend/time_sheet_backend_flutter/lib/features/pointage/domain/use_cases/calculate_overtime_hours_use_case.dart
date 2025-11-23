import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/preference/domain/repositories/overtime_configuration_repository.dart';
import 'package:time_sheet/services/logger_service.dart';

/// Use case for calculating overtime hours with monthly deficit compensation
///
/// This use case handles overtime calculations by:
/// - Loading the daily work threshold from OvertimeConfiguration
/// - Separating weekend and weekday entries
/// - Compensating weekday deficits against excess hours
/// - Applying different overtime rates for weekend vs weekday work
///
/// The daily threshold is loaded from OvertimeConfiguration with a fallback
/// to the default value (8h18) if configuration loading fails.
class CalculateOvertimeHoursUseCase {
  final OvertimeConfigurationRepository _configRepository;

  CalculateOvertimeHoursUseCase({
    required OvertimeConfigurationRepository configRepository,
  }) : _configRepository = configRepository;

  /// Calculates overtime hours for a single timesheet entry
  ///
  /// [entry] The timesheet entry to calculate overtime for
  /// [dailyThreshold] The daily work threshold (defaults to 8h18 if not provided)
  /// Returns the duration of overtime hours
  Future<Duration> execute({
    required TimesheetEntry entry,
    required double normalHoursThreshold, // Keep for backward compatibility
  }) async {
    final totalHours = entry.calculateDailyTotal();

    // Pour les weekends avec overtime activé, toutes les heures sont supplémentaires
    if (entry.isWeekendDay && entry.isWeekendOvertimeEnabled) {
      return totalHours;
    }

    // Pour les jours de semaine, vérifier si hasOvertimeHours est activé
    if (!entry.hasOvertimeHours) {
      return Duration.zero;
    }

    final thresholdDuration = Duration(
      hours: normalHoursThreshold.floor(),
      minutes: ((normalHoursThreshold % 1) * 60).round(),
    );

    if (totalHours > thresholdDuration) {
      return totalHours - thresholdDuration;
    }

    return Duration.zero;
  }

  /// Calculates monthly overtime with deficit compensation
  ///
  /// [entries] List of timesheet entries for the month
  /// [normalHoursThreshold] The daily work threshold in hours (e.g., 8.3 for 8h18)
  ///                        This parameter is kept for backward compatibility
  /// Returns a [MonthlyOvertimeResult] with total overtime and breakdown by day
  ///
  /// Note: The daily threshold should be loaded from OvertimeConfiguration.
  /// This method loads it automatically with fallback to default (8h18) if loading fails.
  Future<MonthlyOvertimeResult> executeMonthly({
    required List<TimesheetEntry> entries,
    required double normalHoursThreshold,
  }) async {
    print('\n========== CALCUL MENSUEL CÔTÉ CLIENT ==========');
    print('Nombre d\'entrées: ${entries.length}');
    
    // LOG DÉTAILLÉ : Lister toutes les entrées avec leurs dates
    print('\n📋 LISTE COMPLÈTE DES ENTRÉES :');
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final total = entry.calculateDailyTotal();
      final isWeekend = entry.isWeekendDay ? '🔵 WEEKEND' : '⚪ SEMAINE';
      final hasAbsence = entry.absence != null ? '❌ ABSENCE' : '✅';
      print('  ${i + 1}. ${entry.dayDate} $isWeekend $hasAbsence - ${total.inHours}h${total.inMinutes.remainder(60)}m');
    }
    print('==========================================\n');

    // Load configuration from repository with error handling
    Duration dailyThreshold;
    double weekdayRate;
    double weekendRate;

    try {
      final config = await _configRepository.getOrCreateDefaultConfiguration();
      dailyThreshold = config.dailyWorkThreshold;
      weekdayRate = config.weekdayOvertimeRate;
      weekendRate = config.weekendOvertimeRate;

      print(
          'Seuil journalier (depuis config): ${dailyThreshold.inHours}h ${dailyThreshold.inMinutes.remainder(60)}min');
      print('Taux weekday: $weekdayRate, Taux weekend: $weekendRate');
    } catch (e) {
      // Fallback to default values if configuration loading fails
      dailyThreshold = const Duration(hours: 8, minutes: 18);
      weekdayRate = 1.25;
      weekendRate = 1.5;
      logger.w(
          'Échec du chargement de la configuration, utilisation des valeurs par défaut: $e');
      print(
          'ATTENTION: Utilisation des valeurs par défaut (8h18, taux 1.25/1.5)');
    }

    final thresholdDuration = dailyThreshold;

    // Séparer les entrées par type (weekend vs weekday)
    final weekdayEntries = <TimesheetEntry>[];
    final weekendEntries = <TimesheetEntry>[];

    for (final entry in entries) {
      if (entry.absence != null) continue; // Ignorer les absences

      if (entry.isWeekendDay && entry.isWeekendOvertimeEnabled) {
        weekendEntries.add(entry);
      } else {
        weekdayEntries.add(entry);
      }
    }

    print('Entrées weekday: ${weekdayEntries.length}');
    print('Entrées weekend: ${weekendEntries.length}');

    // Calculer les heures weekend (toutes les heures sont des heures sup)
    Duration totalWeekendOvertime = Duration.zero;
    Map<String, Duration> overtimeByDay = {};

    for (final entry in weekendEntries) {
      final dailyTotal = entry.calculateDailyTotal();
      totalWeekendOvertime += dailyTotal;
      overtimeByDay[entry.dayDate] = dailyTotal;
      print(
          'Weekend ${entry.dayDate}: ${_formatDuration(dailyTotal)} (tout en heures sup)');
    }

    // Calculer les heures weekday avec compensation des déficits
    Duration totalWorkedMinutes = Duration.zero;
    Duration totalDeficitMinutes = Duration.zero;
    Duration totalExcessMinutes = Duration.zero;

    for (final entry in weekdayEntries) {
      final dailyTotal = entry.calculateDailyTotal();
      totalWorkedMinutes += dailyTotal;

      if (dailyTotal < thresholdDuration) {
        // Déficit d'heures ce jour
        final deficit = thresholdDuration - dailyTotal;
        totalDeficitMinutes += deficit;
        print(
            'Weekday ${entry.dayDate}: ${_formatDuration(dailyTotal)} - DÉFICIT de ${_formatDuration(deficit)}');
      } else if (dailyTotal > thresholdDuration) {
        // Excès d'heures ce jour
        final excess = dailyTotal - thresholdDuration;
        totalExcessMinutes += excess;
        print(
            'Weekday ${entry.dayDate}: ${_formatDuration(dailyTotal)} - EXCÈS de ${_formatDuration(excess)}');
      } else {
        print(
            'Weekday ${entry.dayDate}: ${_formatDuration(dailyTotal)} - EXACT');
      }
    }

    // Calculer les heures théoriques attendues
    final expectedMinutes = thresholdDuration * weekdayEntries.length;

    print('\n--- RÉSUMÉ WEEKDAY ---');
    print('Total travaillé: ${_formatDuration(totalWorkedMinutes)}');
    print('Total attendu: ${_formatDuration(expectedMinutes)}');
    print('Total déficits: ${_formatDuration(totalDeficitMinutes)}');
    print('Total excès: ${_formatDuration(totalExcessMinutes)}');

    // Calculer les heures supplémentaires réelles après compensation des déficits
    // LOGIQUE: Solde net = excès - déficits (peut être négatif)
    Duration realWeekdayOvertime = Duration.zero;

    // Toujours utiliser la logique excès - déficits (solde net)
    if (totalExcessMinutes > totalDeficitMinutes) {
      // Les excès compensent totalement les déficits, il reste des heures sup
      final remainingExcess = totalExcessMinutes - totalDeficitMinutes;
      realWeekdayOvertime = remainingExcess;
      print(
          'Excès > Déficits → Heures sup weekday = ${_formatDuration(realWeekdayOvertime)}');
    } else {
      // Les déficits sont supérieurs ou égaux aux excès = pas d'heures supplémentaires
      realWeekdayOvertime = Duration.zero;
      print('Déficits ≥ Excès → Heures sup weekday = 0');
    }

    // Pour l'affichage par jour dans le PDF, afficher les surplus BRUTS
    // (même s'ils sont compensés dans le calcul mensuel)
    // Cela permet à l'utilisateur de voir l'information complète jour par jour
    for (final entry in weekdayEntries) {
      final dailyTotal = entry.calculateDailyTotal();
      if (dailyTotal > thresholdDuration) {
        // Afficher l'excès brut de ce jour (avant compensation)
        final dailyExcess = dailyTotal - thresholdDuration;
        overtimeByDay[entry.dayDate] = dailyExcess;
        print(
            'Ajout surplus brut pour ${entry.dayDate}: ${_formatDuration(dailyExcess)}');
      }
    }

    final totalOvertime = realWeekdayOvertime + totalWeekendOvertime;

    print('\n--- RÉSULTAT FINAL ---');
    print('Heures sup weekday: ${_formatDuration(realWeekdayOvertime)}');
    print('Heures sup weekend: ${_formatDuration(totalWeekendOvertime)}');
    print('TOTAL heures sup: ${_formatDuration(totalOvertime)}');
    print('===============================================\n');

    return MonthlyOvertimeResult(
      totalOvertime: totalOvertime,
      overtimeByDay: overtimeByDay,
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
}

/// Résultat du calcul mensuel des heures supplémentaires
class MonthlyOvertimeResult {
  final Duration totalOvertime;
  final Map<String, Duration> overtimeByDay;

  const MonthlyOvertimeResult({
    required this.totalOvertime,
    required this.overtimeByDay,
  });
}
