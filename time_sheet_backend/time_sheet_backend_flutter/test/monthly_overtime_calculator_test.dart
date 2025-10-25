import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/services/monthly_overtime_calculator.dart';
import 'package:time_sheet/enum/overtime_type.dart';

void main() {
  group('MonthlyOvertimeCalculator', () {
    late MonthlyOvertimeCalculator calculator;

    setUp(() {
      calculator = MonthlyOvertimeCalculator();
    });

    group('Calcul avec compensation des déficits', () {
      test('Semaine avec déficit compensé par excès', () async {
        // Scénario : Lundi 6h, Mardi 10h = 16h total
        // Attendu : 16h18 (2 jours × 8h18)
        // Résultat : Pas d'heures sup car déficit > excès
        final entries = [
          TimesheetEntry(
            id: 1,
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00', // 3h matin
            startAfternoon: '13:00',
            endAfternoon: '16:00', // 3h après-midi = 6h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),
          TimesheetEntry(
            id: 2,
            dayDate: '02-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '09:00',
            endMorning: '12:00', // 3h matin
            startAfternoon: '13:00',
            endAfternoon: '20:00', // 7h après-midi = 10h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Vérifications
        expect(summary.regularHours,
            equals(const Duration(hours: 16))); // Total travaillé
        expect(summary.weekdayOvertime,
            equals(Duration.zero)); // Pas d'heures sup après compensation
        expect(summary.deficitHours,
            equals(const Duration(hours: 2, minutes: 18))); // Déficit lundi
        expect(summary.compensatedDeficitHours,
            equals(const Duration(hours: 1, minutes: 42))); // Excès mardi
        expect(summary.uncompensatedDeficitHours,
            equals(const Duration(minutes: 36))); // Déficit restant
      });

      test('Semaine avec heures supplémentaires réelles après compensation',
          () async {
        // Scénario : Lundi 6h, Mardi 12h = 18h total
        // Attendu : 16h36 (2 jours × 8h18)
        // Résultat : 1h24 d'heures sup après compensation
        final entries = [
          TimesheetEntry(
            id: 1,
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00', // 3h matin
            startAfternoon: '13:00',
            endAfternoon: '16:00', // 3h après-midi = 6h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),
          TimesheetEntry(
            id: 2,
            dayDate: '02-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '09:00',
            endMorning: '12:00', // 3h matin
            startAfternoon: '13:00',
            endAfternoon: '22:00', // 9h après-midi = 12h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Vérifications
        expect(summary.regularHours,
            equals(const Duration(hours: 16, minutes: 36))); // Heures attendues
        expect(
            summary.weekdayOvertime,
            equals(
                const Duration(hours: 1, minutes: 24))); // Heures sup réelles
        expect(summary.deficitHours,
            equals(const Duration(hours: 2, minutes: 18))); // Déficit lundi
        expect(
            summary.compensatedDeficitHours,
            equals(
                const Duration(hours: 2, minutes: 18))); // Entièrement compensé
        expect(summary.uncompensatedDeficitHours,
            equals(Duration.zero)); // Pas de déficit restant
      });

      test('Semaine normale sans déficit ni excès', () async {
        // Scénario : Chaque jour exactement 8h18
        final entries = [
          TimesheetEntry(
            id: 1,
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00', // 3h matin
            startAfternoon: '13:00',
            endAfternoon: '18:18', // 5h18 après-midi = 8h18 total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),
          TimesheetEntry(
            id: 2,
            dayDate: '02-Jan-24',
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
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Vérifications
        expect(summary.regularHours,
            equals(const Duration(hours: 16, minutes: 36)));
        expect(summary.weekdayOvertime, equals(Duration.zero));
        expect(summary.deficitHours, equals(Duration.zero));
        expect(summary.compensatedDeficitHours, equals(Duration.zero));
        expect(summary.uncompensatedDeficitHours, equals(Duration.zero));
      });
    });

    group('Calcul avec weekend', () {
      test('Weekend + weekday avec compensation', () async {
        final entries = [
          // Lundi déficit
          TimesheetEntry(
            id: 1,
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '16:00', // 6h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),
          // Samedi weekend
          TimesheetEntry(
            id: 2,
            dayDate: '06-Jan-24',
            dayOfWeekDate: 'Samedi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 7h total
            absenceReason: null,
            period: null,
            isWeekendDay: true,
            isWeekendOvertimeEnabled: true,
            overtimeType: OvertimeType.WEEKEND_ONLY,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Vérifications
        expect(summary.regularHours,
            equals(const Duration(hours: 6))); // Seulement lundi
        expect(summary.weekdayOvertime,
            equals(Duration.zero)); // Pas d'heures sup weekday
        expect(summary.weekendOvertime,
            equals(const Duration(hours: 7))); // Toutes les heures weekend
        expect(summary.deficitHours,
            equals(const Duration(hours: 2, minutes: 18))); // Déficit lundi
        expect(summary.uncompensatedDeficitHours,
            equals(const Duration(hours: 2, minutes: 18))); // Non compensé
      });
    });

    group('Calcul hebdomadaire', () {
      test('Breakdown par semaine', () async {
        final entries = [
          // Semaine 1
          TimesheetEntry(
            id: 1,
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 9h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
          // Semaine 2 (8 jours plus tard)
          TimesheetEntry(
            id: 2,
            dayDate: '09-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00', // 7h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),
        ];

        final weeklyBreakdown =
            await calculator.calculateWeeklyBreakdown(entries);

        expect(weeklyBreakdown.length, equals(2)); // 2 semaines différentes

        // Semaine 1 : 9h travaillées, 8h18 attendues = 42min d'heures sup
        expect(weeklyBreakdown[0].weekdayOvertime,
            equals(const Duration(minutes: 42)));

        // Semaine 2 : 7h travaillées, 8h18 attendues = déficit
        expect(weeklyBreakdown[1].weekdayOvertime, equals(Duration.zero));
        expect(weeklyBreakdown[1].deficitHours,
            equals(const Duration(hours: 1, minutes: 18)));
      });
    });

    group('Cas limites', () {
      test('Aucune entrée', () async {
        final summary = await calculator.calculateMonthlyOvertime([]);

        expect(summary.regularHours, equals(Duration.zero));
        expect(summary.weekdayOvertime, equals(Duration.zero));
        expect(summary.weekendOvertime, equals(Duration.zero));
        expect(summary.deficitHours, equals(Duration.zero));
      });

      test('Entrées avec absences', () async {
        final entries = [
          TimesheetEntry(
            id: 1,
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absenceReason: 'Congé',
            period: null,
            isWeekendDay: false,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Les absences ne doivent pas être comptées
        expect(summary.regularHours, equals(Duration.zero));
        expect(summary.workingDaysCount, equals(0));
      });
    });

    group('Formatage et affichage', () {
      test('Formatage des durées', () async {
        final entries = [
          TimesheetEntry(
            id: 1,
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:30', // 9h30 total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        expect(summary.formattedRegularHours, equals('8h 18m'));
        expect(summary.formattedWeekdayOvertime, equals('1h 12m'));
        expect(summary.formattedTotalOvertime, equals('1h 12m'));
      });

      test('Pourcentage de compensation des déficits', () async {
        final entries = [
          TimesheetEntry(
            id: 1,
            dayDate: '01-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '16:00', // 6h total (déficit 2h18)
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),
          TimesheetEntry(
            id: 2,
            dayDate: '02-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:27', // 9h27 total (excès 1h09)
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
        ];

        final summary = await calculator.calculateMonthlyOvertime(entries);

        // Déficit de 2h18 (138 min), compensé par 1h09 (69 min)
        // Pourcentage = 69/138 * 100 = 50%
        expect(summary.deficitCompensationPercentage, equals(50.0));
      });
    });
  });
}
