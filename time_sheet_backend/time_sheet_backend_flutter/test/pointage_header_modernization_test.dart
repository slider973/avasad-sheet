import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_header.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_design_system.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/weekend_badge.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  group('PointageHeader Modernization Tests', () {
    testWidgets('should display title with modern typography', (tester) async {
      final weekday = DateTime(2024, 1, 15); // Monday

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageHeader(selectedDate: weekday),
          ),
        ),
      );

      // Verify title is displayed with modern style
      final titleFinder = find.text('Heure de pointage');
      expect(titleFinder, findsOneWidget);

      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.fontSize,
          equals(PointageTextStyles.pageTitle.fontSize));
      expect(titleWidget.style?.fontWeight,
          equals(PointageTextStyles.pageTitle.fontWeight));
      expect(
          titleWidget.style?.color, equals(PointageTextStyles.pageTitle.color));
    });

    testWidgets('should display formatted date with modern typography',
        (tester) async {
      final testDate = DateTime(2024, 1, 15); // Monday, January 15, 2024

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageHeader(selectedDate: testDate),
          ),
        ),
      );

      // Verify date is displayed and capitalized
      expect(find.textContaining('Lundi 15 janvier 2024'), findsOneWidget);
    });

    testWidgets('should show weekend badge for weekend days', (tester) async {
      final weekend = DateTime(2024, 1, 13); // Saturday

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageHeader(selectedDate: weekend),
          ),
        ),
      );

      // Verify weekend badge is displayed
      expect(find.byType(WeekendBadge), findsOneWidget);
    });

    testWidgets('should show overtime indicator for weekend days',
        (tester) async {
      final weekend = DateTime(2024, 1, 13); // Saturday

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageHeader(selectedDate: weekend),
          ),
        ),
      );

      // Verify overtime indicator is displayed
      expect(find.text('Heures supplémentaires automatiques'), findsOneWidget);
    });

    testWidgets('should not show overtime indicator for weekdays',
        (tester) async {
      final weekday = DateTime(2024, 1, 15); // Monday

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageHeader(selectedDate: weekday),
          ),
        ),
      );

      // Verify overtime indicator is not displayed
      expect(find.text('Heures supplémentaires automatiques'), findsNothing);
    });

    testWidgets('should use design system spacing', (tester) async {
      final testDate = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageHeader(selectedDate: testDate),
          ),
        ),
      );

      // Verify container uses section padding
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      expect(container.padding, equals(PointageSpacing.sectionPadding));
    });

    testWidgets('should preserve weekend detection logic', (tester) async {
      // Test various days to ensure weekend detection works
      final testCases = [
        (DateTime(2024, 1, 13), true), // Saturday
        (DateTime(2024, 1, 14), true), // Sunday
        (DateTime(2024, 1, 15), false), // Monday
        (DateTime(2024, 1, 16), false), // Tuesday
        (DateTime(2024, 1, 17), false), // Wednesday
        (DateTime(2024, 1, 18), false), // Thursday
        (DateTime(2024, 1, 19), false), // Friday
      ];

      for (final (date, isWeekend) in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageHeader(selectedDate: date),
            ),
          ),
        );

        final weekendBadge =
            tester.widget<WeekendBadge>(find.byType(WeekendBadge));
        expect(weekendBadge.isWeekend, equals(isWeekend),
            reason: 'Failed for date: $date');

        if (isWeekend) {
          expect(
              find.text('Heures supplémentaires automatiques'), findsOneWidget,
              reason: 'Overtime indicator should be shown for weekend: $date');
        } else {
          expect(find.text('Heures supplémentaires automatiques'), findsNothing,
              reason:
                  'Overtime indicator should not be shown for weekday: $date');
        }
      }
    });

    testWidgets('should maintain visual hierarchy', (tester) async {
      final testDate = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageHeader(selectedDate: testDate),
          ),
        ),
      );

      // Verify title is larger than date
      final titleWidget = tester.widget<Text>(find.text('Heure de pointage'));
      final dateWidget =
          tester.widget<Text>(find.textContaining('Lundi 15 janvier 2024'));

      expect(titleWidget.style?.fontSize,
          greaterThan(dateWidget.style?.fontSize ?? 0));
    });

    testWidgets('should use design system colors for title', (tester) async {
      final testDate = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PointageHeader(selectedDate: testDate),
          ),
        ),
      );

      // Verify title uses primary color
      final titleWidget = tester.widget<Text>(find.text('Heure de pointage'));
      expect(titleWidget.style?.color, equals(PointageColors.primary));
    });
  });
}
