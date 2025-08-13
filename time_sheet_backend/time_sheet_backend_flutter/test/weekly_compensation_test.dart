import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/entities/anomaly_result.dart';
import 'package:time_sheet/features/pointage/domain/rules/impl/weekly_compensation_rule.dart';
import 'package:time_sheet/features/pointage/domain/rules/impl/insufficient_hours_rule.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/anomaly_type.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/anomaly_severity.dart';

void main() {
  group('WeeklyCompensationRule Tests', () {
    late WeeklyCompensationRule compensationRule;
    late InsufficientHoursRule insufficientHoursRule;

    setUp(() {
      compensationRule = WeeklyCompensationRule();
      insufficientHoursRule = InsufficientHoursRule();
    });

    test('should compensate insufficient hours with weekly surplus', () async {
      // Créer une semaine avec un jour insuffisant et d'autres avec surplus
      final weekEntries = [
        // Lundi - 6h (insuffisant)
        TimesheetEntry(
          id: 1,
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Lundi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '15:00', // 6h total
        ),
        // Mardi - 9h (surplus)
        TimesheetEntry(
          id: 2,
          dayDate: '02-Jan-24',
          dayOfWeekDate: 'Mardi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '18:00', // 9h total
        ),
        // Mercredi - 8h18 (normal)
        TimesheetEntry(
          id: 3,
          dayDate: '03-Jan-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:18', // 8h18 total
        ),
        // Jeudi - 8h18 (normal)
        TimesheetEntry(
          id: 4,
          dayDate: '04-Jan-24',
          dayOfWeekDate: 'Jeudi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:18', // 8h18 total
        ),
        // Vendredi - 10h (surplus)
        TimesheetEntry(
          id: 5,
          dayDate: '05-Jan-24',
          dayOfWeekDate: 'Vendredi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 10h total
        ),
      ];

      // Créer des anomalies pour le jour insuffisant
      final initialAnomalies = [
        AnomalyResult(
          ruleId: 'insufficient_hours',
          ruleName: 'Heures insuffisantes',
          type: AnomalyType.insufficientHours,
          severity: AnomalySeverity.medium,
          description: 'Temps de travail insuffisant: il manque 2h18min',
          detectedDate: DateTime.now(),
          timesheetEntryId: '1',
          metadata: {
            'workedMinutes': 360, // 6h
            'requiredMinutes': 498, // 8h18
            'shortfallMinutes': 138, // 2h18
          },
        ),
      ];

      // Appliquer la compensation
      final compensatedAnomalies = await compensationRule.validateWeek(
        weekEntries,
        initialAnomalies,
        compensationRule.defaultConfiguration,
      );

      // Vérifier que l'anomalie a été compensée
      expect(compensatedAnomalies.length, 1);
      expect(compensatedAnomalies.first.metadata['compensated'], true);
      expect(compensatedAnomalies.first.severity, AnomalySeverity.low);
      expect(compensatedAnomalies.first.description, contains('compensées par la semaine'));
    });

    test('should not compensate if weekly total is insufficient', () async {
      // Créer une semaine avec plusieurs jours insuffisants
      final weekEntries = [
        // Lundi - 6h (insuffisant)
        TimesheetEntry(
          id: 1,
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Lundi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '15:00', // 6h
        ),
        // Mardi - 6h (insuffisant)
        TimesheetEntry(
          id: 2,
          dayDate: '02-Jan-24',
          dayOfWeekDate: 'Mardi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '15:00', // 6h
        ),
        // Mercredi - 7h (insuffisant)
        TimesheetEntry(
          id: 3,
          dayDate: '03-Jan-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // 7h
        ),
        // Jeudi - 7h (insuffisant)
        TimesheetEntry(
          id: 4,
          dayDate: '04-Jan-24',
          dayOfWeekDate: 'Jeudi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // 7h
        ),
        // Vendredi - 8h (insuffisant)
        TimesheetEntry(
          id: 5,
          dayDate: '05-Jan-24',
          dayOfWeekDate: 'Vendredi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00', // 8h
        ),
      ];

      final initialAnomalies = [
        AnomalyResult(
          ruleId: 'insufficient_hours',
          ruleName: 'Heures insuffisantes',
          type: AnomalyType.insufficientHours,
          severity: AnomalySeverity.medium,
          description: 'Temps de travail insuffisant',
          detectedDate: DateTime.now(),
          timesheetEntryId: '1',
          metadata: {'shortfallMinutes': 138},
        ),
      ];

      // Appliquer la compensation
      final compensatedAnomalies = await compensationRule.validateWeek(
        weekEntries,
        initialAnomalies,
        compensationRule.defaultConfiguration,
      );

      // Les anomalies ne doivent pas être compensées car le total hebdomadaire est insuffisant
      expect(compensatedAnomalies, equals(initialAnomalies));
    });

    test('should validate configuration correctly', () {
      // Configuration valide
      final validConfig = {
        'weeklyRequiredMinutes': 2490,
        'compensationTolerance': 15,
        'maxDailyCompensation': 120,
        'minDailyHours': 6,
      };
      expect(compensationRule.isConfigurationValid(validConfig), true);

      // Configuration invalide - paramètre manquant
      final invalidConfig1 = {
        'weeklyRequiredMinutes': 2490,
        'compensationTolerance': 15,
        // 'maxDailyCompensation' manquant
        'minDailyHours': 6,
      };
      expect(compensationRule.isConfigurationValid(invalidConfig1), false);

      // Configuration invalide - valeur négative
      final invalidConfig2 = {
        'weeklyRequiredMinutes': -100,
        'compensationTolerance': 15,
        'maxDailyCompensation': 120,
        'minDailyHours': 6,
      };
      expect(compensationRule.isConfigurationValid(invalidConfig2), false);
    });

    test('should respect minimum daily hours constraint', () async {
      final weekEntries = [
        // Lundi - 4h (trop peu, même avec compensation)
        TimesheetEntry(
          id: 1,
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Lundi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '',
          endAfternoon: '', // 4h seulement
        ),
        // Reste de la semaine avec beaucoup d'heures
        TimesheetEntry(
          id: 2,
          dayDate: '02-Jan-24',
          dayOfWeekDate: 'Mardi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '20:00', // 11h
        ),
        TimesheetEntry(
          id: 3,
          dayDate: '03-Jan-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '20:00', // 11h
        ),
      ];

      final initialAnomalies = [
        AnomalyResult(
          ruleId: 'insufficient_hours',
          ruleName: 'Heures insuffisantes',
          type: AnomalyType.insufficientHours,
          severity: AnomalySeverity.high,
          description: 'Temps de travail insuffisant: il manque 4h18min',
          detectedDate: DateTime.now(),
          timesheetEntryId: '1',
          metadata: {'shortfallMinutes': 258}, // 4h18
        ),
      ];

      final compensatedAnomalies = await compensationRule.validateWeek(
        weekEntries,
        initialAnomalies,
        compensationRule.defaultConfiguration,
      );

      // L'anomalie ne doit pas être compensée car le jour ne respecte pas le minimum de 6h
      expect(compensatedAnomalies, equals(initialAnomalies));
    });
  });
}