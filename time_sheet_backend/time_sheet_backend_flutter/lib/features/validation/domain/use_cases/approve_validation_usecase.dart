import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_usecase.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_signature_usecase.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import 'package:time_sheet/features/validation/domain/services/validation_overtime_analyzer.dart';
import 'package:time_sheet/features/validation/domain/services/validation_notification_service.dart';
import 'package:time_sheet/services/overtime_configuration_service.dart';
import '../entities/validation_request.dart';
import '../repositories/validation_repository.dart';

/// Use case pour approuver une demande de validation
class ApproveValidationUseCase
    implements UseCase<ValidationRequest, ApproveValidationParams> {
  final ValidationRepository repository;
  final GeneratePdfUseCase generatePdfUseCase;
  final GetSignatureUseCase getSignatureUseCase;
  final GetUserPreferenceUseCase getUserPreferenceUseCase;
  final ValidationOvertimeAnalyzer _overtimeAnalyzer;
  final OvertimeConfigurationService _overtimeConfigService;
  final ValidationNotificationService _notificationService;

  ApproveValidationUseCase(
    this.repository,
    this.generatePdfUseCase,
    this.getSignatureUseCase,
    this.getUserPreferenceUseCase, {
    ValidationOvertimeAnalyzer? overtimeAnalyzer,
    OvertimeConfigurationService? overtimeConfigService,
    ValidationNotificationService? notificationService,
  })  : _overtimeAnalyzer = overtimeAnalyzer ?? ValidationOvertimeAnalyzer(),
        _overtimeConfigService =
            overtimeConfigService ?? OvertimeConfigurationService(),
        _notificationService =
            notificationService ?? ValidationNotificationService();

  @override
  Future<Either<Failure, ValidationRequest>> call(
      ApproveValidationParams params) async {
    try {
      logger.i('🔐 Début du processus d\'approbation');
      logger.i('   - Validation ID: ${params.validationId}');

      // Récupérer le nom et la signature du manager depuis les préférences
      final firstName =
          await getUserPreferenceUseCase.execute('firstName') ?? '';
      final lastName = await getUserPreferenceUseCase.execute('lastName') ?? '';
      final managerName = '$firstName $lastName'.trim();

      logger.i('   - Manager: $managerName');

      // Récupérer la signature du manager
      final managerSignatureStr =
          await getUserPreferenceUseCase.execute('signature');
      if (managerSignatureStr == null ||
          managerSignatureStr.toString().isEmpty) {
        logger.e('❌ Le manager n\'a pas de signature configurée');
        return Left(ValidationFailure(
            'Veuillez configurer votre signature dans les paramètres'));
      }

      logger.i(
          '✅ Signature du manager trouvée: ${managerSignatureStr.toString().length} caractères');

      // Récupérer les données timesheet de la validation depuis le serveur
      final dataResult =
          await repository.getValidationTimesheetData(params.validationId);

      if (dataResult.isLeft()) {
        logger.e('Erreur lors de la récupération des données timesheet');
        return Left(
            dataResult.fold((l) => l, (r) => GeneralFailure('Unknown error')));
      }

      final data = dataResult.fold(
        (failure) =>
            throw Exception('Failed to get timesheet data: ${failure.message}'),
        (data) => data,
      );

      // Analyser les heures supplémentaires weekend
      logger.i('🔍 Analyse des heures supplémentaires weekend');
      final overtimeSummary =
          await _overtimeAnalyzer.analyzeTimesheetData(data);

      logger.i(
          '   - Heures weekend: ${overtimeSummary.formattedWeekendOvertime}');
      logger.i(
          '   - Heures semaine: ${overtimeSummary.formattedWeekdayOvertime}');
      logger.i(
          '   - Jours weekend travaillés: ${overtimeSummary.weekendDaysWorked}');

      // Valider les taux de majoration
      final currentWeekendRate =
          await _overtimeConfigService.getWeekendOvertimeRate();
      final currentWeekdayRate =
          await _overtimeConfigService.getWeekdayOvertimeRate();

      if (overtimeSummary.weekendOvertimeRate != currentWeekendRate) {
        logger.w(
            '⚠️ Taux weekend différent: ${overtimeSummary.weekendOvertimeRate} vs $currentWeekendRate');
      }

      if (overtimeSummary.weekdayOvertimeRate != currentWeekdayRate) {
        logger.w(
            '⚠️ Taux semaine différent: ${overtimeSummary.weekdayOvertimeRate} vs $currentWeekdayRate');
      }

      // Vérifier les heures weekend exceptionnelles
      if (_overtimeAnalyzer.hasExceptionalWeekendHours(overtimeSummary)) {
        logger.w('⚠️ Heures weekend exceptionnelles détectées');
        final alert = _overtimeAnalyzer.generateWeekendAlert(overtimeSummary);
        if (alert != null) {
          logger.w('   - Alerte: $alert');
        }
      }

      logger.i('📄 Génération du PDF signé avec les données de la validation');
      logger.i('   - Mois/Année: ${data['month']}/${data['year']}');
      logger.i('   - Employé: ${data['employeeName']}');
      logger.i(
          '   - Total heures supplémentaires: ${overtimeSummary.formattedTotalOvertime}');

      // Récupérer la signature de l'employé depuis les données timesheet
      String? employeeSignatureBase64 = data['employeeSignature'] as String?;
      if (employeeSignatureBase64 != null) {
        logger.i(
            '   - Signature employé récupérée: ${employeeSignatureBase64.length} caractères');
      } else {
        logger.w('   - Pas de signature employé dans les données');
      }

      // Convertir les entries JSON en List<TimesheetEntry> pour générer le PDF
      final entriesJson = data['entries'] as List<dynamic>;
      final List<Map<String, dynamic>> entries =
          entriesJson.map((e) => e as Map<String, dynamic>).toList();

      // Générer le PDF avec TOUTES les données et les DEUX signatures
      final pdfResult = await generatePdfUseCase.generateFromEntries(
        entries: entries.map((entry) {
          // Convertir en TimesheetEntry pour la génération PDF
          return TimesheetEntry(
            dayDate: entry['dayDate'] ?? '',
            dayOfWeekDate: '', // Sera recalculé dans generatePdfUseCase
            startMorning: entry['startMorning'] ?? '',
            endMorning: entry['endMorning'] ?? '',
            startAfternoon: entry['startAfternoon'] ?? '',
            endAfternoon: entry['endAfternoon'] ?? '',
            absence: null, // Géré séparément
            absenceReason: entry['absenceReason'],
            hasOvertimeHours: entry['hasOvertimeHours'] ?? false,
            period: entry['period'] ?? '',
          );
        }).toList(),
        monthNumber: data['month'] as int,
        year: data['year'] as int,
        employeeSignature: employeeSignatureBase64, // Signature de l'employé
        managerSignature: managerSignatureStr, // Signature du manager
        managerName: managerName,
      );

      if (pdfResult.isLeft()) {
        logger.e('Erreur lors de la génération du PDF');
        return Left(
            pdfResult.fold((l) => l, (r) => GeneralFailure('Unknown error')));
      }

      final pdfBytes = pdfResult.fold(
        (failure) =>
            throw Exception('PDF generation failed: ${failure.message}'),
        (bytes) => bytes,
      );

      logger.i('✅ PDF généré avec succès: ${pdfBytes.length} octets');
      logger.i(
          '   - Contient signature employé: ${employeeSignatureBase64 != null ? 'OUI' : 'NON'}');
      logger.i('   - Contient signature manager: OUI');

      // Sauvegarder la signature du manager localement pour le cache (optionnel)
      // Cela permettra de la récupérer plus tard si nécessaire

      // Envoyer le PDF signé au serveur avec l'approbation
      final approvalResult = await repository.approveValidationWithSignedPdf(
        validationId: params.validationId,
        signedPdfBytes: pdfBytes,
        managerName: managerName,
        comment: params.comment,
      );

      // Envoyer les notifications si l'approbation a réussi
      if (approvalResult.isRight()) {
        final approvedValidation = approvalResult.fold(
          (failure) => throw Exception('Approval failed: ${failure.message}'),
          (validation) => validation,
        );

        await _notificationService.notifyValidationApproved(
          validation: approvedValidation,
          overtimeSummary: overtimeSummary,
          managerName: managerName,
        );
      }

      return approvalResult;
    } catch (e) {
      logger.e('Erreur lors de l\'approbation avec PDF signé', error: e);
      // Fallback vers l'ancienne méthode sans PDF signé
      return await repository.approveValidation(
        validationId: params.validationId,
        managerSignature: params.managerSignature,
        comment: params.comment,
      );
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
