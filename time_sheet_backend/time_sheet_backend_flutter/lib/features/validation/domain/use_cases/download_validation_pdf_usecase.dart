import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_usecase.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_signature_usecase.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import '../repositories/validation_repository.dart';
import '../entities/validation_request.dart';

/// Use case pour télécharger le PDF d'une validation.
/// Stratégie :
/// - Pending : télécharger le PDF original depuis Storage (signature employé intégrée)
/// - Approved : régénérer avec les deux signatures (employé + manager) depuis la BDD
class DownloadValidationPdfUseCase implements UseCase<Uint8List, DownloadPdfParams> {
  final ValidationRepository repository;
  final GeneratePdfUseCase generatePdfUseCase;
  final GetSignatureUseCase getSignatureUseCase;
  final GetUserPreferenceUseCase getUserPreferenceUseCase;

  const DownloadValidationPdfUseCase(
    this.repository,
    this.generatePdfUseCase,
    this.getSignatureUseCase,
    this.getUserPreferenceUseCase,
  );

  @override
  Future<Either<Failure, Uint8List>> call(DownloadPdfParams params) async {
    if (params.validationId.isEmpty) {
      return Left(ValidationFailure('L\'ID de la validation est requis'));
    }

    // Vérifier le statut de la validation pour choisir la stratégie
    final dataResult = await repository.getValidationTimesheetData(params.validationId);
    final status = dataResult.fold(
      (failure) => 'pending',
      (data) => data['status'] as String? ?? 'pending',
    );
    final signingStep = dataResult.fold(
      (failure) => '',
      (data) => data['signingStep'] as String? ?? '',
    );

    // Si approuvée OU si le manager a déjà signé (signing_step avancé à 'client' ou 'completed'),
    // régénérer avec les signatures disponibles
    if (status == 'approved' || signingStep == 'client' || signingStep == 'completed') {
      logger.i('Régénération du PDF avec signatures (status=$status, signingStep=$signingStep)');
      return _regeneratePdf(params.validationId);
    }

    // Sinon (pending/rejected), télécharger le PDF original depuis Storage
    logger.i('Téléchargement du PDF depuis Storage pour validation ${params.validationId}');
    try {
      final storageResult = await repository.downloadValidationPdf(params.validationId);

      final storedPdf = storageResult.fold(
        (failure) => null,
        (bytes) => bytes,
      );

      if (storedPdf != null && storedPdf.isNotEmpty) {
        logger.i('PDF téléchargé depuis Storage: ${storedPdf.length} octets');
        return Right(storedPdf);
      }
    } catch (e) {
      logger.w('Erreur téléchargement Storage: $e');
    }

    // Fallback : régénérer depuis les données timesheet
    logger.w('PDF Storage indisponible, régénération en fallback...');
    return _regeneratePdf(params.validationId);
  }

  /// Régénère le PDF à partir des données timesheet (fallback)
  Future<Either<Failure, Uint8List>> _regeneratePdf(String validationId) async {
    logger.i('Régénération du PDF pour validation $validationId');

    final dataResult = await repository.getValidationTimesheetData(validationId);

    if (dataResult.isLeft()) {
      return Left(dataResult.fold((l) => l, (r) => GeneralFailure('Unknown error')));
    }

    final data = dataResult.fold(
      (failure) => throw Exception('Failed to get timesheet data: ${failure.message}'),
      (data) => data,
    );

    logger.i('Données récupérées - Mois: ${data['month']}/${data['year']}, Statut: ${data['status']}');

    final employeeName = data['employeeName'] as String? ?? '';
    final employeeCompany = data['employeeCompany'] as String? ?? 'Avasad';

    // Convertir les entries JSON en List<TimesheetEntry>
    final entriesJson = data['entries'] as List<dynamic>;
    final List<TimesheetEntry> entries = entriesJson.map((entry) {
      String dayOfWeekDate = '';
      DateTime? parsedDate;
      try {
        parsedDate = DateFormat('dd-MMM-yy', 'en_US').parse(entry['dayDate'] ?? '');
        dayOfWeekDate = DateFormat('EEEE', 'fr_FR').format(parsedDate);
      } catch (e) {
        dayOfWeekDate = '';
        parsedDate = DateTime.now();
      }

      return TimesheetEntry(
        dayDate: entry['dayDate'] ?? '',
        dayOfWeekDate: dayOfWeekDate,
        startMorning: entry['startMorning'] ?? '',
        endMorning: entry['endMorning'] ?? '',
        startAfternoon: entry['startAfternoon'] ?? '',
        endAfternoon: entry['endAfternoon'] ?? '',
        absence: entry['isAbsence'] == true
            ? AbsenceEntity(
                type: AbsenceType.other,
                motif: entry['absenceReason'] ?? '',
                startDate: parsedDate ?? DateTime.now(),
                endDate: parsedDate ?? DateTime.now(),
              )
            : null,
        absenceReason: entry['absenceReason'],
        hasOvertimeHours: entry['hasOvertimeHours'] ?? false,
        period: entry['period'] ?? '',
      );
    }).toList();

    logger.i('${entries.length} entrées timesheet converties');

    // Récupérer la signature de l'employé
    String? employeeSignatureBase64 = data['employeeSignature'] as String?;

    // Préparer signature manager si le manager a déjà signé
    // (status approved OU signing_step avancé à 'client' ou 'completed')
    String? managerSignatureBase64;
    String? managerName;
    final statusString = data['status'] as String? ?? 'pending';
    final signingStepStr = data['signingStep'] as String? ?? '';
    final validationStatus = ValidationStatusExtension.fromString(statusString);

    if (validationStatus == ValidationStatus.approved || signingStepStr == 'client' || signingStepStr == 'completed') {
      managerName = data['managerName'] as String?;
      managerSignatureBase64 = data['managerSignature'] as String?;
    }

    // Préparer signature client si le client a signé
    String? clientSignatureBase64;
    String? clientSignerName;
    if (signingStepStr == 'completed') {
      clientSignatureBase64 = data['clientSignature'] as String?;
      clientSignerName = data['clientSignerName'] as String?;
    }

    // Générer le PDF
    final pdfResult = await generatePdfUseCase.generateFromEntries(
      entries: entries,
      monthNumber: data['month'] as int,
      year: data['year'] as int,
      employeeName: employeeName,
      employeeCompany: employeeCompany,
      employeeSignature: employeeSignatureBase64,
      managerSignature: managerSignatureBase64,
      managerName: managerName,
      clientSignature: clientSignatureBase64,
      clientSignerName: clientSignerName,
    );

    if (pdfResult.isLeft()) {
      logger.e('Erreur lors de la régénération du PDF');
      return Left(pdfResult.fold((l) => l, (r) => GeneralFailure('Unknown error')));
    }

    final pdfBytes = pdfResult.fold(
      (failure) => throw Exception('PDF generation failed: ${failure.message}'),
      (bytes) => bytes,
    );

    logger.i('PDF régénéré avec succès: ${pdfBytes.length} octets');
    return Right(pdfBytes);
  }
}

class DownloadPdfParams {
  final String validationId;
  final String? managerSignature;

  const DownloadPdfParams({
    required this.validationId,
    this.managerSignature,
  });
}
