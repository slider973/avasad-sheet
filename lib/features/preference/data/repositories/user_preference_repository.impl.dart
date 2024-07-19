import 'package:isar/isar.dart';

import '../../domain/repositories/user_preference_repository.dart';
import '../models/user_preference.dart';


class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
 Isar isar;

 UserPreferencesRepositoryImpl(this.isar);

  @override
  Future<void> setPreference(String key, String? value) async {
    if (value == null) {
      return;
    }

    await isar.writeTxn(() async {
      // Recherche d'une préférence existante avec la même clé
      final existingPreference = await isar.userPreferences
          .filter()
          .keyEqualTo(key)
          .findFirst();

      if (existingPreference != null) {
        // Si une préférence existe déjà, mettez à jour sa valeur
        existingPreference.value = value;
        await isar.userPreferences.put(existingPreference);
      } else {
        // Si aucune préférence n'existe, créez-en une nouvelle
        final preference = UserPreferences(key: key, value: value);
        await isar.userPreferences.put(preference);
      }
    });
  }

  @override
  Future<String?> getPreference(String key) async {
    final preference = await isar.userPreferences
        .filter()
        .keyEqualTo(key)
        .findFirst();
    return preference?.value;
  }
}