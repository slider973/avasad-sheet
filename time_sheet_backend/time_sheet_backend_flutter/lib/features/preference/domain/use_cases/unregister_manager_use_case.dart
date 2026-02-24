import '../../../../services/logger_service.dart';

/// Use case pour retirer un utilisateur de la liste des managers
/// TODO: Implémenter avec Supabase (table profiles.role)
class UnregisterManagerUseCase {
  UnregisterManagerUseCase();

  /// Désactive un manager (no-op pour l'instant, sera implémenté via Supabase profiles)
  Future<bool> execute({
    required String firstName,
    required String lastName,
    required String company,
  }) async {
    try {
      if (firstName.isEmpty || lastName.isEmpty || company.isEmpty) {
        logger.w('Impossible de supprimer le manager: informations manquantes');
        return false;
      }

      logger.i('UnregisterManagerUseCase: désactivation locale uniquement (Serverpod retiré)');

      // TODO: Mettre à jour profiles.role via PowerSync/Supabase
      return true;
    } catch (e) {
      logger.e('Erreur lors de la désactivation du manager: $e');
      return false;
    }
  }
}
