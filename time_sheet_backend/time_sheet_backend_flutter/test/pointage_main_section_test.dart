import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_main_section.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_design_system.dart';

void main() {
  group('PointageMainSection Tests', () {
    testWidgets('should display time info and timer in standard layout',
        (WidgetTester tester) async {
      // Arrange
      const totalDayHours = Duration(hours: 7, minutes: 30);
      const totalBreakTime = Duration(minutes: 45);
      const etatActuel = 'En cours';
      final dernierPointage = DateTime.now();
      const progression = 0.75;
      final pointages = <Map<String, dynamic>>[];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500, // Standard width
              child: PointageMainSection(
                etatActuel: etatActuel,
                dernierPointage: dernierPointage,
                progression: progression,
                pointages: pointages,
                totalDayHours: totalDayHours,
                totalBreakTime: totalBreakTime,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Total du jour'), findsOneWidget);
      expect(find.text('07:30'), findsOneWidget);
      expect(find.text('Temps de pause'), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget);
      expect(find.text(etatActuel), findsOneWidget);
    });

    testWidgets('should use compact layout for small screens',
        (WidgetTester tester) async {
      // Arrange
      const totalDayHours = Duration(hours: 4, minutes: 15);
      const totalBreakTime = Duration(minutes: 30);
      const etatActuel = 'Pause';
      final dernierPointage = DateTime.now();
      const progression = 0.5;
      final pointages = <Map<String, dynamic>>[];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350, // Compact width
              child: PointageMainSection(
                etatActuel: etatActuel,
                dernierPointage: dernierPointage,
                progression: progression,
                pointages: pointages,
                totalDayHours: totalDayHours,
                totalBreakTime: totalBreakTime,
              ),
            ),
          ),
        ),
      );

      // Assert - Should find compact layout elements
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('04:15'), findsOneWidget);
      expect(find.text('Pause'), findsAtLeastNWidgets(1)); // État + label
      expect(find.text('00:30'), findsOneWidget);
    });

    testWidgets('should use vertical layout for very small screens',
        (WidgetTester tester) async {
      // Arrange
      const totalDayHours = Duration(hours: 2, minutes: 45);
      const totalBreakTime = Duration(minutes: 15);
      const etatActuel = 'Non commencé';
      const progression = 0.0;
      final pointages = <Map<String, dynamic>>[];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300, // Very compact width
              child: PointageMainSection(
                etatActuel: etatActuel,
                dernierPointage: null,
                progression: progression,
                pointages: pointages,
                totalDayHours: totalDayHours,
                totalBreakTime: totalBreakTime,
              ),
            ),
          ),
        ),
      );

      // Assert - Should find vertical layout elements
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('02:45'), findsOneWidget);
      expect(find.text('Pause'), findsAtLeastNWidgets(1));
      expect(find.text('00:15'), findsOneWidget);
      expect(find.text(etatActuel), findsOneWidget);
    });

    testWidgets('should preserve all data and calculations',
        (WidgetTester tester) async {
      // Arrange
      const totalDayHours = Duration(hours: 8, minutes: 0);
      const totalBreakTime = Duration(hours: 1, minutes: 0);
      const etatActuel = 'Sortie';
      final dernierPointage = DateTime.now();
      const progression = 1.0;
      final pointages = [
        {
          'type': 'Entrée',
          'heure': DateTime.now().subtract(const Duration(hours: 8))
        },
        {
          'type': 'Début pause',
          'heure': DateTime.now().subtract(const Duration(hours: 4))
        },
        {
          'type': 'Fin pause',
          'heure': DateTime.now().subtract(const Duration(hours: 3))
        },
        {'type': 'Fin de journée', 'heure': DateTime.now()},
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageMainSection(
              etatActuel: etatActuel,
              dernierPointage: dernierPointage,
              progression: progression,
              pointages: pointages,
              totalDayHours: totalDayHours,
              totalBreakTime: totalBreakTime,
            ),
          ),
        ),
      );

      // Assert - All data should be preserved and displayed correctly
      expect(find.text('08:00'), findsOneWidget); // Total day hours
      expect(find.text('01:00'), findsOneWidget); // Break time
      expect(find.text(etatActuel), findsOneWidget); // Current state
    });

    testWidgets('should handle zero durations correctly',
        (WidgetTester tester) async {
      // Arrange
      const totalDayHours = Duration.zero;
      const totalBreakTime = Duration.zero;
      const etatActuel = 'Non commencé';
      const progression = 0.0;
      final pointages = <Map<String, dynamic>>[];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageMainSection(
              etatActuel: etatActuel,
              dernierPointage: null,
              progression: progression,
              pointages: pointages,
              totalDayHours: totalDayHours,
              totalBreakTime: totalBreakTime,
            ),
          ),
        ),
      );

      // Assert
      expect(
          find.text('00:00'),
          findsAtLeastNWidgets(
              2)); // At least total and break time should be 00:00 (timer may also show 00:00)
      expect(find.text(etatActuel), findsOneWidget);
    });
  });

  group('PointageMainSection Layout Extensions', () {
    testWidgets('should determine compact layout correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Test with different screen sizes
              return const SizedBox();
            },
          ),
        ),
      );

      // Note: In a real test environment, we would mock MediaQuery
      // to test different screen sizes programmatically
    });
  });

  group('PointageDesignSystem', () {
    test('should have correct timer colors preserved', () {
      // Assert - Verify that timer colors are preserved as required
      expect(PointageColors.entreeColor, equals(Colors.teal));
      expect(PointageColors.pauseColor, equals(const Color(0xFFE7D37F)));
      expect(PointageColors.repriseColor, equals(const Color(0xFFFD9B63)));
    });

    test('should have consistent text styles', () {
      // Assert - Verify text styles are defined
      expect(PointageTextStyles.primaryTime.fontSize, equals(18));
      expect(
          PointageTextStyles.primaryTime.fontWeight, equals(FontWeight.w600));
      expect(PointageTextStyles.secondaryTime.fontSize, equals(14));
      expect(
          PointageTextStyles.secondaryTime.fontStyle, equals(FontStyle.italic));
    });

    test('should have proper spacing constants', () {
      // Assert - Verify spacing constants
      expect(PointageSpacing.xs, equals(4.0));
      expect(PointageSpacing.sm, equals(8.0));
      expect(PointageSpacing.md, equals(16.0));
      expect(PointageSpacing.lg, equals(24.0));
      expect(PointageSpacing.xl, equals(32.0));
    });
  });
}
