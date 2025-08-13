import 'package:isar/isar.dart';

part 'user_preference.g.dart';

@collection
class UserPreferences {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String key;

  String value;

  UserPreferences({required this.key, required this.value});
}