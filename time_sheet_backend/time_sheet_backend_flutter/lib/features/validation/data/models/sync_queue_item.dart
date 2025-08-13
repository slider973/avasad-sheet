import 'package:isar/isar.dart';

part 'sync_queue_item.g.dart';

/// Modèle Isar pour la file de synchronisation
@Collection()
class SyncQueueItem {
  Id id = Isar.autoIncrement;
  
  late String action;
  late String payloadJson;
  late bool synced;
  late DateTime createdAt;
  int retryCount = 0;
  String? lastError;
}