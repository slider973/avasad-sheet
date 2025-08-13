import 'package:time_sheet_backend_client/time_sheet_backend_client.dart';
import 'package:time_sheet/core/services/serverpod/serverpod_service.dart';
import '../../../../services/logger_service.dart';

/// Use case pour retirer un utilisateur de la liste des managers dans Serverpod
class UnregisterManagerUseCase {
  final Client _client;

  UnregisterManagerUseCase() : _client = ServerpodService.client;

  /// Désactive un manager dans Serverpod
  /// Retourne true si succès, false sinon
  Future<bool> execute({
    required String firstName,
    required String lastName,
    required String company,
  }) async {
    try {
      // Validation des paramètres
      if (firstName.isEmpty || lastName.isEmpty || company.isEmpty) {
        logger.w('Impossible de supprimer le manager: informations manquantes');
        return false;
      }

      // Générer l'email pour retrouver le manager
      final email = '${firstName.toLowerCase()}.${lastName.toLowerCase()}@${company.toLowerCase().replaceAll(' ', '_')}.ch';

      logger.i('Désactivation du manager dans Serverpod:');
      logger.i('  Email: $email');

      // Récupérer le manager par email
      final manager = await _client.manager.getManagerByEmail(email);
      
      if (manager == null) {
        logger.w('Manager non trouvé avec l\'email: $email');
        return false;
      }

      // Désactiver le manager
      await _client.manager.deactivateManager(manager.id!);

      logger.i('Manager désactivé avec succès dans Serverpod');
      return true;
    } catch (e) {
      logger.e('Erreur lors de la désactivation du manager: $e');
      return false;
    }
  }
}