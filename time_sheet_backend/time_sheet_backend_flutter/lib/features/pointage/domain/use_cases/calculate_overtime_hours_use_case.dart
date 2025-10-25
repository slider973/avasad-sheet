import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';

class CalculateOvertimeHoursUseCase {
  Future<Duration> execute({
    required TimesheetEntry entry,
    required double normalHoursThreshold,
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

  /// Calcule les heures supplémentaires avec compensation mensuelle des déficits
  Future<MonthlyOvertimeResult> executeMonthly({
    required List<TimesheetEntry> entries,
    required double normalHoursThreshold,
  }) async {
    print('\n========== CALCUL MENSUEL CÔTÉ CLIENT ==========');
    print('Nombre d\'entrées: ${entries.length}');
    print('Seuil journalier: ${normalHoursThreshold}h');

    final thresholdDuration = Duration(
      hours: normalHoursThreshold.floor(),
      minutes: ((normalHoursThreshold % 1) * 60).round(),
    );

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
    Duration realWeekdayOvertime = Duration.zero;

    if (totalWorkedMinutes > expectedMinutes) {
      // Il y a plus d'heures travaillées que prévu = heures supplémentaires
      realWeekdayOvertime = totalWorkedMinutes - expectedMinutes;
      print(
          'CAS 1: Total > Attendu → Heures sup weekday = ${_formatDuration(realWeekdayOvertime)}');
    } else if (totalExcessMinutes > totalDeficitMinutes) {
      // Les excès compensent partiellement ou totalement les déficits
      final remainingExcess = totalExcessMinutes - totalDeficitMinutes;
      realWeekdayOvertime = remainingExcess;
      print(
          'CAS 2: Excès > Déficits → Heures sup weekday = ${_formatDuration(realWeekdayOvertime)}');
    } else {
      // Les déficits sont supérieurs aux excès = pas d'heures supplémentaires
      realWeekdayOvertime = Duration.zero;
      print('CAS 3: Déficits ≥ Excès → Heures sup weekday = 0');
    }

    // Pour l'affichage par jour, on ne montre les heures sup weekday que s'il y en a réellement
    if (realWeekdayOvertime > Duration.zero) {
      // Répartir les heures supplémentaires sur les jours qui ont des excès
      for (final entry in weekdayEntries) {
        final dailyTotal = entry.calculateDailyTotal();
        if (dailyTotal > thresholdDuration) {
          final dailyExcess = dailyTotal - thresholdDuration;
          // Proportionnel à l'excès de ce jour
          final proportion =
              dailyExcess.inMinutes / totalExcessMinutes.inMinutes;
          final dailyOvertime = Duration(
              minutes: (realWeekdayOvertime.inMinutes * proportion).round());
          if (dailyOvertime > Duration.zero) {
            overtimeByDay[entry.dayDate] = dailyOvertime;
          }
        }
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
