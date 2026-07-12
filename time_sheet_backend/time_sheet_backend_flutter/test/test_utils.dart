import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/preference/data/models/overtime_configuration.dart';
import 'package:time_sheet/features/preference/domain/repositories/overtime_configuration_repository.dart';
import 'package:time_sheet/features/preference/domain/repositories/user_preference_repository.dart';

/// In-memory fake of [UserPreferencesRepository] for tests.
class FakeUserPreferencesRepository implements UserPreferencesRepository {
  final Map<String, String?> _prefs = {};

  @override
  Future<void> setPreference(String key, String? value) async {
    _prefs[key] = value;
  }

  @override
  Future<String?> getPreference(String key) async => _prefs[key];

  @override
  Future<void> clearAll() async {
    _prefs.clear();
  }
}

/// In-memory fake of [OvertimeConfigurationRepository] for tests.
///
/// Replaces the old Isar-backed test setup (setupTestIsar) that was removed
/// with the Isar -> PowerSync migration.
class FakeOvertimeConfigurationRepository
    implements OvertimeConfigurationRepository {
  OvertimeConfiguration? _configuration;

  @override
  Future<OvertimeConfiguration?> getConfiguration() async => _configuration;

  @override
  Future<void> saveConfiguration(OvertimeConfiguration configuration) async {
    _configuration = configuration;
  }

  /// Default test configuration.
  ///
  /// Uses 8h18 (498 min) as daily threshold — the documented app default
  /// (cf. CalculateOvertimeHoursUseCase / WeekendOvertimeCalculator) —
  /// rather than OvertimeConfiguration.defaultConfig() which is 480.
  static OvertimeConfiguration _defaultTestConfig() =>
      OvertimeConfiguration.defaultConfig()
        ..dailyWorkThresholdMinutes = 498;

  @override
  Future<OvertimeConfiguration> getOrCreateDefaultConfiguration() async {
    _configuration ??= _defaultTestConfig();
    return _configuration!;
  }

  @override
  Future<void> resetToDefault() async {
    _configuration = _defaultTestConfig();
  }

  @override
  Future<void> deleteConfiguration() async {
    _configuration = null;
  }

  @override
  Future<bool> hasConfiguration() async => _configuration != null;

  @override
  Future<void> updateConfiguration({
    bool? weekendOvertimeEnabled,
    List<int>? weekendDays,
    double? weekendOvertimeRate,
    double? weekdayOvertimeRate,
    int? dailyWorkThresholdMinutes,
    String? description,
  }) async {
    final config = await getOrCreateDefaultConfiguration();
    if (weekendOvertimeEnabled != null) {
      config.weekendOvertimeEnabled = weekendOvertimeEnabled;
    }
    if (weekendDays != null) config.weekendDays = weekendDays;
    if (weekendOvertimeRate != null) {
      config.weekendOvertimeRate = weekendOvertimeRate;
    }
    if (weekdayOvertimeRate != null) {
      config.weekdayOvertimeRate = weekdayOvertimeRate;
    }
    if (dailyWorkThresholdMinutes != null) {
      config.dailyWorkThresholdMinutes = dailyWorkThresholdMinutes;
    }
    if (description != null) config.description = description;
    config.lastUpdated = DateTime.now();
  }

  @override
  Future<Map<String, dynamic>?> exportConfiguration() async =>
      _configuration?.toMap();

  @override
  Future<void> importConfiguration(Map<String, dynamic> configMap) async {
    _configuration = OvertimeConfiguration.fromMap(configMap);
  }
}

List<TimesheetEntry> generateMockTimeSheetEntries(
    {required int monthNumber,
    required int year,
    bool includeWeekends = false}) {
  // Calculer les dates de début et de fin de la période
  final startDate = DateTime(year, monthNumber, 21);
  final endDate = DateTime(year, monthNumber + 1, 20);

  final entries = <TimesheetEntry>[];
  var currentDate = startDate;
  var id = 1;

  while (
      currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
    // Sauter les weekends si includeWeekends est false
    if (!includeWeekends &&
        (currentDate.weekday == DateTime.saturday ||
            currentDate.weekday == DateTime.sunday)) {
      currentDate = currentDate.add(const Duration(days: 1));
      continue;
    }

    final dayNames = {
      1: 'Lundi',
      2: 'Mardi',
      3: 'Mercredi',
      4: 'Jeudi',
      5: 'Vendredi',
      6: 'Samedi',
      7: 'Dimanche',
    };

    final monthNames = {
      1: 'Jan',
      2: 'Feb',
      3: 'Mar',
      4: 'Apr',
      5: 'May',
      6: 'Jun',
      7: 'Jul',
      8: 'Aug',
      9: 'Sep',
      10: 'Oct',
      11: 'Nov',
      12: 'Dec'
    };

    // Formater la date comme "dd-MMM-yy"
    final formattedDate = '${currentDate.day.toString().padLeft(2, '0')}-'
        '${monthNames[currentDate.month]}-'
        '${currentDate.year.toString().substring(2)}';

    entries.add(
      TimesheetEntry(
        id: id,
        dayDate: formattedDate,
        dayOfWeekDate: dayNames[currentDate.weekday]!,
        startMorning: '09:00',
        endMorning: '12:00',
        startAfternoon: '13:00',
        endAfternoon: '18:00',
        absenceReason: null,
        period: null,
      ),
    );

    id++;
    currentDate = currentDate.add(const Duration(days: 1));
  }

  return entries;
}
