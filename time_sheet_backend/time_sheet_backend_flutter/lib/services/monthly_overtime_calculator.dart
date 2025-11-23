import '../features/pointage/domain/entities/timesheet_entry.dart';
import 'weekend_detection_service.dart';

/// Service pour calculer les heures supplémentaires sur une base mensuelle
/// en tenant compte des déficits d'heures sur certains jours
class MonthlyOvertimeCalculator {
  final WeekendDetectionService _weekendDetectionService;

  /// Durée standard de travail par jour par défaut (8h18)
  ///
  /// Cette constante sert de valeur de secours lorsque le seuil journalier
  /// n'est pas fourni en paramètre. En production, le seuil journalier
  /// devrait être chargé depuis OvertimeConfiguration et passé aux méthodes de calcul.
  ///
  /// Exemple d'utilisation:
  /// ```dart
  /// final config = await configRepository.getOrCreateDefaultConfiguration();
  /// final summary = await calculator.calculateMonthlyOvertime(
  ///   entries,
  ///   dailyThreshold: config.dailyWorkThreshold,
  ///   weekdayRate: config.weekdayOvertimeRate,
  ///   weekendRate: config.weekendOvertimeRate,
  /// );
  /// ```
  static const Duration defaultStandardWorkDay =
      Duration(hours: 8, minutes: 18);

  /// Taux d'heures supplémentaires par défaut
  ///
  /// Ces constantes servent de valeurs de secours lorsque les taux
  /// ne sont pas fournis en paramètres. En production, les taux devraient
  /// être chargés depuis OvertimeConfiguration et passés aux méthodes de calcul.
  static const double defaultWeekdayOvertimeRate = 1.25; // 125%
  static const double defaultWeekendOvertimeRate = 1.5; // 150%

  MonthlyOvertimeCalculator({
    WeekendDetectionService? weekendDetectionService,
  }) : _weekendDetectionService =
            weekendDetectionService ?? WeekendDetectionService();

  /// Calcule les heures supplémentaires sur une base mensuelle
  /// en compensant les déficits d'heures
  Future<MonthlyOvertimeSummary> calculateMonthlyOvertime(
    List<TimesheetEntry> entries, {
    double? weekdayRate,
    double? weekendRate,
    Duration? dailyThreshold,
  }) async {
    final effectiveWeekdayRate = weekdayRate ?? defaultWeekdayOvertimeRate;
    final effectiveWeekendRate = weekendRate ?? defaultWeekendOvertimeRate;
    final effectiveDailyThreshold = dailyThreshold ?? defaultStandardWorkDay;

    // Séparer les entrées par type (weekend vs weekday)
    final weekdayEntries = <TimesheetEntry>[];
    final weekendEntries = <TimesheetEntry>[];

    for (final entry in entries) {
      if (entry.absence != null) continue;

      bool isWeekendWithOvertime = false;
      if (entry.isWeekendDay && entry.isWeekendOvertimeEnabled) {
        isWeekendWithOvertime = true;
      } else if (entry.date != null) {
        isWeekendWithOvertime = await _weekendDetectionService
            .shouldApplyWeekendOvertime(entry.date!);
      }

      if (isWeekendWithOvertime) {
        weekendEntries.add(entry);
      } else {
        weekdayEntries.add(entry);
      }
    }

    // Calculer les heures weekend (toutes les heures sont des heures sup)
    Duration totalWeekendOvertime = Duration.zero;
    for (final entry in weekendEntries) {
      totalWeekendOvertime += entry.calculateDailyTotal();
    }

    // Calculer les heures weekday avec compensation des déficits
    final weekdayResult = _calculateWeekdayOvertimeWithDeficitCompensation(
      weekdayEntries,
      effectiveDailyThreshold,
    );

    return MonthlyOvertimeSummary(
      regularHours: weekdayResult.regularHours,
      weekdayOvertime: weekdayResult.overtimeHours,
      weekendOvertime: totalWeekendOvertime,
      weekdayOvertimeRate: effectiveWeekdayRate,
      weekendOvertimeRate: effectiveWeekendRate,
      deficitHours: weekdayResult.deficitHours,
      compensatedDeficitHours: weekdayResult.compensatedDeficitHours,
      workingDaysCount: weekdayEntries.length,
      weekendDaysWorked: weekendEntries.length,
    );
  }

  /// Calcule les heures supplémentaires weekday en tenant compte des déficits
  WeekdayOvertimeResult _calculateWeekdayOvertimeWithDeficitCompensation(
    List<TimesheetEntry> weekdayEntries,
    Duration dailyThreshold,
  ) {
    Duration totalWorkedHours = Duration.zero;
    Duration totalDeficitHours = Duration.zero;
    Duration totalExcessHours = Duration.zero;

    // Calculer le total des heures travaillées et identifier les déficits/excès
    for (final entry in weekdayEntries) {
      final dailyTotal = entry.calculateDailyTotal();
      totalWorkedHours += dailyTotal;

      if (dailyTotal < dailyThreshold) {
        // Déficit d'heures ce jour
        totalDeficitHours += (dailyThreshold - dailyTotal);
      } else if (dailyTotal > dailyThreshold) {
        // Excès d'heures ce jour
        totalExcessHours += (dailyTotal - dailyThreshold);
      }
    }

    // Calculer les heures théoriques attendues
    final expectedHours = dailyThreshold * weekdayEntries.length;

    // Calculer les heures régulières (minimum entre travaillé et attendu)
    final regularHours =
        totalWorkedHours < expectedHours ? totalWorkedHours : expectedHours;

    // Calculer les heures supplémentaires réelles après compensation des déficits
    // LOGIQUE: Solde net = excès - déficits (peut être négatif)
    Duration realOvertimeHours = Duration.zero;
    Duration compensatedDeficitHours = Duration.zero;

    // Toujours utiliser la logique excès - déficits (solde net)
    if (totalExcessHours > totalDeficitHours) {
      // Les excès compensent totalement les déficits, il reste des heures sup
      compensatedDeficitHours = totalDeficitHours;
      final remainingExcess = totalExcessHours - totalDeficitHours;
      realOvertimeHours = remainingExcess;
    } else {
      // Les déficits sont supérieurs ou égaux aux excès = pas d'heures supplémentaires
      compensatedDeficitHours = totalExcessHours;
      realOvertimeHours = Duration.zero;
    }

    return WeekdayOvertimeResult(
      regularHours: regularHours,
      overtimeHours: realOvertimeHours,
      deficitHours: totalDeficitHours,
      compensatedDeficitHours: compensatedDeficitHours,
    );
  }

  /// Calcule les heures supplémentaires par semaine pour un suivi plus détaillé
  Future<List<WeeklyOvertimeSummary>> calculateWeeklyBreakdown(
    List<TimesheetEntry> entries, {
    double? weekdayRate,
    double? weekendRate,
    Duration? dailyThreshold,
  }) async {
    // Grouper les entrées par semaine
    final weeklyGroups = <int, List<TimesheetEntry>>{};

    for (final entry in entries) {
      if (entry.date == null) continue;

      final weekNumber = _getWeekNumber(entry.date!);
      weeklyGroups.putIfAbsent(weekNumber, () => []).add(entry);
    }

    final weeklyResults = <WeeklyOvertimeSummary>[];

    for (final weekEntries in weeklyGroups.values) {
      final weeklySummary = await calculateMonthlyOvertime(
        weekEntries,
        weekdayRate: weekdayRate,
        weekendRate: weekendRate,
        dailyThreshold: dailyThreshold,
      );

      weeklyResults.add(WeeklyOvertimeSummary(
        weekNumber: _getWeekNumber(weekEntries.first.date!),
        regularHours: weeklySummary.regularHours,
        weekdayOvertime: weeklySummary.weekdayOvertime,
        weekendOvertime: weeklySummary.weekendOvertime,
        deficitHours: weeklySummary.deficitHours,
        entries: weekEntries,
      ));
    }

    return weeklyResults;
  }

  /// Obtient le numéro de semaine pour une date donnée
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }
}

/// Résultat du calcul des heures supplémentaires weekday
class WeekdayOvertimeResult {
  final Duration regularHours;
  final Duration overtimeHours;
  final Duration deficitHours;
  final Duration compensatedDeficitHours;

  const WeekdayOvertimeResult({
    required this.regularHours,
    required this.overtimeHours,
    required this.deficitHours,
    required this.compensatedDeficitHours,
  });
}

/// Résumé mensuel des heures supplémentaires avec compensation des déficits
class MonthlyOvertimeSummary {
  final Duration regularHours;
  final Duration weekdayOvertime;
  final Duration weekendOvertime;
  final double weekdayOvertimeRate;
  final double weekendOvertimeRate;
  final Duration deficitHours;
  final Duration compensatedDeficitHours;
  final int workingDaysCount;
  final int weekendDaysWorked;

  const MonthlyOvertimeSummary({
    required this.regularHours,
    required this.weekdayOvertime,
    required this.weekendOvertime,
    required this.weekdayOvertimeRate,
    required this.weekendOvertimeRate,
    required this.deficitHours,
    required this.compensatedDeficitHours,
    required this.workingDaysCount,
    required this.weekendDaysWorked,
  });

  /// Total des heures supplémentaires (weekday + weekend)
  Duration get totalOvertime => weekdayOvertime + weekendOvertime;

  /// Total des heures travaillées
  Duration get totalHours => regularHours + totalOvertime;

  /// Déficit d'heures non compensé
  Duration get uncompensatedDeficitHours =>
      deficitHours - compensatedDeficitHours;

  /// Indique s'il y a des heures supplémentaires réelles
  bool get hasRealOvertime => totalOvertime > Duration.zero;

  /// Indique s'il y a un déficit d'heures non compensé
  bool get hasUncompensatedDeficit => uncompensatedDeficitHours > Duration.zero;

  /// Calcule le pourcentage de compensation des déficits
  double get deficitCompensationPercentage {
    if (deficitHours == Duration.zero) return 100.0;
    return (compensatedDeficitHours.inMinutes / deficitHours.inMinutes) * 100.0;
  }

  /// Formate une durée en heures et minutes
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String get formattedRegularHours => _formatDuration(regularHours);
  String get formattedWeekdayOvertime => _formatDuration(weekdayOvertime);
  String get formattedWeekendOvertime => _formatDuration(weekendOvertime);
  String get formattedTotalOvertime => _formatDuration(totalOvertime);
  String get formattedDeficitHours => _formatDuration(deficitHours);
  String get formattedCompensatedDeficitHours =>
      _formatDuration(compensatedDeficitHours);
  String get formattedUncompensatedDeficitHours =>
      _formatDuration(uncompensatedDeficitHours);

  @override
  String toString() {
    return 'MonthlyOvertimeSummary{'
        'regularHours: $formattedRegularHours, '
        'weekdayOvertime: $formattedWeekdayOvertime, '
        'weekendOvertime: $formattedWeekendOvertime, '
        'deficitHours: $formattedDeficitHours, '
        'compensatedDeficit: $formattedCompensatedDeficitHours, '
        'uncompensatedDeficit: $formattedUncompensatedDeficitHours, '
        'workingDays: $workingDaysCount, '
        'weekendDays: $weekendDaysWorked'
        '}';
  }
}

/// Résumé hebdomadaire des heures supplémentaires
class WeeklyOvertimeSummary {
  final int weekNumber;
  final Duration regularHours;
  final Duration weekdayOvertime;
  final Duration weekendOvertime;
  final Duration deficitHours;
  final List<TimesheetEntry> entries;

  const WeeklyOvertimeSummary({
    required this.weekNumber,
    required this.regularHours,
    required this.weekdayOvertime,
    required this.weekendOvertime,
    required this.deficitHours,
    required this.entries,
  });

  Duration get totalOvertime => weekdayOvertime + weekendOvertime;
  Duration get totalHours => regularHours + totalOvertime;
}
