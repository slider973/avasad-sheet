import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:time_sheet/features/preference/data/models/overtime_configuration.dart';
import 'package:time_sheet/features/preference/domain/repositories/overtime_configuration_repository.dart';
import 'package:time_sheet/services/overtime_configuration_service.dart';

/// Mock implementation of OvertimeConfigurationRepository for testing
class MockOvertimeConfigurationRepository
    implements OvertimeConfigurationRepository {
  OvertimeConfiguration? _configuration;

  @override
  Future<OvertimeConfiguration?> getConfiguration() async {
    return _configuration;
  }

  @override
  Future<void> saveConfiguration(OvertimeConfiguration configuration) async {
    configuration.validate();
    _configuration = configuration;
  }

  @override
  Future<OvertimeConfiguration> getOrCreateDefaultConfiguration() async {
    if (_configuration != null) {
      return _configuration!;
    }

    _configuration = OvertimeConfiguration.defaultConfig();
    return _configuration!;
  }

  @override
  Future<void> resetToDefault() async {
    _configuration = OvertimeConfiguration.defaultConfig();
  }

  @override
  Future<void> deleteConfiguration() async {
    _configuration = null;
  }

  @override
  Future<bool> hasConfiguration() async {
    return _configuration != null;
  }

  @override
  Future<void> updateConfiguration({
    bool? weekendOvertimeEnabled,
    List<int>? weekendDays,
    double? weekendOvertimeRate,
    double? weekdayOvertimeRate,
    int? dailyWorkThresholdMinutes,
    String? description,
  }) async {
    final existing = await getOrCreateDefaultConfiguration();

    final updated = existing.copyWith(
      weekendOvertimeEnabled: weekendOvertimeEnabled,
      weekendDays: weekendDays,
      weekendOvertimeRate: weekendOvertimeRate,
      weekdayOvertimeRate: weekdayOvertimeRate,
      dailyWorkThresholdMinutes: dailyWorkThresholdMinutes,
      description: description,
    );

    await saveConfiguration(updated);
  }

  @override
  Future<Map<String, dynamic>?> exportConfiguration() async {
    return _configuration?.toMap();
  }

  @override
  Future<void> importConfiguration(Map<String, dynamic> configMap) async {
    final config = OvertimeConfiguration.fromMap(configMap);
    await saveConfiguration(config);
  }
}

void main() {
  late OvertimeConfigurationService service;
  late MockOvertimeConfigurationRepository mockRepository;

  setUpAll(() async {
    // Set up dependency injection with mock repository
    mockRepository = MockOvertimeConfigurationRepository();
    GetIt.instance
        .registerSingleton<OvertimeConfigurationRepository>(mockRepository);
    service = OvertimeConfigurationService();
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  setUp(() async {
    // Clear repository before each test
    await mockRepository.deleteConfiguration();
    service.clearCache();
  });

  group('OvertimeConfigurationService', () {
    test('should return default values when no configuration exists', () async {
      expect(await service.isWeekendOvertimeEnabled(), true);
      expect(
          await service.getWeekendDays(), [DateTime.saturday, DateTime.sunday]);
      expect(await service.getWeekendOvertimeRate(), 1.5);
      expect(await service.getWeekdayOvertimeRate(), 1.25);
      expect(await service.getDailyWorkThreshold(), Duration(minutes: 480));
    });

    test('should save and retrieve weekend overtime enabled setting', () async {
      await service.setWeekendOvertimeEnabled(false);
      expect(await service.isWeekendOvertimeEnabled(), false);

      await service.setWeekendOvertimeEnabled(true);
      expect(await service.isWeekendOvertimeEnabled(), true);
    });

    test('should save and retrieve weekend days configuration', () async {
      final customWeekendDays = [DateTime.friday, DateTime.saturday];
      await service.setWeekendDays(customWeekendDays);
      expect(await service.getWeekendDays(), customWeekendDays);
    });

    test('should save and retrieve weekend overtime rate', () async {
      await service.setWeekendOvertimeRate(2.0);
      expect(await service.getWeekendOvertimeRate(), 2.0);
    });

    test('should save and retrieve weekday overtime rate', () async {
      await service.setWeekdayOvertimeRate(1.5);
      expect(await service.getWeekdayOvertimeRate(), 1.5);
    });

    test('should save and retrieve daily work threshold', () async {
      final threshold = Duration(hours: 7);
      await service.setDailyWorkThreshold(threshold);
      expect(await service.getDailyWorkThreshold(), threshold);
    });

    test('should reset to default values', () async {
      // Change some values
      await service.setWeekendOvertimeEnabled(false);
      await service.setWeekendOvertimeRate(3.0);
      await service.setWeekdayOvertimeRate(2.0);

      // Reset to defaults
      await service.resetToDefaults();

      // Verify default values are restored
      expect(await service.isWeekendOvertimeEnabled(), true);
      expect(await service.getWeekendOvertimeRate(), 1.5);
      expect(await service.getWeekdayOvertimeRate(), 1.25);
    });

    test('should export and import configuration', () async {
      // Set custom configuration
      await service.setWeekendOvertimeEnabled(false);
      await service.setWeekendOvertimeRate(2.5);
      await service.setWeekdayOvertimeRate(1.75);

      // Export configuration
      final exported = await service.exportConfiguration();
      expect(exported, isNotNull);

      // Reset to defaults
      await service.resetToDefaults();

      // Import configuration
      await service.importConfiguration(exported!);

      // Verify imported values
      expect(await service.isWeekendOvertimeEnabled(), false);
      expect(await service.getWeekendOvertimeRate(), 2.5);
      expect(await service.getWeekdayOvertimeRate(), 1.75);
    });

    test('should get all configuration as map', () async {
      final config = await service.getAllConfiguration();

      expect(config['weekendOvertimeEnabled'], true);
      expect(config['weekendDays'], [DateTime.saturday, DateTime.sunday]);
      expect(config['weekendOvertimeRate'], 1.5);
      expect(config['weekdayOvertimeRate'], 1.25);
      expect(config['dailyWorkThresholdMinutes'], 480);
    });

    test('should handle configuration object operations', () async {
      final configObject = await service.getConfigurationObject();
      expect(configObject.weekendOvertimeEnabled, true);
      expect(configObject.weekendOvertimeRate, 1.5);

      // Modify and save
      final modified = configObject.copyWith(
        weekendOvertimeEnabled: false,
        weekendOvertimeRate: 2.0,
      );
      await service.saveConfiguration(modified);

      // Verify changes
      expect(await service.isWeekendOvertimeEnabled(), false);
      expect(await service.getWeekendOvertimeRate(), 2.0);
    });

    test('should clear cache correctly', () async {
      // Get configuration to populate cache
      await service.isWeekendOvertimeEnabled();

      // Modify configuration directly in repository
      await mockRepository.updateConfiguration(weekendOvertimeEnabled: false);

      // Should still return cached value
      expect(await service.isWeekendOvertimeEnabled(), true);

      // Clear cache
      service.clearCache();

      // Should now return updated value
      expect(await service.isWeekendOvertimeEnabled(), false);
    });
  });

  group('OvertimeConfiguration model validation', () {
    test('should validate weekend days correctly', () {
      final config = OvertimeConfiguration.defaultConfig();

      // Valid configuration should not throw
      expect(() => config.validate(), returnsNormally);

      // Invalid weekend days should throw
      config.weekendDays = [8]; // Invalid day
      expect(() => config.validate(), throwsA(isA<ArgumentError>()));

      config.weekendDays = []; // Empty list
      expect(() => config.validate(), throwsA(isA<ArgumentError>()));

      config.weekendDays = [1, 1]; // Duplicates
      expect(() => config.validate(), throwsA(isA<ArgumentError>()));

      config.weekendDays = [1, 2, 3, 4, 5, 6, 7]; // All days
      expect(() => config.validate(), throwsA(isA<ArgumentError>()));
    });

    test('should validate overtime rates correctly', () {
      final config = OvertimeConfiguration.defaultConfig();

      // Invalid weekend overtime rate
      config.weekendOvertimeRate = 0.5; // Less than 1.0
      expect(() => config.validate(), throwsA(isA<ArgumentError>()));

      config.weekendOvertimeRate = -1.0; // Negative
      expect(() => config.validate(), throwsA(isA<ArgumentError>()));

      config.weekendOvertimeRate = 15.0; // Too high
      expect(() => config.validate(), throwsA(isA<ArgumentError>()));

      // Reset to valid value
      config.weekendOvertimeRate = 1.5;

      // Invalid weekday overtime rate
      config.weekdayOvertimeRate = 0.5; // Less than 1.0
      expect(() => config.validate(), throwsA(isA<ArgumentError>()));

      config.weekdayOvertimeRate = 15.0; // Too high
      expect(() => config.validate(), throwsA(isA<ArgumentError>()));
    });

    test('should validate daily work threshold correctly', () {
      final config = OvertimeConfiguration.defaultConfig();

      // Invalid daily work threshold
      config.dailyWorkThresholdMinutes = 30; // Too short
      expect(() => config.validate(), throwsA(isA<ArgumentError>()));

      config.dailyWorkThresholdMinutes = 1500; // Too long (25 hours)
      expect(() => config.validate(), throwsA(isA<ArgumentError>()));

      // Valid threshold should not throw
      config.dailyWorkThresholdMinutes = 480; // 8 hours
      expect(() => config.validate(), returnsNormally);
    });

    test('should handle copyWith correctly', () {
      final original = OvertimeConfiguration.defaultConfig();

      final modified = original.copyWith(
        weekendOvertimeEnabled: false,
        weekendOvertimeRate: 2.0,
      );

      expect(modified.weekendOvertimeEnabled, false);
      expect(modified.weekendOvertimeRate, 2.0);
      expect(modified.weekdayOvertimeRate,
          original.weekdayOvertimeRate); // Unchanged
      expect(modified.weekendDays, original.weekendDays); // Unchanged
    });

    test('should handle toMap and fromMap correctly', () {
      final original = OvertimeConfiguration.defaultConfig();
      original.description = 'Test configuration';

      final map = original.toMap();
      final restored = OvertimeConfiguration.fromMap(map);

      expect(restored.weekendOvertimeEnabled, original.weekendOvertimeEnabled);
      expect(restored.weekendDays, original.weekendDays);
      expect(restored.weekendOvertimeRate, original.weekendOvertimeRate);
      expect(restored.weekdayOvertimeRate, original.weekdayOvertimeRate);
      expect(restored.dailyWorkThresholdMinutes,
          original.dailyWorkThresholdMinutes);
      expect(restored.description, original.description);
    });
  });
}
