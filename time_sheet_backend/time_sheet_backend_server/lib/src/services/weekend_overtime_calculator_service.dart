import 'dart:convert';
import '../generated/protocol.dart';

/// Backend service for calculating weekend and weekday overtime hours
///
/// This service provides functionality to:
/// - Calculate weekend overtime hours from timesheet data
/// - Calculate weekday overtime hours with monthly compensation
/// - Generate monthly overtime summaries with separation by type
/// - Apply different overtime rates for weekend vs weekday work
/// - Handle pay periods from 20th to 21st of next month
class WeekendOvertimeCalculatorService {
  /// Standard work day duration in minutes (8 hours 18 minutes)
  static const int standardWorkDayMinutes = 498; // 8h18

  /// Default overtime rates
  static const double defaultWeekdayOvertimeRate = 1.25; // 125%
  static const double defaultWeekendOvertimeRate = 1.5; // 150%

  /// Calculates comprehensive overtime summary from timesheet data
  /// Uses monthly calculation with deficit compensation
  /// Takes into account pay periods from 20th to 21st of next month
  ///
  /// [timesheetData] The timesheet data containing entries
  /// [weekdayRate] Optional custom weekday overtime rate (default: 1.25)
  /// [weekendRate] Optional custom weekend overtime rate (default: 1.5)
  /// Returns an [OvertimeSummaryData] with detailed breakdown
  OvertimeSummaryData calculateOvertimeSummary(
    TimesheetData timesheetData, {
    double? weekdayRate,
    double? weekendRate,
  }) {
    final effectiveWeekdayRate = weekdayRate ?? defaultWeekdayOvertimeRate;
    final effectiveWeekendRate = weekendRate ?? defaultWeekendOvertimeRate;

    // Parse entries from JSON
    final entriesJson = jsonDecode(timesheetData.entries) as List;
    final entries = entriesJson.map((e) => e as Map<String, dynamic>).toList();

    print('\n========== ANALYSE PÉRIODE DE PAIE ==========');
    print('Mois de paie: ${timesheetData.month}/${timesheetData.year}');
    print('Nombre total d\'entrées: ${entries.length}');

    // Grouper les entrées par période de paie (du 20 au 21)
    final payPeriodGroups = _groupEntriesByPayPeriod(
        entries, timesheetData.month, timesheetData.year);

    print('Nombre de périodes de paie trouvées: ${payPeriodGroups.length}');

    int totalWeekdayOvertimeMinutes = 0;
    int totalWeekendOvertimeMinutes = 0;
    int totalRegularMinutes = 0;

    // Calculer les heures supplémentaires pour chaque période de paie
    for (int i = 0; i < payPeriodGroups.length; i++) {
      final periodEntries = payPeriodGroups[i];
      print('\n--- PÉRIODE ${i + 1} ---');
      print('Nombre d\'entrées: ${periodEntries.length}');

      // Séparer les entrées par type (weekend vs weekday) pour cette période
      final weekdayEntries = <Map<String, dynamic>>[];
      final weekendEntries = <Map<String, dynamic>>[];

      for (final entry in periodEntries) {
        if (entry['isAbsence'] == true) continue;

        final dayDate = entry['dayDate'] as String?;
        if (dayDate == null) continue;

        final isWeekend = entry['isWeekendDay'] ?? _isWeekendDay(dayDate);
        final isWeekendOvertimeEnabled =
            entry['isWeekendOvertimeEnabled'] ?? true;

        if (isWeekend && isWeekendOvertimeEnabled) {
          weekendEntries.add(entry);
        } else {
          weekdayEntries.add(entry);
        }
      }

      // Calculer les heures weekend pour cette période
      int periodWeekendOvertimeMinutes = 0;
      for (final entry in weekendEntries) {
        periodWeekendOvertimeMinutes += _calculateDailyMinutes(entry);
      }

      // Calculer les heures weekday avec compensation pour cette période
      final weekdayResult = _calculateWeekdayOvertimeWithDeficitCompensation(
        weekdayEntries,
        standardWorkDayMinutes,
      );

      // Ajouter aux totaux
      totalWeekdayOvertimeMinutes += weekdayResult.overtimeMinutes;
      totalWeekendOvertimeMinutes += periodWeekendOvertimeMinutes;
      totalRegularMinutes += weekdayResult.regularMinutes;

      print(
          'Période ${i + 1} - Weekend: ${formatMinutesAsHours(periodWeekendOvertimeMinutes)}');
      print(
          'Période ${i + 1} - Weekday sup: ${formatMinutesAsHours(weekdayResult.overtimeMinutes)}');
    }

    // Si aucune période trouvée, traiter toutes les entrées comme une seule période
    if (payPeriodGroups.isEmpty) {
      print('ATTENTION: Aucune période de paie trouvée, traitement global');

      final weekdayEntries = <Map<String, dynamic>>[];
      final weekendEntries = <Map<String, dynamic>>[];

      for (final entry in entries) {
        if (entry['isAbsence'] == true) continue;

        final dayDate = entry['dayDate'] as String?;
        if (dayDate == null) continue;

        final isWeekend = entry['isWeekendDay'] ?? _isWeekendDay(dayDate);
        final isWeekendOvertimeEnabled =
            entry['isWeekendOvertimeEnabled'] ?? true;

        if (isWeekend && isWeekendOvertimeEnabled) {
          weekendEntries.add(entry);
        } else {
          weekdayEntries.add(entry);
        }
      }

      for (final entry in weekendEntries) {
        totalWeekendOvertimeMinutes += _calculateDailyMinutes(entry);
      }

      final weekdayResult = _calculateWeekdayOvertimeWithDeficitCompensation(
        weekdayEntries,
        standardWorkDayMinutes,
      );

      totalWeekdayOvertimeMinutes = weekdayResult.overtimeMinutes;
      totalRegularMinutes = weekdayResult.regularMinutes;
    }

    print('\n========== RÉSUMÉ FINAL PDF ==========');
    print(
        'Heures weekend: ${formatMinutesAsHours(totalWeekendOvertimeMinutes)}');
    print(
        'Heures weekday régulières: ${formatMinutesAsHours(totalRegularMinutes)}');
    print(
        'Heures weekday supplémentaires: ${formatMinutesAsHours(totalWeekdayOvertimeMinutes)}');
    print(
        'TOTAL heures supplémentaires: ${formatMinutesAsHours(totalWeekdayOvertimeMinutes + totalWeekendOvertimeMinutes)}');
    print('=====================================\n');

    return OvertimeSummaryData(
      weekdayOvertimeMinutes: totalWeekdayOvertimeMinutes,
      weekendOvertimeMinutes: totalWeekendOvertimeMinutes,
      regularMinutes: totalRegularMinutes,
      weekdayOvertimeRate: effectiveWeekdayRate,
      weekendOvertimeRate: effectiveWeekendRate,
    );
  }

  /// Groupe les entrées par période de paie (du 20 au 21)
  List<List<Map<String, dynamic>>> _groupEntriesByPayPeriod(
    List<Map<String, dynamic>> entries,
    int payMonth,
    int payYear,
  ) {
    // Créer les bornes de la période de paie
    // Période va du 20 du mois précédent au 21 du mois courant
    final periodStart = DateTime(payYear, payMonth - 1, 20);
    final periodEnd = DateTime(payYear, payMonth, 21);

    print(
        'Période de paie: du ${_formatDate(periodStart)} au ${_formatDate(periodEnd)}');

    // Filtrer les entrées qui sont dans cette période
    final periodEntries = <Map<String, dynamic>>[];

    for (final entry in entries) {
      final dayDate = entry['dayDate'] as String?;
      if (dayDate == null) continue;

      try {
        final entryDate = DateTime.parse(dayDate);
        if (entryDate.isAfter(periodStart.subtract(const Duration(days: 1))) &&
            entryDate.isBefore(periodEnd.add(const Duration(days: 1)))) {
          periodEntries.add(entry);
          print('Entrée incluse: $dayDate');
        } else {
          print('Entrée exclue: $dayDate (hors période)');
        }
      } catch (e) {
        print('Erreur parsing date: $dayDate');
      }
    }

    // Pour l'instant, retourner toutes les entrées de la période comme un seul groupe
    // Plus tard, on pourrait subdiviser si nécessaire
    return periodEntries.isEmpty ? [] : [periodEntries];
  }

  /// Formate une date pour l'affichage
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Calcule les heures supplémentaires weekday en tenant compte des déficits
  WeekdayOvertimeResult _calculateWeekdayOvertimeWithDeficitCompensation(
    List<Map<String, dynamic>> weekdayEntries,
    int dailyThresholdMinutes,
  ) {
    print('\n========== CALCUL HEURES SUPPLEMENTAIRES WEEKDAY ==========');
    print('Nombre de jours weekday: ${weekdayEntries.length}');
    print(
        'Seuil journalier: $dailyThresholdMinutes minutes (${formatMinutesAsHours(dailyThresholdMinutes)})');

    int totalWorkedMinutes = 0;
    int totalDeficitMinutes = 0;
    int totalExcessMinutes = 0;

    // Calculer le total des heures travaillées et identifier les déficits/excès
    for (int i = 0; i < weekdayEntries.length; i++) {
      final entry = weekdayEntries[i];
      final dailyMinutes = _calculateDailyMinutes(entry);
      final dayDate = entry['dayDate'] ?? 'Unknown';

      totalWorkedMinutes += dailyMinutes;

      if (dailyMinutes < dailyThresholdMinutes) {
        // Déficit d'heures ce jour
        final deficit = dailyThresholdMinutes - dailyMinutes;
        totalDeficitMinutes += deficit;
        print(
            'Jour ${i + 1} ($dayDate): ${formatMinutesAsHours(dailyMinutes)} - DÉFICIT de ${formatMinutesAsHours(deficit)}');
      } else if (dailyMinutes > dailyThresholdMinutes) {
        // Excès d'heures ce jour
        final excess = dailyMinutes - dailyThresholdMinutes;
        totalExcessMinutes += excess;
        print(
            'Jour ${i + 1} ($dayDate): ${formatMinutesAsHours(dailyMinutes)} - EXCÈS de ${formatMinutesAsHours(excess)}');
      } else {
        print(
            'Jour ${i + 1} ($dayDate): ${formatMinutesAsHours(dailyMinutes)} - EXACT');
      }
    }

    // Calculer les heures théoriques attendues
    final expectedMinutes = dailyThresholdMinutes * weekdayEntries.length;

    print('\n--- RÉSUMÉ ---');
    print('Total travaillé: ${formatMinutesAsHours(totalWorkedMinutes)}');
    print('Total attendu: ${formatMinutesAsHours(expectedMinutes)}');
    print('Total déficits: ${formatMinutesAsHours(totalDeficitMinutes)}');
    print('Total excès: ${formatMinutesAsHours(totalExcessMinutes)}');

    // Calculer les heures régulières (minimum entre travaillé et attendu)
    final regularMinutes = totalWorkedMinutes < expectedMinutes
        ? totalWorkedMinutes
        : expectedMinutes;

    // Calculer les heures supplémentaires réelles après compensation des déficits
    int realOvertimeMinutes = 0;

    if (totalWorkedMinutes > expectedMinutes) {
      // Il y a plus d'heures travaillées que prévu = heures supplémentaires
      realOvertimeMinutes = totalWorkedMinutes - expectedMinutes;
      print(
          'CAS 1: Total > Attendu → Heures sup = ${formatMinutesAsHours(realOvertimeMinutes)}');
    } else if (totalExcessMinutes > totalDeficitMinutes) {
      // Les excès compensent partiellement ou totalement les déficits
      final remainingExcess = totalExcessMinutes - totalDeficitMinutes;
      realOvertimeMinutes = remainingExcess;
      print(
          'CAS 2: Excès > Déficits → Heures sup = ${formatMinutesAsHours(realOvertimeMinutes)}');
    } else {
      // Les déficits sont supérieurs aux excès = pas d'heures supplémentaires
      realOvertimeMinutes = 0;
      print('CAS 3: Déficits ≥ Excès → Heures sup = 0');
    }

    print('\n--- RÉSULTAT FINAL ---');
    print('Heures régulières: ${formatMinutesAsHours(regularMinutes)}');
    print(
        'Heures supplémentaires: ${formatMinutesAsHours(realOvertimeMinutes)}');
    print('=========================================================\n');

    return WeekdayOvertimeResult(
      regularMinutes: regularMinutes,
      overtimeMinutes: realOvertimeMinutes,
    );
  }

  /// Determines if a given date string represents a weekend day
  bool _isWeekendDay(String dayDate) {
    try {
      // Parse date string (assuming format like "2025-01-18" or similar)
      final date = DateTime.parse(dayDate);
      return date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;
    } catch (e) {
      // If parsing fails, assume it's not a weekend
      return false;
    }
  }

  /// Calculates total minutes worked in a day from entry data
  int _calculateDailyMinutes(Map<String, dynamic> entry) {
    try {
      int totalMinutes = 0;

      // Morning session
      final startMorning = entry['startMorning'] as String?;
      final endMorning = entry['endMorning'] as String?;
      if (startMorning != null &&
          endMorning != null &&
          startMorning.isNotEmpty &&
          endMorning.isNotEmpty) {
        totalMinutes += _calculateSessionMinutes(startMorning, endMorning);
      }

      // Afternoon session
      final startAfternoon = entry['startAfternoon'] as String?;
      final endAfternoon = entry['endAfternoon'] as String?;
      if (startAfternoon != null &&
          endAfternoon != null &&
          startAfternoon.isNotEmpty &&
          endAfternoon.isNotEmpty) {
        totalMinutes += _calculateSessionMinutes(startAfternoon, endAfternoon);
      }

      return totalMinutes;
    } catch (e) {
      return 0;
    }
  }

  /// Calculates minutes between two time strings
  int _calculateSessionMinutes(String startTime, String endTime) {
    try {
      final start = _parseTimeString(startTime);
      final end = _parseTimeString(endTime);

      if (start == null || end == null) return 0;

      final difference = end.difference(start);
      return difference.inMinutes;
    } catch (e) {
      return 0;
    }
  }

  /// Parses a time string (e.g., "09:00") into a DateTime
  DateTime? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Use a fixed date, we only care about time
      return DateTime(2025, 1, 1, hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// Formats minutes as hours and minutes string
  String formatMinutesAsHours(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes.toString().padLeft(2, '0')}m';
  }

  /// Formats minutes as decimal hours
  String formatMinutesAsDecimalHours(int minutes) {
    final hours = minutes / 60.0;
    return '${hours.toStringAsFixed(2)}h';
  }
}

/// Résultat du calcul des heures supplémentaires weekday
class WeekdayOvertimeResult {
  final int regularMinutes;
  final int overtimeMinutes;

  const WeekdayOvertimeResult({
    required this.regularMinutes,
    required this.overtimeMinutes,
  });
}

/// Summary of overtime hours with detailed breakdown for backend use
class OvertimeSummaryData {
  /// Total overtime minutes worked on weekdays
  final int weekdayOvertimeMinutes;

  /// Total overtime minutes worked on weekends
  final int weekendOvertimeMinutes;

  /// Total regular minutes worked (non-overtime)
  final int regularMinutes;

  /// Overtime rate applied to weekday overtime hours
  final double weekdayOvertimeRate;

  /// Overtime rate applied to weekend overtime hours
  final double weekendOvertimeRate;

  const OvertimeSummaryData({
    required this.weekdayOvertimeMinutes,
    required this.weekendOvertimeMinutes,
    required this.regularMinutes,
    required this.weekdayOvertimeRate,
    required this.weekendOvertimeRate,
  });

  /// Total overtime minutes (weekday + weekend)
  int get totalOvertimeMinutes =>
      weekdayOvertimeMinutes + weekendOvertimeMinutes;

  /// Total minutes worked (regular + overtime)
  int get totalMinutes => regularMinutes + totalOvertimeMinutes;

  /// Returns true if any overtime hours were worked
  bool get hasOvertime => totalOvertimeMinutes > 0;

  /// Returns true if weekend overtime hours were worked
  bool get hasWeekendOvertime => weekendOvertimeMinutes > 0;

  /// Returns true if weekday overtime hours were worked
  bool get hasWeekdayOvertime => weekdayOvertimeMinutes > 0;

  /// Formats minutes as hours and minutes string
  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes.toString().padLeft(2, '0')}m';
  }

  /// Returns a formatted string representation of weekday overtime
  String get formattedWeekdayOvertime => _formatMinutes(weekdayOvertimeMinutes);

  /// Returns a formatted string representation of weekend overtime
  String get formattedWeekendOvertime => _formatMinutes(weekendOvertimeMinutes);

  /// Returns a formatted string representation of total overtime
  String get formattedTotalOvertime => _formatMinutes(totalOvertimeMinutes);

  /// Returns a formatted string representation of regular hours
  String get formattedRegularHours => _formatMinutes(regularMinutes);

  /// Returns a formatted string representation of total hours
  String get formattedTotalHours => _formatMinutes(totalMinutes);

  @override
  String toString() {
    return 'OvertimeSummaryData{'
        'regularHours: $formattedRegularHours, '
        'weekdayOvertime: $formattedWeekdayOvertime (${weekdayOvertimeRate}x), '
        'weekendOvertime: $formattedWeekendOvertime (${weekendOvertimeRate}x), '
        'totalOvertime: $formattedTotalOvertime, '
        'totalHours: $formattedTotalHours'
        '}';
  }
}
