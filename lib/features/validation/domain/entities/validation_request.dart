import 'package:equatable/equatable.dart';

/// Entité représentant une demande de validation
class ValidationRequest extends Equatable {
  final String id;
  final String organizationId;
  final String employeeId;
  final String managerId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final ValidationStatus status;
  final DateTime? statusChangedAt;
  final String? managerComment;
  final String? managerSignature;
  final DateTime? validatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  
  // Métadonnées du PDF
  final String pdfPath;
  final String pdfHash;
  final int pdfSizeBytes;
  
  const ValidationRequest({
    required this.id,
    required this.organizationId,
    required this.employeeId,
    required this.managerId,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    this.statusChangedAt,
    this.managerComment,
    this.managerSignature,
    this.validatedAt,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    required this.pdfPath,
    required this.pdfHash,
    required this.pdfSizeBytes,
  });
  
  /// Vérifie si la demande est expirée
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  /// Vérifie si la demande est en attente
  bool get isPending => status == ValidationStatus.pending;
  
  /// Vérifie si la demande est approuvée
  bool get isApproved => status == ValidationStatus.approved;
  
  /// Vérifie si la demande est rejetée
  bool get isRejected => status == ValidationStatus.rejected;
  
  /// Copie avec modifications
  ValidationRequest copyWith({
    String? id,
    String? organizationId,
    String? employeeId,
    String? managerId,
    DateTime? periodStart,
    DateTime? periodEnd,
    ValidationStatus? status,
    DateTime? statusChangedAt,
    String? managerComment,
    String? managerSignature,
    DateTime? validatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    String? pdfPath,
    String? pdfHash,
    int? pdfSizeBytes,
  }) {
    return ValidationRequest(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      employeeId: employeeId ?? this.employeeId,
      managerId: managerId ?? this.managerId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      managerComment: managerComment ?? this.managerComment,
      managerSignature: managerSignature ?? this.managerSignature,
      validatedAt: validatedAt ?? this.validatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfHash: pdfHash ?? this.pdfHash,
      pdfSizeBytes: pdfSizeBytes ?? this.pdfSizeBytes,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    organizationId,
    employeeId,
    managerId,
    periodStart,
    periodEnd,
    status,
    statusChangedAt,
    managerComment,
    managerSignature,
    validatedAt,
    createdAt,
    updatedAt,
    expiresAt,
    pdfPath,
    pdfHash,
    pdfSizeBytes,
  ];
}

/// Statut de validation
enum ValidationStatus {
  pending,
  approved,
  rejected,
}

/// Extension pour la sérialisation
extension ValidationStatusExtension on ValidationStatus {
  String get value {
    switch (this) {
      case ValidationStatus.pending:
        return 'pending';
      case ValidationStatus.approved:
        return 'approved';
      case ValidationStatus.rejected:
        return 'rejected';
    }
  }
  
  static ValidationStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ValidationStatus.pending;
      case 'approved':
        return ValidationStatus.approved;
      case 'rejected':
        return ValidationStatus.rejected;
      default:
        throw ArgumentError('Invalid validation status: $value');
    }
  }
}