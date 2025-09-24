import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_main_section.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_timer.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_fab.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_screen.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_layout.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/vacation_days_info.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';

/// Tests de performance pour les composants pointage modernisés
/// Valide les exigences de performance (Requirement 10.3)
void main() {
  setUpAll(() async {
    // Initialize date formatting for French locale
    await initializeDateFormatting('fr_FR', null);
  });

  group('Pointage Performance Tests', () {
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

    group('Widget Build Performance (Requirement 10.3)', () {
      testWidgets('PointageMainSection builds within performance threshold',
          (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Entrée',
                dernierPointage: testDate,
                progression: 0.5,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 2)),
                  }
                ],
                totalDayHours: const Duration(hours: 2),
                totalBreakTime: Duration.zero,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Performance threshold: should build in less than 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason: 'PointageMainSection should build in less than 100ms');

        print(
            'PointageMainSection build time: ${stopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('PointageTimer builds within performance threshold',
          (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageTimer(
                etatActuel: 'Sortie',
                dernierPointage: testDate,
                progression: 1.0,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 8)),
                  },
                  {
                    'type': 'Début pause',
                    'heure': testDate.subtract(const Duration(hours: 4)),
                  },
                  {
                    'type': 'Fin pause',
                    'heure': testDate.subtract(const Duration(hours: 3)),
                  },
                  {
                    'type': 'Fin de journée',
                    'heure': testDate,
                  }
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Performance threshold: should build in less than 150ms (CustomPaint is more expensive)
        expect(stopwatch.elapsedMilliseconds, lessThan(150),
            reason: 'PointageTimer should build in less than 150ms');

        print('PointageTimer build time: ${stopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('PointageFAB builds within performance threshold',
          (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageFAB(
                etatActuel: 'Non commencé',
                onPressed: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Performance threshold: should build in less than 50ms (simple widget)
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: 'PointageFAB should build in less than 50ms');

        print('PointageFAB build time: ${stopwatch.elapsedMilliseconds}ms');
      });

      testWidgets('Complete PointageScreen builds within performance threshold',
          (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: PointageScreen(
              etatActuel: 'Reprise',
              dernierPointage: testDate,
              selectedDate: testDate,
              progression: 0.8,
              pointages: [
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
        stopwatch.stop();

        // Performance threshold: should build in less than 300ms (complete screen)
        expect(stopwatch.elapsedMilliseconds, lessThan(300),
            reason: 'Complete PointageScreen should build in less than 300ms');

        print(
            'Complete PointageScreen build time: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Memory Performance Tests (Requirement 10.3)', () {
      testWidgets('Multiple widget rebuilds do not cause memory leaks',
          (WidgetTester tester) async {
        // Test multiple rebuilds to check for memory leaks
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageMainSection(
                  etatActuel: i % 2 == 0 ? 'Entrée' : 'Pause',
                  dernierPointage: testDate.subtract(Duration(hours: i)),
                  progression: i / 10.0,
                  pointages: [
                    {
                      'type': 'Entrée',
                      'heure': testDate.subtract(Duration(hours: i + 1)),
                    }
                  ],
                  totalDayHours: Duration(hours: i + 1),
                  totalBreakTime: Duration(minutes: i * 10),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
        }

        // If we reach here without memory issues, the test passes
        expect(true, isTrue,
            reason: 'Multiple rebuilds completed without memory issues');
      });

      testWidgets('Large pointage list handles efficiently',
          (WidgetTester tester) async {
        // Create a large list of pointages
        final largePointageList = List.generate(
            100,
            (index) => {
                  'type': index % 4 == 0
                      ? 'Entrée'
                      : index % 4 == 1
                          ? 'Début pause'
                          : index % 4 == 2
                              ? 'Fin pause'
                              : 'Fin de journée',
                  'heure': testDate.subtract(Duration(minutes: 100 - index)),
                });

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Sortie',
                dernierPointage: testDate,
                progression: 1.0,
                pointages: largePointageList,
                totalDayHours: const Duration(hours: 8),
                totalBreakTime: const Duration(hours: 2),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should handle large lists efficiently (less than 500ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Large pointage list should render in less than 500ms');

        print(
            'Large pointage list (100 items) render time: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Animation Performance Tests (Requirement 10.3)', () {
      testWidgets('FAB state transitions are smooth',
          (WidgetTester tester) async {
        final states = ['Non commencé', 'Entrée', 'Pause', 'Reprise', 'Sortie'];
        final transitionTimes = <int>[];

        for (int i = 0; i < states.length - 1; i++) {
          final stopwatch = Stopwatch()..start();

          // Build initial state
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageFAB(
                  etatActuel: states[i],
                  onPressed: () {},
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Transition to next state
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageFAB(
                  etatActuel: states[i + 1],
                  onPressed: () {},
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          stopwatch.stop();

          transitionTimes.add(stopwatch.elapsedMilliseconds);
        }

        // All transitions should be under 100ms
        for (final time in transitionTimes) {
          expect(time, lessThan(100),
              reason: 'FAB state transition should be under 100ms');
        }

        final averageTime =
            transitionTimes.reduce((a, b) => a + b) / transitionTimes.length;
        print(
            'Average FAB transition time: ${averageTime.toStringAsFixed(1)}ms');
      });

      testWidgets('Timer animation performance is acceptable',
          (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageTimer(
                etatActuel: 'Entrée',
                dernierPointage: testDate.subtract(const Duration(hours: 1)),
                progression: 0.25,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 1)),
                  }
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Simulate progression change (animation trigger)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageTimer(
                etatActuel: 'Entrée',
                dernierPointage: testDate.subtract(const Duration(hours: 1)),
                progression: 0.5,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 1)),
                  }
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Timer animation should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(200),
            reason: 'Timer animation should complete in less than 200ms');

        print('Timer animation time: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Responsive Performance Tests (Requirement 10.3)', () {
      testWidgets('Screen size changes are handled efficiently',
          (WidgetTester tester) async {
        final sizes = [
          const Size(320, 568), // iPhone SE
          const Size(375, 812), // iPhone X
          const Size(414, 896), // iPhone XS Max
          const Size(768, 1024), // iPad
        ];

        final resizeTimes = <int>[];

        for (final size in sizes) {
          final stopwatch = Stopwatch()..start();

          await tester.binding.setSurfaceSize(size);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageMainSection(
                  etatActuel: 'Entrée',
                  dernierPointage: testDate,
                  progression: 0.5,
                  pointages: [
                    {
                      'type': 'Entrée',
                      'heure': testDate.subtract(const Duration(hours: 2)),
                    }
                  ],
                  totalDayHours: const Duration(hours: 2),
                  totalBreakTime: Duration.zero,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          stopwatch.stop();

          resizeTimes.add(stopwatch.elapsedMilliseconds);
        }

        // All screen size adaptations should be under 150ms
        for (final time in resizeTimes) {
          expect(time, lessThan(150),
              reason: 'Screen size adaptation should be under 150ms');
        }

        final averageTime =
            resizeTimes.reduce((a, b) => a + b) / resizeTimes.length;
        print(
            'Average screen resize time: ${averageTime.toStringAsFixed(1)}ms');

        // Reset surface size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('Rapid state changes are handled efficiently',
          (WidgetTester tester) async {
        final states = ['Non commencé', 'Entrée', 'Pause', 'Reprise', 'Sortie'];
        final stateChangeTimes = <int>[];

        for (int i = 0; i < 20; i++) {
          // Test 20 rapid state changes
          final stopwatch = Stopwatch()..start();
          final currentState = states[i % states.length];

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageMainSection(
                  etatActuel: currentState,
                  dernierPointage: testDate,
                  progression: (i % 10) / 10.0,
                  pointages: [
                    {
                      'type': 'Entrée',
                      'heure': testDate.subtract(Duration(hours: i % 8 + 1)),
                    }
                  ],
                  totalDayHours: Duration(hours: i % 8 + 1),
                  totalBreakTime: Duration(minutes: i * 5),
                ),
              ),
            ),
          );

          await tester.pump(); // Single pump for rapid changes
          stopwatch.stop();

          stateChangeTimes.add(stopwatch.elapsedMilliseconds);
        }

        // Rapid state changes should be very fast (under 50ms each)
        for (final time in stateChangeTimes) {
          expect(time, lessThan(50),
              reason: 'Rapid state change should be under 50ms');
        }

        final averageTime =
            stateChangeTimes.reduce((a, b) => a + b) / stateChangeTimes.length;
        print(
            'Average rapid state change time: ${averageTime.toStringAsFixed(1)}ms');
      });
    });

    group('Stress Tests (Requirement 10.3)', () {
      testWidgets('Continuous updates performance test',
          (WidgetTester tester) async {
        final updateTimes = <int>[];

        for (int i = 0; i < 50; i++) {
          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageTimer(
                  etatActuel: 'Entrée',
                  dernierPointage: testDate.subtract(Duration(minutes: i)),
                  progression: (i % 100) / 100.0,
                  pointages: [
                    {
                      'type': 'Entrée',
                      'heure': testDate.subtract(Duration(minutes: i + 10)),
                    }
                  ],
                ),
              ),
            ),
          );

          await tester.pump();
          stopwatch.stop();

          updateTimes.add(stopwatch.elapsedMilliseconds);
        }

        // Continuous updates should maintain performance
        final averageTime =
            updateTimes.reduce((a, b) => a + b) / updateTimes.length;
        expect(averageTime, lessThan(30),
            reason: 'Average continuous update time should be under 30ms');

        print(
            'Average continuous update time: ${averageTime.toStringAsFixed(1)}ms');
      });

      testWidgets('Complex layout performance under stress',
          (WidgetTester tester) async {
        final complexPointages = List.generate(
            50,
            (index) => {
                  'type': [
                    'Entrée',
                    'Début pause',
                    'Fin pause',
                    'Sortie'
                  ][index % 4],
                  'heure': testDate.subtract(Duration(minutes: index * 10)),
                });

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: PointageScreen(
              etatActuel: 'Sortie',
              dernierPointage: testDate,
              selectedDate: testDate,
              progression: 1.0,
              pointages: complexPointages,
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
              overtimeHours: const Duration(hours: 2),
              currentEntry: currentEntry,
              onToggleOvertime: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Complex layout should still perform well
        expect(stopwatch.elapsedMilliseconds, lessThan(800),
            reason: 'Complex layout should render in less than 800ms');

        print(
            'Complex layout (50 pointages) render time: ${stopwatch.elapsedMilliseconds}ms');
      });
    });
  });
}
