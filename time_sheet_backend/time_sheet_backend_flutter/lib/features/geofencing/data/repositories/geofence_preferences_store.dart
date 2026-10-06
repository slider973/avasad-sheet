import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/features/preference/domain/repositories/user_preference_repository.dart';

/// Stockage des réglages de géorepérage, partagé entre l'application et
/// l'isolate d'arrière-plan.
///
/// L'implémentation PowerSync de [UserPreferencesRepository] ne convient pas
/// ici : elle exige une `PowerSyncDatabase` ouverte, ce qui est impossible
/// depuis l'isolate déclenché par le plugin natif (base déjà verrouillée par
/// l'application, moteur de synchronisation non initialisé).
///
/// SharedPreferences est au contraire lisible et inscriptible depuis les deux
/// contextes, ce qui garantit une source de vérité unique pour les réglages
/// du pointage automatique.
class GeofencePreferencesStore implements UserPreferencesRepository {
  static const String _prefix = 'geofencing_pref_';

  const GeofencePreferencesStore();

  @override
  Future<String?> getPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // L'application au premier plan a pu écrire depuis le dernier cache.
    await prefs.reload();
    return prefs.getString('$_prefix$key');
  }

  @override
  Future<void> setPreference(String key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('$_prefix$key');
      return;
    }
    await prefs.setString('$_prefix$key', value);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
