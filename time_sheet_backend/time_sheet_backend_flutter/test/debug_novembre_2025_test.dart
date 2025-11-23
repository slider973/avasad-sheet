import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/services/monthly_overtime_calculator.dart';

/// Test de debug pour reproduire le calcul de novembre 2025
/// avec les données exactes fournies par l'utilisateur
void main() {
  group('Debug Novembre 2025', () {
    late MonthlyOvertimeCalculator calculator;

    setUp(() {
      calculator = MonthlyOvertimeCalculator();
    });

    test('Calcul avec les données réelles de novembre 2025 (21/10 -> 20/11)', () async {
      // Semaine 1 (21-24 octobre 2025)
      final entries = [
        // Mardi 21/10: 10h25
        TimesheetEntry(
          id: 1,
          dayDate: '2025-10-21',
          dayOfWeekDate: 'Mardi',
          startMorning: '07:30',
          endMorning: '11:55',
          startAfternoon: '13:30',
          endAfternoon: '19:30',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
        // Mercredi 22/10: 9h23
        TimesheetEntry(
          id: 2,
          dayDate: '2025-10-22',
          dayOfWeekDate: 'Mercredi',
          startMorning: '08:00',
          endMorning: '11:58',
          startAfternoon: '14:05',
          endAfternoon: '19:30',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
        // Jeudi 23/10: 7h22
        TimesheetEntry(
          id: 3,
          dayDate: '2025-10-23',
          dayOfWeekDate: 'Jeudi',
          startMorning: '08:55',
          endMorning: '12:15',
          startAfternoon: '12:58',
          endAfternoon: '17:00',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: false,
        ),
        // Vendredi 24/10: 8h58
        TimesheetEntry(
          id: 4,
          dayDate: '2025-10-24',
          dayOfWeekDate: 'Vendredi',
          startMorning: '08:35',
          endMorning: '12:10',
          startAfternoon: '12:50',
          endAfternoon: '18:13',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),

        // Semaine 2 (27-31 octobre 2025)
        // Lundi 27/10: 11h58
        TimesheetEntry(
          id: 5,
          dayDate: '2025-10-27',
          dayOfWeekDate: 'Lundi',
          startMorning: '07:02',
          endMorning: '12:20',
          startAfternoon: '12:50',
          endAfternoon: '19:30',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
        // Mardi 28/10: 7h21
        TimesheetEntry(
          id: 6,
          dayDate: '2025-10-28',
          dayOfWeekDate: 'Mardi',
          startMorning: '08:45',
          endMorning: '12:22',
          startAfternoon: '13:20',
          endAfternoon: '17:04',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: false,
        ),
        // Mercredi 29/10: 9h07
        TimesheetEntry(
          id: 7,
          dayDate: '2025-10-29',
          dayOfWeekDate: 'Mercredi',
          startMorning: '08:20',
          endMorning: '12:52',
          startAfternoon: '13:30',
          endAfternoon: '18:05',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
        // Jeudi 30/10: 7h45
        TimesheetEntry(
          id: 8,
          dayDate: '2025-10-30',
          dayOfWeekDate: 'Jeudi',
          startMorning: '08:10',
          endMorning: '12:10',
          startAfternoon: '13:25',
          endAfternoon: '17:10',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: false,
        ),
        // Vendredi 31/10: 7h52
        TimesheetEntry(
          id: 9,
          dayDate: '2025-10-31',
          dayOfWeekDate: 'Vendredi',
          startMorning: '08:10',
          endMorning: '11:47',
          startAfternoon: '13:10',
          endAfternoon: '17:25',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: false,
        ),

        // Semaine 3 (03-07 novembre 2025)
        // Lundi 03/11: 7h40
        TimesheetEntry(
          id: 10,
          dayDate: '2025-11-03',
          dayOfWeekDate: 'Lundi',
          startMorning: '09:00',
          endMorning: '12:10',
          startAfternoon: '13:15',
          endAfternoon: '17:45',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: false,
        ),
        // Mardi 04/11: 8h53
        TimesheetEntry(
          id: 11,
          dayDate: '2025-11-04',
          dayOfWeekDate: 'Mardi',
          startMorning: '09:00',
          endMorning: '12:20',
          startAfternoon: '13:10',
          endAfternoon: '18:43',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
        // Mercredi 05/11: 8h35
        TimesheetEntry(
          id: 12,
          dayDate: '2025-11-05',
          dayOfWeekDate: 'Mercredi',
          startMorning: '07:45',
          endMorning: '13:20',
          startAfternoon: '15:00',
          endAfternoon: '18:00',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
        // Jeudi 06/11: 7h34
        TimesheetEntry(
          id: 13,
          dayDate: '2025-11-06',
          dayOfWeekDate: 'Jeudi',
          startMorning: '08:31',
          endMorning: '12:16',
          startAfternoon: '13:16',
          endAfternoon: '17:05',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: false,
        ),
        // Vendredi 07/11: 8h30
        TimesheetEntry(
          id: 14,
          dayDate: '2025-11-07',
          dayOfWeekDate: 'Vendredi',
          startMorning: '08:05',
          endMorning: '11:57',
          startAfternoon: '12:45',
          endAfternoon: '17:23',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),

        // Semaine 4 (10-14 novembre 2025)
        // Lundi 10/11: 9h20
        TimesheetEntry(
          id: 15,
          dayDate: '2025-11-10',
          dayOfWeekDate: 'Lundi',
          startMorning: '08:45',
          endMorning: '12:05',
          startAfternoon: '12:33',
          endAfternoon: '18:33',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
        // Mardi 11/11: 8h40
        TimesheetEntry(
          id: 16,
          dayDate: '2025-11-11',
          dayOfWeekDate: 'Mardi',
          startMorning: '08:40',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '18:20',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
        // Mercredi 12/11: 8h40
        TimesheetEntry(
          id: 17,
          dayDate: '2025-11-12',
          dayOfWeekDate: 'Mercredi',
          startMorning: '08:20',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '18:00',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
        // Jeudi 13/11: 7h05
        TimesheetEntry(
          id: 18,
          dayDate: '2025-11-13',
          dayOfWeekDate: 'Jeudi',
          startMorning: '08:55',
          endMorning: '12:19',
          startAfternoon: '13:15',
          endAfternoon: '16:56',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: false,
        ),
        // Vendredi 14/11: 8h41
        TimesheetEntry(
          id: 19,
          dayDate: '2025-11-14',
          dayOfWeekDate: 'Vendredi',
          startMorning: '08:19',
          endMorning: '13:00',
          startAfternoon: '13:30',
          endAfternoon: '17:30',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),

        // Semaine 5 (17-20 novembre 2025)
        // Lundi 17/11: 8h24
        TimesheetEntry(
          id: 20,
          dayDate: '2025-11-17',
          dayOfWeekDate: 'Lundi',
          startMorning: '09:00',
          endMorning: '12:05',
          startAfternoon: '13:06',
          endAfternoon: '18:25',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
        // Mardi 18/11: 9h05
        TimesheetEntry(
          id: 21,
          dayDate: '2025-11-18',
          dayOfWeekDate: 'Mardi',
          startMorning: '08:57',
          endMorning: '11:57',
          startAfternoon: '13:30',
          endAfternoon: '19:35',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
        // Mercredi 19/11: 7h11
        TimesheetEntry(
          id: 22,
          dayDate: '2025-11-19',
          dayOfWeekDate: 'Mercredi',
          startMorning: '08:55',
          endMorning: '12:26',
          startAfternoon: '13:15',
          endAfternoon: '16:55',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: false,
        ),
        // Jeudi 20/11: 8h59
        TimesheetEntry(
          id: 23,
          dayDate: '2025-11-20',
          dayOfWeekDate: 'Jeudi',
          startMorning: '08:01',
          endMorning: '12:45',
          startAfternoon: '13:15',
          endAfternoon: '17:30',
          absenceReason: null,
          period: null,
          isWeekendDay: false,
          hasOvertimeHours: true,
        ),
      ];

      print('\n========================================');
      print('TEST DEBUG NOVEMBRE 2025');
      print('Période: 21/10/2025 → 20/11/2025');
      print('Nombre d\'entrées: ${entries.length}');
      print('========================================\n');

      // DEBUG: Afficher les heures calculées pour chaque jour
      print('VÉRIFICATION DES HEURES PAR JOUR:');
      Duration totalExcess = Duration.zero;
      Duration totalDeficit = Duration.zero;
      const threshold = Duration(hours: 8, minutes: 18);
      
      for (final entry in entries) {
        final daily = entry.calculateDailyTotal();
        final diff = daily - threshold;
        final sign = diff.isNegative ? '-' : '+';
        final absDiff = diff.abs();
        
        if (daily > threshold) {
          totalExcess += (daily - threshold);
        } else if (daily < threshold) {
          totalDeficit += (threshold - daily);
        }
        
        print('${entry.dayDate}: ${daily.inHours}h${daily.inMinutes.remainder(60)}m ($sign${absDiff.inHours}h${absDiff.inMinutes.remainder(60)}m)');
      }
      
      print('\nTOTAL EXCÈS: ${totalExcess.inHours}h${totalExcess.inMinutes.remainder(60)}m');
      print('TOTAL DÉFICIT: ${totalDeficit.inHours}h${totalDeficit.inMinutes.remainder(60)}m');
      print('SOLDE NET: ${(totalExcess - totalDeficit).inHours}h${(totalExcess - totalDeficit).inMinutes.remainder(60)}m\n');

      final summary = await calculator.calculateMonthlyOvertime(entries);

      print('\n========================================');
      print('RÉSULTAT DU CALCUL:');
      print('========================================');
      print('Heures régulières: ${summary.formattedRegularHours}');
      print('Heures sup weekday: ${summary.formattedWeekdayOvertime}');
      print('Heures sup weekend: ${summary.formattedWeekendOvertime}');
      print('TOTAL heures sup: ${summary.formattedTotalOvertime}');
      print('');
      print('Déficit total: ${summary.formattedDeficitHours}');
      print('Déficit compensé: ${summary.formattedCompensatedDeficitHours}');
      print('Déficit non compensé: ${summary.formattedUncompensatedDeficitHours}');
      print('');
      print('Jours travaillés: ${summary.workingDaysCount} weekday, ${summary.weekendDaysWorked} weekend');
      print('========================================\n');

      // Vérifications
      // Avec 23 jours de semaine, attendu = 23 × 8h18 = 190h54
      // Total travaillé selon tes données ≈ 197h28
      // Donc heures sup weekday attendues ≈ 6h34 (si aucun weekend)
      
      // Si le résultat est 6h34, c'est qu'il n'y a PAS de weekends dans les données
      // Si le résultat est 0h04, c'est qu'il y a un problème de compensation
      
      print('ANALYSE:');
      print('Si le total est ≈ 6h34 → pas de weekends, calcul brut sans compensation correcte');
      print('Si le total est ≈ 0h04 → compensation des déficits fonctionne correctement');
    });
  });
}
