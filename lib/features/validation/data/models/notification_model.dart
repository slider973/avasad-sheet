import 'package:time_sheet/features/validation/domain/entities/notification.dart';

/// Modèle pour la sérialisation des notifications
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    super.validationRequestId,
    required super.type,
    required super.title,
    required super.body,
    super.data,
    required super.read,
    super.readAt,
    required super.createdAt,
  });
  
  /// Crée un modèle depuis JSON (Supabase)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      validationRequestId: json['validation_request_id'] as String?,
      type: NotificationTypeExtension.fromString(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      read: json['read'] as bool,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  /// Convertit en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'validation_request_id': validationRequestId,
      'type': type.value,
      'title': title,
      'body': body,
      'data': data,
      'read': read,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// Crée un modèle depuis l'entité
  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      validationRequestId: entity.validationRequestId,
      type: entity.type,
      title: entity.title,
      body: entity.body,
      data: entity.data,
      read: entity.read,
      readAt: entity.readAt,
      createdAt: entity.createdAt,
    );
  }
}