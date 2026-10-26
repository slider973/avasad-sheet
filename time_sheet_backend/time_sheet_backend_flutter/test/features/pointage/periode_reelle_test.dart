import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/calculate_overtime_hours_use_case.dart';
import 'package:time_sheet/features/preference/data/models/overtime_configuration.dart';
import 'package:time_sheet/features/preference/domain/repositories/overtime_configuration_repository.dart';

/// Config figée à 8h18 (498 min), comme la prod.
class _FakeConfigRepo implements OvertimeConfigurationRepository {
  @override
  Future<OvertimeConfiguration> getOrCreateDefaultConfiguration() async {
    final c = OvertimeConfiguration.defaultConfig();
    c.dailyWorkThresholdMinutes = 498;
    return c;
  }

  @override
  Future<OvertimeConfiguration?> getConfiguration() =>
      getOrCreateDefaultConfiguration();

  @override
  Future<void> saveConfiguration(OvertimeConfiguration configuration) async {}

  @override
  Future<void> resetToDefault() async {}

  @override
  Future<void> deleteConfiguration() async {}

  @override
  Future<bool> hasConfiguration() async => true;

  @override
  Future<void> updateConfiguration({
    bool? weekendOvertimeEnabled,
    List<int>? weekendDays,
    double? weekendOvertimeRate,
    double? weekdayOvertimeRate,
    int? dailyWorkThresholdMinutes,
    String? description,
  }) async {}

  @override
  Future<Map<String, dynamic>?> exportConfiguration() async => null;

  @override
  Future<void> importConfiguration(Map<String, dynamic> configMap) async {}
}

/// Reproduit la période de paie réelle 21/09 → 20/10/2026 (données de prod)
/// pour constater ce que `executeMonthly` renvoie comme total mensuel.
///
/// Attendu d'après le calcul SQL sur la base : +32 min d'heures supp
/// (excès 166 min, déficits 134 min).
void main() {
  TimesheetEntry e(String date, String sm, String em, String sa, String ea,
      {String? reason, String? period}) {
    return TimesheetEntry(
      id: date.hashCode,
      dayDate: date,
      dayOfWeekDate: 'Monday',
      startMorning: sm,
      endMorning: em,
      startAfternoon: sa,
      endAfternoon: ea,
      absenceReason: reason,
      period: period,
    );
  }

  test('total mensuel réel de la période 21/09 → 20/10', () async {
    final entries = <TimesheetEntry>[
      e('21-Sep-26', '', '', '', '', reason: 'Jour férié', period: 'Journée complète'),
      e('22-Sep-26', '07:42', '12:11', '13:14', '17:03', period: 'Journée complète'),
      e('23-Sep-26', '08:05', '12:18', '13:18', '17:23', period: 'Journée complète'),
      e('24-Sep-26', '', '', '13:30', '18:30', reason: 'Congés', period: 'Demi journée'),
      e('25-Sep-26', '07:28', '12:09', '13:15', '16:52', period: 'Journée complète'),
      e('28-Sep-26', '08:33', '12:25', '13:26', '17:52', period: 'Journée complète'),
      e('29-Sep-26', '07:55', '12:07', '13:19', '17:25', period: 'Journée complète'),
      e('30-Sep-26', '08:17', '12:22', '13:26', '17:39', period: 'Journée complète'),
      e('01-Oct-26', '07:34', '12:14', '13:21', '16:59', period: 'Journée complète'),
      e('02-Oct-26', '08:47', '12:29', '13:29', '18:05', period: 'Journée complète'),
      e('05-Oct-26', '07:19', '12:05', '13:15', '16:47', period: 'Journée complète'),
      e('06-Oct-26', '08:11', '12:20', '13:22', '17:31', period: 'Journée complète'),
      e('07-Oct-26', '07:48', '12:16', '13:24', '17:14', period: 'Journée complète'),
      e('08-Oct-26', '08:26', '12:13', '13:18', '17:49', period: 'Journée complète'),
      e('09-Oct-26', '08:02', '12:27', '13:28', '17:21', period: 'Journée complète'),
      e('12-Oct-26', '07:10', '12:00', '12:30', '16:23'),
      e('13-Oct-26', '08:05', '12:00', '13:21', '16:00'),
      e('14-Oct-26', '08:00', '12:00', '13:00', '17:13'),
      e('15-Oct-26', '07:24', '12:00', '13:30', '18:39'),
      e('16-Oct-26', '', '', '', '', reason: 'Congés', period: 'Journée complète'),
      e('19-Oct-26', '08:00', '12:00', '13:30', '17:23'),
      e('20-Oct-26', '07:00', '12:00', '13:30', '16:51'),
    ];

    // Somme de contrôle indépendante du use-case.
    var exces = 0, deficits = 0;
    for (final x in entries) {
      final reason = x.absenceReason ?? '';
      if (reason.isNotEmpty && x.period == 'Journée complète') continue;
      final total = x.calculateDailyTotal().inMinutes;
      if (total == 0) continue;
      final seuil = x.period == 'Demi journée' ? 249 : 498;
      final ecart = total - seuil;
      if (ecart > 0) exces += ecart;
      if (ecart < 0) deficits += -ecart;
    }
    print('CONTROLE  exces=$exces deficits=$deficits net=${exces - deficits}');

    final uc = CalculateOvertimeHoursUseCase(
      configRepository: _FakeConfigRepo(),
    );
    final r = await uc.executeMonthly(
      entries: entries,
      normalHoursThreshold: 8.3,
    );
    print('USE-CASE  totalOvertime=${r.totalOvertime.inMinutes} min');
    print('USE-CASE  overtimeByDay=${r.overtimeByDay.map((k, v) => MapEntry(k, v.inMinutes))}');

    expect(r.totalOvertime.inMinutes, 32);
  });
}
