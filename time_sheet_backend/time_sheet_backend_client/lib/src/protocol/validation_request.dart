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
import 'validation_status.dart' as _i2;

abstract class ValidationRequest implements _i1.SerializableModel {
  ValidationRequest._({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.managerId,
    required this.managerEmail,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    required this.pdfPath,
    required this.pdfHash,
    required this.pdfSizeBytes,
    this.managerSignature,
    this.managerComment,
    this.managerName,
    this.validatedAt,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ValidationRequest({
    int? id,
    required String employeeId,
    required String employeeName,
    required String managerId,
    required String managerEmail,
    required DateTime periodStart,
    required DateTime periodEnd,
    required _i2.ValidationStatus status,
    required String pdfPath,
    required String pdfHash,
    required int pdfSizeBytes,
    String? managerSignature,
    String? managerComment,
    String? managerName,
    DateTime? validatedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ValidationRequestImpl;

  factory ValidationRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return ValidationRequest(
      id: jsonSerialization['id'] as int?,
      employeeId: jsonSerialization['employeeId'] as String,
      employeeName: jsonSerialization['employeeName'] as String,
      managerId: jsonSerialization['managerId'] as String,
      managerEmail: jsonSerialization['managerEmail'] as String,
      periodStart:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['periodStart']),
      periodEnd:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['periodEnd']),
      status:
          _i2.ValidationStatus.fromJson((jsonSerialization['status'] as int)),
      pdfPath: jsonSerialization['pdfPath'] as String,
      pdfHash: jsonSerialization['pdfHash'] as String,
      pdfSizeBytes: jsonSerialization['pdfSizeBytes'] as int,
      managerSignature: jsonSerialization['managerSignature'] as String?,
      managerComment: jsonSerialization['managerComment'] as String?,
      managerName: jsonSerialization['managerName'] as String?,
      validatedAt: jsonSerialization['validatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['validatedAt']),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String employeeId;

  String employeeName;

  String managerId;

  String managerEmail;

  DateTime periodStart;

  DateTime periodEnd;

  _i2.ValidationStatus status;

  String pdfPath;

  String pdfHash;

  int pdfSizeBytes;

  String? managerSignature;

  String? managerComment;

  String? managerName;

  DateTime? validatedAt;

  DateTime? expiresAt;

  DateTime? createdAt;

  DateTime? updatedAt;

  /// Returns a shallow copy of this [ValidationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ValidationRequest copyWith({
    int? id,
    String? employeeId,
    String? employeeName,
    String? managerId,
    String? managerEmail,
    DateTime? periodStart,
    DateTime? periodEnd,
    _i2.ValidationStatus? status,
    String? pdfPath,
    String? pdfHash,
    int? pdfSizeBytes,
    String? managerSignature,
    String? managerComment,
    String? managerName,
    DateTime? validatedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'managerId': managerId,
      'managerEmail': managerEmail,
      'periodStart': periodStart.toJson(),
      'periodEnd': periodEnd.toJson(),
      'status': status.toJson(),
      'pdfPath': pdfPath,
      'pdfHash': pdfHash,
      'pdfSizeBytes': pdfSizeBytes,
      if (managerSignature != null) 'managerSignature': managerSignature,
      if (managerComment != null) 'managerComment': managerComment,
      if (managerName != null) 'managerName': managerName,
      if (validatedAt != null) 'validatedAt': validatedAt?.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ValidationRequestImpl extends ValidationRequest {
  _ValidationRequestImpl({
    int? id,
    required String employeeId,
    required String employeeName,
    required String managerId,
    required String managerEmail,
    required DateTime periodStart,
    required DateTime periodEnd,
    required _i2.ValidationStatus status,
    required String pdfPath,
    required String pdfHash,
    required int pdfSizeBytes,
    String? managerSignature,
    String? managerComment,
    String? managerName,
    DateTime? validatedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
          id: id,
          employeeId: employeeId,
          employeeName: employeeName,
          managerId: managerId,
          managerEmail: managerEmail,
          periodStart: periodStart,
          periodEnd: periodEnd,
          status: status,
          pdfPath: pdfPath,
          pdfHash: pdfHash,
          pdfSizeBytes: pdfSizeBytes,
          managerSignature: managerSignature,
          managerComment: managerComment,
          managerName: managerName,
          validatedAt: validatedAt,
          expiresAt: expiresAt,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Returns a shallow copy of this [ValidationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ValidationRequest copyWith({
    Object? id = _Undefined,
    String? employeeId,
    String? employeeName,
    String? managerId,
    String? managerEmail,
    DateTime? periodStart,
    DateTime? periodEnd,
    _i2.ValidationStatus? status,
    String? pdfPath,
    String? pdfHash,
    int? pdfSizeBytes,
    Object? managerSignature = _Undefined,
    Object? managerComment = _Undefined,
    Object? managerName = _Undefined,
    Object? validatedAt = _Undefined,
    Object? expiresAt = _Undefined,
    Object? createdAt = _Undefined,
    Object? updatedAt = _Undefined,
  }) {
    return ValidationRequest(
      id: id is int? ? id : this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      managerId: managerId ?? this.managerId,
      managerEmail: managerEmail ?? this.managerEmail,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfHash: pdfHash ?? this.pdfHash,
      pdfSizeBytes: pdfSizeBytes ?? this.pdfSizeBytes,
      managerSignature: managerSignature is String?
          ? managerSignature
          : this.managerSignature,
      managerComment:
          managerComment is String? ? managerComment : this.managerComment,
      managerName: managerName is String? ? managerName : this.managerName,
      validatedAt: validatedAt is DateTime? ? validatedAt : this.validatedAt,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
      updatedAt: updatedAt is DateTime? ? updatedAt : this.updatedAt,
    );
  }
}
