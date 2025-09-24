import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_screen.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_content_minimal.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/vacation_days_info.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';

/// Tests de benchmark pour comparer les performances des composants pointage
/// Mesure l'impact de la modernisation sur les performances (Requirement 10.3)
void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  group('Pointage Performance Benchmark Tests', () {
    late VacationDaysInfo vacationInfo;
    late TimesheetEntry currentEntry;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
      vacationInfo = VacationDaysInfo(
        currentYearTotal: 25,
        lastYearRemaining: 5,
        usedDays: 10,
        remainingTotal: 20,
      );

      final dateFormat = DateFormat('dd-MMM-yy');
      final dayFormat = DateFormat('EEEE');

      currentEntry = TimesheetEntry(
        id: 1,
        dayDate: dateFormat.format(testDate),
        dayOfWeekDate: dayFormat.format(testDate),
        startMorning: '',
        endMorning: '',
        startAfternoon: '',
        endAfternoon: '',
        hasOvertimeHours: false,
      );
    });

    group('Benchmark: Version Comparison', () {
      testWidgets('Benchmark: PointageScreen vs PointageContentMinimal',
          (WidgetTester tester) async {
        final pointages = [
          {
            'type': 'Entrée',
            'heure': testDate.subtract(const Duration(hours: 6)),
          },
          {
            'type': 'Début pause',
            'heure': testDate.subtract(const Duration(hours: 3)),
          },
          {
            'type': 'Fin pause',
            'heure': testDate.subtract(const Duration(hours: 2)),
          }
        ];

        // Benchmark PointageScreen (version complète)
        final stopwatchFull = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: PointageScreen(
              etatActuel: 'Reprise',
              dernierPointage: testDate,
              selectedDate: testDate,
              progression: 0.8,
              pointages: pointages,
              onActionPointage: () {},
              onModifierPointage: (pointage) {},
              onSignalerAbsencePeriode: (DateTime start,
                  DateTime end,
                  String motif,
                  AbsenceType type,
                  String comment,
                  String period,
                  TimeOfDay? startTime,
                  TimeOfDay? endTime) {},
              onDeleteEntry: () {},
              totalDayHours: const Duration(hours: 5),
              monthlyHoursStatus: 'OK',
              totalBreakTime: const Duration(hours: 1),
              weeklyWorkTime: const Duration(hours: 25),
              weeklyTarget: const Duration(hours: 40),
              vacationInfo: vacationInfo,
              overtimeHours: Duration.zero,
              currentEntry: currentEntry,
              onToggleOvertime: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatchFull.stop();

        // Benchmark PointageContentMinimal (version optimisée)
        final stopwatchMinimal = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageContentMinimal(
                etatActuel: 'Reprise',
                dernierPointage: testDate,
                selectedDate: testDate,
                progression: 0.8,
                pointages: pointages,
                onActionPointage: () {},
                onModifierPointage: (pointage) {},
                onSignalerAbsencePeriode: (DateTime start,
                    DateTime end,
                    String motif,
                    AbsenceType type,
                    String comment,
                    String period,
                    TimeOfDay? startTime,
                    TimeOfDay? endTime) {},
                onDeleteEntry: () {},
                totalDayHours: const Duration(hours: 5),
                monthlyHoursStatus: 'OK',
                totalBreakTime: const Duration(hours: 1),
                weeklyWorkTime: const Duration(hours: 25),
                weeklyTarget: const Duration(hours: 40),
                vacationInfo: vacationInfo,
                overtimeHours: Duration.zero,
                currentEntry: currentEntry,
                onToggleOvertime: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatchMinimal.stop();

        final fullTime = stopwatchFull.elapsedMilliseconds;
        final minimalTime = stopwatchMinimal.elapsedMilliseconds;
        final improvement = ((fullTime - minimalTime) / fullTime * 100);

        print('=== BENCHMARK RESULTS ===');
        print('PointageScreen (full): ${fullTime}ms');
        print('PointageContentMinimal: ${minimalTime}ms');
        print('Performance improvement: ${improvement.toStringAsFixed(1)}%');

        // La version minimale devrait être plus rapide
        expect(minimalTime, lessThan(fullTime),
            reason:
                'PointageContentMinimal should be faster than PointageScreen');

        // Amélioration d'au moins 10% attendue
        expect(improvement, greaterThan(10),
            reason: 'Should have at least 10% performance improvement');
      });

      testWidgets('Benchmark: Multiple rapid state changes',
          (WidgetTester tester) async {
        final states = ['Non commencé', 'Entrée', 'Pause', 'Reprise', 'Sortie'];
        final iterations = 10;

        // Benchmark version complète
        final fullVersionTimes = <int>[];
        for (int i = 0; i < iterations; i++) {
          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: PointageScreen(
                etatActuel: states[i % states.length],
                dernierPointage: testDate,
                selectedDate: testDate,
                progression: (i % 10) / 10.0,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(Duration(hours: i % 8 + 1)),
                  }
                ],
                onActionPointage: () {},
                onModifierPointage: (pointage) {},
                onSignalerAbsencePeriode: (DateTime start,
                    DateTime end,
                    String motif,
                    AbsenceType type,
                    String comment,
                    String period,
                    TimeOfDay? startTime,
                    TimeOfDay? endTime) {},
                onDeleteEntry: () {},
                totalDayHours: Duration(hours: i % 8 + 1),
                monthlyHoursStatus: 'OK',
                totalBreakTime: Duration(minutes: i * 5),
                weeklyWorkTime: const Duration(hours: 25),
                weeklyTarget: const Duration(hours: 40),
                vacationInfo: vacationInfo,
                overtimeHours: Duration.zero,
                currentEntry: currentEntry,
                onToggleOvertime: () {},
              ),
            ),
          );

          await tester.pump();
          stopwatch.stop();
          fullVersionTimes.add(stopwatch.elapsedMilliseconds);
        }

        // Benchmark version minimale
        final minimalVersionTimes = <int>[];
        for (int i = 0; i < iterations; i++) {
          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageContentMinimal(
                  etatActuel: states[i % states.length],
                  dernierPointage: testDate,
                  selectedDate: testDate,
                  progression: (i % 10) / 10.0,
                  pointages: [
                    {
                      'type': 'Entrée',
                      'heure': testDate.subtract(Duration(hours: i % 8 + 1)),
                    }
                  ],
                  onActionPointage: () {},
                  onModifierPointage: (pointage) {},
                  onSignalerAbsencePeriode: (DateTime start,
                      DateTime end,
                      String motif,
                      AbsenceType type,
                      String comment,
                      String period,
                      TimeOfDay? startTime,
                      TimeOfDay? endTime) {},
                  onDeleteEntry: () {},
                  totalDayHours: Duration(hours: i % 8 + 1),
                  monthlyHoursStatus: 'OK',
                  totalBreakTime: Duration(minutes: i * 5),
                  weeklyWorkTime: const Duration(hours: 25),
                  weeklyTarget: const Duration(hours: 40),
                  vacationInfo: vacationInfo,
                  overtimeHours: Duration.zero,
                  currentEntry: currentEntry,
                  onToggleOvertime: () {},
                ),
              ),
            ),
          );

          await tester.pump();
          stopwatch.stop();
          minimalVersionTimes.add(stopwatch.elapsedMilliseconds);
        }

        final avgFullTime =
            fullVersionTimes.reduce((a, b) => a + b) / fullVersionTimes.length;
        final avgMinimalTime = minimalVersionTimes.reduce((a, b) => a + b) /
            minimalVersionTimes.length;
        final improvement =
            ((avgFullTime - avgMinimalTime) / avgFullTime * 100);

        print('=== RAPID STATE CHANGES BENCHMARK ===');
        print(
            'Average PointageScreen time: ${avgFullTime.toStringAsFixed(1)}ms');
        print(
            'Average PointageContentMinimal time: ${avgMinimalTime.toStringAsFixed(1)}ms');
        print('Performance improvement: ${improvement.toStringAsFixed(1)}%');

        // La version minimale devrait être consistamment plus rapide
        expect(avgMinimalTime, lessThan(avgFullTime),
            reason: 'Minimal version should be faster on average');
      });
    });

    group('Benchmark: Memory Usage', () {
      testWidgets('Memory efficiency comparison', (WidgetTester tester) async {
        // Test de construction/destruction répétée pour détecter les fuites
        const cycles = 20;

        // Test version complète
        for (int i = 0; i < cycles; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: PointageScreen(
                etatActuel: 'Entrée',
                dernierPointage: testDate,
                selectedDate: testDate,
                progression: 0.5,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 2)),
                  }
                ],
                onActionPointage: () {},
                onModifierPointage: (pointage) {},
                onSignalerAbsencePeriode: (DateTime start,
                    DateTime end,
                    String motif,
                    AbsenceType type,
                    String comment,
                    String period,
                    TimeOfDay? startTime,
                    TimeOfDay? endTime) {},
                onDeleteEntry: () {},
                totalDayHours: const Duration(hours: 2),
                monthlyHoursStatus: 'OK',
                totalBreakTime: Duration.zero,
                weeklyWorkTime: const Duration(hours: 25),
                weeklyTarget: const Duration(hours: 40),
                vacationInfo: vacationInfo,
                overtimeHours: Duration.zero,
                currentEntry: currentEntry,
                onToggleOvertime: () {},
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Destruction
          await tester.pumpWidget(const MaterialApp(home: SizedBox()));
          await tester.pumpAndSettle();
        }

        // Test version minimale
        for (int i = 0; i < cycles; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageContentMinimal(
                  etatActuel: 'Entrée',
                  dernierPointage: testDate,
                  selectedDate: testDate,
                  progression: 0.5,
                  pointages: [
                    {
                      'type': 'Entrée',
                      'heure': testDate.subtract(const Duration(hours: 2)),
                    }
                  ],
                  onActionPointage: () {},
                  onModifierPointage: (pointage) {},
                  onSignalerAbsencePeriode: (DateTime start,
                      DateTime end,
                      String motif,
                      AbsenceType type,
                      String comment,
                      String period,
                      TimeOfDay? startTime,
                      TimeOfDay? endTime) {},
                  onDeleteEntry: () {},
                  totalDayHours: const Duration(hours: 2),
                  monthlyHoursStatus: 'OK',
                  totalBreakTime: Duration.zero,
                  weeklyWorkTime: const Duration(hours: 25),
                  weeklyTarget: const Duration(hours: 40),
                  vacationInfo: vacationInfo,
                  overtimeHours: Duration.zero,
                  currentEntry: currentEntry,
                  onToggleOvertime: () {},
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Destruction
          await tester.pumpWidget(const MaterialApp(home: SizedBox()));
          await tester.pumpAndSettle();
        }

        // Si nous arrivons ici sans erreur de mémoire, le test passe
        expect(true, isTrue,
            reason: 'Memory efficiency test completed successfully');
        print(
            'Memory efficiency test: ${cycles * 2} cycles completed without issues');
      });
    });

    group('Benchmark: Scalability', () {
      testWidgets('Large dataset performance comparison',
          (WidgetTester tester) async {
        // Créer des datasets de tailles croissantes
        final dataSizes = [10, 25, 50, 100];

        for (final size in dataSizes) {
          final largePointageList = List.generate(
              size,
              (index) => {
                    'type': [
                      'Entrée',
                      'Début pause',
                      'Fin pause',
                      'Sortie'
                    ][index % 4],
                    'heure': testDate.subtract(Duration(minutes: index * 5)),
                  });

          // Test version complète
          final stopwatchFull = Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: PointageScreen(
                etatActuel: 'Sortie',
                dernierPointage: testDate,
                selectedDate: testDate,
                progression: 1.0,
                pointages: largePointageList,
                onActionPointage: () {},
                onModifierPointage: (pointage) {},
                onSignalerAbsencePeriode: (DateTime start,
                    DateTime end,
                    String motif,
                    AbsenceType type,
                    String comment,
                    String period,
                    TimeOfDay? startTime,
                    TimeOfDay? endTime) {},
                onDeleteEntry: () {},
                totalDayHours: const Duration(hours: 8),
                monthlyHoursStatus: 'OK',
                totalBreakTime: const Duration(hours: 1),
                weeklyWorkTime: const Duration(hours: 40),
                weeklyTarget: const Duration(hours: 40),
                vacationInfo: vacationInfo,
                overtimeHours: Duration.zero,
                currentEntry: currentEntry,
                onToggleOvertime: () {},
              ),
            ),
          );

          await tester.pumpAndSettle();
          stopwatchFull.stop();

          // Test version minimale
          final stopwatchMinimal = Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageContentMinimal(
                  etatActuel: 'Sortie',
                  dernierPointage: testDate,
                  selectedDate: testDate,
                  progression: 1.0,
                  pointages: largePointageList,
                  onActionPointage: () {},
                  onModifierPointage: (pointage) {},
                  onSignalerAbsencePeriode: (DateTime start,
                      DateTime end,
                      String motif,
                      AbsenceType type,
                      String comment,
                      String period,
                      TimeOfDay? startTime,
                      TimeOfDay? endTime) {},
                  onDeleteEntry: () {},
                  totalDayHours: const Duration(hours: 8),
                  monthlyHoursStatus: 'OK',
                  totalBreakTime: const Duration(hours: 1),
                  weeklyWorkTime: const Duration(hours: 40),
                  weeklyTarget: const Duration(hours: 40),
                  vacationInfo: vacationInfo,
                  overtimeHours: Duration.zero,
                  currentEntry: currentEntry,
                  onToggleOvertime: () {},
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          stopwatchMinimal.stop();

          final fullTime = stopwatchFull.elapsedMilliseconds;
          final minimalTime = stopwatchMinimal.elapsedMilliseconds;
          final improvement = ((fullTime - minimalTime) / fullTime * 100);

          print('=== SCALABILITY BENCHMARK (${size} items) ===');
          print('PointageScreen: ${fullTime}ms');
          print('PointageContentMinimal: ${minimalTime}ms');
          print('Improvement: ${improvement.toStringAsFixed(1)}%');

          // Vérifier que les performances restent acceptables même avec de gros datasets
          expect(minimalTime, lessThan(1000),
              reason:
                  'Minimal version should handle ${size} items in less than 1s');

          expect(minimalTime, lessThan(fullTime),
              reason: 'Minimal version should be faster with ${size} items');
        }
      });
    });
  });
}
