import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_overtime_summary.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';
import 'package:time_sheet/services/weekend_overtime_calculator.dart';
import 'package:time_sheet/utils/time_utils.dart';
import 'package:time_sheet/enum/overtime_type.dart';

/// Service pour analyser les données timesheet d'une validation
/// et calculer les heures supplémentaires weekend/semaine
class ValidationOvertimeAnalyzer {
  final WeekendDetectionService _weekendDetectionService;
  final WeekendOvertimeCalculator _overtimeCalculator;

  ValidationOvertimeAnalyzer({
    WeekendDetectionService? weekendDetectionService,
    WeekendOvertimeCalculator? overtimeCalculator,
  })  : _weekendDetectionService =
            weekendDetectionService ?? WeekendDetectionService(),
        _overtimeCalculator = overtimeCalculator ?? WeekendOvertimeCalculator();

  /// Analyse les données timesheet et calcule le résumé des heures supplémentaires
  Future<ValidationOvertimeSummary> analyzeTimesheetData(
      Map<String, dynamic> timesheetData) async {
    // Extraire les entrées du timesheet
    final entriesData = timesheetData['entries'] as List<dynamic>? ?? [];

    // Convertir en TimesheetEntry
    final entries = <TimesheetEntry>[];
    for (final entryData in entriesData) {
      if (entryData is Map<String, dynamic>) {
        try {
          final entry = _parseTimesheetEntry(entryData);
          if (entry != null) {
            entries.add(entry);
          }
        } catch (e) {
          // Ignorer les entrées malformées
          continue;
        }
      }
    }

    // Calculer le résumé des heures supplémentaires
    final overtimeSummary =
        await _overtimeCalculator.calculateMonthlyOvertime(entries);

    // Compter les jours travaillés
    int weekendDaysWorked = 0;
    int weekdayOvertimeDays = 0;

    for (final entry in entries) {
      if (entry.absence != null) continue;

      final dailyTotal = entry.calculateDailyTotal();
      if (dailyTotal <= Duration.zero) continue;

      if (await _weekendDetectionService
          .shouldApplyWeekendOvertime(entry.date!)) {
        weekendDaysWorked++;
      } else if (dailyTotal > WeekendOvertimeCalculator.standardWorkDay) {
        weekdayOvertimeDays++;
      }
    }

    return ValidationOvertimeSummary(
      weekdayOvertime: overtimeSummary.weekdayOvertime,
      weekendOvertime: overtimeSummary.weekendOvertime,
      regularHours: overtimeSummary.regularHours,
      weekdayOvertimeRate: overtimeSummary.weekdayOvertimeRate,
      weekendOvertimeRate: overtimeSummary.weekendOvertimeRate,
      weekendDaysWorked: weekendDaysWorked,
      weekdayOvertimeDays: weekdayOvertimeDays,
    );
  }

  /// Parse une entrée timesheet depuis les données JSON
  TimesheetEntry? _parseTimesheetEntry(Map<String, dynamic> data) {
    try {
      // Extraire la date
      DateTime? date;
      if (data['date'] != null) {
        if (data['date'] is String) {
          date = DateTime.tryParse(data['date']);
        } else if (data['date'] is DateTime) {
          date = data['date'];
        }
      }

      if (date == null) return null;

      // Extraire les heures de début et fin
      DateTime? startTime;
      DateTime? endTime;

      if (data['startTime'] != null) {
        if (data['startTime'] is String) {
          startTime = DateTime.tryParse(data['startTime']);
        } else if (data['startTime'] is DateTime) {
          startTime = data['startTime'];
        }
      }

      if (data['endTime'] != null) {
        if (data['endTime'] is String) {
          endTime = DateTime.tryParse(data['endTime']);
        } else if (data['endTime'] is DateTime) {
          endTime = data['endTime'];
        }
      }

      // Extraire les pauses
      Duration? breakDuration;
      if (data['breakDuration'] != null) {
        if (data['breakDuration'] is int) {
          breakDuration = Duration(minutes: data['breakDuration']);
        } else if (data['breakDuration'] is String) {
          final minutes = int.tryParse(data['breakDuration']);
          if (minutes != null) {
            breakDuration = Duration(minutes: minutes);
          }
        }
      }

      // Créer l'entrée timesheet
      final dayNames = {
        1: 'Lundi',
        2: 'Mardi',
        3: 'Mercredi',
        4: 'Jeudi',
        5: 'Vendredi',
        6: 'Samedi',
        7: 'Dimanche',
      };

      final monthNames = {
        1: 'Jan',
        2: 'Feb',
        3: 'Mar',
        4: 'Apr',
        5: 'May',
        6: 'Jun',
        7: 'Jul',
        8: 'Aug',
        9: 'Sep',
        10: 'Oct',
        11: 'Nov',
        12: 'Dec'
      };

      final formattedDate = '${date.day.toString().padLeft(2, '0')}-'
          '${monthNames[date.month]}-'
          '${date.year.toString().substring(2)}';

      return TimesheetEntry(
        id: int.tryParse(data['id']?.toString() ?? '0'),
        dayDate: formattedDate,
        dayOfWeekDate: dayNames[date.weekday]!,
        startMorning: startTime != null
            ? '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'
            : '',
        endMorning: '12:00', // Default lunch break start
        startAfternoon: '13:00', // Default lunch break end
        endAfternoon: endTime != null
            ? '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'
            : '',
        absenceReason: null,
        period: null,
        isWeekendDay: TimeUtils.isWeekend(date),
        isWeekendOvertimeEnabled: true, // Par défaut activé
        overtimeType: TimeUtils.isWeekend(date)
            ? OvertimeType.WEEKEND_ONLY
            : OvertimeType.NONE,
      );
    } catch (e) {
      return null;
    }
  }

  /// Détermine si une validation contient des heures de weekend exceptionnelles
  /// (plus de X heures par jour de weekend ou plus de Y jours de weekend)
  bool hasExceptionalWeekendHours(
    ValidationOvertimeSummary summary, {
    Duration maxWeekendHoursPerDay = const Duration(hours: 10),
    int maxWeekendDays = 2,
  }) {
    // Vérifier le nombre de jours de weekend
    if (summary.weekendDaysWorked > maxWeekendDays) {
      return true;
    }

    // Vérifier la moyenne d'heures par jour de weekend
    if (summary.weekendDaysWorked > 0) {
      final avgHoursPerWeekendDay = Duration(
          milliseconds: summary.weekendOvertime.inMilliseconds ~/
              summary.weekendDaysWorked);
      if (avgHoursPerWeekendDay > maxWeekendHoursPerDay) {
        return true;
      }
    }

    return false;
  }

  /// Génère un message d'alerte pour les heures de weekend exceptionnelles
  String? generateWeekendAlert(ValidationOvertimeSummary summary) {
    if (!summary.hasWeekendOvertime) {
      return null;
    }

    final messages = <String>[];

    if (summary.weekendDaysWorked > 2) {
      messages.add('${summary.weekendDaysWorked} jours de weekend travaillés');
    }

    if (summary.weekendOvertime > const Duration(hours: 16)) {
      messages.add('${summary.formattedWeekendOvertime} d\'heures de weekend');
    }

    if (hasExceptionalWeekendHours(summary)) {
      messages.add('Volume d\'heures weekend exceptionnel');
    }

    if (messages.isEmpty) {
      return null;
    }

    return 'Attention: ${messages.join(', ')}';
  }
}
