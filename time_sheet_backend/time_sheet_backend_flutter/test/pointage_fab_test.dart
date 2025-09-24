import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_fab.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_screen.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/vacation_days_info.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';

void main() {
  group('Pointage FAB Tests', () {
    testWidgets('PointageFAB shows correct icon and color for each state',
        (WidgetTester tester) async {
      bool buttonPressed = false;

      // Test Non commencé state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: PointageFAB(
              etatActuel: 'Non commencé',
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Commencer'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(buttonPressed, isTrue);

      buttonPressed = false;

      // Test Entrée state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: PointageFAB(
              etatActuel: 'Entrée',
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Pause'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(buttonPressed, isTrue);

      buttonPressed = false;

      // Test Pause state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: PointageFAB(
              etatActuel: 'Pause',
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Reprise'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(buttonPressed, isTrue);
    });

    testWidgets('PointageFAB hides when state is Sortie',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: PointageFAB(
              etatActuel: 'Sortie',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('PointageFAB shows loading indicator when isLoading is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: PointageFAB(
              etatActuel: 'Non commencé',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('PointageFABCompact shows only icon',
        (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: PointageFABCompact(
              etatActuel: 'Non commencé',
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Commencer'),
          findsNothing); // Pas de texte dans la version compacte

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(buttonPressed, isTrue);
    });

    testWidgets('PointageCompletionMessage displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageCompletionMessage(),
          ),
        ),
      );

      expect(find.text('Félicitations !'), findsOneWidget);
      expect(
          find.text('Votre journée de travail est terminée.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('FAB animations work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: PointageFAB(
              etatActuel: 'Non commencé',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Vérifier que le FAB apparaît avec animation
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Attendre que l'animation se termine
      await tester.pumpAndSettle();

      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('FAB color changes with state transitions',
        (WidgetTester tester) async {
      Widget buildFAB(String etat) {
        return MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: PointageFAB(
              etatActuel: etat,
              onPressed: () {},
            ),
          ),
        );
      }

      // Test transition from Non commencé to Entrée
      await tester.pumpWidget(buildFAB('Non commencé'));
      await tester.pumpAndSettle();

      expect(find.text('Commencer'), findsOneWidget);

      // Change state
      await tester.pumpWidget(buildFAB('Entrée'));
      await tester.pumpAndSettle();

      expect(find.text('Pause'), findsOneWidget);
    });
  });

  group('PointageScreen Tests', () {
    late VacationDaysInfo vacationInfo;
    late List<Map<String, dynamic>> pointages;
    late TimesheetEntry currentEntry;

    setUp(() {
      vacationInfo = VacationDaysInfo(
        currentYearTotal: 25,
        lastYearRemaining: 5,
        usedDays: 10,
        remainingTotal: 20,
      );

      pointages = [
        {
          'type': 'Entrée',
          'heure': '09:00',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        },
      ];

      final today = DateTime.now();
      final dateFormat = DateFormat('dd-MMM-yy');
      final dayFormat = DateFormat('EEEE');

      currentEntry = TimesheetEntry(
        id: 1,
        dayDate: dateFormat.format(today),
        dayOfWeekDate: dayFormat.format(today),
        startMorning: '',
        endMorning: '',
        startAfternoon: '',
        endAfternoon: '',
        hasOvertimeHours: false,
      );
    });

    testWidgets('PointageScreen integrates FAB correctly',
        (WidgetTester tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PointageScreen(
            etatActuel: 'Non commencé',
            dernierPointage: null,
            selectedDate: DateTime.now(),
            progression: 0.0,
            pointages: pointages,
            onActionPointage: () => actionPressed = true,
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
            weeklyWorkTime: const Duration(hours: 35),
            weeklyTarget: const Duration(hours: 40),
            vacationInfo: vacationInfo,
            overtimeHours: Duration.zero,
            currentEntry: currentEntry,
            onToggleOvertime: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que le FAB est présent
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);

      // Tester l'action du FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(actionPressed, isTrue);
    });

    testWidgets('PointageScreen shows completion message for Sortie state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PointageScreen(
            etatActuel: 'Sortie',
            dernierPointage: DateTime.now(),
            selectedDate: DateTime.now(),
            progression: 1.0,
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

      // Vérifier que le message de félicitations est affiché
      expect(find.text('Félicitations !'), findsOneWidget);
      expect(
          find.text('Votre journée de travail est terminée.'), findsOneWidget);

      // Vérifier que le FAB n'est pas affiché
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('PointageScreenCompact uses compact FAB',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PointageScreenCompact(
            etatActuel: 'Non commencé',
            dernierPointage: null,
            selectedDate: DateTime.now(),
            progression: 0.0,
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
            totalDayHours: Duration.zero,
            monthlyHoursStatus: 'OK',
            totalBreakTime: Duration.zero,
            weeklyWorkTime: const Duration(hours: 35),
            weeklyTarget: const Duration(hours: 40),
            vacationInfo: vacationInfo,
            overtimeHours: Duration.zero,
            currentEntry: currentEntry,
            onToggleOvertime: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que le FAB compact est présent (icône seulement)
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Commencer'),
          findsNothing); // Pas de texte dans la version compacte
    });
  });
}
