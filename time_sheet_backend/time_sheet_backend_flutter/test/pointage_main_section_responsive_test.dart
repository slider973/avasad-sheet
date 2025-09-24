import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_main_section.dart';

void main() {
  group('PointageMainSection Responsive Tests', () {
    testWidgets('should adapt to different screen sizes correctly',
        (WidgetTester tester) async {
      // Arrange
      const totalDayHours = Duration(hours: 6, minutes: 30);
      const totalBreakTime = Duration(minutes: 30);
      const etatActuel = 'En cours';
      final dernierPointage = DateTime.now();
      const progression = 0.6;
      final pointages = <Map<String, dynamic>>[];

      // Test different screen sizes
      final screenSizes = [
        const Size(300, 600), // Very compact
        const Size(350, 600), // Compact
        const Size(500, 800), // Standard
        const Size(800, 600), // Wide
      ];

      for (final size in screenSizes) {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
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

        // Assert - Should render without overflow errors
        expect(tester.takeException(), isNull);

        // Should find time information
        expect(find.text('06:30'), findsOneWidget);
        expect(find.text('00:30'), findsOneWidget);
        expect(find.text(etatActuel), findsOneWidget);
      }
    });

    testWidgets('should handle orientation changes gracefully',
        (WidgetTester tester) async {
      // Arrange
      const totalDayHours = Duration(hours: 8, minutes: 15);
      const totalBreakTime = Duration(hours: 1, minutes: 15);
      const etatActuel = 'Pause';
      final dernierPointage = DateTime.now();
      const progression = 0.8;
      final pointages = <Map<String, dynamic>>[];

      // Portrait orientation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
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

      // Assert - Portrait should work
      expect(tester.takeException(), isNull);
      expect(find.text('08:15'), findsOneWidget);
      expect(find.text('01:15'), findsOneWidget);

      // Landscape orientation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
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

      // Assert - Landscape should also work
      expect(tester.takeException(), isNull);
      expect(find.text('08:15'), findsOneWidget);
      expect(find.text('01:15'), findsOneWidget);
    });

    testWidgets('should preserve all data during layout changes',
        (WidgetTester tester) async {
      // Arrange
      const totalDayHours = Duration(hours: 7, minutes: 45);
      const totalBreakTime = Duration(minutes: 45);
      const etatActuel = 'Reprise';
      final dernierPointage = DateTime.now();
      const progression = 0.9;
      final pointages = [
        {
          'type': 'Entrée',
          'heure': DateTime.now().subtract(const Duration(hours: 7))
        },
        {
          'type': 'Début pause',
          'heure': DateTime.now().subtract(const Duration(hours: 4))
        },
        {
          'type': 'Fin pause',
          'heure': DateTime.now().subtract(const Duration(hours: 3))
        },
      ];

      // Test with different layouts
      final layouts = [
        {'width': 300.0, 'height': 600.0, 'name': 'Vertical'},
        {'width': 350.0, 'height': 600.0, 'name': 'Compact'},
        {'width': 500.0, 'height': 800.0, 'name': 'Standard'},
      ];

      for (final layout in layouts) {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: layout['width'] as double,
                height: layout['height'] as double,
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

        // Assert - All data should be preserved regardless of layout
        expect(tester.takeException(), isNull,
            reason: 'Layout ${layout['name']} should not cause exceptions');

        // Time data should be preserved
        expect(find.text('07:45'), findsOneWidget,
            reason:
                'Total day hours should be preserved in ${layout['name']} layout');
        expect(find.text('00:45'), findsOneWidget,
            reason:
                'Break time should be preserved in ${layout['name']} layout');
        expect(find.text(etatActuel), findsOneWidget,
            reason:
                'Current state should be preserved in ${layout['name']} layout');
      }
    });
  });
}
