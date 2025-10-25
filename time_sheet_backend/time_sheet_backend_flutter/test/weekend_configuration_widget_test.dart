import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:time_sheet/features/preference/presentation/widgets/weekend_configuration_widget.dart';
import 'package:time_sheet/services/overtime_configuration_service.dart';

// Generate mocks
@GenerateMocks([OvertimeConfigurationService])
import 'weekend_configuration_widget_test.mocks.dart';

void main() {
  late MockOvertimeConfigurationService mockConfigService;

  setUp(() {
    mockConfigService = MockOvertimeConfigurationService();

    // Clear GetIt before each test
    if (GetIt.instance.isRegistered<OvertimeConfigurationService>()) {
      GetIt.instance.unregister<OvertimeConfigurationService>();
    }

    // Register mock service
    GetIt.instance
        .registerSingleton<OvertimeConfigurationService>(mockConfigService);

    // Setup default mock responses
    when(mockConfigService.isWeekendOvertimeEnabled())
        .thenAnswer((_) async => true);
    when(mockConfigService.getWeekendDays())
        .thenAnswer((_) async => [DateTime.saturday, DateTime.sunday]);
    when(mockConfigService.getWeekendOvertimeRate())
        .thenAnswer((_) async => 1.5);
    when(mockConfigService.getWeekdayOvertimeRate())
        .thenAnswer((_) async => 1.25);
    when(mockConfigService.getDailyWorkThreshold())
        .thenAnswer((_) async => const Duration(hours: 8, minutes: 18));
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('WeekendConfigurationWidget', () {
    testWidgets('should allow precise minute-level threshold configuration',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const WeekendConfigurationWidget(),
          ),
        ),
      );

      // Wait for the widget to load
      await tester.pumpAndSettle();

      // Find the threshold slider
      final thresholdSlider = find.byType(Slider).last;
      expect(thresholdSlider, findsOneWidget);

      // Verify initial value is 8h18 (498 minutes)
      final slider = tester.widget<Slider>(thresholdSlider);
      expect(slider.value, equals(498.0)); // 8h18 = 498 minutes
      expect(slider.min, equals(360.0)); // 6h00
      expect(slider.max, equals(600.0)); // 10h00
      expect(slider.divisions, equals(240)); // 1-minute increments

      // Verify that we can set exactly 8h18
      expect(slider.value, equals(498.0));

      // Test that the slider allows 1-minute precision
      final minuteIncrement = (slider.max! - slider.min!) / slider.divisions!;
      expect(minuteIncrement, equals(1.0)); // Should be 1 minute per division
    });

    testWidgets('should display correct time format for 8h18',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const WeekendConfigurationWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the text that displays the current threshold
      expect(find.text('8h 18min'), findsOneWidget);
    });

    testWidgets('should show recommendation for 8h18',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const WeekendConfigurationWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the recommendation text
      expect(
          find.text('Valeur recommandée: 8h18 (498 minutes)'), findsOneWidget);
    });
  });
}
