import 'package:powersync/powersync.dart';

import '../../domain/repositories/user_preference_repository.dart';

/// PowerSync-based implementation of UserPreferencesRepository.
/// Uses a local-only SQLite table (not synced to PostgreSQL).
class UserPreferencesRepositoryPowerSyncImpl
    implements UserPreferencesRepository {
  final PowerSyncDatabase db;

  UserPreferencesRepositoryPowerSyncImpl(this.db);

  /// Create the local-only table if it doesn't exist.
  /// Must be called once during app initialization.
  Future<void> initialize() async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  @override
  Future<void> setPreference(String key, String? value) async {
    if (value == null) {
      return;
    }
    await db.execute(
      'INSERT OR REPLACE INTO user_preferences (key, value) VALUES (?, ?)',
      [key, value],
    );
  }

  @override
  Future<String?> getPreference(String key) async {
    final row = await db.getOptional(
      'SELECT value FROM user_preferences WHERE key = ?',
      [key],
    );
    return row?['value'] as String?;
  }

  @override
  Future<void> clearAll() async {
    await db.execute('DELETE FROM user_preferences');
  }
}
