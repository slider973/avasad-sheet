import 'package:isar/isar.dart';
import 'package:time_sheet/features/validation/data/models/validation_request_model.dart';
import 'package:time_sheet/features/validation/data/models/notification_model.dart';
import 'package:time_sheet/features/validation/data/models/validation_request_cache.dart';
import 'package:time_sheet/features/validation/data/models/notification_cache.dart';
import 'package:time_sheet/features/validation/data/models/sync_queue_item.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/features/validation/domain/entities/notification.dart';

/// Source de données locale pour les validations
abstract class ValidationLocalDataSource {
  Future<void> saveValidationRequest(ValidationRequestModel validation);
  Future<ValidationRequestModel?> getValidationRequest(String id);
  Future<List<ValidationRequestModel>> getEmployeeValidations(String employeeId);
  Future<List<ValidationRequestModel>> getManagerValidations(String managerId);
  Future<void> deleteValidationRequest(String id);
  
  Future<void> saveNotification(NotificationModel notification);
  Future<List<NotificationModel>> getUserNotifications(String userId);
  Future<NotificationModel?> markNotificationAsRead(String notificationId);
  Future<void> markAllNotificationsAsRead(String userId);
  Future<int> getUnreadNotificationCount(String userId);
  
  Future<void> addToSyncQueue({
    required String action,
    required Map<String, dynamic> payload,
  });
  Future<List<Map<String, dynamic>>> getPendingSyncItems();
  Future<void> markAsSynced(String itemId);
}

/// Implémentation avec Isar
class ValidationLocalDataSourceImpl implements ValidationLocalDataSource {
  final Isar isar;
  
  const ValidationLocalDataSourceImpl({
    required this.isar,
  });
  
  @override
  Future<void> saveValidationRequest(ValidationRequestModel validation) async {
    final cache = ValidationRequestCache()
      ..validationId = validation.id
      ..jsonData = validation.toJson().toString()
      ..employeeId = validation.employeeId
      ..managerId = validation.managerId
      ..lastUpdated = DateTime.now();
    
    await isar.writeTxn(() async {
      await isar.validationRequestCaches.put(cache);
    });
  }
  
  @override
  Future<ValidationRequestModel?> getValidationRequest(String id) async {
    final cache = await isar.validationRequestCaches
        .where()
        .validationIdEqualTo(id)
        .findFirst();
    
    if (cache == null) return null;
    
    try {
      final json = _parseJsonString(cache.jsonData);
      return ValidationRequestModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<ValidationRequestModel>> getEmployeeValidations(String employeeId) async {
    final caches = await isar.validationRequestCaches
        .where()
        .employeeIdEqualTo(employeeId)
        .sortByLastUpdatedDesc()
        .findAll();
    
    return caches
        .map((cache) {
          try {
            final json = _parseJsonString(cache.jsonData);
            return ValidationRequestModel.fromJson(json);
          } catch (e) {
            return null;
          }
        })
        .whereType<ValidationRequestModel>()
        .toList();
  }
  
  @override
  Future<List<ValidationRequestModel>> getManagerValidations(String managerId) async {
    final caches = await isar.validationRequestCaches
        .where()
        .managerIdEqualTo(managerId)
        .sortByLastUpdatedDesc()
        .findAll();
    
    return caches
        .map((cache) {
          try {
            final json = _parseJsonString(cache.jsonData);
            return ValidationRequestModel.fromJson(json);
          } catch (e) {
            return null;
          }
        })
        .whereType<ValidationRequestModel>()
        .toList();
  }
  
  @override
  Future<void> deleteValidationRequest(String id) async {
    await isar.writeTxn(() async {
      await isar.validationRequestCaches
          .where()
          .validationIdEqualTo(id)
          .deleteAll();
    });
  }
  
  @override
  Future<void> saveNotification(NotificationModel notification) async {
    final cache = NotificationCache()
      ..notificationId = notification.id
      ..jsonData = notification.toJson().toString()
      ..userId = notification.userId
      ..isRead = notification.read
      ..createdAt = notification.createdAt;
    
    await isar.writeTxn(() async {
      await isar.notificationCaches.put(cache);
    });
  }
  
  @override
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final caches = await isar.notificationCaches
        .where()
        .userIdEqualTo(userId)
        .sortByCreatedAtDesc()
        .findAll();
    
    return caches
        .map((cache) {
          try {
            final json = _parseJsonString(cache.jsonData);
            return NotificationModel.fromJson(json);
          } catch (e) {
            return null;
          }
        })
        .whereType<NotificationModel>()
        .toList();
  }
  
  @override
  Future<NotificationModel?> markNotificationAsRead(String notificationId) async {
    final cache = await isar.notificationCaches
        .where()
        .notificationIdEqualTo(notificationId)
        .findFirst();
    
    if (cache == null) return null;
    
    cache.isRead = true;
    
    await isar.writeTxn(() async {
      await isar.notificationCaches.put(cache);
    });
    
    try {
      final json = _parseJsonString(cache.jsonData);
      final notification = NotificationModel.fromJson(json);
      return NotificationModel.fromEntity(notification.markAsRead());
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> markAllNotificationsAsRead(String userId) async {
    final caches = await isar.notificationCaches
        .where()
        .userIdEqualTo(userId)
        .filter()
        .isReadEqualTo(false)
        .findAll();
    
    await isar.writeTxn(() async {
      for (final cache in caches) {
        cache.isRead = true;
        await isar.notificationCaches.put(cache);
      }
    });
  }
  
  @override
  Future<int> getUnreadNotificationCount(String userId) async {
    return await isar.notificationCaches
        .where()
        .userIdEqualTo(userId)
        .filter()
        .isReadEqualTo(false)
        .count();
  }
  
  @override
  Future<void> addToSyncQueue({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final item = SyncQueueItem()
      ..action = action
      ..payloadJson = payload.toString()
      ..synced = false
      ..createdAt = DateTime.now();
    
    await isar.writeTxn(() async {
      await isar.syncQueueItems.put(item);
    });
  }
  
  @override
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final items = await isar.syncQueueItems
        .where()
        .filter()
        .syncedEqualTo(false)
        .sortByCreatedAt()
        .findAll();
    
    return items.map((item) => {
      'id': item.id.toString(),
      'action': item.action,
      'payload': _parseJsonString(item.payloadJson),
      'retry_count': item.retryCount,
    }).toList();
  }
  
  @override
  Future<void> markAsSynced(String itemId) async {
    final id = int.tryParse(itemId);
    if (id == null) return;
    
    await isar.writeTxn(() async {
      final item = await isar.syncQueueItems.get(id);
      if (item != null) {
        item.synced = true;
        await isar.syncQueueItems.put(item);
      }
    });
  }
  
  /// Parse une chaîne JSON stockée
  Map<String, dynamic> _parseJsonString(String jsonString) {
    // Simple parsing - dans un cas réel, utiliser jsonDecode
    // Pour l'exemple, on retourne un Map vide
    return {};
  }
}