import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/services/monthly_overtime_calculator.dart';
import 'package:time_sheet/enum/overtime_type.dart';

void main() {
  group('Monthly Overtime Integration Tests', () {
    late MonthlyOvertimeCalculator calculator;

    setUp(() {
      calculator = MonthlyOvertimeCalculator();
    });

    group('Scénarios réels de compensation des déficits', () {
      test('Semaine typique avec déficit compensé', () async {
        // Scénario réel : Employé qui fait moins d'heures certains jours
        // mais compense avec plus d'heures d'autres jours
        final entries = [
          // Lundi : Rendez-vous médical, seulement 4h
          TimesheetEntry(
            id: 1,
            dayDate: '08-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00', // 3h matin
            startAfternoon: '13:00',
            endAfternoon: '14:00', // 1h après-midi = 4h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),

          // Mardi : Journée normale
          TimesheetEntry(
            id: 2,
            dayDate: '09-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '09:00',
            endMorning: '12:00', // 3h matin
            startAfternoon: '13:00',
            endAfternoon: '18:18', // 5h18 après-midi = 8h18 total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),

          // Mercredi : Rattrapage, journée longue
          TimesheetEntry(
            id: 3,
            dayDate: '10-Jan-24',
            dayOfWeekDate: 'Mercredi',
            startMorning: '08:00',
            endMorning: '12:00', // 4h matin
            startAfternoon: '13:00',
            endAfternoon: '20:00', // 7h après-midi = 11h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),

          // Jeudi : Journée normale
          TimesheetEntry(
            id: 4,
            dayDate: '11-Jan-24',
            dayOfWeekDate: 'Jeudi',
            startMorning: '09:00',
            endMorning: '12:00', // 3h matin
            startAfternoon: '13:00',
            endAfternoon: '18:18', // 5h18 après-midi = 8h18 total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),

          // Vendredi : Départ anticipé
          TimesheetEntry(
            id: 5,
            dayDate: '12-Jan-24',
            dayOfWeekDate: 'Vendredi',
            startMorning: '09:00',
            endMorning: '12:00', // 3h matin
            startAfternoon: '13:00',
            endAfternoon: '16:00', // 3h après-midi = 6h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Calculs attendus :
        // Total travaillé : 4h + 8h18 + 11h + 8h18 + 6h = 37h36
        // Total attendu : 5 × 8h18 = 41h30
        // Déficit total : 4h18 (lundi) + 2h18 (vendredi) = 6h36
        // Excès total : 2h42 (mercredi)
        // Déficit non compensé : 6h36 - 2h42 = 3h54
        // Heures sup réelles : 0 (car déficit > excès)

        expect(summary.regularHours,
            equals(const Duration(hours: 37, minutes: 36)));
        expect(summary.weekdayOvertime, equals(Duration.zero));
        expect(summary.deficitHours,
            equals(const Duration(hours: 6, minutes: 36)));
        expect(summary.compensatedDeficitHours,
            equals(const Duration(hours: 2, minutes: 42)));
        expect(summary.uncompensatedDeficitHours,
            equals(const Duration(hours: 3, minutes: 54)));
        expect(summary.hasRealOvertime, isFalse);
        expect(summary.hasUncompensatedDeficit, isTrue);
      });

      test('Mois avec vraies heures supplémentaires après compensation',
          () async {
        // Scénario : Employé qui fait beaucoup d'heures supplémentaires
        final entries = [
          // Semaine 1 : Projet urgent
          TimesheetEntry(
            id: 1,
            dayDate: '08-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '08:00',
            endMorning: '12:00', // 4h matin
            startAfternoon: '13:00',
            endAfternoon: '21:00', // 8h après-midi = 12h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),

          TimesheetEntry(
            id: 2,
            dayDate: '09-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '08:00',
            endMorning: '12:00', // 4h matin
            startAfternoon: '13:00',
            endAfternoon: '20:00', // 7h après-midi = 11h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),

          // Mercredi : Journée courte pour récupérer
          TimesheetEntry(
            id: 3,
            dayDate: '10-Jan-24',
            dayOfWeekDate: 'Mercredi',
            startMorning: '10:00',
            endMorning: '12:00', // 2h matin
            startAfternoon: '13:00',
            endAfternoon: '16:00', // 3h après-midi = 5h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Calculs attendus :
        // Total travaillé : 12h + 11h + 5h = 28h
        // Total attendu : 3 × 8h18 = 24h54
        // Excès total : 3h42 (lundi) + 2h42 (mardi) = 6h24
        // Déficit total : 3h18 (mercredi)
        // Heures sup réelles : 6h24 - 3h18 = 3h06

        expect(summary.regularHours,
            equals(const Duration(hours: 24, minutes: 54)));
        expect(summary.weekdayOvertime,
            equals(const Duration(hours: 3, minutes: 6)));
        expect(summary.deficitHours,
            equals(const Duration(hours: 3, minutes: 18)));
        expect(summary.compensatedDeficitHours,
            equals(const Duration(hours: 3, minutes: 18)));
        expect(summary.uncompensatedDeficitHours, equals(Duration.zero));
        expect(summary.hasRealOvertime, isTrue);
        expect(summary.hasUncompensatedDeficit, isFalse);
      });

      test('Mois mixte avec weekend et compensation weekday', () async {
        final entries = [
          // Lundi : Déficit
          TimesheetEntry(
            id: 1,
            dayDate: '08-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '10:00',
            endMorning: '12:00', // 2h matin
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 4h après-midi = 6h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),

          // Mardi : Excès
          TimesheetEntry(
            id: 2,
            dayDate: '09-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '08:00',
            endMorning: '12:00', // 4h matin
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 6h après-midi = 10h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),

          // Samedi : Travail weekend
          TimesheetEntry(
            id: 3,
            dayDate: '13-Jan-24',
            dayOfWeekDate: 'Samedi',
            startMorning: '09:00',
            endMorning: '12:00', // 3h matin
            startAfternoon: '13:00',
            endAfternoon: '18:00', // 5h après-midi = 8h total
            absenceReason: null,
            period: null,
            isWeekendDay: true,
            isWeekendOvertimeEnabled: true,
            overtimeType: OvertimeType.WEEKEND_ONLY,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Calculs attendus :
        // Weekday : 6h + 10h = 16h travaillées, 16h36 attendues
        // Déficit weekday : 2h18 (lundi), Excès weekday : 1h42 (mardi)
        // Déficit non compensé : 36 minutes
        // Weekend : 8h (toutes en heures sup)

        expect(summary.regularHours, equals(const Duration(hours: 16)));
        expect(
            summary.weekdayOvertime, equals(Duration.zero)); // Déficit > excès
        expect(summary.weekendOvertime, equals(const Duration(hours: 8)));
        expect(summary.totalOvertime,
            equals(const Duration(hours: 8))); // Seulement weekend
        expect(summary.deficitHours,
            equals(const Duration(hours: 2, minutes: 18)));
        expect(summary.compensatedDeficitHours,
            equals(const Duration(hours: 1, minutes: 42)));
        expect(summary.uncompensatedDeficitHours,
            equals(const Duration(minutes: 36)));
      });
    });

    group('Calculs de pourcentages et statistiques', () {
      test('Pourcentage de compensation des déficits', () async {
        final entries = [
          // Déficit de 4h18
          TimesheetEntry(
            id: 1,
            dayDate: '08-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '14:00', // 4h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),

          // Excès de 2h09 (compense partiellement)
          TimesheetEntry(
            id: 2,
            dayDate: '09-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '18:27', // 10h27 total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Déficit : 4h18 (258 minutes)
        // Compensation : 2h09 (129 minutes)
        // Pourcentage : 129/258 * 100 = 50%
        expect(summary.deficitCompensationPercentage, equals(50.0));
      });

      test('Statistiques de jours travaillés', () async {
        final entries = [
          // 2 jours weekday
          TimesheetEntry(
            id: 1,
            dayDate: '08-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '18:18',
            absenceReason: null,
            period: null,
            isWeekendDay: false,
          ),

          TimesheetEntry(
            id: 2,
            dayDate: '09-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '18:18',
            absenceReason: null,
            period: null,
            isWeekendDay: false,
          ),

          // 1 jour weekend
          TimesheetEntry(
            id: 3,
            dayDate: '13-Jan-24',
            dayOfWeekDate: 'Samedi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            absenceReason: null,
            period: null,
            isWeekendDay: true,
            isWeekendOvertimeEnabled: true,
            overtimeType: OvertimeType.WEEKEND_ONLY,
          ),

          // 1 absence (ne doit pas être comptée)
          TimesheetEntry(
            id: 4,
            dayDate: '10-Jan-24',
            dayOfWeekDate: 'Mercredi',
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absenceReason: 'Congé maladie',
            period: null,
            isWeekendDay: false,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        expect(summary.workingDaysCount,
            equals(2)); // Seulement les jours weekday travaillés
        expect(summary.weekendDaysWorked, equals(1)); // 1 samedi
      });
    });

    group('Formatage et affichage', () {
      test('Formatage des résumés complexes', () async {
        final entries = [
          TimesheetEntry(
            id: 1,
            dayDate: '08-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '08:30',
            endMorning: '12:15',
            startAfternoon: '13:45',
            endAfternoon: '19:22', // 9h22 total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Vérifier le formatage des durées avec minutes
        expect(summary.formattedRegularHours, equals('8h 18m'));
        expect(
            summary.formattedWeekdayOvertime, equals('1h 04m')); // 9h22 - 8h18
        expect(summary.formattedTotalOvertime, equals('1h 04m'));

        // Vérifier le toString complet
        final summaryString = summary.toString();
        expect(summaryString, contains('regularHours: 8h 18m'));
        expect(summaryString, contains('weekdayOvertime: 1h 04m'));
        expect(summaryString, contains('workingDays: 1'));
      });
    });

    group('Breakdown hebdomadaire', () {
      test('Calcul par semaine avec compensation', () async {
        final entries = [
          // Semaine 1 (8-12 janvier)
          TimesheetEntry(
            id: 1,
            dayDate: '08-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '20:00', // 10h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),

          TimesheetEntry(
            id: 2,
            dayDate: '09-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '10:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '16:00', // 5h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),

          // Semaine 2 (15-19 janvier)
          TimesheetEntry(
            id: 3,
            dayDate: '15-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '18:18', // 8h18 total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),
        ];

        final weeklyBreakdown =
            await calculator.calculateWeeklyBreakdown(entries);

        expect(weeklyBreakdown.length, equals(2)); // 2 semaines

        // Semaine 1 : 15h travaillées, 16h36 attendues
        // Excès : 1h42, Déficit : 3h18 → Pas d'heures sup
        expect(weeklyBreakdown[0].weekdayOvertime, equals(Duration.zero));
        expect(weeklyBreakdown[0].deficitHours,
            equals(const Duration(hours: 1, minutes: 36))); // Net déficit

        // Semaine 2 : 8h18 travaillées, 8h18 attendues → Parfait
        expect(weeklyBreakdown[1].weekdayOvertime, equals(Duration.zero));
        expect(weeklyBreakdown[1].deficitHours, equals(Duration.zero));
      });
    });
  });
}
