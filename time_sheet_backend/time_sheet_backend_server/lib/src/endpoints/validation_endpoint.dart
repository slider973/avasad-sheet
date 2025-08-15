import 'package:serverpod/serverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import '../generated/protocol.dart';
import '../services/pdf_generator_service.dart';

class ValidationEndpoint extends Endpoint {
  /// Créer une nouvelle demande de validation
  Future<ValidationRequest> createValidation(
    Session session,
    String employeeId,
    String employeeName,
    String managerId,
    String managerEmail,
    DateTime periodStart,
    DateTime periodEnd,
    List<int> pdfBytes,
    String? employeeCompany, // Nouveau paramètre optionnel
  ) async {
    try {
      // Calculer le hash du PDF
      final pdfHash = sha256.convert(pdfBytes).toString();

      // Générer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${employeeId}_${periodStart.month}_${periodStart.year}_$timestamp.pdf';
      final pdfPath = 'uploads/validations/$fileName';

      // Créer le dossier si nécessaire
      final uploadDir = Directory('uploads/validations');
      if (!await uploadDir.exists()) {
        await uploadDir.create(recursive: true);
      }

      // Sauvegarder le PDF
      final file = File(pdfPath);
      await file.writeAsBytes(pdfBytes);

      // Créer la demande de validation
      final validation = ValidationRequest(
        employeeId: employeeId,
        employeeName: employeeName,
        managerId: managerId,
        managerEmail: managerEmail,
        periodStart: periodStart,
        periodEnd: periodEnd,
        status: ValidationStatus.pending,
        pdfPath: pdfPath,
        pdfHash: pdfHash,
        pdfSizeBytes: pdfBytes.length,
        expiresAt: DateTime.now().add(Duration(days: 30)),
      );

      // Insérer en base de données et récupérer l'objet avec l'ID
      final insertedValidation = await ValidationRequest.db.insertRow(session, validation);

      // Créer une notification pour le manager
      final notification = Notification(
        userId: managerId,
        type: NotificationType.validationCreated,
        title: 'Nouvelle validation à traiter',
        message: 'Une nouvelle timesheet de $employeeName attend votre validation.',
        data: jsonEncode({
          'validationId': insertedValidation.id,
          'employeeName': employeeName,
        }),
      );

      await Notification.db.insertRow(session, notification);

      // Log pour debug
      session.log('Created validation with ID: ${insertedValidation.id}');

      // Créer automatiquement les données timesheet avec les bonnes dates
      // On utilise periodEnd pour déterminer le mois et l'année (le 20 du mois sélectionné)
      try {
        final timesheetData = TimesheetData(
          validationRequestId: insertedValidation.id!,
          employeeId: employeeId,
          employeeName: employeeName,
          employeeCompany: employeeCompany ?? 'Avasad', // Utiliser la valeur passée ou Avasad par défaut
          month: periodEnd.month,  // Utiliser periodEnd (20 du mois) au lieu de periodStart (21 du mois précédent)
          year: periodEnd.year,
          entries: '[]', // Sera rempli via updateTimesheetData
          totalDays: 0.0,
          totalHours: '0h',
          totalOvertimeHours: '0h',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await TimesheetData.db.insertRow(session, timesheetData);
        session.log('Données timesheet créées avec mois=${periodEnd.month}, année=${periodEnd.year}');
      } catch (e) {
        session.log('Erreur lors de la création des données timesheet: $e');
      }

      return insertedValidation;
    } catch (e) {
      session.log('Error creating validation: $e');
      throw Exception('Impossible de créer la validation: $e');
    }
  }

  /// Mettre à jour les données timesheet d'une validation
  Future<void> updateTimesheetData(
    Session session,
    int validationId,
    String entries,
    double totalDays,
    String totalHours,
    String totalOvertimeHours,
  ) async {
    try {
      // Récupérer les données timesheet existantes
      final existingTimesheet = await TimesheetData.db.findFirstRow(
        session,
        where: (t) => t.validationRequestId.equals(validationId),
      );
      
      if (existingTimesheet != null) {
        // Mettre à jour avec les nouvelles données
        existingTimesheet.entries = entries;
        existingTimesheet.totalDays = totalDays;
        existingTimesheet.totalHours = totalHours;
        existingTimesheet.totalOvertimeHours = totalOvertimeHours;
        existingTimesheet.updatedAt = DateTime.now();
        
        await TimesheetData.db.updateRow(session, existingTimesheet);
        session.log('Données timesheet mises à jour pour la validation $validationId');
      } else {
        session.log('Aucune donnée timesheet trouvée pour la validation $validationId');
      }
    } catch (e) {
      session.log('Erreur lors de la mise à jour des données timesheet: $e');
      throw Exception('Impossible de mettre à jour les données timesheet: $e');
    }
  }

  /// Approuver une validation  
  Future<ValidationRequest> approveValidation(
    Session session,
    int validationId,
    String managerName,
    String? comment,
    List<int>? signedPdfBytes, // PDF signé généré côté client
  ) async {
    try {
      // Récupérer la validation
      final validation = await ValidationRequest.db.findById(
        session,
        validationId,
      );

      if (validation == null) {
        throw Exception('Validation introuvable');
      }

      if (validation.status != ValidationStatus.pending) {
        throw Exception('Cette validation a déjà été traitée');
      }

      // Logs pour déboguer
      print('\n========== APPROVING VALIDATION ==========');
      print('Validation ID: $validationId');
      print('Manager name: $managerName');
      print('Signed PDF provided: ${signedPdfBytes != null}');
      if (signedPdfBytes != null) {
        print('Signed PDF size: ${signedPdfBytes.length} bytes');
      }
      session.log('Approving validation $validationId');

      // Si un PDF signé est fourni, le sauvegarder
      if (signedPdfBytes != null && signedPdfBytes.isNotEmpty) {
        final fileName = 'timesheet_${validationId}_approved_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = '/tmp/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(signedPdfBytes);
        
        // Mettre à jour le chemin du PDF
        validation.pdfPath = filePath;
        validation.pdfSizeBytes = signedPdfBytes.length;
        validation.pdfHash = signedPdfBytes.hashCode.toString();
        
        print('PDF signé sauvegardé: $filePath');
      }

      // Mettre à jour la validation
      validation.status = ValidationStatus.approved;
      validation.managerName = managerName;
      validation.managerComment = comment;
      validation.validatedAt = DateTime.now();
      validation.updatedAt = DateTime.now();

      await ValidationRequest.db.updateRow(session, validation);

      // Notifier l'employé
      final notification = Notification(
        userId: validation.employeeId,
        type: NotificationType.validationApproved,
        title: 'Timesheet approuvée',
        message: 'Votre timesheet a été approuvée par $managerName.',
        data: jsonEncode({
          'validationId': validationId,
        }),
      );

      await Notification.db.insertRow(session, notification);

      return validation;
    } catch (e) {
      session.log('Error approving validation: $e');
      throw Exception('Impossible d\'approuver la validation: $e');
    }
  }

  /// Rejeter une validation
  Future<ValidationRequest> rejectValidation(
    Session session,
    int validationId,
    String comment,
    String managerName,
  ) async {
    try {
      // Récupérer la validation
      final validation = await ValidationRequest.db.findById(
        session,
        validationId,
      );

      if (validation == null) {
        throw Exception('Validation introuvable');
      }

      if (validation.status != ValidationStatus.pending) {
        throw Exception('Cette validation a déjà été traitée');
      }

      // Mettre à jour la validation
      validation.status = ValidationStatus.rejected;
      validation.managerComment = comment;
      validation.managerName = managerName;
      validation.validatedAt = DateTime.now();
      validation.updatedAt = DateTime.now();

      await ValidationRequest.db.updateRow(session, validation);

      // Notifier l'employé
      final notification = Notification(
        userId: validation.employeeId,
        type: NotificationType.validationRejected,
        title: 'Timesheet rejetée',
        message: 'Votre timesheet a été rejetée par $managerName. Raison: $comment',
        data: jsonEncode({
          'validationId': validationId,
        }),
      );

      await Notification.db.insertRow(session, notification);

      return validation;
    } catch (e) {
      session.log('Error rejecting validation: $e');
      throw Exception('Impossible de rejeter la validation: $e');
    }
  }

  /// Obtenir les validations d'un employé
  Future<List<ValidationRequest>> getEmployeeValidations(
    Session session,
    String employeeId,
  ) async {
    try {
      return await ValidationRequest.db.find(
        session,
        where: (t) => t.employeeId.equals(employeeId),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
    } catch (e) {
      session.log('Error getting employee validations: $e');
      throw Exception('Impossible de récupérer les validations: $e');
    }
  }

  /// Obtenir les validations à traiter par un manager
  Future<List<ValidationRequest>> getManagerValidations(
    Session session,
    String managerEmail,
  ) async {
    try {
      // D'abord récupérer l'ID du manager depuis son email
      final manager = await Manager.db.findFirstRow(
        session,
        where: (t) => t.email.equals(managerEmail),
      );

      if (manager == null) {
        session.log('Manager not found with email: $managerEmail');
        return [];
      }

      // Récupérer les validations avec l'ID du manager
      return await ValidationRequest.db.find(
        session,
        where: (t) => t.managerId.equals(manager.id.toString()),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
    } catch (e) {
      session.log('Error getting manager validations: $e');
      throw Exception('Impossible de récupérer les validations: $e');
    }
  }

  /// Obtenir une validation spécifique
  Future<ValidationRequest?> getValidation(
    Session session,
    int validationId,
  ) async {
    try {
      return await ValidationRequest.db.findById(
        session,
        validationId,
      );
    } catch (e) {
      session.log('Error getting validation: $e');
      throw Exception('Impossible de récupérer la validation: $e');
    }
  }

  /// Télécharger le PDF d'une validation
  Future<List<int>> downloadValidationPdf(
    Session session,
    int validationId,
  ) async {
    try {
      final validation = await ValidationRequest.db.findById(
        session,
        validationId,
      );

      if (validation == null) {
        throw Exception('Validation introuvable');
      }

      // Retourner simplement le PDF stocké (qu'il soit approuvé ou non)
      final file = File(validation.pdfPath);
      if (!await file.exists()) {
        throw Exception('Fichier PDF introuvable');
      }

      return await file.readAsBytes();
    } catch (e) {
      session.log('Error downloading PDF: $e');
      throw Exception('Impossible de télécharger le PDF: $e');
    }
  }

  /// Obtenir les données timesheet pour une validation
  Future<TimesheetDataResponse> getValidationTimesheetData(
    Session session,
    int validationId,
  ) async {
    try {
      final validation = await ValidationRequest.db.findById(
        session,
        validationId,
      );

      if (validation == null) {
        throw Exception('Validation introuvable');
      }

      // Récupérer les données timesheet
      final timesheetData = await TimesheetData.db.findFirstRow(
        session,
        where: (t) => t.validationRequestId.equals(validationId),
      );

      if (timesheetData == null) {
        throw Exception('Données timesheet introuvables');
      }

      // Retourner les données structurées avec le modèle Serverpod
      return TimesheetDataResponse(
        validationId: validationId,
        employeeId: timesheetData.employeeId,
        employeeName: timesheetData.employeeName,
        employeeCompany: timesheetData.employeeCompany,
        month: timesheetData.month,
        year: timesheetData.year,
        entries: timesheetData.entries, // Garder en JSON string
        totalDays: timesheetData.totalDays,
        totalHours: timesheetData.totalHours,
        totalOvertimeHours: timesheetData.totalOvertimeHours,
        periodStart: validation.periodStart,
        periodEnd: validation.periodEnd,
        status: validation.status.toString(),
        managerName: validation.managerName,
        managerComment: validation.managerComment,
        validatedAt: validation.validatedAt,
      );
    } catch (e) {
      session.log('Error getting timesheet data: $e');
      throw Exception('Impossible de récupérer les données: $e');
    }
  }

  /// Vérifier et marquer les validations expirées
  Future<void> checkExpiredValidations(Session session) async {
    try {
      final now = DateTime.now();

      // Trouver les validations expirées
      final allPendingValidations = await ValidationRequest.db.find(
        session,
        where: (t) => t.status.equals(ValidationStatus.pending) & t.expiresAt.notEquals(null),
      );

      // Filtrer manuellement celles qui sont expirées
      final expiredValidations =
          allPendingValidations.where((v) => v.expiresAt != null && v.expiresAt!.isBefore(now)).toList();

      // Marquer comme expirées
      for (final validation in expiredValidations) {
        validation.status = ValidationStatus.expired;
        validation.updatedAt = DateTime.now();
        await ValidationRequest.db.updateRow(session, validation);

        // Notifier l'employé
        final notification = Notification(
          userId: validation.employeeId,
          type: NotificationType.validationExpiring,
          title: 'Validation expirée',
          message: 'Votre timesheet a expiré et doit être resoumise.',
          data: jsonEncode({
            'validationId': validation.id,
          }),
        );

        await Notification.db.insertRow(session, notification);
      }

      session.log('Checked expired validations: ${expiredValidations.length} found');
    } catch (e) {
      session.log('Error checking expired validations: $e');
    }
  }
  
  /// Traiter la régénération d'un PDF avec signatures
  Future<void> _processSinglePdfRegeneration(Session session, int validationId) async {
    try {
      // Récupérer la validation
      final validation = await ValidationRequest.db.findById(session, validationId);
      if (validation == null) {
        throw Exception('Validation not found');
      }
      
      // Récupérer les données timesheet
      final timesheetData = await TimesheetData.db.findFirstRow(
        session,
        where: (t) => t.validationRequestId.equals(validationId),
      );
      
      if (timesheetData == null) {
        throw Exception('Timesheet data not found');
      }
      
      session.log('Generating PDF for validation $validationId');
      session.log('- Employee: ${timesheetData.employeeName}');
      session.log('- Period: ${timesheetData.month}/${timesheetData.year}');
      session.log('- Status: ${validation.status}');
      
      // Générer le PDF avec les données timesheet (sans signature)
      final pdfGenerator = PdfGeneratorService();
      final pdfBytes = await pdfGenerator.generateTimesheetPdf(
        timesheetData: timesheetData,
        validation: validation,
        includeManagerSignature: false, // Jamais de signature stockée
      );
      
      // Sauvegarder le PDF
      final fileName = 'timesheet_${validationId}_signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '/tmp/$fileName'; // Utiliser un répertoire temporaire
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      // Mettre à jour le chemin du PDF dans la validation
      validation.pdfPath = filePath;
      validation.updatedAt = DateTime.now();
      await ValidationRequest.db.updateRow(session, validation);
      
      // Marquer le job comme complété
      final jobs = await PdfRegenerationQueue.db.find(
        session,
        where: (j) => j.validationId.equals(validationId),
      );
      
      for (var job in jobs) {
        if (job.status == QueueStatus.pending || job.status == QueueStatus.processing) {
          job.status = QueueStatus.completed;
          job.processedAt = DateTime.now();
          await PdfRegenerationQueue.db.updateRow(session, job);
        }
      }
      
      session.log('PDF regeneration completed for validation $validationId, saved to: $filePath');
    } catch (e) {
      session.log('Error in _processSinglePdfRegeneration: $e');
      throw e;
    }
  }
}