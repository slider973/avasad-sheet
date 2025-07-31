import 'package:time_sheet/core/services/supabase/supabase_service.dart';
import '../../../../services/logger_service.dart';

/// Use case pour retirer un utilisateur de la liste des managers dans Supabase
class UnregisterManagerUseCase {
  final SupabaseService _supabaseService;

  UnregisterManagerUseCase(this._supabaseService);

  /// Supprime un manager de Supabase
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

      // Générer l'ID
      final managerId = '${company}_${firstName}_${lastName}'
          .toLowerCase()
          .replaceAll(' ', '_');

      logger.i('Suppression du manager de Supabase: $managerId');

      // Supprimer de Supabase
      await _supabaseService.client
          .from('managers')
          .delete()
          .eq('id', managerId);

      logger.i('Manager supprimé avec succès de Supabase');
      return true;
    } catch (e) {
      logger.e('Erreur lors de la suppression du manager: $e');
      return false;
    }
  }
}