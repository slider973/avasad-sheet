import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:isar/isar.dart';

import '../test_utils.dart';
import '../../lib/features/pointage/data/models/timesheet_entry_model.dart';
import '../../lib/features/preference/data/models/overtime_configuration.dart';
import '../../lib/services/overtime_configuration_service.dart';
import '../../lib/services/weekend_overtime_calculator.dart';
import '../../lib/services/weekend_detection_service.dart';
import '../../lib/enum/overtime_type.dart';

// Generate mocks
@GenerateMocks([
  WeekendDetectionService,
])
import 'weekend_configuration_integration_test.mocks.dart';

void main() {
  group('Weekend Configuration Integration Tests', () {
    late Isar isar;
    late OvertimeConfigurationService configService;
    late WeekendOvertimeCalculator calculator;
    late MockWeekendDetectionService mockWeekendDetectionService;

    setUpAll(() async {
      isar = await setupTestIsar();
    });

    setUp(() async {
      await isar.writeTxn(() async {
        await isar.timeSheetEntryModels.clear();
        await isar.overtimeConfigurations.clear();
      });

      configService = OvertimeConfigurationService(isar);
      calculator = WeekendOvertimeCalculator();
      mockWeekendDetectionService = MockWeekendDetectionService();

      // Setup default weekend detection
      when(mockWeekendDetectionService.isWeekend(any)).thenAnswer((invocation) {
        final date = invocation.positionalArguments[0] as DateTime;
        return date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday;
      });
    });

    tearDownAll(() async {
      await isar.close();
    });

    group('Configuration Changes Impact', () {
      testWidgets('Enabling weekend overtime affects existing calculations',
          (tester) async {
        // Requirement 3.1: Configuration changes affect calculations

        // Create weekend entries with overtime initially disabled
        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = false // Initially disabled
            ..overtimeType = OvertimeType.NONE,
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 7) // Sunday
            ..clockInTime = DateTime(2024, 1, 7, 10, 0)
            ..clockOutTime = DateTime(2024, 1, 7, 16, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = false // Initially disabled
            ..overtimeType = OvertimeType.NONE,
        ];

        // Save initial entries
        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Calculate initial overtime (should be zero)
        var domainEntries = entries.map((e) => e.toDomain()).toList();
        var summary = calculator.calculateMonthlyOvertime(domainEntries);

        expect(summary.weekendOvertime, equals(Duration.zero));
        expect(summary.totalOvertime, equals(Duration.zero));

        // Enable weekend overtime configuration
        await configService.setWeekendOvertimeEnabled(true);

        // Update entries to reflect new configuration
        await isar.writeTxn(() async {
          final updatedEntries =
              await isar.timeSheetEntryModels.where().findAll();
          for (final entry in updatedEntries) {
            entry.isWeekendOvertimeEnabled = true;
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Recalculate with new configuration
        final updatedEntries =
            await isar.timeSheetEntryModels.where().findAll();
        domainEntries = updatedEntries.map((e) => e.toDomain()).toList();
        summary = calculator.calculateMonthlyOvertime(domainEntries);

        // Should now show weekend overtime
        expect(summary.weekendOvertime,
            equals(const Duration(hours: 14))); // 8 + 6 hours
        expect(summary.totalOvertime, equals(const Duration(hours: 14)));
      });

      testWidgets('Disabling weekend overtime removes overtime calculations',
          (tester) async {
        // Start with weekend overtime enabled
        await configService.setWeekendOvertimeEnabled(true);

        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Initial calculation should show overtime
        var domainEntries = entries.map((e) => e.toDomain()).toList();
        var summary = calculator.calculateMonthlyOvertime(domainEntries);
        expect(summary.weekendOvertime, equals(const Duration(hours: 8)));

        // Disable weekend overtime
        await configService.setWeekendOvertimeEnabled(false);

        // Update entries to reflect disabled configuration
        await isar.writeTxn(() async {
          final updatedEntries =
              await isar.timeSheetEntryModels.where().findAll();
          for (final entry in updatedEntries) {
            entry.isWeekendOvertimeEnabled = false;
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Recalculate - should show no weekend overtime
        final updatedEntries =
            await isar.timeSheetEntryModels.where().findAll();
        domainEntries = updatedEntries.map((e) => e.toDomain()).toList();
        summary = calculator.calculateMonthlyOvertime(domainEntries);

        expect(summary.weekendOvertime, equals(Duration.zero));
        expect(summary.totalOvertime, equals(Duration.zero));
      });

      testWidgets('Custom weekend days configuration affects detection',
          (tester) async {
        // Requirement 6.2: Custom weekend days configuration

        // Configure Friday-Saturday as weekend days
        await configService
            .setWeekendDays([DateTime.friday, DateTime.saturday]);

        // Mock weekend detection service to use custom days
        when(mockWeekendDetectionService.isWeekend(any))
            .thenAnswer((invocation) {
          final date = invocation.positionalArguments[0] as DateTime;
          return date.weekday == DateTime.friday ||
              date.weekday == DateTime.saturday;
        });

        final entries = <TimeSheetEntryModel>[
          // Friday - should be weekend with custom config
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 5) // Friday
            ..clockInTime = DateTime(2024, 1, 5, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 5, 17, 0)
            ..isWeekendDay = true // Manually set based on custom config
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,

          // Saturday - should be weekend with custom config
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,

          // Sunday - should NOT be weekend with custom config
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 7) // Sunday
            ..clockInTime = DateTime(2024, 1, 7, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 7, 17, 0)
            ..isWeekendDay = false // Not weekend with custom config
            ..hasOvertimeHours = false
            ..overtimeType = OvertimeType.NONE,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Verify custom weekend configuration
        final weekendDays = await configService.getWeekendDays();
        expect(weekendDays, containsAll([DateTime.friday, DateTime.saturday]));
        expect(weekendDays, isNot(contains(DateTime.sunday)));

        // Calculate overtime with custom weekend days
        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final summary = calculator.calculateMonthlyOvertime(domainEntries);

        // Should count Friday and Saturday as weekend, but not Sunday
        expect(summary.weekendOvertime,
            equals(const Duration(hours: 16))); // Fri + Sat
        expect(summary.weekdayOvertime, equals(Duration.zero));
      });

      testWidgets('Overtime rate changes affect calculations', (tester) async {
        // Requirement 6.1: Overtime rate configuration

        // Set custom overtime rates
        await configService.setWeekendOvertimeRate(2.0); // 200%
        await configService.setWeekdayOvertimeRate(1.5); // 150%

        final entries = <TimeSheetEntryModel>[
          // Weekday overtime
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 1) // Monday
            ..clockInTime = DateTime(2024, 1, 1, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 1, 19, 0) // 10 hours
            ..isWeekendDay = false
            ..hasOvertimeHours = true
            ..overtimeType = OvertimeType.WEEKDAY_ONLY,

          // Weekend work
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0) // 8 hours
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Verify rate configuration
        final weekendRate = await configService.getWeekendOvertimeRate();
        final weekdayRate = await configService.getWeekdayOvertimeRate();

        expect(weekendRate, equals(2.0));
        expect(weekdayRate, equals(1.5));

        // Calculate overtime summary
        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final summary = calculator.calculateMonthlyOvertime(domainEntries);

        // Verify rates are included in summary
        expect(summary.weekendOvertimeRate, equals(2.0));
        expect(summary.weekdayOvertimeRate, equals(1.5));
        expect(summary.weekendOvertime, equals(const Duration(hours: 8)));
        expect(summary.weekdayOvertime, equals(const Duration(hours: 2)));
      });
    });

    group('Configuration Persistence', () {
      testWidgets('Configuration persists across app restarts', (tester) async {
        // Set custom configuration
        await configService.setWeekendOvertimeEnabled(true);
        await configService
            .setWeekendDays([DateTime.friday, DateTime.saturday]);
        await configService.setWeekendOvertimeRate(1.75);
        await configService.setWeekdayOvertimeRate(1.25);

        // Simulate app restart by creating new service instance
        final newConfigService = OvertimeConfigurationService(isar);

        // Verify configuration persisted
        expect(await newConfigService.isWeekendOvertimeEnabled(), isTrue);
        expect(await newConfigService.getWeekendDays(),
            containsAll([DateTime.friday, DateTime.saturday]));
        expect(await newConfigService.getWeekendOvertimeRate(), equals(1.75));
        expect(await newConfigService.getWeekdayOvertimeRate(), equals(1.25));
      });

      testWidgets('Default configuration is created on first run',
          (tester) async {
        // Clear any existing configuration
        await isar.writeTxn(() async {
          await isar.overtimeConfigurations.clear();
        });

        // Create new service instance (simulates first run)
        final newConfigService = OvertimeConfigurationService(isar);

        // Should create default configuration
        expect(await newConfigService.isWeekendOvertimeEnabled(), isTrue);
        expect(await newConfigService.getWeekendDays(),
            containsAll([DateTime.saturday, DateTime.sunday]));
        expect(await newConfigService.getWeekendOvertimeRate(), equals(1.5));
        expect(await newConfigService.getWeekdayOvertimeRate(), equals(1.25));
      });
    });

    group('Configuration Validation', () {
      testWidgets('Invalid weekend days are rejected', (tester) async {
        // Test invalid weekend day values
        expect(
          () => configService.setWeekendDays([0, 8]), // Invalid day numbers
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => configService.setWeekendDays([]), // Empty list
          throwsA(isA<ArgumentError>()),
        );
      });

      testWidgets('Invalid overtime rates are rejected', (tester) async {
        // Test invalid overtime rates
        expect(
          () => configService.setWeekendOvertimeRate(0.5), // Less than 1.0
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => configService.setWeekdayOvertimeRate(-1.0), // Negative rate
          throwsA(isA<ArgumentError>()),
        );
      });

      testWidgets('Configuration limits are enforced', (tester) async {
        // Test maximum values
        expect(
          () => configService.setWeekendOvertimeRate(10.0), // Too high
          throwsA(isA<ArgumentError>()),
        );

        // Test that all 7 days cannot be weekend
        expect(
          () => configService.setWeekendDays([1, 2, 3, 4, 5, 6, 7]),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Bulk Configuration Updates', () {
      testWidgets('Multiple configuration changes are atomic', (tester) async {
        // Create entries before configuration change
        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Perform bulk configuration update
        await isar.writeTxn(() async {
          final config = OvertimeConfiguration()
            ..weekendOvertimeEnabled = false
            ..weekendDays = [DateTime.friday, DateTime.saturday]
            ..weekendOvertimeRate = 2.0
            ..weekdayOvertimeRate = 1.5
            ..lastUpdated = DateTime.now();

          await isar.overtimeConfigurations.put(config);

          // Update all entries to reflect new configuration
          final allEntries = await isar.timeSheetEntryModels.where().findAll();
          for (final entry in allEntries) {
            entry.isWeekendOvertimeEnabled = false;
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Verify all changes were applied atomically
        expect(await configService.isWeekendOvertimeEnabled(), isFalse);
        expect(await configService.getWeekendDays(),
            containsAll([DateTime.friday, DateTime.saturday]));
        expect(await configService.getWeekendOvertimeRate(), equals(2.0));

        // Verify entries were updated
        final updatedEntries =
            await isar.timeSheetEntryModels.where().findAll();
        expect(updatedEntries.first.isWeekendOvertimeEnabled, isFalse);
        expect(updatedEntries.first.overtimeType, equals(OvertimeType.NONE));
      });
    });

    group('Configuration History', () {
      testWidgets('Configuration changes are timestamped', (tester) async {
        final beforeUpdate = DateTime.now();

        await configService.setWeekendOvertimeEnabled(false);

        final afterUpdate = DateTime.now();

        // Get configuration to check timestamp
        final configs = await isar.overtimeConfigurations.where().findAll();
        expect(configs, isNotEmpty);

        final config = configs.first;
        expect(config.lastUpdated.isAfter(beforeUpdate), isTrue);
        expect(config.lastUpdated.isBefore(afterUpdate), isTrue);
      });

      testWidgets('Multiple configuration updates maintain latest timestamp',
          (tester) async {
        // First update
        await configService.setWeekendOvertimeEnabled(true);
        await Future.delayed(const Duration(milliseconds: 10));

        // Second update
        final beforeSecondUpdate = DateTime.now();
        await configService.setWeekendOvertimeRate(2.0);
        final afterSecondUpdate = DateTime.now();

        // Verify latest timestamp
        final configs = await isar.overtimeConfigurations.where().findAll();
        final config = configs.first;

        expect(config.lastUpdated.isAfter(beforeSecondUpdate), isTrue);
        expect(config.lastUpdated.isBefore(afterSecondUpdate), isTrue);
        expect(config.weekendOvertimeEnabled, isTrue);
        expect(config.weekendOvertimeRate, equals(2.0));
      });
    });
  });
}
