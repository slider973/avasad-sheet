import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? organizationId;
  final String role;
  final String? signatureUrl;
  final String? phone;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.organizationId,
    this.role = 'employee',
    this.signatureUrl,
    this.phone,
    this.isActive = true,
  });

  bool get isManager => role == 'manager' || role == 'admin';
  bool get isAdmin => role == 'admin';
  bool get isOrgAdmin => role == 'org_admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get hasManagerAccess => isManager || isOrgAdmin || isSuperAdmin;
  bool get hasCompletedProfile => firstName.isNotEmpty && lastName.isNotEmpty;

  AppUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? organizationId,
    String? role,
    String? signatureUrl,
    String? phone,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      organizationId: organizationId ?? this.organizationId,
      role: role ?? this.role,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String? ?? '',
      organizationId: map['organization_id'] as String?,
      role: map['role'] as String? ?? 'employee',
      signatureUrl: map['signature_url'] as String?,
      phone: map['phone'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'organization_id': organizationId,
      'role': role,
      'signature_url': signatureUrl,
      'phone': phone,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, email, firstName, lastName, organizationId, role, signatureUrl, phone, isActive];
}
