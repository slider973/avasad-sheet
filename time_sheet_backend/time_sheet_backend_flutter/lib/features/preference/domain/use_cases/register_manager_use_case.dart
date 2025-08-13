import 'package:time_sheet_backend_client/time_sheet_backend_client.dart';
import 'package:time_sheet/core/services/serverpod/serverpod_service.dart';
import '../../../../services/logger_service.dart';

/// Use case pour enregistrer ou réactiver un utilisateur comme manager dans Serverpod
class RegisterManagerUseCase {
  final Client _client;

  RegisterManagerUseCase() : _client = ServerpodService.client;

  /// Enregistre ou réactive un manager dans Serverpod
  /// Si le manager existe déjà mais est inactif, il sera réactivé
  /// Retourne true si succès, false sinon
  Future<bool> execute({
    required String firstName,
    required String lastName,
    required String company,
  }) async {
    try {
      // Validation des paramètres
      if (firstName.isEmpty || lastName.isEmpty || company.isEmpty) {
        logger.w('Impossible d\'enregistrer le manager: informations manquantes');
        return false;
      }

      // Générer l'email
      final email = '${firstName.toLowerCase()}.${lastName.toLowerCase()}@${company.toLowerCase().replaceAll(' ', '_')}.ch';

      logger.i('Enregistrement/réactivation du manager dans Serverpod:');
      logger.i('  Company: $company');
      logger.i('  Name: $firstName $lastName');
      logger.i('  Email: $email');

      // Utiliser createOrActivateManager qui gère la création ou réactivation
      await _client.manager.createOrActivateManager(
        email,
        firstName,
        lastName,
        company,
        null, // signature (optionnelle)
      );

      logger.i('Manager enregistré/réactivé avec succès dans Serverpod');
      return true;
    } catch (e) {
      logger.e('Erreur lors de l\'enregistrement/réactivation du manager: $e');
      return false;
    }
  }
}