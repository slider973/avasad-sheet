import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import 'package:time_sheet/features/validation/domain/services/validation_overtime_analyzer.dart';
import 'package:time_sheet/features/validation/domain/services/validation_notification_service.dart';
import '../entities/validation_request.dart';
import '../repositories/validation_repository.dart';

/// Use case pour approuver une demande de validation.
/// Stratégie : met à jour le statut + stocke la signature manager en BDD.
/// Le PDF original (avec signature employé intégrée) reste intact dans Storage.
class ApproveValidationUseCase
    implements UseCase<ValidationRequest, ApproveValidationParams> {
  final ValidationRepository repository;
  final GetUserPreferenceUseCase getUserPreferenceUseCase;
  final ValidationOvertimeAnalyzer _overtimeAnalyzer;
  final ValidationNotificationService _notificationService;

  ApproveValidationUseCase(
    this.repository,
    this.getUserPreferenceUseCase, {
    ValidationOvertimeAnalyzer? overtimeAnalyzer,
    ValidationNotificationService? notificationService,
  })  : _overtimeAnalyzer = overtimeAnalyzer ?? ValidationOvertimeAnalyzer(),
        _notificationService =
            notificationService ?? ValidationNotificationService();

  @override
  Future<Either<Failure, ValidationRequest>> call(
      ApproveValidationParams params) async {
    try {
      logger.i('Début du processus d\'approbation');
      logger.i('   - Validation ID: ${params.validationId}');

      // Approuver la validation (met à jour le statut + stocke la signature manager en BDD)
      // Le PDF original (avec signature employé) reste intact dans Storage
      final approvalResult = await repository.approveValidation(
        validationId: params.validationId,
        managerSignature: params.managerSignature,
        comment: params.comment,
      );

      // Analyser les heures sup et envoyer les notifications si succès
      if (approvalResult.isRight()) {
        try {
          final dataResult =
              await repository.getValidationTimesheetData(params.validationId);

          if (dataResult.isRight()) {
            final data = dataResult.fold(
              (failure) => <String, dynamic>{},
              (data) => data,
            );

            final overtimeSummary =
                await _overtimeAnalyzer.analyzeTimesheetData(data);

            final firstName =
                await getUserPreferenceUseCase.execute('firstName') ?? '';
            final lastName =
                await getUserPreferenceUseCase.execute('lastName') ?? '';
            final managerName = '$firstName $lastName'.trim();

            final approvedValidation = approvalResult.fold(
              (failure) => throw Exception('Approval failed'),
              (validation) => validation,
            );

            await _notificationService.notifyValidationApproved(
              validation: approvedValidation,
              overtimeSummary: overtimeSummary,
              managerName: managerName,
            );
          }
        } catch (e) {
          logger.w('Notification après approbation échouée: $e');
        }
      }

      return approvalResult;
    } catch (e) {
      logger.e('Erreur lors de l\'approbation', error: e);
      return Left(GeneralFailure('Erreur lors de l\'approbation: $e'));
    }
  }
}

/// Paramètres pour approuver une validation
class ApproveValidationParams {
  final String validationId;
  final String managerSignature;
  final String? comment;

  const ApproveValidationParams({
    required this.validationId,
    required this.managerSignature,
    this.comment,
  });
}
