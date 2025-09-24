import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_layout.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/vacation_days_info.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';

void main() {
  group('Pointage Action Buttons Integration Tests', () {
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
        'All modernized action buttons are displayed correctly in PointageLayout',
        (WidgetTester tester) async {
      bool actionPressed = false;
      bool deletePressed = false;
      bool overtimeToggled = false;

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
              onDeleteEntry: () => deletePressed = true,
              totalDayHours: Duration.zero,
              monthlyHoursStatus: 'OK',
              totalBreakTime: Duration.zero,
              weeklyWorkTime: const Duration(hours: 35),
              weeklyTarget: const Duration(hours: 40),
              vacationInfo: vacationInfo,
              overtimeHours: Duration.zero,
              currentEntry: currentEntry,
              onToggleOvertime: () => overtimeToggled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all action buttons are present with modern styling
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);
      expect(find.text('Signaler une absence'), findsOneWidget);
      expect(find.text('Supprimer la journée'), findsOneWidget);

      // Verify icons are present
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Test main action button
      await tester.tap(find.text('Commencer'));
      await tester.pump();
      expect(actionPressed, isTrue);

      // Test delete button
      await tester.tap(find.text('Supprimer la journée'));
      await tester.pump();
      expect(deletePressed, isTrue);

      // Test absence button opens bottom sheet
      await tester.tap(find.text('Signaler une absence'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('Button states change correctly based on etatActuel',
        (WidgetTester tester) async {
      // Test Entrée state
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

      // Should show Pause button
      expect(find.text('Pause'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Test Pause state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageLayout(
              etatActuel: 'Pause',
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
              totalBreakTime: const Duration(minutes: 30),
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

      // Should show Reprise button
      expect(find.text('Reprise'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('Sortie state shows congratulations message',
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

      // Should show congratulations message instead of regular button
      expect(find.text('Félicitations !'), findsOneWidget);
      expect(
          find.text('Votre journée de travail est terminée.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      // Absence button should be hidden
      expect(find.text('Signaler une absence'), findsNothing);
    });

    testWidgets('Delete button is disabled when etatActuel is Non commencé',
        (WidgetTester tester) async {
      bool deletePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageLayout(
              etatActuel: 'Non commencé',
              dernierPointage: null,
              selectedDate: DateTime.now(),
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
              onDeleteEntry: () => deletePressed = true,
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

      // Button should be present but disabled
      expect(find.text('Supprimer la journée'), findsOneWidget);

      // Tap should not trigger callback when disabled
      await tester.tap(find.text('Supprimer la journée'));
      await tester.pump();
      expect(deletePressed, isFalse);
    });

    testWidgets('Action buttons section has proper styling and layout',
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

      // Verify section title is present
      expect(find.text('Actions'), findsOneWidget);

      // Verify all buttons are in a column layout with proper spacing
      final column = tester.widget<Column>(
        find
            .descendant(
              of: find.byType(Container),
              matching: find.byType(Column),
            )
            .last,
      );

      expect(column.crossAxisAlignment, CrossAxisAlignment.stretch);
      expect(
          column.children.length, greaterThan(3)); // Title + buttons + spacing
    });
  });
}
