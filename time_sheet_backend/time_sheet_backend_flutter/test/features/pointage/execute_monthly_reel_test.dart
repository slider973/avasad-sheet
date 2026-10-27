import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/calculate_overtime_hours_use_case.dart';
import 'package:time_sheet/features/preference/data/models/overtime_configuration.dart';
import 'package:time_sheet/features/preference/domain/repositories/overtime_configuration_repository.dart';

/// Test d'INTÉGRATION du vrai `executeMonthly()`.
///
/// Le test précédent (coherence_mensuel_hebdo_test.dart) ne refaisait que
/// l'arithmétique à la main : il passait alors même que le PDF restait faux.
/// Celui-ci instancie le use case réel avec les 22 entrées de la période
/// 21/09→20/10/2026 et vérifie ce que la méthode RETOURNE vraiment.
class _FakeConfigRepository implements OvertimeConfigurationRepository {
  _FakeConfigRepository(this.thresholdMinutes);

  final int thresholdMinutes;

  @override
  Future<OvertimeConfiguration> getOrCreateDefaultConfiguration() async =>
      OvertimeConfiguration.defaultConfig().copyWith(
        dailyWorkThresholdMinutes: thresholdMinutes,
      );

  @override
  Future<OvertimeConfiguration?> getConfiguration() async =>
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
  Future<Map<String, dynamic>?> exportConfiguration() async => null;

  @override
  Future<void> importConfiguration(Map<String, dynamic> configMap) async {}

  @override
  Future<void> updateConfiguration({
    bool? weekendOvertimeEnabled,
    List<int>? weekendDays,
    double? weekendOvertimeRate,
    double? weekdayOvertimeRate,
    int? dailyWorkThresholdMinutes,
    String? description,
  }) async {}
}

TimesheetEntry _entry({
  required String date,
  String startMorning = '',
  String endMorning = '',
  String startAfternoon = '',
  String endAfternoon = '',
  String? absenceReason,
  String? period,
}) {
  final d = DateTime.parse(date);
  const jours = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche'
  ];
  return TimesheetEntry(
    dayDate: '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-${d.year}',
    dayOfWeekDate: jours[d.weekday - 1],
    startMorning: startMorning,
    endMorning: endMorning,
    startAfternoon: startAfternoon,
    endAfternoon: endAfternoon,
    absenceReason: absenceReason,
    period: period,
    isWeekendDay: d.weekday > 5,
  );
}

/// Les 22 jours réellement en base pour la période de paie 21/09 → 20/10/2026.
List<TimesheetEntry> _periodeReelle() => [
      _entry(
          date: '2026-09-21',
          absenceReason: 'Jour férié',
          period: 'Journée complète'),
      _entry(
          date: '2026-09-22',
          startMorning: '07:42',
          endMorning: '12:11',
          startAfternoon: '13:14',
          endAfternoon: '17:03'),
      _entry(
          date: '2026-09-23',
          startMorning: '08:05',
          endMorning: '12:18',
          startAfternoon: '13:18',
          endAfternoon: '17:23'),
      // Congé le matin, 5h00 travaillées l'après-midi → seuil 4h09, +51 min.
      _entry(
          date: '2026-09-24',
          startAfternoon: '13:30',
          endAfternoon: '18:30',
          absenceReason: 'Congés',
          period: 'Demi journée'),
      _entry(
          date: '2026-09-25',
          startMorning: '07:28',
          endMorning: '12:09',
          startAfternoon: '13:15',
          endAfternoon: '16:52'),
      _entry(
          date: '2026-09-28',
          startMorning: '08:33',
          endMorning: '12:25',
          startAfternoon: '13:26',
          endAfternoon: '17:52'),
      _entry(
          date: '2026-09-29',
          startMorning: '07:55',
          endMorning: '12:07',
          startAfternoon: '13:19',
          endAfternoon: '17:25'),
      _entry(
          date: '2026-09-30',
          startMorning: '08:17',
          endMorning: '12:22',
          startAfternoon: '13:26',
          endAfternoon: '17:39'),
      _entry(
          date: '2026-10-01',
          startMorning: '07:34',
          endMorning: '12:14',
          startAfternoon: '13:21',
          endAfternoon: '16:59'),
      _entry(
          date: '2026-10-02',
          startMorning: '08:47',
          endMorning: '12:29',
          startAfternoon: '13:29',
          endAfternoon: '18:05'),
      _entry(
          date: '2026-10-05',
          startMorning: '07:19',
          endMorning: '12:05',
          startAfternoon: '13:15',
          endAfternoon: '16:47'),
      _entry(
          date: '2026-10-06',
          startMorning: '08:11',
          endMorning: '12:20',
          startAfternoon: '13:22',
          endAfternoon: '17:31'),
      _entry(
          date: '2026-10-07',
          startMorning: '07:48',
          endMorning: '12:16',
          startAfternoon: '13:24',
          endAfternoon: '17:14'),
      _entry(
          date: '2026-10-08',
          startMorning: '08:26',
          endMorning: '12:13',
          startAfternoon: '13:18',
          endAfternoon: '17:49'),
      _entry(
          date: '2026-10-09',
          startMorning: '08:02',
          endMorning: '12:27',
          startAfternoon: '13:28',
          endAfternoon: '17:21'),
      _entry(
          date: '2026-10-12',
          startMorning: '07:10',
          endMorning: '12:00',
          startAfternoon: '12:30',
          endAfternoon: '16:23'),
      _entry(
          date: '2026-10-13',
          startMorning: '08:05',
          endMorning: '12:00',
          startAfternoon: '13:21',
          endAfternoon: '16:00'),
      _entry(
          date: '2026-10-14',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:13'),
      _entry(
          date: '2026-10-15',
          startMorning: '07:24',
          endMorning: '12:00',
          startAfternoon: '13:30',
          endAfternoon: '18:39'),
      _entry(
          date: '2026-10-16',
          absenceReason: 'Congés',
          period: 'Journée complète'),
      _entry(
          date: '2026-10-19',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:30',
          endAfternoon: '17:23'),
      _entry(
          date: '2026-10-20',
          startMorning: '07:00',
          endMorning: '12:00',
          startAfternoon: '13:30',
          endAfternoon: '16:51'),
    ];

void main() {
  test('executeMonthly retourne 32 min sur la période réelle', () async {
    final useCase = CalculateOvertimeHoursUseCase(
      configRepository: _FakeConfigRepository(498),
    );

    final result = await useCase.executeMonthly(
      entries: _periodeReelle(),
      normalHoursThreshold: 8.3, // = 498 min, valeur de la préférence
    );

    expect(result.totalOvertime, const Duration(minutes: 32),
        reason: 'c\'est la valeur attendue par le client et affichée '
            'par les colonnes hebdomadaires du PDF');
  });

  test('le résultat est > 0, donc la ligne PDF est rendue', () async {
    final useCase = CalculateOvertimeHoursUseCase(
      configRepository: _FakeConfigRepository(498),
    );

    final result = await useCase.executeMonthly(
      entries: _periodeReelle(),
      normalHoursThreshold: 8.3,
    );

    // Condition exacte de _buildMonthTotal() dans generate_pdf_usecase.dart.
    expect(result.totalOvertime > Duration.zero, isTrue,
        reason: 'sinon « Heures supplémentaires » est masquée sans erreur');
  });

  test('une config à 480 ne change plus le résultat (seuil = paramètre)',
      () async {
    // Régression : le seuil doit venir du PARAMÈTRE, plus de la config.
    // Avant le correctif, une config à 480 faisait diverger le total mensuel
    // des colonnes hebdomadaires.
    final useCase = CalculateOvertimeHoursUseCase(
      configRepository: _FakeConfigRepository(480),
    );

    final result = await useCase.executeMonthly(
      entries: _periodeReelle(),
      normalHoursThreshold: 8.3,
    );

    expect(result.totalOvertime, const Duration(minutes: 32),
        reason: 'la config ne doit plus influencer le seuil journalier');
  });
}
