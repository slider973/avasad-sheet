import 'dart:typed_data';
import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
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
import '../repositories/validation_repository.dart';
import './get_employee_validations_usecase.dart';

/// Use case pour générer le PDF d'une validation localement
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
          absence: entry['isAbsence'] == true ? AbsenceEntity(
            type: AbsenceType.other,
            motif: entry['absenceReason'] ?? '',
            startDate: parsedDate ?? DateTime.now(),
            endDate: parsedDate ?? DateTime.now(),
          ) : null,
          absenceReason: entry['absenceReason'],
          hasOvertimeHours: entry['hasOvertimeHours'] ?? false,
          period: entry['period'] ?? '',
        );
      }).toList();
      
      // Préparer les paramètres pour la génération du PDF
      String? managerSignatureBase64;
      String? managerName;
      
      // Si la validation est approuvée, ajouter la signature du manager
      if (data['status'] == 'ValidationStatus.approved') {
        logger.i('   - Validation approuvée, ajout de la signature du manager');
        
        // Récupérer la signature depuis Isar
        final managerSignatureBytes = await getSignatureUseCase.execute();
        if (managerSignatureBytes != null) {
          managerSignatureBase64 = base64Encode(managerSignatureBytes);
          logger.i('   - Signature récupérée depuis Isar');
        }
        
        // Utiliser le nom du manager depuis les données
        managerName = data['managerName'] as String?;
        logger.i('   - Manager: $managerName');
      }
      
      // Générer le PDF avec les entries fournies
      final pdfResult = await generatePdfUseCase.generateFromEntries(
        entries: entries,
        monthNumber: data['month'] as int,
        year: data['year'] as int,
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