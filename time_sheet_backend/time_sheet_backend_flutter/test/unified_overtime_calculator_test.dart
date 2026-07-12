import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/services/unified_overtime_calculator.dart';
import 'package:time_sheet/features/preference/presentation/widgets/overtime_calculation_mode_widget.dart';
import 'package:time_sheet/enum/overtime_type.dart';

// NOTE : l'API a changé — UnifiedOvertimeCalculator n'a plus de modeService
// ni de compareCalculationModes : le calcul est toujours mensuel avec
// compensation. Les tests de mode journalier et de comparaison des modes
// ont été supprimés avec l'API.
void main() {
  group('UnifiedOvertimeCalculator', () {
    late UnifiedOvertimeCalculator calculator;

    setUp(() {
      calculator = UnifiedOvertimeCalculator();
    });

    group('Mode mensuel avec compensation', () {
      test('Compense les déficits avec les excès', () async {
        final entries = [
          // Lundi : Déficit de 2h18
          TimesheetEntry(
            id: 1,
            dayDate: '08-Jan-24',
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
          // Mardi : 9h travaillées -> excès de 42min au-delà du seuil de 8h18
          TimesheetEntry(
            id: 2,
            dayDate: '09-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 9h total (3h + 6h)
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
        ];

        final summary = await calculator.calculateOvertime(entries);

        expect(summary.mode,
            equals(OvertimeCalculationMode.monthlyWithCompensation));
        expect(summary.weekdayOvertime,
            equals(Duration.zero)); // Pas d'heures sup après compensation
        expect(summary.deficitHours,
            equals(const Duration(hours: 2, minutes: 18)));
        expect(summary.compensatedDeficitHours,
            equals(const Duration(minutes: 42)));
        expect(summary.uncompensatedDeficitHours,
            equals(const Duration(hours: 1, minutes: 36)));
      });
    });

    group('Gestion des modes', () {
      test('Le mode est toujours mensuel avec compensation', () async {
        final mode = await calculator.getCurrentMode();
        expect(
            mode, equals(OvertimeCalculationMode.monthlyWithCompensation));

        // setCalculationMode est un no-op : le mode reste mensuel
        await calculator.setCalculationMode(OvertimeCalculationMode.daily);
        expect(await calculator.getCurrentMode(),
            equals(OvertimeCalculationMode.monthlyWithCompensation));
      });
    });

    group('Formatage et affichage', () {
      test('Formate correctement le résumé unifié', () async {
        final entries = [
          TimesheetEntry(
            id: 1,
            dayDate: '08-Jan-24',
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

        final summary = await calculator.calculateOvertime(entries);

        expect(summary.formattedRegularHours, equals('8h 18m'));
        expect(summary.formattedWeekdayOvertime, equals('1h 12m'));
        expect(summary.formattedTotalOvertime, equals('1h 12m'));

        final summaryString = summary.toString();
        expect(summaryString, contains('Calcul mensuel avec compensation'));
        expect(summaryString, contains('Heures régulières: 8h 18m'));
        expect(summaryString, contains('Heures sup weekday: 1h 12m'));
      });
    });

    group('Cas avec weekend', () {
      test('Gère correctement les heures weekend', () async {
        final entries = [
          // Weekday avec déficit
          TimesheetEntry(
            id: 1,
            dayDate: '08-Jan-24',
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
          // Weekend
          TimesheetEntry(
            id: 2,
            dayDate: '13-Jan-24',
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

        final summary = await calculator.calculateOvertime(entries);

        // Les heures weekend sont intégralement des heures supplémentaires
        expect(summary.weekendOvertime, equals(const Duration(hours: 7)));
        // Le lundi est en déficit : pas d'heures sup weekday
        expect(summary.weekdayOvertime, equals(Duration.zero));
      });
    });
  });
}
