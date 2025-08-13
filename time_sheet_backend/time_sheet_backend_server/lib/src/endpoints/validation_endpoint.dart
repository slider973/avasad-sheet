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

      // Sauvegarder les données timesheet si l'ID contient des données JSON
      // Hack temporaire: on utilise employeeId pour passer les données
      if (employeeId.startsWith('JSON:')) {
        try {
          // Extraire le vrai employeeId et le JSON
          final parts = employeeId.substring(5).split('|');
          final realEmployeeId = parts[0];
          final jsonData = parts.sublist(1).join('|'); // Au cas où il y a des | dans le JSON
          
          // Mettre à jour la validation avec le vrai employeeId
          insertedValidation.employeeId = realEmployeeId;
          await ValidationRequest.db.updateRow(session, insertedValidation);
          
          // Décoder et sauvegarder les données timesheet
          final data = jsonDecode(jsonData) as Map<String, dynamic>;
          
          final timesheetData = TimesheetData(
            validationRequestId: insertedValidation.id!,
            employeeId: realEmployeeId,
            employeeName: data['employeeName'] as String,
            employeeCompany: data['employeeCompany'] as String,
            month: data['month'] as int,
            year: data['year'] as int,
            entries: jsonEncode(data['entries']),
            totalDays: (data['totalDays'] as num).toDouble(),
            totalHours: data['totalHours'] as String,
            totalOvertimeHours: data['totalOvertimeHours'] as String,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await TimesheetData.db.insertRow(session, timesheetData);
          session.log('Données timesheet sauvegardées avec succès (hack JSON)');
        } catch (e) {
          session.log('Erreur lors du décodage/sauvegarde timesheet: $e');
        }
      }

      return insertedValidation;
    } catch (e) {
      session.log('Error creating validation: $e');
      throw Exception('Impossible de créer la validation: $e');
    }
  }

  /// Approuver une validation  
  Future<ValidationRequest> approveValidation(
    Session session,
    int validationId,
    String managerName,
    String? comment,
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
      session.log('Approving validation $validationId');

      // Mettre à jour la validation (SANS stocker la signature)
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

  /// Télécharger le PDF d'une validation (avec signature optionnelle du manager)
  Future<List<int>> downloadValidationPdf(
    Session session,
    int validationId,
    String? managerSignature,
  ) async {
    try {
      final validation = await ValidationRequest.db.findById(
        session,
        validationId,
      );

      if (validation == null) {
        throw Exception('Validation introuvable');
      }

      // Si la validation est approuvée ET qu'on fournit une signature, générer le PDF avec signature
      if (validation.status == ValidationStatus.approved && managerSignature != null && managerSignature.isNotEmpty) {
        // Récupérer les données timesheet
        final timesheetData = await TimesheetData.db.findFirstRow(
          session,
          where: (t) => t.validationRequestId.equals(validationId),
        );
        
        if (timesheetData != null) {
          print('\n========== DOWNLOAD PDF - GENERATING WITH SIGNATURE ==========');
          print('Validation ID: $validationId');
          print('Manager signature provided: ${managerSignature.length} chars');
          
          // Générer le PDF avec la signature fournie par le client
          final pdfGenerator = PdfGeneratorService();
          final pdfBytes = await pdfGenerator.generateTimesheetPdf(
            timesheetData: timesheetData,
            validation: validation,
            managerSignature: managerSignature,
            includeManagerSignature: true,
          );
          
          print('PDF generated with signature, size: ${pdfBytes.length} bytes');
          return pdfBytes;
        }
      }

      // Sinon, retourner le PDF original
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
      session.log('- Manager signature available: ${validation.managerSignature != null}');
      
      // Générer le PDF avec les données timesheet et signatures
      final pdfGenerator = PdfGeneratorService();
      final pdfBytes = await pdfGenerator.generateTimesheetPdf(
        timesheetData: timesheetData,
        validation: validation,
        includeManagerSignature: validation.managerSignature != null,
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