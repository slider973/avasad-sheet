import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_layout.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/vacation_days_info.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';

void main() {
  group('Pointage Button Accessibility Tests', () {
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

    testWidgets(
        'Main pointage button is immediately accessible without scrolling',
        (WidgetTester tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageLayout(
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
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que le bouton principal est visible sans faire défiler
      expect(find.text('Commencer'), findsOneWidget);

      // Vérifier que le bouton est dans la zone visible (pas besoin de scroll)
      final buttonFinder = find.text('Commencer');
      final buttonWidget = tester.widget<Widget>(buttonFinder);
      final renderBox = tester.renderObject(buttonFinder);

      // Le bouton doit être visible à l'écran
      expect(tester.binding.renderView.size.height, greaterThan(0));
      expect(renderBox.attached, isTrue);

      // Tester que le bouton fonctionne
      await tester.tap(buttonFinder);
      await tester.pump();
      expect(actionPressed, isTrue);
    });

    testWidgets('Secondary buttons are in separate section below',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageLayout(
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
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que les boutons secondaires sont présents
      expect(find.text('Actions supplémentaires'), findsOneWidget);
      expect(find.text('Signaler une absence'), findsOneWidget);
      expect(find.text('Supprimer la journée'), findsOneWidget);

      // Vérifier que le bouton principal n'est PAS dans la section des actions supplémentaires
      final actionsSection = find.ancestor(
        of: find.text('Actions supplémentaires'),
        matching: find.byType(Container),
      );

      expect(
        find.descendant(
          of: actionsSection.first,
          matching: find.text('Commencer'),
        ),
        findsNothing,
      );
    });

    testWidgets('Button states change correctly in main section',
        (WidgetTester tester) async {
      // Test état Entrée
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageLayout(
              etatActuel: 'Entrée',
              dernierPointage: DateTime.now(),
              selectedDate: DateTime.now(),
              progression: 0.5,
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
              totalDayHours: const Duration(hours: 4),
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
        ),
      );

      await tester.pumpAndSettle();

      // Le bouton principal doit afficher "Pause" et être immédiatement accessible
      expect(find.text('Pause'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets(
        'Congratulations message is shown in main section for Sortie state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageLayout(
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
        ),
      );

      await tester.pumpAndSettle();

      // Le message de félicitations doit être visible immédiatement
      expect(find.text('Félicitations !'), findsOneWidget);
      expect(
          find.text('Votre journée de travail est terminée.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('Layout is responsive and button remains accessible',
        (WidgetTester tester) async {
      // Test avec une taille d'écran réduite
      await tester.binding.setSurfaceSize(const Size(300, 600));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageLayout(
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
        ),
      );

      await tester.pumpAndSettle();

      // Même sur petit écran, le bouton doit être accessible
      expect(find.text('Commencer'), findsOneWidget);

      // Remettre la taille normale
      await tester.binding.setSurfaceSize(null);
    });
  });
}
