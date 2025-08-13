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
import 'queue_status.dart' as _i2;

abstract class PdfRegenerationQueue implements _i1.SerializableModel {
  PdfRegenerationQueue._({
    this.id,
    required this.validationId,
    _i2.QueueStatus? status,
    this.createdAt,
    this.processedAt,
    this.errorMessage,
    int? retryCount,
  })  : status = status ?? _i2.QueueStatus.pending,
        retryCount = retryCount ?? 0;

  factory PdfRegenerationQueue({
    int? id,
    required int validationId,
    _i2.QueueStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? errorMessage,
    int? retryCount,
  }) = _PdfRegenerationQueueImpl;

  factory PdfRegenerationQueue.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return PdfRegenerationQueue(
      id: jsonSerialization['id'] as int?,
      validationId: jsonSerialization['validationId'] as int,
      status: _i2.QueueStatus.fromJson((jsonSerialization['status'] as int)),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      processedAt: jsonSerialization['processedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['processedAt']),
      errorMessage: jsonSerialization['errorMessage'] as String?,
      retryCount: jsonSerialization['retryCount'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int validationId;

  _i2.QueueStatus status;

  DateTime? createdAt;

  DateTime? processedAt;

  String? errorMessage;

  int retryCount;

  /// Returns a shallow copy of this [PdfRegenerationQueue]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PdfRegenerationQueue copyWith({
    int? id,
    int? validationId,
    _i2.QueueStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? errorMessage,
    int? retryCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'validationId': validationId,
      'status': status.toJson(),
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (processedAt != null) 'processedAt': processedAt?.toJson(),
      if (errorMessage != null) 'errorMessage': errorMessage,
      'retryCount': retryCount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PdfRegenerationQueueImpl extends PdfRegenerationQueue {
  _PdfRegenerationQueueImpl({
    int? id,
    required int validationId,
    _i2.QueueStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? errorMessage,
    int? retryCount,
  }) : super._(
          id: id,
          validationId: validationId,
          status: status,
          createdAt: createdAt,
          processedAt: processedAt,
          errorMessage: errorMessage,
          retryCount: retryCount,
        );

  /// Returns a shallow copy of this [PdfRegenerationQueue]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PdfRegenerationQueue copyWith({
    Object? id = _Undefined,
    int? validationId,
    _i2.QueueStatus? status,
    Object? createdAt = _Undefined,
    Object? processedAt = _Undefined,
    Object? errorMessage = _Undefined,
    int? retryCount,
  }) {
    return PdfRegenerationQueue(
      id: id is int? ? id : this.id,
      validationId: validationId ?? this.validationId,
      status: status ?? this.status,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
      processedAt: processedAt is DateTime? ? processedAt : this.processedAt,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
