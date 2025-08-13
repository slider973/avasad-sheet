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

abstract class Manager implements _i1.SerializableModel {
  Manager._({
    this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.company,
    this.signature,
    bool? isActive,
    this.createdAt,
    this.updatedAt,
  }) : isActive = isActive ?? true;

  factory Manager({
    int? id,
    required String email,
    required String firstName,
    required String lastName,
    required String company,
    String? signature,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ManagerImpl;

  factory Manager.fromJson(Map<String, dynamic> jsonSerialization) {
    return Manager(
      id: jsonSerialization['id'] as int?,
      email: jsonSerialization['email'] as String,
      firstName: jsonSerialization['firstName'] as String,
      lastName: jsonSerialization['lastName'] as String,
      company: jsonSerialization['company'] as String,
      signature: jsonSerialization['signature'] as String?,
      isActive: jsonSerialization['isActive'] as bool,
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

  String email;

  String firstName;

  String lastName;

  String company;

  String? signature;

  bool isActive;

  DateTime? createdAt;

  DateTime? updatedAt;

  /// Returns a shallow copy of this [Manager]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Manager copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? company,
    String? signature,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      if (signature != null) 'signature': signature,
      'isActive': isActive,
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

class _ManagerImpl extends Manager {
  _ManagerImpl({
    int? id,
    required String email,
    required String firstName,
    required String lastName,
    required String company,
    String? signature,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
          id: id,
          email: email,
          firstName: firstName,
          lastName: lastName,
          company: company,
          signature: signature,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Returns a shallow copy of this [Manager]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Manager copyWith({
    Object? id = _Undefined,
    String? email,
    String? firstName,
    String? lastName,
    String? company,
    Object? signature = _Undefined,
    bool? isActive,
    Object? createdAt = _Undefined,
    Object? updatedAt = _Undefined,
  }) {
    return Manager(
      id: id is int? ? id : this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      signature: signature is String? ? signature : this.signature,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
      updatedAt: updatedAt is DateTime? ? updatedAt : this.updatedAt,
    );
  }
}
