import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/features/pointage/presentation/widgets/pointage_widget/pointage_timer.dart';

void main() {
  group('PointageTimer Visual Improvements', () {
    testWidgets('should render PointageTimer with modern styling',
        (WidgetTester tester) async {
      // Arrange
      final pointages = <Map<String, dynamic>>[
        {
          'type': 'Entrée',
          'heure': DateTime.now().subtract(const Duration(hours: 2))
        },
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageTimer(
              etatActuel: 'Entrée',
              dernierPointage:
                  DateTime.now().subtract(const Duration(hours: 2)),
              progression: 0.5,
              pointages: pointages,
            ),
          ),
        ),
      );

      // Assert - Verify widget renders without errors
      expect(find.byType(PointageTimer), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
      expect(find.text('Entrée'), findsOneWidget);
    });

    testWidgets('should display PointageTimerContent',
        (WidgetTester tester) async {
      // Arrange
      final pointages = <Map<String, dynamic>>[
        {
          'type': 'Entrée',
          'heure': DateTime.now().subtract(const Duration(hours: 1))
        },
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageTimer(
              etatActuel: 'Entrée',
              dernierPointage:
                  DateTime.now().subtract(const Duration(hours: 1)),
              progression: 0.3,
              pointages: pointages,
            ),
          ),
        ),
      );

      // Assert - Verify PointageTimerContent is present
      expect(find.byType(PointageTimerContent), findsOneWidget);
      expect(find.text('Entrée'), findsOneWidget);
      expect(find.textContaining('Durée:'), findsOneWidget);
    });

    testWidgets('should preserve CustomPaint functionality',
        (WidgetTester tester) async {
      // Arrange
      final pointages = <Map<String, dynamic>>[
        {
          'type': 'Entrée',
          'heure': DateTime.now().subtract(const Duration(hours: 2))
        },
        {
          'type': 'Début pause',
          'heure': DateTime.now().subtract(const Duration(hours: 1))
        },
        {
          'type': 'Fin pause',
          'heure': DateTime.now().subtract(const Duration(minutes: 30))
        },
        {'type': 'Fin de journée', 'heure': DateTime.now()},
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageTimer(
              etatActuel: 'Sortie',
              dernierPointage: DateTime.now(),
              progression: 1.0,
              pointages: pointages,
            ),
          ),
        ),
      );

      // Assert - Verify CustomPaint is present (there might be multiple)
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(GestureDetector), findsOneWidget);
    });
  });

  group('PointageTimerContent', () {
    testWidgets('should display content with proper formatting',
        (WidgetTester tester) async {
      // Arrange
      final now = DateTime.now();
      const elapsedTime = Duration(hours: 2, minutes: 30, seconds: 45);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageTimerContent(
              etatActuel: 'Entrée',
              dernierPointage: now,
              elapsedTime: elapsedTime,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Entrée'), findsOneWidget);
      expect(find.textContaining('Durée: 02:30:45'), findsOneWidget);
    });

    testWidgets('should handle non-started state', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageTimerContent(
              etatActuel: 'Non commencé',
              dernierPointage: null,
              elapsedTime: Duration.zero,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Non commencé'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.textContaining('Durée:'), findsNothing);
    });

    testWidgets('should handle finished state', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageTimerContent(
              etatActuel: 'Sortie',
              dernierPointage: DateTime.now(),
              elapsedTime: const Duration(hours: 8),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Sortie'), findsOneWidget);
      expect(find.textContaining('Durée:'),
          findsNothing); // No duration for finished state
    });
  });
}
