import 'package:time_sheet/features/validation/domain/entities/validation_overtime_summary.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/services/logger_service.dart';

/// Service pour gérer les notifications liées aux validations
class ValidationNotificationService {
  /// Génère une notification pour les heures weekend exceptionnelles
  Future<void> notifyExceptionalWeekendHours({
    required ValidationRequest validation,
    required ValidationOvertimeSummary overtimeSummary,
    required String managerName,
  }) async {
    try {
      if (!overtimeSummary.hasWeekendOvertime) {
        return; // Pas d'heures weekend, pas de notification
      }

      // Déterminer si les heures sont exceptionnelles
      final isExceptional = _isExceptionalWeekendHours(overtimeSummary);

      if (!isExceptional) {
        return; // Heures normales, pas de notification
      }

      // Créer le message de notification
      final message =
          _buildNotificationMessage(validation, overtimeSummary, managerName);

      // Log de la notification (dans une vraie implémentation, on enverrait une vraie notification)
      logger.i('📧 Notification heures weekend exceptionnelles:');
      logger.i('   - Employé: ${validation.employeeName}');
      logger.i('   - Manager: $managerName');
      logger.i('   - Message: $message');

      // TODO: Implémenter l'envoi de notification réelle
      // - Email au manager
      // - Notification push
      // - Notification dans l'app
    } catch (e) {
      logger.e('Erreur lors de l\'envoi de notification weekend', error: e);
    }
  }

  /// Détermine si les heures weekend sont exceptionnelles
  bool _isExceptionalWeekendHours(ValidationOvertimeSummary summary) {
    // Critères pour considérer les heures comme exceptionnelles:

    // 1. Plus de 2 jours de weekend travaillés
    if (summary.weekendDaysWorked > 2) {
      return true;
    }

    // 2. Plus de 16 heures de weekend au total
    if (summary.weekendOvertime > const Duration(hours: 16)) {
      return true;
    }

    // 3. Plus de 10 heures par jour de weekend en moyenne
    if (summary.weekendDaysWorked > 0) {
      final avgHoursPerDay = Duration(
          milliseconds: summary.weekendOvertime.inMilliseconds ~/
              summary.weekendDaysWorked);
      if (avgHoursPerDay > const Duration(hours: 10)) {
        return true;
      }
    }

    return false;
  }

  /// Construit le message de notification
  String _buildNotificationMessage(
    ValidationRequest validation,
    ValidationOvertimeSummary summary,
    String managerName,
  ) {
    final messages = <String>[];

    messages.add('Validation approuvée avec heures weekend exceptionnelles');
    messages.add('Employé: ${validation.employeeName}');
    messages.add('Manager: $managerName');
    messages.add(
        'Période: ${_formatDate(validation.periodStart)} - ${_formatDate(validation.periodEnd)}');

    if (summary.weekendDaysWorked > 2) {
      messages
          .add('⚠️ ${summary.weekendDaysWorked} jours de weekend travaillés');
    }

    if (summary.weekendOvertime > const Duration(hours: 16)) {
      messages.add('⚠️ ${summary.formattedWeekendOvertime} d\'heures weekend');
    }

    messages
        .add('Total heures supplémentaires: ${summary.formattedTotalOvertime}');

    return messages.join('\n');
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Génère une notification pour validation approuvée avec résumé overtime
  Future<void> notifyValidationApproved({
    required ValidationRequest validation,
    required ValidationOvertimeSummary overtimeSummary,
    required String managerName,
  }) async {
    try {
      logger.i('📧 Notification validation approuvée:');
      logger.i('   - Employé: ${validation.employeeName}');
      logger.i('   - Manager: $managerName');
      logger
          .i('   - Heures normales: ${overtimeSummary.formattedRegularHours}');
      logger.i(
          '   - Heures supplémentaires semaine: ${overtimeSummary.formattedWeekdayOvertime}');
      logger.i(
          '   - Heures supplémentaires weekend: ${overtimeSummary.formattedWeekendOvertime}');
      logger.i('   - Total: ${overtimeSummary.formattedTotalHours}');

      // Envoyer notification pour heures exceptionnelles si nécessaire
      await notifyExceptionalWeekendHours(
        validation: validation,
        overtimeSummary: overtimeSummary,
        managerName: managerName,
      );
    } catch (e) {
      logger.e('Erreur lors de l\'envoi de notification d\'approbation',
          error: e);
    }
  }
}
