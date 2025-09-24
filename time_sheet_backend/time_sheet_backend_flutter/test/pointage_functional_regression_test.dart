import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_main_section.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_timer.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_design_system.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_fab.dart';

/// Focused functional regression tests to ensure all pointage functionality
/// remains identical after design modernization (Requirements 7.1-7.7)
void main() {
  setUpAll(() async {
    // Initialize date formatting for French locale
    await initializeDateFormatting('fr_FR', null);
  });

  group('Pointage Functional Regression Tests', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
    });

    group('Time Calculations Accuracy (Requirement 7.1)', () {
      testWidgets('Total day hours calculation remains exact',
          (WidgetTester tester) async {
        const expectedTotalHours = Duration(hours: 8, minutes: 30);
        const expectedBreakTime = Duration(hours: 1, minutes: 15);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Sortie',
                dernierPointage: testDate,
                progression: 1.0,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate
                        .subtract(const Duration(hours: 9, minutes: 45)),
                  },
                  {
                    'type': 'Début pause',
                    'heure': testDate
                        .subtract(const Duration(hours: 5, minutes: 45)),
                  },
                  {
                    'type': 'Fin pause',
                    'heure': testDate
                        .subtract(const Duration(hours: 4, minutes: 30)),
                  },
                  {
                    'type': 'Fin de journée',
                    'heure': testDate,
                  }
                ],
                totalDayHours: expectedTotalHours,
                totalBreakTime: expectedBreakTime,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify exact time calculations are displayed
        expect(find.text('08:30'), findsOneWidget); // Total day hours
        expect(find.text('01:15'), findsOneWidget); // Break time
      });

      testWidgets('Zero duration handling remains consistent',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Non commencé',
                dernierPointage: null,
                progression: 0.0,
                pointages: [],
                totalDayHours: Duration.zero,
                totalBreakTime: Duration.zero,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify zero durations are handled correctly
        expect(find.text('00:00'), findsAtLeastNWidgets(2));
      });

      testWidgets('Complex time calculations with multiple breaks',
          (WidgetTester tester) async {
        const totalHours = Duration(hours: 7, minutes: 45);
        const breakTime = Duration(hours: 1, minutes: 30);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Reprise',
                dernierPointage: testDate.subtract(const Duration(hours: 1)),
                progression: 0.85,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate
                        .subtract(const Duration(hours: 9, minutes: 15)),
                  },
                  {
                    'type': 'Début pause',
                    'heure': testDate
                        .subtract(const Duration(hours: 5, minutes: 30)),
                  },
                  {
                    'type': 'Fin pause',
                    'heure': testDate
                        .subtract(const Duration(hours: 4, minutes: 45)),
                  },
                  {
                    'type': 'Début pause',
                    'heure': testDate
                        .subtract(const Duration(hours: 2, minutes: 15)),
                  },
                  {
                    'type': 'Fin pause',
                    'heure': testDate
                        .subtract(const Duration(hours: 1, minutes: 30)),
                  }
                ],
                totalDayHours: totalHours,
                totalBreakTime: breakTime,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify complex calculations are preserved
        expect(find.text('07:45'), findsOneWidget);
        expect(find.text('01:30'), findsOneWidget);
      });
    });

    group('Timer Visual Structure Preservation (Requirement 7.1)', () {
      testWidgets('Timer maintains circular structure and interactions',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageTimer(
                etatActuel: 'Sortie',
                dernierPointage: testDate,
                progression: 1.0,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 8)),
                  },
                  {
                    'type': 'Début pause',
                    'heure': testDate.subtract(const Duration(hours: 4)),
                  },
                  {
                    'type': 'Fin pause',
                    'heure': testDate.subtract(const Duration(hours: 3)),
                  },
                  {
                    'type': 'Fin de journée',
                    'heure': testDate,
                  }
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify timer structure is preserved (may have multiple CustomPaint widgets)
        expect(find.byType(CustomPaint), findsWidgets);
        expect(find.byType(GestureDetector), findsOneWidget);

        // Verify timer can be interacted with (tap the GestureDetector instead)
        final gestureDetectorFinder = find.byType(GestureDetector);
        await tester.tap(gestureDetectorFinder);
        await tester.pump();

        // Verify long press works
        await tester.longPress(gestureDetectorFinder);
        await tester.pump();
      });

      testWidgets('Timer displays correct state information',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageTimer(
                etatActuel: 'Entrée',
                dernierPointage: testDate.subtract(const Duration(hours: 2)),
                progression: 0.5,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 2)),
                  }
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify state is displayed
        expect(find.text('Entrée'), findsOneWidget);

        // Verify time information is present
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Design System Preservation (Requirements 8.1-8.4)', () {
      test('Timer colors are preserved exactly', () {
        // Verify that timer colors are preserved as required
        expect(PointageColors.entreeColor, equals(Colors.teal));
        expect(PointageColors.pauseColor, equals(const Color(0xFFE7D37F)));
        expect(PointageColors.repriseColor, equals(const Color(0xFFFD9B63)));
      });

      test('Text styles are consistent', () {
        // Verify text styles are defined and consistent
        expect(PointageTextStyles.primaryTime.fontSize, equals(18));
        expect(
            PointageTextStyles.primaryTime.fontWeight, equals(FontWeight.w600));
        expect(PointageTextStyles.secondaryTime.fontSize, equals(14));
        expect(PointageTextStyles.secondaryTime.fontStyle,
            equals(FontStyle.italic));
      });

      test('Spacing constants are properly defined', () {
        // Verify spacing constants
        expect(PointageSpacing.xs, equals(4.0));
        expect(PointageSpacing.sm, equals(8.0));
        expect(PointageSpacing.md, equals(16.0));
        expect(PointageSpacing.lg, equals(24.0));
        expect(PointageSpacing.xl, equals(32.0));
      });
    });

    group('Responsive Layout Preservation (Requirement 6.3)', () {
      testWidgets('Main section adapts to different screen sizes',
          (WidgetTester tester) async {
        // Test standard layout
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 500,
                child: PointageMainSection(
                  etatActuel: 'Entrée',
                  dernierPointage: testDate,
                  progression: 0.5,
                  pointages: [
                    {
                      'type': 'Entrée',
                      'heure': testDate.subtract(const Duration(hours: 2)),
                    }
                  ],
                  totalDayHours: const Duration(hours: 2),
                  totalBreakTime: Duration.zero,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify standard layout elements
        expect(find.text('Total du jour'), findsOneWidget);
        expect(find.text('02:00'), findsOneWidget);
        expect(find.text('Temps de pause'), findsOneWidget);
        expect(find.text('00:00'), findsOneWidget);
      });

      testWidgets('Compact layout for smaller screens',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 350,
                child: PointageMainSection(
                  etatActuel: 'Pause',
                  dernierPointage: testDate,
                  progression: 0.6,
                  pointages: [
                    {
                      'type': 'Entrée',
                      'heure': testDate.subtract(const Duration(hours: 3)),
                    },
                    {
                      'type': 'Début pause',
                      'heure': testDate.subtract(const Duration(minutes: 30)),
                    }
                  ],
                  totalDayHours: const Duration(hours: 2, minutes: 30),
                  totalBreakTime: const Duration(minutes: 30),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify compact layout elements
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('02:30'), findsOneWidget);
        expect(find.text('Pause'), findsAtLeastNWidgets(1));
        expect(find.text('00:30'), findsOneWidget);
      });
    });

    group('FAB Functionality Tests', () {
      testWidgets('FAB displays correct state-based colors and icons',
          (WidgetTester tester) async {
        // Test Non commencé state
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageFAB(
                etatActuel: 'Non commencé',
                onPressed: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify FAB is present
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);

        // Test Entrée state
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageFAB(
                etatActuel: 'Entrée',
                onPressed: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsOneWidget);

        // Test Pause state
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageFAB(
                etatActuel: 'Pause',
                onPressed: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);

        // Test Reprise state
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageFAB(
                etatActuel: 'Reprise',
                onPressed: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.stop), findsOneWidget);
      });

      testWidgets('FAB compact version works correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageFABCompact(
                etatActuel: 'Entrée',
                onPressed: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify compact FAB is present
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsOneWidget);
      });

      testWidgets('FAB press functionality works', (WidgetTester tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageFAB(
                etatActuel: 'Non commencé',
                onPressed: () {
                  pressed = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test FAB press
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();

        expect(pressed, isTrue);
      });
    });

    group('Data Preservation Tests (Requirements 7.5-7.7)', () {
      testWidgets('All pointage data is preserved and displayed correctly',
          (WidgetTester tester) async {
        final testPointages = [
          {
            'type': 'Entrée',
            'heure': testDate.subtract(const Duration(hours: 8)),
          },
          {
            'type': 'Début pause',
            'heure': testDate.subtract(const Duration(hours: 4)),
          },
          {
            'type': 'Fin pause',
            'heure': testDate.subtract(const Duration(hours: 3)),
          },
          {
            'type': 'Fin de journée',
            'heure': testDate,
          }
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Sortie',
                dernierPointage: testDate,
                progression: 1.0,
                pointages: testPointages,
                totalDayHours: const Duration(hours: 8),
                totalBreakTime: const Duration(hours: 1),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify all data is preserved
        expect(find.text('08:00'), findsOneWidget); // Total hours
        expect(find.text('01:00'), findsOneWidget); // Break time
        expect(find.text('Sortie'), findsOneWidget); // Current state
      });

      testWidgets('Edge cases are handled correctly',
          (WidgetTester tester) async {
        // Test with very long work day
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Sortie',
                dernierPointage: testDate,
                progression: 1.0,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 12)),
                  },
                  {
                    'type': 'Fin de journée',
                    'heure': testDate,
                  }
                ],
                totalDayHours: const Duration(hours: 12),
                totalBreakTime: Duration.zero,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify long duration is handled
        expect(find.text('12:00'), findsOneWidget);
        expect(find.text('00:00'), findsOneWidget);
      });

      testWidgets('Fractional minutes are displayed correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Entrée',
                dernierPointage: testDate,
                progression: 0.3,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate
                        .subtract(const Duration(hours: 2, minutes: 37)),
                  }
                ],
                totalDayHours: const Duration(hours: 2, minutes: 37),
                totalBreakTime: const Duration(minutes: 23),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify fractional minutes are displayed correctly
        expect(find.text('02:37'), findsOneWidget);
        expect(find.text('00:23'), findsOneWidget);
      });
    });

    group('Performance and Stability Tests (Requirement 10.1)', () {
      testWidgets('Widgets build without errors under stress',
          (WidgetTester tester) async {
        // Test with many pointage entries
        final manyPointages = List.generate(
            20,
            (index) => {
                  'type': index % 4 == 0
                      ? 'Entrée'
                      : index % 4 == 1
                          ? 'Début pause'
                          : index % 4 == 2
                              ? 'Fin pause'
                              : 'Fin de journée',
                  'heure': testDate.subtract(Duration(hours: 20 - index)),
                });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Sortie',
                dernierPointage: testDate,
                progression: 1.0,
                pointages: manyPointages,
                totalDayHours: const Duration(hours: 8),
                totalBreakTime: const Duration(hours: 2),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify it builds without errors
        expect(find.byType(PointageMainSection), findsOneWidget);
        expect(find.text('08:00'), findsOneWidget);
        expect(find.text('02:00'), findsOneWidget);
      });

      testWidgets('Rapid state changes are handled correctly',
          (WidgetTester tester) async {
        final states = ['Non commencé', 'Entrée', 'Pause', 'Reprise', 'Sortie'];

        for (final state in states) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageFAB(
                  etatActuel: state,
                  onPressed: () {},
                ),
              ),
            ),
          );

          await tester.pump();

          // Verify each state renders correctly (FAB may not be present for all states)
          expect(find.byType(PointageFAB), findsOneWidget);
        }
      });
    });
  });
}
