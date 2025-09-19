import 'package:flutter_test/flutter_test.dart';
import '../lib/services/weekend_overtime_calculator.dart';
import '../lib/services/weekend_detection_service.dart';

void main() {
  group('WeekendOvertimeCalculator Simple Test', () {
    test('should create WeekendOvertimeCalculator instance', () {
      final weekendDetectionService = WeekendDetectionService();
      final calculator = WeekendOvertimeCalculator(
        weekendDetectionService: weekendDetectionService,
      );

      expect(calculator, isNotNull);
      expect(calculator.getWeekdayOvertimeRate(), equals(1.25));
      expect(calculator.getWeekendOvertimeRate(), equals(1.5));
    });
  });
}
