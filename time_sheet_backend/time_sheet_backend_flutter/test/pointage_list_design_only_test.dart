import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_list.dart';

void main() {
  group('PointageList Design Modernization Tests', () {
    testWidgets('should preserve exact same interface and functionality',
        (WidgetTester tester) async {
      final pointages = [
        {
          'type': 'Entrée',
          'heure': DateTime(2024, 1, 15, 8, 30),
        },
      ];

      bool modifierCalled = false;
      Map<String, dynamic>? modifiedPointage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageList(
              pointages: pointages,
              onModifier: (pointage) {
                modifierCalled = true;
                modifiedPointage = pointage;
              },
            ),
          ),
        ),
      );

      // Vérifier que le widget se construit sans erreur
      expect(find.byType(PointageList), findsOneWidget);

      // Vérifier que l'interface publique est exactement la même
      final widget = tester.widget<PointageList>(find.byType(PointageList));
      expect(widget.pointages, equals(pointages));
      expect(widget.onModifier, isA<Function>());

      // Vérifier que l'en-tête moderne est présent
      expect(find.text('Historique du jour'), findsOneWidget);

      // Vérifier que le pointage est affiché
      expect(find.text('Entrée'), findsOneWidget);
      expect(find.text('08:30'), findsOneWidget);

      // Vérifier que le badge de comptage est présent
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should handle empty state gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageList(
              pointages: [],
              onModifier: (pointage) {},
            ),
          ),
        ),
      );

      // Vérifier l'état vide moderne
      expect(find.text('Aucun pointage aujourd\'hui'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);

      // Vérifier qu'aucun badge de comptage n'est affiché pour l'état vide
      expect(find.text('0'), findsNothing);
    });

    testWidgets('should preserve constructor parameters exactly',
        (WidgetTester tester) async {
      final pointages = [
        {'type': 'Test', 'heure': DateTime.now()},
      ];

      void onModifier(Map<String, dynamic> pointage) {}

      // Vérifier que le constructeur accepte exactement les mêmes paramètres
      final widget = PointageList(
        pointages: pointages,
        onModifier: onModifier,
      );

      expect(widget.pointages, equals(pointages));
      expect(widget.onModifier, equals(onModifier));
    });

    testWidgets('should call onModifier when card is tapped',
        (WidgetTester tester) async {
      final pointages = [
        {
          'type': 'Entrée',
          'heure': DateTime(2024, 1, 15, 8, 30),
        },
      ];

      bool modifierCalled = false;
      Map<String, dynamic>? modifiedPointage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageList(
              pointages: pointages,
              onModifier: (pointage) {
                modifierCalled = true;
                modifiedPointage = pointage;
              },
            ),
          ),
        ),
      );

      // Attendre que les animations se terminent
      await tester.pumpAndSettle();

      // Taper sur la carte
      await tester.tap(find.text('Entrée'));
      await tester.pump();

      // Vérifier que la fonction de modification a été appelée avec les bonnes données
      expect(modifierCalled, isTrue);
      expect(modifiedPointage, isNotNull);
      expect(modifiedPointage!['type'], equals('Entrée'));
      expect(modifiedPointage!['heure'], equals(DateTime(2024, 1, 15, 8, 30)));
    });

    testWidgets('should display multiple pointages correctly',
        (WidgetTester tester) async {
      final pointages = [
        {
          'type': 'Entrée',
          'heure': DateTime(2024, 1, 15, 8, 30),
        },
        {
          'type': 'Pause',
          'heure': DateTime(2024, 1, 15, 12, 0),
        },
        {
          'type': 'Reprise',
          'heure': DateTime(2024, 1, 15, 13, 0),
        },
        {
          'type': 'Sortie',
          'heure': DateTime(2024, 1, 15, 17, 30),
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageList(
              pointages: pointages,
              onModifier: (pointage) {},
            ),
          ),
        ),
      );

      // Vérifier que tous les pointages sont affichés
      expect(find.text('Entrée'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Reprise'), findsOneWidget);
      expect(find.text('Sortie'), findsOneWidget);

      // Vérifier le compteur
      expect(find.text('4'), findsOneWidget);

      // Vérifier les heures
      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
      expect(find.text('13:00'), findsOneWidget);
      expect(find.text('17:30'), findsOneWidget);
    });
  });
}
