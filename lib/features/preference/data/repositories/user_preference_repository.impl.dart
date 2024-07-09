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
    final preference = UserPreferences(key: key, value: value);
    await isar.writeTxn(() async {
      await isar.userPreferences.put(preference);
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