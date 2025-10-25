import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/services/unified_overtime_calculator.dart';
import 'package:time_sheet/services/overtime_calculation_mode_service.dart';
import 'package:time_sheet/features/preference/presentation/widgets/overtime_calculation_mode_widget.dart';
import 'package:time_sheet/enum/overtime_type.dart';

@GenerateMocks([OvertimeCalculationModeService])
import 'unified_overtime_calculator_test.mocks.dart';

void main() {
  group('UnifiedOvertimeCalculator', () {
    late UnifiedOvertimeCalculator calculator;
    late MockOvertimeCalculationModeService mockModeService;

    setUp(() {
      mockModeService = MockOvertimeCalculationModeService();
      calculator = UnifiedOvertimeCalculator(modeService: mockModeService);
    });

    group('Mode journalier', () {
      setUp(() {
        when(mockModeService.getCurrentMode())
            .thenAnswer((_) async => OvertimeCalculationMode.daily);
      });

      test('Calcule les heures sup jour par jour', () async {
        final entries = [
          TimesheetEntry(
            id: 1,
            dayDate: '08-Jan-24',
            dayOfWeekDate: 'Lundi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '20:00', // 10h total = 1h42 d'heures sup
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
            endAfternoon: '16:00', // 5h total = pas d'heures sup
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: false,
          ),
        ];

        final summary = await calculator.calculateOvertime(entries);

        expect(summary.mode, equals(OvertimeCalculationMode.daily));
        expect(summary.weekdayOvertime,
            equals(const Duration(hours: 1, minutes: 42)));
        expect(summary.deficitHours,
            equals(Duration.zero)); // Pas de compensation en mode journalier
        expect(summary.compensatedDeficitHours, equals(Duration.zero));
      });
    });

    group('Mode mensuel avec compensation', () {
      setUp(() {
        when(mockModeService.getCurrentMode()).thenAnswer(
            (_) async => OvertimeCalculationMode.monthlyWithCompensation);
      });

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
          // Mardi : Excès de 1h42
          TimesheetEntry(
            id: 2,
            dayDate: '09-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 10h total
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
            equals(const Duration(hours: 1, minutes: 42)));
        expect(summary.uncompensatedDeficitHours,
            equals(const Duration(minutes: 36)));
      });
    });

    group('Comparaison des modes', () {
      test('Compare les deux modes de calcul', () async {
        final entries = [
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
          TimesheetEntry(
            id: 2,
            dayDate: '09-Jan-24',
            dayOfWeekDate: 'Mardi',
            startMorning: '09:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '20:00', // 11h total
            absenceReason: null,
            period: null,
            isWeekendDay: false,
            hasOvertimeHours: true,
          ),
        ];

        final comparison = await calculator.compareCalculationModes(entries);

        // Mode journalier : 0h (lundi) + 2h42 (mardi) = 2h42
        expect(comparison.dailyMode.totalOvertime,
            equals(const Duration(hours: 2, minutes: 42)));

        // Mode mensuel : 17h travaillées - 16h36 attendues = 24min d'heures sup
        expect(comparison.monthlyMode.totalOvertime,
            equals(const Duration(minutes: 24)));

        // Le mode journalier donne plus d'heures sup dans ce cas
        expect(comparison.modeWithMoreOvertime,
            equals(OvertimeCalculationMode.daily));
        expect(comparison.overtimeDifference,
            equals(const Duration(hours: 2, minutes: 18)));
      });
    });

    group('Gestion des modes', () {
      test('Change le mode de calcul', () async {
        await calculator.setCalculationMode(
            OvertimeCalculationMode.monthlyWithCompensation);

        verify(mockModeService.setCalculationMode(
                OvertimeCalculationMode.monthlyWithCompensation))
            .called(1);
      });

      test('Obtient le mode actuel', () async {
        when(mockModeService.getCurrentMode())
            .thenAnswer((_) async => OvertimeCalculationMode.daily);

        final mode = await calculator.getCurrentMode();

        expect(mode, equals(OvertimeCalculationMode.daily));
        verify(mockModeService.getCurrentMode()).called(1);
      });
    });

    group('Formatage et affichage', () {
      test('Formate correctement le résumé unifié', () async {
        when(mockModeService.getCurrentMode()).thenAnswer(
            (_) async => OvertimeCalculationMode.monthlyWithCompensation);

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

      test('Formate correctement la comparaison', () async {
        final entries = [
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
        ];

        final comparison = await calculator.compareCalculationModes(entries);
        final comparisonString = comparison.toString();

        expect(comparisonString, contains('Comparaison des modes de calcul'));
        expect(comparisonString, contains('Mode journalier'));
        expect(comparisonString, contains('Mode mensuel avec compensation'));
        expect(comparisonString, contains('Différence:'));
      });
    });

    group('Cas avec weekend', () {
      test('Gère correctement les heures weekend dans les deux modes',
          () async {
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

        final comparison = await calculator.compareCalculationModes(entries);

        // Les heures weekend doivent être identiques dans les deux modes
        expect(comparison.dailyMode.weekendOvertime,
            equals(const Duration(hours: 7)));
        expect(comparison.monthlyMode.weekendOvertime,
            equals(const Duration(hours: 7)));

        // Seules les heures weekday diffèrent
        expect(comparison.dailyMode.weekdayOvertime,
            equals(Duration.zero)); // Pas d'excès en journalier
        expect(comparison.monthlyMode.weekdayOvertime,
            equals(Duration.zero)); // Déficit en mensuel
      });
    });
  });
}
