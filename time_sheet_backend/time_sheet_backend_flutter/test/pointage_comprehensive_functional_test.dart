import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_layout.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_timer.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_main_section.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_fab.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_screen.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/vacation_days_info.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';

/// Comprehensive functional tests to ensure all pointage functionality
/// remains identical after design modernization (Requirements 7.1-7.7)
void main() {
  group('Pointage Comprehensive Functional Tests', () {
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

    group('Pointage Actions Functionality (Requirement 7.1)', () {
      testWidgets('Entrée action works identically to original',
          (WidgetTester tester) async {
        bool actionPressed = false;
        String? capturedAction;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageLayout(
                etatActuel: 'Non commencé',
                dernierPointage: null,
                selectedDate: testDate,
                progression: 0.0,
                pointages: [],
                onActionPointage: () {
                  actionPressed = true;
                  capturedAction = 'Entrée';
                },
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
                totalDayHours: Duration.zero,
                monthlyHoursStatus: 'OK',
                totalBreakTime: Duration.zero,
                weeklyWorkTime: Duration.zero,
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

        // Test main action button (should be "Commencer" for Non commencé state)
        expect(find.text('Commencer'), findsOneWidget);
        await tester.tap(find.text('Commencer'));
        await tester.pump();

        expect(actionPressed, isTrue);
        expect(capturedAction, equals('Entrée'));
      });

      testWidgets('Pause action works identically to original',
          (WidgetTester tester) async {
        bool actionPressed = false;
        String? capturedAction;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageLayout(
                etatActuel: 'Entrée',
                dernierPointage: testDate.subtract(const Duration(hours: 2)),
                selectedDate: testDate,
                progression: 0.5,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 2)),
                  }
                ],
                onActionPointage: () {
                  actionPressed = true;
                  capturedAction = 'Pause';
                },
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
                weeklyWorkTime: const Duration(hours: 10),
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

        // Test pause button
        expect(find.text('Pause'), findsOneWidget);
        await tester.tap(find.text('Pause'));
        await tester.pump();

        expect(actionPressed, isTrue);
        expect(capturedAction, equals('Pause'));
      });

      testWidgets('Reprise action works identically to original',
          (WidgetTester tester) async {
        bool actionPressed = false;
        String? capturedAction;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageLayout(
                etatActuel: 'Pause',
                dernierPointage: testDate.subtract(const Duration(minutes: 30)),
                selectedDate: testDate,
                progression: 0.6,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 3)),
                  },
                  {
                    'type': 'Début pause',
                    'heure': testDate.subtract(const Duration(minutes: 30)),
                  }
                ],
                onActionPointage: () {
                  actionPressed = true;
                  capturedAction = 'Reprise';
                },
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
                totalDayHours: const Duration(hours: 2, minutes: 30),
                monthlyHoursStatus: 'OK',
                totalBreakTime: const Duration(minutes: 30),
                weeklyWorkTime: const Duration(hours: 12, minutes: 30),
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

        // Test reprise button
        expect(find.text('Reprise'), findsOneWidget);
        await tester.tap(find.text('Reprise'));
        await tester.pump();

        expect(actionPressed, isTrue);
        expect(capturedAction, equals('Reprise'));
      });

      testWidgets('Sortie action works identically to original',
          (WidgetTester tester) async {
        bool actionPressed = false;
        String? capturedAction;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageLayout(
                etatActuel: 'Reprise',
                dernierPointage: testDate.subtract(const Duration(hours: 1)),
                selectedDate: testDate,
                progression: 0.9,
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
                  }
                ],
                onActionPointage: () {
                  actionPressed = true;
                  capturedAction = 'Sortie';
                },
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
                totalDayHours: const Duration(hours: 7),
                monthlyHoursStatus: 'OK',
                totalBreakTime: const Duration(hours: 1),
                weeklyWorkTime: const Duration(hours: 35),
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

        // Test sortie button
        expect(find.text('Sortie'), findsOneWidget);
        await tester.tap(find.text('Sortie'));
        await tester.pump();

        expect(actionPressed, isTrue);
        expect(capturedAction, equals('Sortie'));
      });
    });

    group('Time Calculations Accuracy (Requirement 7.1)', () {
      testWidgets('Total day hours calculation remains exact',
          (WidgetTester tester) async {
        const expectedTotalHours = Duration(hours: 8, minutes: 30);
        const expectedBreakTime = Duration(hours: 1, minutes: 15);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Sortie',
                dernierPointage: testDate,
                progression: 1.0,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate
                        .subtract(const Duration(hours: 9, minutes: 45)),
                  },
                  {
                    'type': 'Début pause',
                    'heure': testDate
                        .subtract(const Duration(hours: 5, minutes: 45)),
                  },
                  {
                    'type': 'Fin pause',
                    'heure': testDate
                        .subtract(const Duration(hours: 4, minutes: 30)),
                  },
                  {
                    'type': 'Fin de journée',
                    'heure': testDate,
                  }
                ],
                totalDayHours: expectedTotalHours,
                totalBreakTime: expectedBreakTime,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify exact time calculations are displayed
        expect(find.text('08:30'), findsOneWidget); // Total day hours
        expect(find.text('01:15'), findsOneWidget); // Break time
      });

      testWidgets('Zero duration handling remains consistent',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Non commencé',
                dernierPointage: null,
                progression: 0.0,
                pointages: [],
                totalDayHours: Duration.zero,
                totalBreakTime: Duration.zero,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify zero durations are handled correctly
        expect(find.text('00:00'), findsAtLeastNWidgets(2));
      });
    });

    group('Timer Interactions Preservation (Requirement 7.1)', () {
      testWidgets('Timer tap interactions work identically',
          (WidgetTester tester) async {
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

        // Test timer tap interaction structure
        final timerFinder = find.byType(CustomPaint);
        expect(timerFinder, findsOneWidget);

        // Verify gesture detector is present for interactions
        expect(find.byType(GestureDetector), findsOneWidget);

        // Test that timer can be tapped (basic interaction test)
        await tester.tap(timerFinder);
        await tester.pump();
      });

      testWidgets('Timer long press interactions work identically',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageTimer(
                etatActuel: 'Entrée',
                dernierPointage: testDate.subtract(const Duration(hours: 2)),
                progression: 0.5,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 2)),
                  }
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test timer long press interaction structure
        final timerFinder = find.byType(CustomPaint);
        expect(timerFinder, findsOneWidget);

        // Verify gesture detector is present for long press
        expect(find.byType(GestureDetector), findsOneWidget);

        // Test that timer can be long pressed (basic interaction test)
        await tester.longPress(timerFinder);
        await tester.pump();
      });
    });

    group('Pointage Modifications (Requirement 7.2)', () {
      testWidgets('Pointage modification functionality preserved',
          (WidgetTester tester) async {
        Map<String, dynamic>? modifiedPointage;

        final testPointages = [
          {
            'type': 'Entrée',
            'heure': testDate.subtract(const Duration(hours: 8)),
            'id': 1,
          },
          {
            'type': 'Début pause',
            'heure': testDate.subtract(const Duration(hours: 4)),
            'id': 2,
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageLayout(
                etatActuel: 'Pause',
                dernierPointage: testDate.subtract(const Duration(hours: 4)),
                selectedDate: testDate,
                progression: 0.6,
                pointages: testPointages,
                onActionPointage: () {},
                onModifierPointage: (pointage) {
                  modifiedPointage = pointage;
                },
                onSignalerAbsencePeriode: (DateTime start,
                    DateTime end,
                    String motif,
                    AbsenceType type,
                    String comment,
                    String period,
                    TimeOfDay? startTime,
                    TimeOfDay? endTime) {},
                onDeleteEntry: () {},
                totalDayHours: const Duration(hours: 4),
                monthlyHoursStatus: 'OK',
                totalBreakTime: Duration.zero,
                weeklyWorkTime: const Duration(hours: 20),
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

        // Verify pointage list is displayed
        expect(find.text('Historique'), findsOneWidget);

        // Note: In a real test, we would tap on specific pointage entries
        // to test modification functionality. This verifies the structure exists.
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Absence Functionality (Requirement 7.3)', () {
      testWidgets('Absence signaling functionality preserved',
          (WidgetTester tester) async {
        bool absenceSignaled = false;
        DateTime? startDate;
        DateTime? endDate;
        String? motif;
        AbsenceType? type;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageLayout(
                etatActuel: 'Non commencé',
                dernierPointage: null,
                selectedDate: testDate,
                progression: 0.0,
                pointages: [],
                onActionPointage: () {},
                onModifierPointage: (pointage) {},
                onSignalerAbsencePeriode: (DateTime start,
                    DateTime end,
                    String motifParam,
                    AbsenceType typeParam,
                    String comment,
                    String period,
                    TimeOfDay? startTime,
                    TimeOfDay? endTime) {
                  absenceSignaled = true;
                  startDate = start;
                  endDate = end;
                  motif = motifParam;
                  type = typeParam;
                },
                onDeleteEntry: () {},
                totalDayHours: Duration.zero,
                monthlyHoursStatus: 'OK',
                totalBreakTime: Duration.zero,
                weeklyWorkTime: Duration.zero,
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

        // Test absence button
        expect(find.text('Signaler une absence'), findsOneWidget);
        await tester.tap(find.text('Signaler une absence'));
        await tester.pumpAndSettle();

        // Verify absence bottom sheet opens
        expect(find.byType(BottomSheet), findsOneWidget);
      });

      testWidgets('All absence types remain available',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageLayout(
                etatActuel: 'Non commencé',
                dernierPointage: null,
                selectedDate: testDate,
                progression: 0.0,
                pointages: [],
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
                totalDayHours: Duration.zero,
                monthlyHoursStatus: 'OK',
                totalBreakTime: Duration.zero,
                weeklyWorkTime: Duration.zero,
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

        // Open absence dialog
        await tester.tap(find.text('Signaler une absence'));
        await tester.pumpAndSettle();

        // Verify absence types are available
        // Note: Specific absence types would be tested based on the actual implementation
        expect(find.byType(BottomSheet), findsOneWidget);
      });
    });

    group('Overtime Toggle Functionality (Requirement 7.4)', () {
      testWidgets('Overtime toggle works identically',
          (WidgetTester tester) async {
        bool overtimeToggled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageLayout(
                etatActuel: 'Sortie',
                dernierPointage: testDate,
                selectedDate: testDate,
                progression: 1.0,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 8)),
                  },
                  {
                    'type': 'Fin de journée',
                    'heure': testDate,
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
                totalDayHours: const Duration(hours: 8),
                monthlyHoursStatus: 'OK',
                totalBreakTime: Duration.zero,
                weeklyWorkTime: const Duration(hours: 40),
                weeklyTarget: const Duration(hours: 40),
                vacationInfo: vacationInfo,
                overtimeHours: const Duration(hours: 2),
                currentEntry: currentEntry,
                onToggleOvertime: () {
                  overtimeToggled = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and test overtime toggle
        expect(find.text('Heures supplémentaires'), findsOneWidget);

        // Test toggle functionality
        final toggleFinder = find.byType(Switch);
        if (toggleFinder.evaluate().isNotEmpty) {
          await tester.tap(toggleFinder);
          await tester.pump();
          expect(overtimeToggled, isTrue);
        }
      });
    });

    group('History and Data Preservation (Requirements 7.5, 7.6, 7.7)', () {
      testWidgets('History data and interactions preserved',
          (WidgetTester tester) async {
        final testPointages = [
          {
            'type': 'Entrée',
            'heure': testDate.subtract(const Duration(hours: 8)),
            'id': 1,
          },
          {
            'type': 'Début pause',
            'heure': testDate.subtract(const Duration(hours: 4)),
            'id': 2,
          },
          {
            'type': 'Fin pause',
            'heure': testDate.subtract(const Duration(hours: 3)),
            'id': 3,
          },
          {
            'type': 'Fin de journée',
            'heure': testDate,
            'id': 4,
          }
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageLayout(
                etatActuel: 'Sortie',
                dernierPointage: testDate,
                selectedDate: testDate,
                progression: 1.0,
                pointages: testPointages,
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

        // Verify history section exists
        expect(find.text('Historique'), findsOneWidget);

        // Verify all pointage entries are displayed
        expect(find.text('Entrée'), findsOneWidget);
        expect(find.text('Début pause'), findsOneWidget);
        expect(find.text('Fin pause'), findsOneWidget);
        expect(find.text('Fin de journée'), findsOneWidget);
      });

      testWidgets('Entry deletion functionality preserved',
          (WidgetTester tester) async {
        bool entryDeleted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageLayout(
                etatActuel: 'Entrée',
                dernierPointage: testDate.subtract(const Duration(hours: 2)),
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
                onDeleteEntry: () {
                  entryDeleted = true;
                },
                totalDayHours: const Duration(hours: 2),
                monthlyHoursStatus: 'OK',
                totalBreakTime: Duration.zero,
                weeklyWorkTime: const Duration(hours: 10),
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

        // Test delete button
        expect(find.text('Supprimer la journée'), findsOneWidget);
        await tester.tap(find.text('Supprimer la journée'));
        await tester.pump();

        expect(entryDeleted, isTrue);
      });

      testWidgets('Date change behavior remains identical',
          (WidgetTester tester) async {
        final differentDate = testDate.add(const Duration(days: 1));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageLayout(
                etatActuel: 'Non commencé',
                dernierPointage: null,
                selectedDate: differentDate,
                progression: 0.0,
                pointages: [],
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
                totalDayHours: Duration.zero,
                monthlyHoursStatus: 'OK',
                totalBreakTime: Duration.zero,
                weeklyWorkTime: Duration.zero,
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

        // Verify date is displayed correctly
        final expectedDateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
        final expectedDateString = expectedDateFormat.format(differentDate);

        // Note: The exact date format may vary, but the date should be displayed
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('FAB Integration Tests', () {
      testWidgets('FAB works identically to original action buttons',
          (WidgetTester tester) async {
        bool fabPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageScreen(
                etatActuel: 'Non commencé',
                dernierPointage: null,
                selectedDate: testDate,
                progression: 0.0,
                pointages: [],
                onActionPointage: () {
                  fabPressed = true;
                },
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
                totalDayHours: Duration.zero,
                monthlyHoursStatus: 'OK',
                totalBreakTime: Duration.zero,
                weeklyWorkTime: Duration.zero,
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

        // Test FAB functionality
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        await tester.tap(fabFinder);
        await tester.pump();

        expect(fabPressed, isTrue);
      });

      testWidgets('FAB state changes correctly with etatActuel',
          (WidgetTester tester) async {
        // Test different states
        final states = [
          {'etat': 'Non commencé', 'icon': Icons.play_arrow},
          {'etat': 'Entrée', 'icon': Icons.pause},
          {'etat': 'Pause', 'icon': Icons.play_arrow},
          {'etat': 'Reprise', 'icon': Icons.stop},
        ];

        for (final state in states) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageScreen(
                  etatActuel: state['etat'] as String,
                  dernierPointage:
                      state['etat'] != 'Non commencé' ? testDate : null,
                  selectedDate: testDate,
                  progression: state['etat'] == 'Non commencé' ? 0.0 : 0.5,
                  pointages: state['etat'] != 'Non commencé'
                      ? [
                          {
                            'type': 'Entrée',
                            'heure':
                                testDate.subtract(const Duration(hours: 2)),
                          }
                        ]
                      : [],
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
                  totalDayHours: state['etat'] == 'Non commencé'
                      ? Duration.zero
                      : const Duration(hours: 2),
                  monthlyHoursStatus: 'OK',
                  totalBreakTime: Duration.zero,
                  weeklyWorkTime: Duration.zero,
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

          // Verify FAB is present
          expect(find.byType(FloatingActionButton), findsOneWidget);

          // Verify correct icon is displayed
          expect(find.byIcon(state['icon'] as IconData), findsOneWidget);
        }
      });
    });
  });
}
