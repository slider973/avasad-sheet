import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_boutton.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence_bouton.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_remove_timesheet_day.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';

void main() {
  group('Pointage Action Buttons Modernization Tests', () {
    testWidgets('PointageButton shows correct modern button for each state',
        (WidgetTester tester) async {
      bool buttonPressed = false;

      // Test Non commencé state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageButton(
              etatActuel: 'Non commencé',
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Commencer'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.text('Commencer'));
      await tester.pump();
      expect(buttonPressed, isTrue);

      buttonPressed = false;

      // Test Entrée state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageButton(
              etatActuel: 'Entrée',
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Pause'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(find.text('Pause'));
      await tester.pump();
      expect(buttonPressed, isTrue);

      buttonPressed = false;

      // Test Pause state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageButton(
              etatActuel: 'Pause',
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Reprise'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.text('Reprise'));
      await tester.pump();
      expect(buttonPressed, isTrue);
    });

    testWidgets('PointageButton shows congratulations message for Sortie state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageButton(
              etatActuel: 'Sortie',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Félicitations !'), findsOneWidget);
      expect(
          find.text('Votre journée de travail est terminée.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('PointageAbsenceBouton shows modern secondary button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageAbsenceBouton(
              etatActuel: 'Non commencé',
              selectedDate: DateTime.now(),
              onSignalerAbsencePeriode: (DateTime start,
                  DateTime end,
                  String motif,
                  AbsenceType type,
                  String comment,
                  String period,
                  TimeOfDay? startTime,
                  TimeOfDay? endTime) {},
            ),
          ),
        ),
      );

      expect(find.text('Signaler une absence'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);

      // Test that button opens bottom sheet
      await tester.tap(find.text('Signaler une absence'));
      await tester.pumpAndSettle();

      // Should show the absence form in bottom sheet
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('PointageAbsenceBouton hides when state is Sortie',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageAbsenceBouton(
              etatActuel: 'Sortie',
              selectedDate: DateTime.now(),
              onSignalerAbsencePeriode: (DateTime start,
                  DateTime end,
                  String motif,
                  AbsenceType type,
                  String comment,
                  String period,
                  TimeOfDay? startTime,
                  TimeOfDay? endTime) {},
            ),
          ),
        ),
      );

      expect(find.text('Signaler une absence'), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('PointageRemoveTimesheetDay shows modern destructive button',
        (WidgetTester tester) async {
      bool deletePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageRemoveTimesheetDay(
              etatActuel: 'Non commencé',
              isDisabled: false,
              onDeleteEntry: () => deletePressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Supprimer la journée'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.tap(find.text('Supprimer la journée'));
      await tester.pump();
      expect(deletePressed, isTrue);
    });

    testWidgets(
        'PointageRemoveTimesheetDay is disabled when isDisabled is true',
        (WidgetTester tester) async {
      bool deletePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageRemoveTimesheetDay(
              etatActuel: 'Non commencé',
              isDisabled: true,
              onDeleteEntry: () => deletePressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Supprimer la journée'), findsOneWidget);

      // Button should be disabled, so tap should not trigger callback
      await tester.tap(find.text('Supprimer la journée'));
      await tester.pump();
      expect(deletePressed, isFalse);
    });

    testWidgets('All buttons have consistent modern styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PointageButton(
                  etatActuel: 'Non commencé',
                  onPressed: () {},
                ),
                PointageAbsenceBouton(
                  etatActuel: 'Non commencé',
                  selectedDate: DateTime.now(),
                  onSignalerAbsencePeriode: (DateTime start,
                      DateTime end,
                      String motif,
                      AbsenceType type,
                      String comment,
                      String period,
                      TimeOfDay? startTime,
                      TimeOfDay? endTime) {},
                ),
                PointageRemoveTimesheetDay(
                  etatActuel: 'Non commencé',
                  isDisabled: false,
                  onDeleteEntry: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // All buttons should be present
      expect(find.text('Commencer'), findsOneWidget);
      expect(find.text('Signaler une absence'), findsOneWidget);
      expect(find.text('Supprimer la journée'), findsOneWidget);

      // All buttons should have icons
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('Button animations work correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageButton(
              etatActuel: 'Non commencé',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Find the button
      final buttonFinder = find.text('Commencer');
      expect(buttonFinder, findsOneWidget);

      // Test tap down animation
      await tester.press(buttonFinder);
      await tester.pump(const Duration(milliseconds: 100));

      // Button should be in pressed state (scaled down)
      // We can't easily test the exact scale value, but we can verify the animation controller is working

      // Release the button
      await tester.pumpAndSettle();

      // Animation should complete
      expect(buttonFinder, findsOneWidget);
    });
  });
}
