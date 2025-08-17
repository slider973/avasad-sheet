import 'dart:typed_data';
import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_usecase.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_params.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_signature_usecase.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import 'package:time_sheet/features/validation/data/models/manager_signature.dart';
import '../repositories/validation_repository.dart';
import './get_employee_validations_usecase.dart';

/// Use case pour générer le PDF d'une validation localement
class DownloadValidationPdfUseCase implements UseCase<Uint8List, DownloadPdfParams> {
  final ValidationRepository repository;
  final GeneratePdfUseCase generatePdfUseCase;
  final GetSignatureUseCase getSignatureUseCase;
  final GetUserPreferenceUseCase getUserPreferenceUseCase;
  final Isar isar;

  const DownloadValidationPdfUseCase(
    this.repository,
    this.generatePdfUseCase,
    this.getSignatureUseCase,
    this.getUserPreferenceUseCase,
    this.isar,
  );

  @override
  Future<Either<Failure, Uint8List>> call(DownloadPdfParams params) async {
    if (params.validationId.isEmpty) {
      return Left(ValidationFailure('L\'ID de la validation est requis'));
    }

    try {
      // Récupérer les données timesheet depuis le serveur
      final dataResult = await repository.getValidationTimesheetData(params.validationId);

      if (dataResult.isLeft()) {
        return Left(dataResult.fold((l) => l, (r) => GeneralFailure('Unknown error')));
      }

      final data = dataResult.fold(
        (failure) => throw Exception('Failed to get timesheet data: ${failure.message}'),
        (data) => data,
      );

      logger.i('📄 Génération locale du PDF pour validation ${params.validationId}');
      logger.i('   - Mois: ${data['month']}/${data['year']}');
      logger.i('   - Statut: ${data['status']}');
      logger.i('   - Manager Name dans data: ${data['managerName']}');

      // Récupérer les informations de l'employé depuis les données timesheet (PAS des préférences)
      final employeeName = data['employeeName'] as String? ?? '';
      final employeeCompany = data['employeeCompany'] as String? ?? 'Avasad';

      logger.i('📋 Données de la BDD:');
      logger.i('   - Employé: $employeeName');
      logger.i('   - Entreprise: $employeeCompany');

      // Convertir les entries JSON en List<TimesheetEntry>
      final entriesJson = data['entries'] as List<dynamic>;
      final List<TimesheetEntry> entries = entriesJson.map((entry) {
        // Calculer le jour de la semaine à partir de la date
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

      // Récupérer la signature de l'employé depuis les données timesheet
      String? employeeSignatureBase64 = data['employeeSignature'] as String?;
      if (employeeSignatureBase64 != null) {
        logger.i('   - Signature de l\'employé trouvée dans les données: ${employeeSignatureBase64.length} caractères');
      } else {
        logger.w('   - Pas de signature d\'employé dans les données');
      }

      // Préparer les paramètres pour la génération du PDF
      String? managerSignatureBase64;
      String? managerName;

      logger.i('📝 Vérification du statut pour la signature du manager...');

      // Si la validation est approuvée, récupérer la signature du manager LOCALEMENT
      if (data['status'] == 'ValidationStatus.approved') {
        logger.i('   - Validation approuvée, récupération de la signature du manager LOCALEMENT');

        managerName = data['managerName'] as String?;
        logger.i('   - Manager qui a approuvé: $managerName');

        // Récupérer la signature du manager depuis les préférences locales
        final localSignature = await getUserPreferenceUseCase.execute('signature');
        if (localSignature != null && localSignature.toString().isNotEmpty) {
          managerSignatureBase64 = localSignature.toString();
          logger.i('✅ Signature du manager récupérée localement: ${managerSignatureBase64.length} caractères');
        } else {
          logger.w('❌ Pas de signature dans les préférences locales du manager');
        }
      } else {
        logger.i('   - Validation non approuvée, pas de signature manager à ajouter');
      }

      // Log final avant génération
      logger.i('🎯 Génération du PDF avec:');
      logger.i(
          '   - Signature employé: ${employeeSignatureBase64 != null ? '${employeeSignatureBase64.length} caractères' : 'NON'}');
      logger.i(
          '   - Signature manager: ${managerSignatureBase64 != null ? '${managerSignatureBase64.length} caractères' : 'NON'}');
      logger.i('   - Nom manager: $managerName');

      // Générer le PDF avec les entries fournies ET les données de la BDD
      final pdfResult = await generatePdfUseCase.generateFromEntries(
        entries: entries,
        monthNumber: data['month'] as int,
        year: data['year'] as int,
        employeeName: employeeName, // Nom de l'employé depuis BDD
        employeeCompany: employeeCompany, // Entreprise depuis BDD
        employeeSignature: employeeSignatureBase64, // Signature de l'employé depuis BDD
        managerSignature: managerSignatureBase64,
        managerName: managerName,
      );

      if (pdfResult.isLeft()) {
        logger.e('Erreur lors de la génération du PDF');
        return Left(pdfResult.fold((l) => l, (r) => GeneralFailure('Unknown error')));
      }

      final pdfBytes = pdfResult.fold(
        (failure) => throw Exception('PDF generation failed: ${failure.message}'),
        (bytes) => bytes,
      );

      logger.i('✅ PDF généré localement avec succès: ${pdfBytes.length} octets');

      return Right(pdfBytes);
    } catch (e) {
      logger.e('Erreur lors de la génération locale du PDF', error: e);
      return Left(GeneralFailure('Erreur lors de la génération du PDF: $e'));
    }
  }
}

class DownloadPdfParams {
  final String validationId;
  final String? managerSignature; // Plus utilisé, gardé pour compatibilité

  const DownloadPdfParams({
    required this.validationId,
    this.managerSignature,
  });
}
