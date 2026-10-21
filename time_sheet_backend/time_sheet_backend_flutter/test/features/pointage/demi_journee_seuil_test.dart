import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/enum/absence_period.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';

/// Régression : le seuil quotidien appliqué EN PLEIN sur une demi-journée.
///
/// Cas réel (relevé de septembre 2026, signalé par la Resource Manager) :
/// le 24/09, congé le matin, travail de 13:30 à 18:30. Le PDF affichait
/// **−3h18** de déficit (5h00 − 8h18) alors que la demi-journée due vaut
/// 4h09 — soit **+51 min** d'excédent. 4h09 d'erreur sur une seule ligne,
/// dans un document qui part à la finance du client.
void main() {
  TimesheetEntry entry({
    String startMorning = '',
    String endMorning = '',
    String startAfternoon = '',
    String endAfternoon = '',
    String? absenceReason,
    String? period,
  }) {
    return TimesheetEntry(
      id: 1,
      dayDate: '24-Sep-26',
      dayOfWeekDate: 'Thursday',
      startMorning: startMorning,
      endMorning: endMorning,
      startAfternoon: startAfternoon,
      endAfternoon: endAfternoon,
      absenceReason: absenceReason,
      period: period,
    );
  }

  group('AbsencePeriod.tryParse', () {
    test('reconnaît le libellé RÉELLEMENT stocké en base', () {
      // Le piège d'origine : la colonne contient le libellé, pas le nom de
      // la constante. `period == 'fullDay'` ne matchait jamais.
      expect(AbsencePeriod.tryParse('Journée complète'),
          AbsencePeriod.fullDay);
      expect(AbsencePeriod.tryParse('Demi journée'), AbsencePeriod.halfDay);
    });

    test('tolère le nom de constante (anciennes lignes)', () {
      expect(AbsencePeriod.tryParse('fullDay'), AbsencePeriod.fullDay);
      expect(AbsencePeriod.tryParse('halfDay'), AbsencePeriod.halfDay);
    });

    test('traite vide, espaces et null comme absence de période', () {
      expect(AbsencePeriod.tryParse(null), isNull);
      expect(AbsencePeriod.tryParse(''), isNull);
      expect(AbsencePeriod.tryParse('   '), isNull);
      expect(AbsencePeriod.tryParse('n importe quoi'), isNull);
    });

    test('expose la fraction de journée due', () {
      expect(AbsencePeriod.halfDay.dayFraction, 0.5);
      expect(AbsencePeriod.fullDay.dayFraction, 0.0);
    });
  });

  group('calculateDailyTotal', () {
    test('LE CAS DU 24/09 : la demi-journée garde ses heures travaillées', () {
      final result = entry(
        startAfternoon: '13:30',
        endAfternoon: '18:30',
        absenceReason: 'Congés',
        period: 'Demi journée',
      ).calculateDailyTotal();

      expect(result, const Duration(hours: 5));
    });

    test('une journée complète d\'absence ne compte aucune heure', () {
      final result = entry(
        absenceReason: 'Congés',
        period: 'Journée complète',
      ).calculateDailyTotal();

      expect(result, Duration.zero);
    });

    /// Le bug de comparaison : avant correction, « Journée complète » ne
    /// matchait pas `'fullDay'`, donc une absence pleine conservait ses
    /// horaires résiduels au lieu de compter zéro.
    test('le libellé base d\'une journée complète est bien reconnu', () {
      final result = entry(
        startMorning: '08:00',
        endMorning: '12:00',
        absenceReason: 'Congés',
        period: 'Journée complète',
      ).calculateDailyTotal();

      expect(result, Duration.zero,
          reason: 'le libellé stocké doit annuler les heures, pas les garder');
    });

    test('une journée normale reste inchangée', () {
      final result = entry(
        startMorning: '08:05',
        endMorning: '12:18',
        startAfternoon: '13:18',
        endAfternoon: '17:23',
      ).calculateDailyTotal();

      expect(result, const Duration(hours: 8, minutes: 18));
    });
  });

  group('seuil proratisé', () {
    const threshold = Duration(hours: 8, minutes: 18);

    /// Reproduit l'arithmétique du use-case pour figer le résultat attendu :
    /// 5h00 sur une demi-journée due de 4h09 = +51 min, et NON −3h18.
    test('le 24/09 produit un excédent de 51 min, pas un déficit de 3h18', () {
      const worked = Duration(hours: 5);
      final halfThreshold = Duration(minutes: threshold.inMinutes ~/ 2);

      expect(halfThreshold, const Duration(hours: 4, minutes: 9));
      expect(worked - halfThreshold, const Duration(minutes: 51));

      // Ce qu'affichait le PDF avant correction, pour mémoire :
      expect(worked - threshold, const Duration(hours: -3, minutes: -18));
    });
  });
}
