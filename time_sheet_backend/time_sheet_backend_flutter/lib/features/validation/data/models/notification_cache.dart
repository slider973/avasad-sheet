import 'package:isar/isar.dart';

part 'notification_cache.g.dart';

/// Modèle Isar pour la persistance locale des notifications
@Collection()
class NotificationCache {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true, replace: true)
  late String notificationId;
  
  late String jsonData;
  
  @Index()
  late String userId;
  
  late bool isRead;
  
  late DateTime createdAt;
}