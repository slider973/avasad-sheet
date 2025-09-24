import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/modern_info_card.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/time_info_card.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/modern_pointage_button.dart';

void main() {
  group('ModernInfoCard Tests', () {
    testWidgets('should render basic card with child content', (tester) async {
      const testText = 'Test Content';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernInfoCard(
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
      expect(find.byType(ModernInfoCard), findsOneWidget);
    });

    testWidgets('should handle tap interactions when onTap is provided',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernInfoCard(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ModernInfoCard), warnIfMissed: false);
      expect(tapped, isTrue);
    });

    testWidgets('should apply custom styling properties', (tester) async {
      const customPadding = EdgeInsets.all(24.0);
      const customMargin = EdgeInsets.all(12.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernInfoCard(
              padding: customPadding,
              margin: customMargin,
              backgroundColor: Colors.red,
              child: const Text('Styled card'),
            ),
          ),
        ),
      );

      final card = tester.widget<ModernInfoCard>(find.byType(ModernInfoCard));
      expect(card.padding, equals(customPadding));
      expect(card.margin, equals(customMargin));
      expect(card.backgroundColor, equals(Colors.red));
    });

    testWidgets('should create accent variant correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernInfoCardVariants.accent(
              accentColor: Colors.blue,
              child: const Text('Accent card'),
            ),
          ),
        ),
      );

      expect(find.text('Accent card'), findsOneWidget);
      expect(find.byType(ModernInfoCard), findsOneWidget);
    });

    testWidgets('should create compact variant correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernInfoCardVariants.compact(
              child: const Text('Compact card'),
            ),
          ),
        ),
      );

      expect(find.text('Compact card'), findsOneWidget);
      expect(find.byType(ModernInfoCard), findsOneWidget);
    });
  });

  group('TimeInfoCard Tests', () {
    testWidgets('should render time information correctly', (tester) async {
      const title = 'Work Time';
      const timeValue = '08:30:45';
      const subtitle = 'Today';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeInfoCard(
              title: title,
              timeValue: timeValue,
              subtitle: subtitle,
              icon: Icons.work,
            ),
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
      expect(find.text(timeValue), findsOneWidget);
      expect(find.text(subtitle), findsOneWidget);
      expect(find.byIcon(Icons.work), findsOneWidget);
    });

    testWidgets('should render compact version correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeInfoCard(
              title: 'Break Time',
              timeValue: '01:15:00',
              isCompact: true,
              icon: Icons.pause,
            ),
          ),
        ),
      );

      expect(find.text('Break Time'), findsOneWidget);
      expect(find.text('01:15:00'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('should show progress bar when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeInfoCard(
              title: 'Daily Progress',
              timeValue: '06:30:00',
              showProgress: true,
              progressValue: 0.75,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('should create daily work variant correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeInfoCardVariants.dailyWork(
              timeValue: '07:45:30',
              subtitle: 'Target: 8 hours',
              showProgress: true,
              progressValue: 0.97,
            ),
          ),
        ),
      );

      expect(find.text('Temps de travail'), findsOneWidget);
      expect(find.text('07:45:30'), findsOneWidget);
      expect(find.text('Target: 8 hours'), findsOneWidget);
      expect(find.byIcon(Icons.work_outline), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should create break time variant correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeInfoCardVariants.breakTime(
              timeValue: '00:45:00',
              subtitle: 'Current break',
            ),
          ),
        ),
      );

      expect(find.text('Temps de pause'), findsOneWidget);
      expect(find.text('00:45:00'), findsOneWidget);
      expect(find.text('Current break'), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
    });

    testWidgets('should create estimated end variant correctly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeInfoCardVariants.estimatedEnd(
              timeValue: '17:30',
              subtitle: 'Based on current pace',
            ),
          ),
        ),
      );

      expect(find.text('Fin de journée estimée'), findsOneWidget);
      expect(find.text('17:30'), findsOneWidget);
      expect(find.text('Based on current pace'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });
  });

  group('ModernPointageButton Tests', () {
    testWidgets('should render basic button correctly', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernPointageButton(
              text: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);

      await tester.tap(find.byType(ModernPointageButton), warnIfMissed: false);
      expect(pressed, isTrue);
    });

    testWidgets('should render entry button correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernPointageButton.entry(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Commencer'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should render pause button correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernPointageButton.pause(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pause'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('should render resume button correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernPointageButton.resume(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Reprise'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should render exit button correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernPointageButton.exit(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Terminer'), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('should render secondary button correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernPointageButton.secondary(
              text: 'Secondary Action',
              onPressed: () {},
              icon: Icons.settings,
            ),
          ),
        ),
      );

      expect(find.text('Secondary Action'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should show loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernPointageButton(
              text: 'Loading Button',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsNothing);
    });

    testWidgets('should be disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernPointageButton(
              text: 'Disabled Button',
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.text('Disabled Button'), findsOneWidget);

      // Button should not respond to taps when disabled
      await tester.tap(find.byType(ModernPointageButton), warnIfMissed: false);
      // No exception should be thrown
    });

    testWidgets('should handle different button sizes correctly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ModernPointageButton(
                  text: 'Small',
                  size: PointageButtonSize.small,
                  onPressed: () {},
                ),
                ModernPointageButton(
                  text: 'Medium',
                  size: PointageButtonSize.medium,
                  onPressed: () {},
                ),
                ModernPointageButton(
                  text: 'Large',
                  size: PointageButtonSize.large,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
    });
  });

  group('Responsive Design Tests', () {
    testWidgets('should adapt to different screen sizes - phone',
        (tester) async {
      // Simulate phone screen size
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TimeInfoCard(
                  title: 'Work Time',
                  timeValue: '08:30:45',
                  icon: Icons.work,
                ),
                ModernPointageButton.entry(
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TimeInfoCard), findsOneWidget);
      expect(find.byType(ModernPointageButton), findsOneWidget);

      addTearDown(tester.view.reset);
    });

    testWidgets('should adapt to different screen sizes - tablet',
        (tester) async {
      // Simulate tablet screen size
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: TimeInfoCard(
                    title: 'Work Time',
                    timeValue: '08:30:45',
                    icon: Icons.work,
                  ),
                ),
                Expanded(
                  child: TimeInfoCard(
                    title: 'Break Time',
                    timeValue: '01:15:00',
                    icon: Icons.pause,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TimeInfoCard), findsNWidgets(2));

      addTearDown(tester.view.reset);
    });

    testWidgets('should handle compact layout for small screens',
        (tester) async {
      // Simulate small screen
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TimeInfoCard(
                  title: 'Work Time',
                  timeValue: '08:30:45',
                  isCompact: true,
                  icon: Icons.work,
                ),
                ModernPointageButton(
                  text: 'Action',
                  size: PointageButtonSize.small,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TimeInfoCard), findsOneWidget);
      expect(find.byType(ModernPointageButton), findsOneWidget);

      addTearDown(tester.view.reset);
    });
  });

  group('Animation Tests', () {
    testWidgets('should animate card interactions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernInfoCard(
              onTap: () {},
              child: const Text('Animated card'),
            ),
          ),
        ),
      );

      // Test tap down animation
      await tester.press(find.byType(ModernInfoCard), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      // Test tap up animation
      await tester.pumpAndSettle();

      expect(find.text('Animated card'), findsOneWidget);
    });

    testWidgets('should animate button interactions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernPointageButton(
              text: 'Animated button',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Test button press animation
      await tester.press(find.byType(ModernPointageButton),
          warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      // Test button release animation
      await tester.pumpAndSettle();

      expect(find.text('Animated button'), findsOneWidget);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('should provide proper semantics for screen readers',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TimeInfoCard(
                  title: 'Work Time',
                  timeValue: '08:30:45',
                  subtitle: 'Today',
                  icon: Icons.work,
                ),
                ModernPointageButton.entry(
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Verify that text is accessible
      expect(find.text('Work Time'), findsOneWidget);
      expect(find.text('08:30:45'), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('should handle disabled state properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernPointageButton(
              text: 'Disabled Button',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester
          .widget<ModernPointageButton>(find.byType(ModernPointageButton));
      expect(button.onPressed, isNull);
    });
  });
}
