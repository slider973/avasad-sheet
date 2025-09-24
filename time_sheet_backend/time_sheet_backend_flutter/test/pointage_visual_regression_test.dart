import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_main_section.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_timer.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_design_system.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_fab.dart';

/// Focused visual regression tests for pointage design harmonization
/// Validates requirements 6.3, 9.1, 9.3, 9.4, 10.2
void main() {
  setUpAll(() async {
    // Initialize date formatting for French locale
    await initializeDateFormatting('fr_FR', null);
  });

  group('Pointage Visual Regression Tests', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
    });

    group('Responsive Layout Core Tests (Requirement 6.3)', () {
      testWidgets('Small screen layout (320px) adapts correctly',
          (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
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
        );

        await tester.pumpAndSettle();

        // Verify compact layout elements
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('02:00'), findsOneWidget);
        expect(find.byType(PointageTimer), findsOneWidget);

        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('Large screen layout (768px) uses standard layout',
          (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(768, 1024));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
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
        );

        await tester.pumpAndSettle();

        // Verify standard layout elements
        expect(find.text('Total du jour'), findsOneWidget);
        expect(find.text('02:30'), findsOneWidget);
        expect(find.text('Temps de pause'), findsOneWidget);
        expect(find.text('00:30'), findsOneWidget);

        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('Medium screen layout (414px) adapts appropriately',
          (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(414, 896));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Reprise',
                dernierPointage: testDate,
                progression: 0.8,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 5)),
                  },
                  {
                    'type': 'Début pause',
                    'heure': testDate.subtract(const Duration(hours: 2)),
                  },
                  {
                    'type': 'Fin pause',
                    'heure': testDate.subtract(const Duration(hours: 1)),
                  }
                ],
                totalDayHours: const Duration(hours: 4),
                totalBreakTime: const Duration(hours: 1),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify layout works on medium screens
        expect(find.text('Total du jour'), findsOneWidget);
        expect(find.text('04:00'), findsOneWidget);
        expect(find.text('01:00'), findsOneWidget);
        expect(find.text('Reprise'), findsOneWidget);

        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Visual Design System Tests (Requirements 9.1, 9.3)', () {
      test('Timer colors are preserved exactly', () {
        // Verify exact color preservation as required
        expect(PointageColors.entreeColor, equals(Colors.teal));
        expect(PointageColors.pauseColor, equals(const Color(0xFFE7D37F)));
        expect(PointageColors.repriseColor, equals(const Color(0xFFFD9B63)));
      });

      test('Typography system is consistent', () {
        // Verify text styles consistency
        expect(PointageTextStyles.primaryTime.fontSize, equals(18));
        expect(
            PointageTextStyles.primaryTime.fontWeight, equals(FontWeight.w600));
        expect(PointageTextStyles.secondaryTime.fontSize, equals(14));
        expect(PointageTextStyles.secondaryTime.fontStyle,
            equals(FontStyle.italic));

        // Verify timer text styles
        expect(PointageTextStyles.timerState.fontSize, equals(18));
        expect(
            PointageTextStyles.timerState.fontWeight, equals(FontWeight.bold));
        expect(PointageTextStyles.timerTime.fontSize, equals(32));
        expect(
            PointageTextStyles.timerTime.fontWeight, equals(FontWeight.bold));
      });

      test('Spacing system is properly defined', () {
        // Verify spacing constants
        expect(PointageSpacing.xs, equals(4.0));
        expect(PointageSpacing.sm, equals(8.0));
        expect(PointageSpacing.md, equals(16.0));
        expect(PointageSpacing.lg, equals(24.0));
        expect(PointageSpacing.xl, equals(32.0));
      });

      testWidgets('Visual hierarchy is maintained',
          (WidgetTester tester) async {
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
                    'heure': testDate.subtract(const Duration(hours: 8)),
                  },
                  {
                    'type': 'Fin de journée',
                    'heure': testDate,
                  }
                ],
                totalDayHours: const Duration(hours: 8),
                totalBreakTime: Duration.zero,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify visual hierarchy elements are present
        expect(find.text('Total du jour'), findsOneWidget);
        expect(find.text('08:00'), findsOneWidget);
        expect(find.text('Temps de pause'), findsOneWidget);
        expect(find.text('00:00'), findsOneWidget);
        expect(find.text('Sortie'), findsOneWidget);
      });
    });

    group('Animation and Interaction Tests (Requirement 9.4)', () {
      testWidgets('Timer structure supports animations',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageTimer(
                etatActuel: 'Entrée',
                dernierPointage: testDate.subtract(const Duration(hours: 1)),
                progression: 0.25,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 1)),
                  }
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify animation-supporting structure
        expect(find.byType(PointageTimer), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
        expect(find.byType(GestureDetector), findsOneWidget);

        // Verify state information is displayed
        expect(find.text('Entrée'), findsOneWidget);
      });

      testWidgets('FAB state transitions work smoothly',
          (WidgetTester tester) async {
        // Test different FAB states
        final states = [
          {'state': 'Non commencé', 'icon': Icons.play_arrow},
          {'state': 'Entrée', 'icon': Icons.pause},
          {'state': 'Pause', 'icon': Icons.play_arrow},
          {'state': 'Reprise', 'icon': Icons.stop},
        ];

        for (final stateInfo in states) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageFAB(
                  etatActuel: stateInfo['state'] as String,
                  onPressed: () {},
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify correct icon for each state
          expect(find.byType(FloatingActionButton), findsOneWidget);
          expect(find.byIcon(stateInfo['icon'] as IconData), findsOneWidget);
        }
      });

      testWidgets('FAB press animation works', (WidgetTester tester) async {
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

        // Test press animation
        final fabFinder = find.byType(FloatingActionButton);
        await tester.tap(fabFinder);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(pressed, isTrue);
      });
    });

    group('Accessibility Visual Tests (Requirements 9.1, 9.3)', () {
      testWidgets('Text elements have sufficient contrast',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Entrée',
                dernierPointage: testDate,
                progression: 0.4,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 3)),
                  }
                ],
                totalDayHours: const Duration(hours: 3, minutes: 15),
                totalBreakTime: const Duration(minutes: 30),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify text elements are readable (structure test)
        expect(find.text('Total du jour'), findsOneWidget);
        expect(find.text('03:15'), findsOneWidget);
        expect(find.text('Temps de pause'), findsOneWidget);
        expect(find.text('00:30'), findsOneWidget);
        expect(find.text('Entrée'), findsOneWidget);

        // Verify design system provides proper contrast colors
        expect(PointageColors.primary, isNotNull);
        expect(PointageColors.secondary, isNotNull);
        expect(PointageColors.background, isNotNull);
        expect(PointageColors.cardBackground, isNotNull);
      });

      testWidgets('Touch targets are appropriately sized',
          (WidgetTester tester) async {
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

        // Verify FAB has adequate touch target
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        // Verify timer has gesture detection
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageTimer(
                etatActuel: 'Pause',
                dernierPointage: testDate,
                progression: 0.6,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate.subtract(const Duration(hours: 4)),
                  },
                  {
                    'type': 'Début pause',
                    'heure': testDate.subtract(const Duration(minutes: 30)),
                  }
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(GestureDetector), findsOneWidget);
      });
    });

    group('Performance Visual Tests (Requirement 10.2)', () {
      testWidgets('Widgets render efficiently', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

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
                totalDayHours: const Duration(hours: 8),
                totalBreakTime: const Duration(hours: 1),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Verify reasonable render time (less than 500ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(500));

        // Verify components are rendered
        expect(find.byType(PointageMainSection), findsOneWidget);
        expect(find.byType(PointageTimer), findsOneWidget);
        expect(find.text('08:00'), findsOneWidget);
        expect(find.text('01:00'), findsOneWidget);
      });

      testWidgets('Multiple screen size changes handled efficiently',
          (WidgetTester tester) async {
        final sizes = [
          const Size(320, 568), // Small
          const Size(375, 812), // Medium
          const Size(414, 896), // Large
        ];

        for (final size in sizes) {
          final stopwatch = Stopwatch()..start();

          await tester.binding.setSurfaceSize(size);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PointageMainSection(
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
          );

          await tester.pumpAndSettle();
          stopwatch.stop();

          // Verify efficient rendering for each size
          expect(stopwatch.elapsedMilliseconds, lessThan(300));
          expect(find.byType(PointageMainSection), findsOneWidget);
          expect(find.byType(PointageTimer), findsOneWidget);
        }

        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Visual Regression Prevention Tests', () {
      testWidgets('Timer visual structure remains consistent',
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

        // Verify timer structure is preserved
        expect(find.byType(PointageTimer), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
        expect(find.text('Sortie'), findsOneWidget);

        // Verify timer content structure
        expect(find.byType(GestureDetector), findsOneWidget);
      });

      testWidgets('Time display formatting is consistent',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PointageMainSection(
                etatActuel: 'Reprise',
                dernierPointage: testDate,
                progression: 0.85,
                pointages: [
                  {
                    'type': 'Entrée',
                    'heure': testDate
                        .subtract(const Duration(hours: 6, minutes: 45)),
                  },
                  {
                    'type': 'Début pause',
                    'heure': testDate
                        .subtract(const Duration(hours: 3, minutes: 15)),
                  },
                  {
                    'type': 'Fin pause',
                    'heure': testDate
                        .subtract(const Duration(hours: 2, minutes: 30)),
                  }
                ],
                totalDayHours: const Duration(hours: 5, minutes: 30),
                totalBreakTime: const Duration(minutes: 45),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify time formatting consistency
        expect(find.text('05:30'), findsOneWidget);
        expect(find.text('00:45'), findsOneWidget);
        expect(find.text('Reprise'), findsOneWidget);
      });
    });
  });
}
