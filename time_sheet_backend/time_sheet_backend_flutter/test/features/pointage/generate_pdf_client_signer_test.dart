import 'package:flutter_test/flutter_test.dart';

import 'package:time_sheet/features/pointage/domain/repositories/timesheet_repository.dart';
import 'package:time_sheet/features/pointage/domain/services/anomaly_detection_service.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/calculate_overtime_hours_use_case.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_usecase.dart';
import 'package:time_sheet/features/preference/domain/repositories/overtime_configuration_repository.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_signature_usecase.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';

import '../../test_utils.dart';

class _FakeTimesheetRepository extends Fake implements TimesheetRepository {}

class _FakeAnomalyDetectionService extends Fake
    implements AnomalyDetectionService {}

class _FakeCalculateOvertimeHoursUseCase extends Fake
    implements CalculateOvertimeHoursUseCase {}

class _FakeOvertimeConfigRepository extends Fake
    implements OvertimeConfigurationRepository {}

Future<GeneratePdfUseCase> _buildUseCase(
    {String? clientSignerPreference}) async {
  final preferencesRepository = FakeUserPreferencesRepository();
  if (clientSignerPreference != null) {
    await preferencesRepository.setPreference(
        'clientSignerName', clientSignerPreference);
  }
  return GeneratePdfUseCase(
    repository: _FakeTimesheetRepository(),
    getSignatureUseCase: GetSignatureUseCase(preferencesRepository),
    getUserPreferenceUseCase: GetUserPreferenceUseCase(preferencesRepository),
    anomalyDetectionService: _FakeAnomalyDetectionService(),
    calculateOvertimeHoursUseCase: _FakeCalculateOvertimeHoursUseCase(),
    configRepository: _FakeOvertimeConfigRepository(),
  );
}

void main() {
  group('GeneratePdfUseCase.resolveClientSignerName', () {
    test('priorité au nom explicite quand il est non vide', () async {
      final useCase = await _buildUseCase(
        clientSignerPreference: 'Nom Depuis Préférence',
      );

      final result = await useCase.resolveClientSignerName('Nom Explicite');

      expect(result, 'Nom Explicite');
    });

    test('le nom explicite est nettoyé (trim)', () async {
      final useCase = await _buildUseCase();

      final result =
          await useCase.resolveClientSignerName('  Nom Explicite  ');

      expect(result, 'Nom Explicite');
    });

    test('repli sur la préférence clientSignerName si le nom est null',
        () async {
      final useCase = await _buildUseCase(
        clientSignerPreference: 'Nom Depuis Préférence',
      );

      final result = await useCase.resolveClientSignerName(null);

      expect(result, 'Nom Depuis Préférence');
    });

    test('repli sur la préférence si le nom explicite est vide ou blanc',
        () async {
      final useCase = await _buildUseCase(
        clientSignerPreference: 'Nom Depuis Préférence',
      );

      expect(
          await useCase.resolveClientSignerName(''), 'Nom Depuis Préférence');
      expect(await useCase.resolveClientSignerName('   '),
          'Nom Depuis Préférence');
    });

    test('chaîne vide quand ni nom explicite ni préférence', () async {
      final useCase = await _buildUseCase();

      final result = await useCase.resolveClientSignerName(null);

      expect(result, '');
    });

    test('chaîne vide quand la préférence ne contient que des espaces',
        () async {
      final useCase = await _buildUseCase(clientSignerPreference: '   ');

      final result = await useCase.resolveClientSignerName(null);

      expect(result, '');
    });
  });
}
