import 'package:serverpod/serverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:convert';
import '../generated/protocol.dart';

class PdfProcessorEndpoint extends Endpoint {
  /// Traiter la queue de régénération PDF
  Future<void> processPdfQueue(Session session) async {
    try {
      // Récupérer les jobs en attente
      final pendingJobs = await PdfRegenerationQueue.db.find(
        session,
        where: (t) => t.status.equals(QueueStatus.pending),
        orderBy: (t) => t.createdAt,
        limit: 10, // Traiter 10 jobs maximum à la fois
      );
      
      session.log('Processing PDF queue: ${pendingJobs.length} pending jobs');
      
      for (final job in pendingJobs) {
        try {
          // Marquer comme en cours de traitement
          job.status = QueueStatus.processing;
          await PdfRegenerationQueue.db.updateRow(session, job);
          
          // Récupérer la validation
          final validation = await ValidationRequest.db.findById(
            session,
            job.validationId,
          );
          
          if (validation == null) {
            throw Exception('Validation ${job.validationId} not found');
          }
          
          // Plus de signature stockée en BDD - elle sera gérée côté client
          // if (validation.managerSignature == null) {
          //   throw Exception('No manager signature for validation ${job.validationId}');
          // }
          
          // Régénérer le PDF avec la signature
          final newPdfPath = await _regeneratePdfWithSignature(
            session,
            validation,
          );
          
          // Mettre à jour le chemin du PDF
          validation.pdfPath = newPdfPath;
          validation.updatedAt = DateTime.now();
          await ValidationRequest.db.updateRow(session, validation);
          
          // Marquer le job comme complété
          job.status = QueueStatus.completed;
          job.processedAt = DateTime.now();
          await PdfRegenerationQueue.db.updateRow(session, job);
          
          session.log('Successfully processed PDF for validation ${validation.id}');
          
        } catch (e) {
          // Marquer le job comme échoué
          job.status = QueueStatus.failed;
          job.errorMessage = e.toString();
          job.retryCount = job.retryCount + 1;
          
          // Si moins de 3 essais, remettre en pending pour retry
          if (job.retryCount < 3) {
            job.status = QueueStatus.pending;
          }
          
          await PdfRegenerationQueue.db.updateRow(session, job);
          
          session.log('Error processing PDF job ${job.id}: $e');
        }
      }
    } catch (e) {
      session.log('Error processing PDF queue: $e');
    }
  }
  
  /// Régénérer un PDF avec la signature du manager
  Future<String> _regeneratePdfWithSignature(
    Session session,
    ValidationRequest validation,
  ) async {
    try {
      // Pour l'instant, on charge le PDF original et on le copie avec un nouveau nom
      // Dans une implémentation complète, on devrait :
      // 1. Soit fusionner les PDFs (original + page de signature)
      // 2. Soit stocker les données du timesheet et tout régénérer
      
      final originalFile = File(validation.pdfPath);
      if (!await originalFile.exists()) {
        throw Exception('Original PDF not found: ${validation.pdfPath}');
      }
      
      // Lire le PDF original
      final originalBytes = await originalFile.readAsBytes();
      
      // TODO: Implémenter la fusion du PDF original avec la signature du manager
      // Pour l'instant, on crée juste une copie du PDF original
      // Dans le futur, on pourrait utiliser une bibliothèque comme pdf_manipulation
      // pour ajouter une page de signature au PDF existant
      
      // Créer le nom du fichier validé
      final newFileName = validation.pdfPath
          .replaceAll('.pdf', '_signed_${DateTime.now().millisecondsSinceEpoch}.pdf');
      final newFile = File(newFileName);
      
      // Pour l'instant, copier simplement le PDF original
      // TODO: Ajouter la page de signature au PDF
      await newFile.writeAsBytes(originalBytes);
      
      session.log('PDF copied to: $newFileName');
      // Plus de signature stockée en BDD
      // session.log('Manager signature available: ${validation.managerSignature != null}');
      session.log('This is a temporary implementation - PDF fusion not yet implemented');
      
      return newFileName;
    } catch (e) {
      throw Exception('Failed to regenerate PDF: $e');
    }
  }
  
  /// Nettoyer les anciens jobs de la queue
  Future<void> cleanupOldJobs(Session session) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: 30));
      
      // Supprimer les jobs complétés ou échoués de plus de 30 jours
      // Note: Serverpod doesn't have a direct deleteWhere, so we find and delete
      final allCompletedOrFailed = await PdfRegenerationQueue.db.find(
        session,
        where: (t) => t.status.inSet({QueueStatus.completed, QueueStatus.failed}),
      );
      
      // Filtrer manuellement ceux qui sont trop vieux
      final oldJobs = allCompletedOrFailed.where((job) => 
        job.createdAt != null && job.createdAt!.isBefore(cutoffDate)
      ).toList();
      
      int deletedCount = 0;
      for (final job in oldJobs) {
        await PdfRegenerationQueue.db.deleteRow(session, job);
        deletedCount++;
      }
      
      session.log('Cleaned up $deletedCount old PDF queue jobs');
    } catch (e) {
      session.log('Error cleaning up old jobs: $e');
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}