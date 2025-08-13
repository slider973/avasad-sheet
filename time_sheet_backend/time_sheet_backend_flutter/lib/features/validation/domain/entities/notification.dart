import 'package:equatable/equatable.dart';

/// Entité représentant une notification
class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String? validationRequestId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;
  
  const NotificationEntity({
    required this.id,
    required this.userId,
    this.validationRequestId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.read,
    this.readAt,
    required this.createdAt,
  });
  
  /// Marque la notification comme lue
  NotificationEntity markAsRead() {
    return NotificationEntity(
      id: id,
      userId: userId,
      validationRequestId: validationRequestId,
      type: type,
      title: title,
      body: body,
      data: data,
      read: true,
      readAt: DateTime.now(),
      createdAt: createdAt,
    );
  }
  
  /// Copie avec modifications
  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? validationRequestId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      validationRequestId: validationRequestId ?? this.validationRequestId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    userId,
    validationRequestId,
    type,
    title,
    body,
    data,
    read,
    readAt,
    createdAt,
  ];
}

/// Type de notification
enum NotificationType {
  validationRequest,
  validationFeedback,
  reminder,
}

/// Extension pour la sérialisation
extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.validationRequest:
        return 'validation_request';
      case NotificationType.validationFeedback:
        return 'validation_feedback';
      case NotificationType.reminder:
        return 'reminder';
    }
  }
  
  static NotificationType fromString(String value) {
    switch (value) {
      case 'validation_request':
        return NotificationType.validationRequest;
      case 'validation_feedback':
        return NotificationType.validationFeedback;
      case 'reminder':
        return NotificationType.reminder;
      default:
        throw ArgumentError('Invalid notification type: $value');
    }
  }
}