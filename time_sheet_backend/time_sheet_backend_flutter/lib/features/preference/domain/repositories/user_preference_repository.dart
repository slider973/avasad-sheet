abstract class UserPreferencesRepository {
  Future<void> setPreference(String key, String? value);
  Future<String?> getPreference(String key);
}