import 'dart:typed_data';
import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_usecase.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_params.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_signature_usecase.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import '../entities/validation_request.dart';
import '../repositories/validation_repository.dart';

/// Use case pour approuver une demande de validation
class ApproveValidationUseCase implements UseCase<ValidationRequest, ApproveValidationParams> {
  final ValidationRepository repository;
  final GeneratePdfUseCase generatePdfUseCase;
  final GetSignatureUseCase getSignatureUseCase;
  final GetUserPreferenceUseCase getUserPreferenceUseCase;
  
  const ApproveValidationUseCase(
    this.repository,
    this.generatePdfUseCase,
    this.getSignatureUseCase,
    this.getUserPreferenceUseCase,
  );
  
  @override
  Future<Either<Failure, ValidationRequest>> call(ApproveValidationParams params) async {
    try {
      // Récupérer la validation pour avoir les détails
      final validationResult = await repository.getValidationRequest(params.validationId);
      if (validationResult.isLeft()) {
        return validationResult;
      }
      
      final validation = validationResult.fold(
        (failure) => throw Exception('Validation not found: ${failure.message}'),
        (validation) => validation,
      );
      
      // Extraire le mois et l'année de la période
      final month = validation.periodStart.month;
      final year = validation.periodStart.year;
      
      // Récupérer le nom du manager depuis les préférences
      final firstName = await getUserPreferenceUseCase.execute('firstName') ?? '';
      final lastName = await getUserPreferenceUseCase.execute('lastName') ?? '';
      final managerName = '$firstName $lastName'.trim();
      
      logger.i('🔐 Génération du PDF signé côté client');
      logger.i('   - Validation ID: ${params.validationId}');
      logger.i('   - Manager: $managerName');
      logger.i('   - Période: $month/$year');
      
      // Récupérer la signature du manager depuis Isar
      final managerSignatureBytes = await getSignatureUseCase.execute();
      String? managerSignatureBase64;
      if (managerSignatureBytes != null) {
        managerSignatureBase64 = base64Encode(managerSignatureBytes);
        logger.i('   - Signature récupérée depuis Isar: ${managerSignatureBase64.length} caractères');
      } else {
        logger.w('   - Aucune signature trouvée dans Isar');
      }
      
      // Générer le PDF avec la signature
      final pdfParams = GeneratePdfParams(
        monthNumber: month,
        year: year,
        managerSignature: managerSignatureBase64,
        managerName: managerName,
      );
      
      final pdfResult = await generatePdfUseCase.call(pdfParams);
      
      if (pdfResult.isLeft()) {
        logger.e('Erreur lors de la génération du PDF');
        return Left(pdfResult.fold((l) => l, (r) => GeneralFailure('Unknown error')));
      }
      
      final pdfBytes = pdfResult.fold(
        (failure) => throw Exception('PDF generation failed: ${failure.message}'),
        (bytes) => bytes,
      );
      logger.i('   - PDF généré avec succès: ${pdfBytes.length} octets');
      
      // Envoyer le PDF signé au serveur avec l'approbation
      return await repository.approveValidationWithSignedPdf(
        validationId: params.validationId,
        signedPdfBytes: pdfBytes,
        managerName: managerName,
        comment: params.comment,
      );
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

