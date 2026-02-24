import '../../../../services/logger_service.dart';

/// Use case pour enregistrer un utilisateur comme manager
/// TODO: Implémenter avec Supabase (table profiles.role)
class RegisterManagerUseCase {
  RegisterManagerUseCase();

  /// Enregistre un manager (no-op pour l'instant, sera implémenté via Supabase profiles)
  Future<bool> execute({
    required String firstName,
    required String lastName,
    required String company,
  }) async {
    try {
      if (firstName.isEmpty || lastName.isEmpty || company.isEmpty) {
        logger.w('Impossible d\'enregistrer le manager: informations manquantes');
        return false;
      }

      logger.i('RegisterManagerUseCase: enregistrement local uniquement (Serverpod retiré)');
      logger.i('  Company: $company, Name: $firstName $lastName');

      // TODO: Mettre à jour profiles.role via PowerSync/Supabase
      return true;
    } catch (e) {
      logger.e('Erreur lors de l\'enregistrement du manager: $e');
      return false;
    }
  }
}
