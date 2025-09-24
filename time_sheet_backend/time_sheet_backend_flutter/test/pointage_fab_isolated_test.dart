import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_fab.dart';

void main() {
  group('Pointage FAB Isolated Tests', () {
    testWidgets('PointageFAB shows correct text and icon for Non commencé',
        (WidgetTester tester) async {
      bool buttonPressed = false;

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

      await tester.pumpAndSettle();

      expect(find.text('Commencer'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(buttonPressed, isTrue);
    });

    testWidgets('PointageFAB shows correct text and icon for Entrée',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: PointageFAB(
              etatActuel: 'Entrée',
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pause'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('PointageFAB shows correct text and icon for Pause',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: PointageFAB(
              etatActuel: 'Pause',
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reprise'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
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

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('PointageFABCompact shows only icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: PointageFABCompact(
              etatActuel: 'Non commencé',
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Commencer'),
          findsNothing); // Pas de texte dans la version compacte
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

      await tester.pumpAndSettle();

      expect(find.text('Félicitations !'), findsOneWidget);
      expect(
          find.text('Votre journée de travail est terminée.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
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

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);
    });
  });
}
