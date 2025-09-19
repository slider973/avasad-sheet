import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import '../lib/services/injection_container.dart';
import '../lib/services/weekend_overtime_calculator.dart';
import '../lib/services/weekend_detection_service.dart';

void main() {
  group('Injection Container', () {
    setUp(() async {
      // Clear GetIt before each test
      GetIt.instance.reset();
    });

    test('should register WeekendOvertimeCalculator successfully', () async {
      // Setup the injection container
      await setup();

      // Verify that WeekendOvertimeCalculator is registered
      expect(GetIt.instance.isRegistered<WeekendOvertimeCalculator>(), isTrue);
      
      // Verify that WeekendDetectionService is registered
      expect(GetIt.instance.isRegistered<WeekendDetectionService>(), isTrue);
      
      // Verify we can get the instance
      final calculator = GetIt.instance<WeekendOvertimeCalculator>();
      expect(calculator, isNotNull);
      expect(calculator, isA<WeekendOvertimeCalculator>());
    });

    test('should get WeekendOvertimeCalculator instance without error', () async {
      // Setup the injection container
      await setup();

      // This should not throw an error
      expect(() => GetIt.instance<WeekendOvertimeCalculator>(), returnsNormally);
      
      final calculator = GetIt.instance<WeekendOvertimeCalculator>();
      expect(calculator.getWeekdayOvertimeRate(), equals(1.25));
      expect(calculator.getWeekendOvertimeRate(), equals(1.5));
    });
  });
}