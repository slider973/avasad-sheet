import 'package:serverpod/serverpod.dart';
import 'dart:convert';
import '../generated/protocol.dart';
import '../services/pdf_generator_service.dart';

class TimesheetEndpoint extends Endpoint {
  /// Endpoint unique et professionnel pour gérer toutes les opérations timesheet
  ///
  /// Cette méthode gère toutes les opérations via un paramètre 'action':
  /// - 'save': Sauvegarder des données timesheet
  /// - 'get': Récupérer des données timesheet
  /// - 'update': Mettre à jour des données existantes
  /// - 'generatePdf': Générer un PDF avec signatures
  Future<Map<String, dynamic>> processTimesheet(
    Session session,
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      session.log('Processing timesheet action: $action');

      switch (action) {
        case 'save':
          return await _handleSave(session, data);

        case 'get':
          return await _handleGet(session, data);

        case 'update':
          return await _handleUpdate(session, data);

        case 'generatePdf':
          return await _handleGeneratePdf(session, data);

        default:
          throw Exception('Action non supportée: $action');
      }
    } catch (e) {
      session.log('Error in processTimesheet: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Gestion de la sauvegarde des données timesheet
  Future<Map<String, dynamic>> _handleSave(
    Session session,
    Map<String, dynamic> data,
  ) async {
    try {
      // Validation des paramètres requis
      final validationRequestId = data['validationRequestId'] as int?;
      if (validationRequestId == null) {
        throw Exception('validationRequestId est requis');
      }

      // Extraction des données avec valeurs par défaut
      final employeeId = data['employeeId'] as String? ?? '';
      final employeeName = data['employeeName'] as String? ?? '';
      final employeeCompany = data['employeeCompany'] as String? ?? '';
      final month = data['month'] as int? ?? DateTime.now().month;
      final year = data['year'] as int? ?? DateTime.now().year;
      final entries = data['entries'] ?? [];
      final totalDays = (data['totalDays'] as num?)?.toDouble() ?? 0.0;
      final totalHours = data['totalHours'] as String? ?? '0:00';
      final totalOvertimeHours = data['totalOvertimeHours'] as String? ?? '0:00';

      // Vérifier si les données existent déjà
      final existing = await TimesheetData.db.findFirstRow(
        session,
        where: (t) => t.validationRequestId.equals(validationRequestId),
      );

      TimesheetData timesheetData;

      if (existing != null) {
        // Mise à jour
        existing.entries = jsonEncode(entries);
        existing.totalDays = totalDays;
        existing.totalHours = totalHours;
        existing.totalOvertimeHours = totalOvertimeHours;
        existing.updatedAt = DateTime.now();

        timesheetData = await TimesheetData.db.updateRow(session, existing);
        session.log('Updated existing timesheet data with id: ${timesheetData.id}');
      } else {
        // Création
        final newData = TimesheetData(
          validationRequestId: validationRequestId,
          employeeId: employeeId,
          employeeName: employeeName,
          employeeCompany: employeeCompany,
          month: month,
          year: year,
          entries: jsonEncode(entries),
          totalDays: totalDays,
          totalHours: totalHours,
          totalOvertimeHours: totalOvertimeHours,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        timesheetData = await TimesheetData.db.insertRow(session, newData);
        session.log('Created new timesheet data with id: ${timesheetData.id}');
      }

      return {
        'success': true,
        'data': {
          'id': timesheetData.id,
          'validationRequestId': timesheetData.validationRequestId,
          'employeeName': timesheetData.employeeName,
          'month': timesheetData.month,
          'year': timesheetData.year,
        },
        'message': existing != null ? 'Données mises à jour' : 'Données créées',
      };
    } catch (e) {
      session.log('Error in _handleSave: $e');
      throw e;
    }
  }

  /// Gestion de la récupération des données
  Future<Map<String, dynamic>> _handleGet(
    Session session,
    Map<String, dynamic> data,
  ) async {
    try {
      final validationRequestId = data['validationRequestId'] as int?;
      if (validationRequestId == null) {
        throw Exception('validationRequestId est requis');
      }

      final timesheetData = await TimesheetData.db.findFirstRow(
        session,
        where: (t) => t.validationRequestId.equals(validationRequestId),
      );

      if (timesheetData == null) {
        return {
          'success': false,
          'error': 'Données non trouvées',
        };
      }

      // Décoder les entrées JSON
      final entries = jsonDecode(timesheetData.entries);

      return {
        'success': true,
        'data': {
          'id': timesheetData.id,
          'validationRequestId': timesheetData.validationRequestId,
          'employeeId': timesheetData.employeeId,
          'employeeName': timesheetData.employeeName,
          'employeeCompany': timesheetData.employeeCompany,
          'month': timesheetData.month,
          'year': timesheetData.year,
          'entries': entries,
          'totalDays': timesheetData.totalDays,
          'totalHours': timesheetData.totalHours,
          'totalOvertimeHours': timesheetData.totalOvertimeHours,
          'createdAt': timesheetData.createdAt.toIso8601String(),
          'updatedAt': timesheetData.updatedAt.toIso8601String(),
        },
      };
    } catch (e) {
      session.log('Error in _handleGet: $e');
      throw e;
    }
  }

  /// Gestion de la mise à jour des données
  Future<Map<String, dynamic>> _handleUpdate(
    Session session,
    Map<String, dynamic> data,
  ) async {
    try {
      final id = data['id'] as int?;
      if (id == null) {
        throw Exception('id est requis pour la mise à jour');
      }

      final existing = await TimesheetData.db.findById(session, id);
      if (existing == null) {
        throw Exception('Données non trouvées pour id: $id');
      }

      // Mise à jour des champs fournis uniquement
      if (data.containsKey('entries')) {
        existing.entries = jsonEncode(data['entries']);
      }
      if (data.containsKey('totalDays')) {
        existing.totalDays = (data['totalDays'] as num).toDouble();
      }
      if (data.containsKey('totalHours')) {
        existing.totalHours = data['totalHours'] as String;
      }
      if (data.containsKey('totalOvertimeHours')) {
        existing.totalOvertimeHours = data['totalOvertimeHours'] as String;
      }

      existing.updatedAt = DateTime.now();

      final updated = await TimesheetData.db.updateRow(session, existing);

      return {
        'success': true,
        'data': {
          'id': updated.id,
          'updatedAt': updated.updatedAt.toIso8601String(),
        },
        'message': 'Données mises à jour avec succès',
      };
    } catch (e) {
      session.log('Error in _handleUpdate: $e');
      throw e;
    }
  }

  /// Gestion de la génération de PDF
  Future<Map<String, dynamic>> _handleGeneratePdf(
    Session session,
    Map<String, dynamic> data,
  ) async {
    try {
      final validationRequestId = data['validationRequestId'] as int?;
      if (validationRequestId == null) {
        throw Exception('validationRequestId est requis');
      }

      final timesheetData = await TimesheetData.db.findFirstRow(
        session,
        where: (t) => t.validationRequestId.equals(validationRequestId),
      );

      if (timesheetData == null) {
        throw Exception('Données timesheet non trouvées');
      }

      final validation = await ValidationRequest.db.findById(
        session,
        validationRequestId,
      );

      if (validation == null) {
        throw Exception('Validation non trouvée');
      }

      // Signatures optionnelles
      final employeeSignature = data['employeeSignature'] as String?;
      final managerSignature = data['managerSignature'] as String?;
      final managerName = data['managerName'] as String?;

      // TODO: Implémenter la génération réelle du PDF
      // Pour l'instant, on retourne les métadonnées

      return {
        'success': true,
        'data': {
          'validationRequestId': validationRequestId,
          'employeeName': timesheetData.employeeName,
          'period': '${timesheetData.month}/${timesheetData.year}',
          'hasEmployeeSignature': employeeSignature != null,
          'hasManagerSignature': managerSignature != null,
          'managerName': managerName,
          'pdfGenerated': false, // TODO: changer à true quand implémenté
          'message': 'Génération PDF pas encore implémentée côté serveur',
        },
      };
    } catch (e) {
      session.log('Error in _handleGeneratePdf: $e');
      throw e;
    }
  }

  // ===== MÉTHODES LEGACY POUR LA COMPATIBILITÉ =====
  // Ces méthodes sont nécessaires car le code généré les attend encore

  /// Sauvegarder les données du timesheet (compatibilité)
  Future<TimesheetData> saveTimesheetData(
    Session session,
    int validationRequestId,
    String employeeId,
    String employeeName,
    String employeeCompany,
    int month,
    int year,
    List<TimesheetEntry> entries,
    double totalDays,
    String totalHours,
    String totalOvertimeHours,
  ) async {
    try {
      print('Saving timesheet data...');
      // Utiliser la nouvelle méthode processTimesheet
      // Convertir les TimesheetEntry en Map pour la méthode processTimesheet
      final entriesData = entries.map((e) => {
        'dayDate': e.dayDate,
        'startMorning': e.startMorning,
        'endMorning': e.endMorning,
        'startAfternoon': e.startAfternoon,
        'endAfternoon': e.endAfternoon,
        'isAbsence': e.isAbsence,
        'hasOvertimeHours': e.hasOvertimeHours,
      }).toList();
      final result = await processTimesheet(session, 'save', {
        'validationRequestId': validationRequestId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'employeeCompany': employeeCompany,
        'month': month,
        'year': year,
        'entries': entriesData,
        'totalDays': totalDays,
        'totalHours': totalHours,
        'totalOvertimeHours': totalOvertimeHours,
      });

      if (!result['success']) {
        throw Exception(result['error'] ?? 'Erreur lors de la sauvegarde');
      }

      // Récupérer les données complètes
      final getData = await processTimesheet(session, 'get', {
        'validationRequestId': validationRequestId,
      });

      if (getData['success'] && getData['data'] != null) {
        final data = getData['data'] as Map<String, dynamic>;
        return TimesheetData(
          id: data['id'],
          validationRequestId: data['validationRequestId'],
          employeeId: data['employeeId'],
          employeeName: data['employeeName'],
          employeeCompany: data['employeeCompany'],
          month: data['month'],
          year: data['year'],
          entries: jsonEncode(data['entries']),
          totalDays: data['totalDays'],
          totalHours: data['totalHours'],
          totalOvertimeHours: data['totalOvertimeHours'],
          createdAt: DateTime.parse(data['createdAt']),
          updatedAt: DateTime.parse(data['updatedAt']),
        );
      }

      throw Exception('Impossible de récupérer les données sauvegardées');
    } catch (e) {
      session.log('Error in saveTimesheetData legacy: $e');
      throw Exception('Impossible de sauvegarder les données du timesheet: $e');
    }
  }

  /// Récupérer les données du timesheet (compatibilité)
  Future<TimesheetData?> getTimesheetData(
    Session session,
    int validationRequestId,
  ) async {
    try {
      final result = await processTimesheet(session, 'get', {
        'validationRequestId': validationRequestId,
      });

      if (!result['success'] || result['data'] == null) {
        return null;
      }

      final data = result['data'] as Map<String, dynamic>;
      return TimesheetData(
        id: data['id'],
        validationRequestId: data['validationRequestId'],
        employeeId: data['employeeId'],
        employeeName: data['employeeName'],
        employeeCompany: data['employeeCompany'],
        month: data['month'],
        year: data['year'],
        entries: jsonEncode(data['entries']),
        totalDays: data['totalDays'],
        totalHours: data['totalHours'],
        totalOvertimeHours: data['totalOvertimeHours'],
        createdAt: DateTime.parse(data['createdAt']),
        updatedAt: DateTime.parse(data['updatedAt']),
      );
    } catch (e) {
      session.log('Error in getTimesheetData legacy: $e');
      return null;
    }
  }

  /// Générer un PDF avec signature (compatibilité)
  Future<List<int>> generateSignedPdf(
    Session session,
    int validationRequestId,
    String? employeeSignature,
    String? managerSignature,
    String? managerName,
  ) async {
    try {
      // Récupérer la validation
      final validation = await ValidationRequest.db.findById(
        session,
        validationRequestId,
      );
      
      if (validation == null) {
        throw Exception('Validation non trouvée');
      }
      
      // Récupérer les données timesheet
      final timesheetData = await TimesheetData.db.findFirstRow(
        session,
        where: (t) => t.validationRequestId.equals(validationRequestId),
      );
      
      if (timesheetData == null) {
        throw Exception('Données timesheet non trouvées');
      }
      
      // Si on a une signature de manager, la sauvegarder dans la validation
      if (managerSignature != null && managerSignature.isNotEmpty) {
        validation.managerSignature = managerSignature;
        validation.managerName = managerName;
        await ValidationRequest.db.updateRow(session, validation);
      }
      
      // Générer le PDF avec les signatures
      final pdfGenerator = PdfGeneratorService();
      final pdfBytes = await pdfGenerator.generateTimesheetPdf(
        timesheetData: timesheetData,
        validation: validation,
        includeManagerSignature: validation.managerSignature != null,
      );
      
      session.log('PDF généré avec succès pour validation $validationRequestId');
      return pdfBytes;
    } catch (e) {
      session.log('Error in generateSignedPdf: $e');
      throw Exception('Impossible de générer le PDF signé: $e');
    }
  }
}
