import '../repositories/user_preference_repository.dart';

class SetUserPreferenceUseCase {
  final UserPreferencesRepository repository;

  SetUserPreferenceUseCase(this.repository);

  Future<void> execute(String key, String? value) async {
    await repository.setPreference(key, value);
  }
}