import 'package:serverpod/serverpod.dart';
import 'dart:convert';
import '../generated/protocol.dart';

class NotificationEndpoint extends Endpoint {
  /// Obtenir les notifications d'un utilisateur
  Future<List<Notification>> getUserNotifications(
    Session session,
    String userId,
    {bool unreadOnly = false}
  ) async {
    try {
      return await Notification.db.find(
        session,
        where: unreadOnly 
          ? (t) => t.userId.equals(userId) & t.isRead.equals(false)
          : (t) => t.userId.equals(userId),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 50, // Limiter à 50 notifications récentes
      );
    } catch (e) {
      session.log('Error getting user notifications: $e');
      throw Exception('Impossible de récupérer les notifications: $e');
    }
  }
  
  /// Marquer une notification comme lue
  Future<Notification> markAsRead(
    Session session,
    int notificationId,
  ) async {
    try {
      final notification = await Notification.db.findById(
        session,
        notificationId,
      );
      
      if (notification == null) {
        throw Exception('Notification introuvable');
      }
      
      if (!notification.isRead) {
        notification.isRead = true;
        notification.readAt = DateTime.now();
        await Notification.db.updateRow(session, notification);
      }
      
      return notification;
    } catch (e) {
      session.log('Error marking notification as read: $e');
      throw Exception('Impossible de marquer la notification comme lue: $e');
    }
  }
  
  /// Marquer toutes les notifications d'un utilisateur comme lues
  Future<int> markAllAsRead(
    Session session,
    String userId,
  ) async {
    try {
      final unreadNotifications = await Notification.db.find(
        session,
        where: (t) => t.userId.equals(userId) & t.isRead.equals(false),
      );
      
      for (final notification in unreadNotifications) {
        notification.isRead = true;
        notification.readAt = DateTime.now();
        await Notification.db.updateRow(session, notification);
      }
      
      session.log('Marked ${unreadNotifications.length} notifications as read for user $userId');
      
      return unreadNotifications.length;
    } catch (e) {
      session.log('Error marking all notifications as read: $e');
      throw Exception('Impossible de marquer toutes les notifications comme lues: $e');
    }
  }
  
  /// Supprimer une notification
  Future<void> deleteNotification(
    Session session,
    int notificationId,
  ) async {
    try {
      final notification = await Notification.db.findById(
        session,
        notificationId,
      );
      
      if (notification == null) {
        throw Exception('Notification introuvable');
      }
      
      await Notification.db.deleteRow(session, notification);
    } catch (e) {
      session.log('Error deleting notification: $e');
      throw Exception('Impossible de supprimer la notification: $e');
    }
  }
  
  /// Supprimer toutes les notifications lues d'un utilisateur
  Future<int> deleteReadNotifications(
    Session session,
    String userId,
  ) async {
    try {
      final notifications = await Notification.db.find(
        session,
        where: (t) => t.userId.equals(userId) & t.isRead.equals(true),
      );
      
      int deletedCount = 0;
      for (final notification in notifications) {
        await Notification.db.deleteRow(session, notification);
        deletedCount++;
      }
      
      session.log('Deleted $deletedCount read notifications for user $userId');
      
      return deletedCount;
    } catch (e) {
      session.log('Error deleting read notifications: $e');
      throw Exception('Impossible de supprimer les notifications lues: $e');
    }
  }
  
  /// Obtenir le nombre de notifications non lues
  Future<int> getUnreadCount(
    Session session,
    String userId,
  ) async {
    try {
      final notifications = await Notification.db.find(
        session,
        where: (t) => t.userId.equals(userId) & t.isRead.equals(false),
      );
      return notifications.length;
    } catch (e) {
      session.log('Error getting unread count: $e');
      throw Exception('Impossible de compter les notifications non lues: $e');
    }
  }
  
  /// Créer une notification personnalisée
  Future<Notification> createNotification(
    Session session,
    String userId,
    NotificationType type,
    String title,
    String message,
    Map<String, dynamic>? data,
  ) async {
    try {
      final notification = Notification(
        userId: userId,
        type: type,
        title: title,
        message: message,
        data: data != null ? jsonEncode(data) : null,
      );
      
      await Notification.db.insertRow(session, notification);
      
      return notification;
    } catch (e) {
      session.log('Error creating notification: $e');
      throw Exception('Impossible de créer la notification: $e');
    }
  }
  
  /// Envoyer une notification à plusieurs utilisateurs
  Future<List<Notification>> createBulkNotifications(
    Session session,
    List<String> userIds,
    NotificationType type,
    String title,
    String message,
    Map<String, dynamic>? data,
  ) async {
    final notifications = <Notification>[];
    
    try {
      for (final userId in userIds) {
        final notification = Notification(
          userId: userId,
          type: type,
          title: title,
          message: message,
          data: data != null ? jsonEncode(data) : null,
        );
        
        await Notification.db.insertRow(session, notification);
        notifications.add(notification);
      }
      
      session.log('Created ${notifications.length} bulk notifications');
      
      return notifications;
    } catch (e) {
      session.log('Error creating bulk notifications: $e');
      throw Exception('Impossible de créer les notifications en masse: $e');
    }
  }
  
  /// Nettoyer les anciennes notifications
  Future<void> cleanupOldNotifications(Session session) async {
    try {
      // Supprimer les notifications lues de plus de 30 jours
      final cutoffDateRead = DateTime.now().subtract(Duration(days: 30));
      
      final allReadNotifications = await Notification.db.find(
        session,
        where: (t) => t.isRead.equals(true) & 
                      t.readAt.notEquals(null),
      );
      
      // Filtrer manuellement celles qui sont trop vieilles
      final readNotifications = allReadNotifications.where((n) =>
        n.readAt != null && n.readAt!.isBefore(cutoffDateRead)
      ).toList();
      
      int deletedReadCount = 0;
      for (final notification in readNotifications) {
        await Notification.db.deleteRow(session, notification);
        deletedReadCount++;
      }
      
      // Supprimer les notifications non lues de plus de 90 jours
      final cutoffDateUnread = DateTime.now().subtract(Duration(days: 90));
      
      final allUnreadNotifications = await Notification.db.find(
        session,
        where: (t) => t.isRead.equals(false),
      );
      
      // Filtrer manuellement celles qui sont trop vieilles
      final unreadNotifications = allUnreadNotifications.where((n) =>
        n.createdAt != null && n.createdAt!.isBefore(cutoffDateUnread)
      ).toList();
      
      int deletedUnreadCount = 0;
      for (final notification in unreadNotifications) {
        await Notification.db.deleteRow(session, notification);
        deletedUnreadCount++;
      }
      
      session.log('Cleaned up notifications: $deletedReadCount read, $deletedUnreadCount unread');
    } catch (e) {
      session.log('Error cleaning up old notifications: $e');
    }
  }
  
  /// Obtenir les notifications groupées par type
  Future<Map<NotificationType, List<Notification>>> getNotificationsByType(
    Session session,
    String userId,
  ) async {
    try {
      final notifications = await Notification.db.find(
        session,
        where: (t) => t.userId.equals(userId),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
      
      final groupedNotifications = <NotificationType, List<Notification>>{};
      
      for (final notification in notifications) {
        if (!groupedNotifications.containsKey(notification.type)) {
          groupedNotifications[notification.type] = [];
        }
        groupedNotifications[notification.type]!.add(notification);
      }
      
      return groupedNotifications;
    } catch (e) {
      session.log('Error getting notifications by type: $e');
      throw Exception('Impossible de grouper les notifications: $e');
    }
  }
  
  /// Envoyer des rappels pour les validations en attente
  Future<void> sendValidationReminders(Session session) async {
    try {
      // Trouver les validations en attente depuis plus de 3 jours
      final threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
      
      final allPendingValidations = await ValidationRequest.db.find(
        session,
        where: (t) => t.status.equals(ValidationStatus.pending),
      );
      
      // Filtrer manuellement celles qui sont vieilles de plus de 3 jours
      final pendingValidations = allPendingValidations.where((v) =>
        v.createdAt != null && v.createdAt!.isBefore(threeDaysAgo)
      ).toList();
      
      // Grouper par manager
      final validationsByManager = <String, List<ValidationRequest>>{};
      
      for (final validation in pendingValidations) {
        if (!validationsByManager.containsKey(validation.managerId)) {
          validationsByManager[validation.managerId] = [];
        }
        validationsByManager[validation.managerId]!.add(validation);
      }
      
      // Créer des notifications de rappel
      for (final entry in validationsByManager.entries) {
        final managerId = entry.key;
        final validations = entry.value;
        
        final notification = Notification(
          userId: managerId,
          type: NotificationType.validationReminder,
          title: 'Rappel: ${validations.length} validation(s) en attente',
          message: 'Vous avez ${validations.length} timesheet(s) à valider depuis plus de 3 jours.',
          data: jsonEncode({
            'validationIds': validations.map((v) => v.id).toList(),
          }),
        );
        
        await Notification.db.insertRow(session, notification);
      }
      
      session.log('Sent validation reminders to ${validationsByManager.length} managers');
    } catch (e) {
      session.log('Error sending validation reminders: $e');
    }
  }
}