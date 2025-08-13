/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'notification_type.dart' as _i2;

abstract class Notification implements _i1.SerializableModel {
  Notification._({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    bool? isRead,
    this.createdAt,
    this.readAt,
  }) : isRead = isRead ?? false;

  factory Notification({
    int? id,
    required String userId,
    required _i2.NotificationType type,
    required String title,
    required String message,
    String? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) = _NotificationImpl;

  factory Notification.fromJson(Map<String, dynamic> jsonSerialization) {
    return Notification(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      type: _i2.NotificationType.fromJson((jsonSerialization['type'] as int)),
      title: jsonSerialization['title'] as String,
      message: jsonSerialization['message'] as String,
      data: jsonSerialization['data'] as String?,
      isRead: jsonSerialization['isRead'] as bool,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      readAt: jsonSerialization['readAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['readAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String userId;

  _i2.NotificationType type;

  String title;

  String message;

  String? data;

  bool isRead;

  DateTime? createdAt;

  DateTime? readAt;

  /// Returns a shallow copy of this [Notification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Notification copyWith({
    int? id,
    String? userId,
    _i2.NotificationType? type,
    String? title,
    String? message,
    String? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'type': type.toJson(),
      'title': title,
      'message': message,
      if (data != null) 'data': data,
      'isRead': isRead,
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (readAt != null) 'readAt': readAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationImpl extends Notification {
  _NotificationImpl({
    int? id,
    required String userId,
    required _i2.NotificationType type,
    required String title,
    required String message,
    String? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) : super._(
          id: id,
          userId: userId,
          type: type,
          title: title,
          message: message,
          data: data,
          isRead: isRead,
          createdAt: createdAt,
          readAt: readAt,
        );

  /// Returns a shallow copy of this [Notification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Notification copyWith({
    Object? id = _Undefined,
    String? userId,
    _i2.NotificationType? type,
    String? title,
    String? message,
    Object? data = _Undefined,
    bool? isRead,
    Object? createdAt = _Undefined,
    Object? readAt = _Undefined,
  }) {
    return Notification(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data is String? ? data : this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
      readAt: readAt is DateTime? ? readAt : this.readAt,
    );
  }
}
