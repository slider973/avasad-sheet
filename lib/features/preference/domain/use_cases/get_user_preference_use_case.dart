import '../repositories/user_preference_repository.dart';

class GetUserPreferenceUseCase {
  final UserPreferencesRepository repository;

  GetUserPreferenceUseCase(this.repository);

  Future<String?> execute(String key) async {
    return await repository.getPreference(key);
  }
}