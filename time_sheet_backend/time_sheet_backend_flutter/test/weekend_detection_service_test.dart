import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';

void main() {
  group('WeekendDetectionService', () {
    late WeekendDetectionService service;

    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      service = WeekendDetectionService();
      service.clearCache();
    });

    group('isWeekend', () {
      test('should return true for Saturday with default configuration', () {
        // Saturday, January 6, 2024
        final saturday = DateTime(2024, 1, 6);

        expect(service.isWeekend(saturday), isTrue);
      });

      test('should return true for Sunday with default configuration', () {
        // Sunday, January 7, 2024
        final sunday = DateTime(2024, 1, 7);

        expect(service.isWeekend(sunday), isTrue);
      });

      test('should return false for Monday with default configuration', () {
        // Monday, January 8, 2024
        final monday = DateTime(2024, 1, 8);

        expect(service.isWeekend(monday), isFalse);
      });

      test('should return false for Friday with default configuration', () {
        // Friday, January 5, 2024
        final friday = DateTime(2024, 1, 5);

        expect(service.isWeekend(friday), isFalse);
      });

      test('should use custom weekend days when provided', () {
        // Friday, January 5, 2024
        final friday = DateTime(2024, 1, 5);
        final customWeekendDays = [DateTime.friday, DateTime.saturday];

        expect(service.isWeekend(friday, customWeekendDays: customWeekendDays),
            isTrue);
      });

      test('should handle edge case with only one weekend day', () {
        // Sunday, January 7, 2024
        final sunday = DateTime(2024, 1, 7);
        final customWeekendDays = [DateTime.sunday];

        expect(service.isWeekend(sunday, customWeekendDays: customWeekendDays),
            isTrue);
      });
    });

    group('getConfiguredWeekendDays', () {
      test('should return default weekend days when no configuration exists',
          () async {
        final weekendDays = await service.getConfiguredWeekendDays();

        expect(
            weekendDays, equals(WeekendDetectionService.DEFAULT_WEEKEND_DAYS));
      });

      test('should return cached weekend days on subsequent calls', () async {
        // First call
        final firstCall = await service.getConfiguredWeekendDays();

        // Second call should return the same instance (cached)
        final secondCall = await service.getConfiguredWeekendDays();

        expect(identical(firstCall, secondCall), isTrue);
      });

      test('should return configured weekend days from SharedPreferences',
          () async {
        // Set up SharedPreferences with custom weekend days
        SharedPreferences.setMockInitialValues({
          'weekend_days': ['1', '7'], // Monday and Sunday
        });

        service.clearCache(); // Clear cache to force reload
        final weekendDays = await service.getConfiguredWeekendDays();

        expect(weekendDays, equals([1, 7]));
      });
    });

    group('updateWeekendConfiguration', () {
      test('should update weekend days configuration successfully', () async {
        final newWeekendDays = [DateTime.friday, DateTime.saturday];

        await service.updateWeekendConfiguration(newWeekendDays);
        final retrievedDays = await service.getConfiguredWeekendDays();

        expect(retrievedDays, equals(newWeekendDays));
      });

      test('should persist weekend days configuration', () async {
        final newWeekendDays = [DateTime.monday, DateTime.tuesday];

        await service.updateWeekendConfiguration(newWeekendDays);

        // Create new service instance to test persistence
        final newService = WeekendDetectionService();
        newService.clearCache();
        final retrievedDays = await newService.getConfiguredWeekendDays();

        expect(retrievedDays, equals(newWeekendDays));
      });

      test('should throw ArgumentError for empty weekend days', () async {
        expect(
          () => service.updateWeekendConfiguration([]),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Weekend days cannot be empty'),
          )),
        );
      });

      test('should throw ArgumentError for invalid weekend day (0)', () async {
        expect(
          () => service.updateWeekendConfiguration([0, DateTime.sunday]),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid weekend day: 0'),
          )),
        );
      });

      test('should throw ArgumentError for invalid weekend day (8)', () async {
        expect(
          () => service.updateWeekendConfiguration([DateTime.saturday, 8]),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid weekend day: 8'),
          )),
        );
      });

      test('should throw ArgumentError for duplicate weekend days', () async {
        expect(
          () => service.updateWeekendConfiguration(
              [DateTime.saturday, DateTime.saturday]),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Duplicate weekend days are not allowed'),
          )),
        );
      });

      test('should throw ArgumentError when all days are set as weekend',
          () async {
        expect(
          () => service.updateWeekendConfiguration([1, 2, 3, 4, 5, 6, 7]),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Cannot set all days as weekend days'),
          )),
        );
      });
    });

    group('shouldApplyWeekendOvertime', () {
      test('should return true for weekend day when overtime is enabled',
          () async {
        await service.setWeekendOvertimeEnabled(true);
        await service
            .updateWeekendConfiguration([DateTime.saturday, DateTime.sunday]);

        // Saturday, January 6, 2024
        final saturday = DateTime(2024, 1, 6);

        final result = await service.shouldApplyWeekendOvertime(saturday);
        expect(result, isTrue);
      });

      test('should return false for weekend day when overtime is disabled',
          () async {
        await service.setWeekendOvertimeEnabled(false);
        await service
            .updateWeekendConfiguration([DateTime.saturday, DateTime.sunday]);

        // Saturday, January 6, 2024
        final saturday = DateTime(2024, 1, 6);

        final result = await service.shouldApplyWeekendOvertime(saturday);
        expect(result, isFalse);
      });

      test('should return false for weekday when overtime is enabled',
          () async {
        await service.setWeekendOvertimeEnabled(true);
        await service
            .updateWeekendConfiguration([DateTime.saturday, DateTime.sunday]);

        // Monday, January 8, 2024
        final monday = DateTime(2024, 1, 8);

        final result = await service.shouldApplyWeekendOvertime(monday);
        expect(result, isFalse);
      });
    });

    group('isWeekendOvertimeEnabled', () {
      test('should return true by default', () async {
        final result = await service.isWeekendOvertimeEnabled();
        expect(result, isTrue);
      });

      test('should return configured value from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'weekend_overtime_enabled': false,
        });

        service.clearCache();
        final result = await service.isWeekendOvertimeEnabled();
        expect(result, isFalse);
      });

      test('should cache the result for subsequent calls', () async {
        // First call
        await service.isWeekendOvertimeEnabled();

        // Change SharedPreferences value
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('weekend_overtime_enabled', false);

        // Second call should still return cached value (true)
        final result = await service.isWeekendOvertimeEnabled();
        expect(result, isTrue);
      });
    });

    group('setWeekendOvertimeEnabled', () {
      test('should update weekend overtime enabled setting', () async {
        await service.setWeekendOvertimeEnabled(false);

        final result = await service.isWeekendOvertimeEnabled();
        expect(result, isFalse);
      });

      test('should persist weekend overtime enabled setting', () async {
        await service.setWeekendOvertimeEnabled(false);

        // Create new service instance to test persistence
        final newService = WeekendDetectionService();
        newService.clearCache();
        final result = await newService.isWeekendOvertimeEnabled();

        expect(result, isFalse);
      });
    });

    group('resetToDefaults', () {
      test('should reset weekend days and overtime enabled to defaults',
          () async {
        // Set non-default values
        await service
            .updateWeekendConfiguration([DateTime.monday, DateTime.tuesday]);
        await service.setWeekendOvertimeEnabled(false);

        // Reset to defaults
        await service.resetToDefaults();

        // Verify defaults are restored
        final weekendDays = await service.getConfiguredWeekendDays();
        final overtimeEnabled = await service.isWeekendOvertimeEnabled();

        expect(
            weekendDays, equals(WeekendDetectionService.DEFAULT_WEEKEND_DAYS));
        expect(overtimeEnabled, isTrue);
      });
    });

    group('clearCache', () {
      test('should force reload of configuration from SharedPreferences',
          () async {
        // Load initial configuration
        await service.getConfiguredWeekendDays();
        await service.isWeekendOvertimeEnabled();

        // Change SharedPreferences directly
        final prefs = await SharedPreferences.getInstance();
        await prefs
            .setStringList('weekend_days', ['1', '2']); // Monday, Tuesday
        await prefs.setBool('weekend_overtime_enabled', false);

        // Clear cache and verify new values are loaded
        service.clearCache();

        final weekendDays = await service.getConfiguredWeekendDays();
        final overtimeEnabled = await service.isWeekendOvertimeEnabled();

        expect(weekendDays, equals([1, 2]));
        expect(overtimeEnabled, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle leap year dates correctly', () {
        // February 29, 2024 (leap year, Thursday)
        final leapYearDate = DateTime(2024, 2, 29);

        expect(service.isWeekend(leapYearDate), isFalse);
      });

      test('should handle year boundary dates correctly', () {
        // December 31, 2023 (Sunday)
        final yearEnd = DateTime(2023, 12, 31);
        // January 1, 2024 (Monday)
        final yearStart = DateTime(2024, 1, 1);

        expect(service.isWeekend(yearEnd), isTrue);
        expect(service.isWeekend(yearStart), isFalse);
      });

      test('should handle different time zones consistently', () {
        // Same date in different time representations
        final utcDate = DateTime.utc(2024, 1, 6); // Saturday
        final localDate = DateTime(2024, 1, 6); // Saturday

        expect(
            service.isWeekend(utcDate), equals(service.isWeekend(localDate)));
      });
    });
  });
}
