import 'package:time_sheet/core/services/supabase/supabase_service.dart';
import '../../../../services/logger_service.dart';

/// Use case pour enregistrer un utilisateur comme manager dans Supabase
class RegisterManagerUseCase {
  final SupabaseService _supabaseService;

  RegisterManagerUseCase(this._supabaseService);

  /// Enregistre un manager dans Supabase
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

      // Générer l'ID et l'email
      final managerId = '${company}_${firstName}_${lastName}'
          .toLowerCase()
          .replaceAll(' ', '_');
      final email = '${firstName.toLowerCase()}.${lastName.toLowerCase()}@${company.toLowerCase().replaceAll(' ', '_')}.ch';

      logger.i('Enregistrement du manager dans Supabase:');
      logger.i('  ID: $managerId');
      logger.i('  Company: $company');
      logger.i('  Name: $firstName $lastName');
      logger.i('  Email: $email');

      // Enregistrer dans Supabase
      await _supabaseService.client.from('managers').upsert({
        'id': managerId,
        'company': company,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      }).select();

      logger.i('Manager enregistré avec succès dans Supabase');
      return true;
    } catch (e) {
      logger.e('Erreur lors de l\'enregistrement du manager: $e');
      return false;
    }
  }
}