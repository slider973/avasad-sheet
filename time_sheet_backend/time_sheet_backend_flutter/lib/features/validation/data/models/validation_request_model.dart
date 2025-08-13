import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';

/// Modèle pour la sérialisation des demandes de validation
class ValidationRequestModel extends ValidationRequest {
  const ValidationRequestModel({
    required super.id,
    required super.organizationId,
    required super.employeeId,
    required super.managerId,
    required super.periodStart,
    required super.periodEnd,
    required super.status,
    super.statusChangedAt,
    super.managerComment,
    super.managerSignature,
    super.validatedAt,
    required super.createdAt,
    required super.updatedAt,
    super.expiresAt,
    required super.pdfPath,
    required super.pdfHash,
    required super.pdfSizeBytes,
  });
  
  /// Crée un modèle depuis JSON
  factory ValidationRequestModel.fromJson(Map<String, dynamic> json) {
    return ValidationRequestModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      employeeId: json['employee_id'] as String,
      managerId: json['manager_id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      status: ValidationStatusExtension.fromString(json['status'] as String),
      statusChangedAt: json['status_changed_at'] != null 
          ? DateTime.parse(json['status_changed_at'] as String)
          : null,
      managerComment: json['manager_comment'] as String?,
      managerSignature: json['manager_signature'] as String?,
      validatedAt: json['validated_at'] != null
          ? DateTime.parse(json['validated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      pdfPath: json['pdf_path'] as String,
      pdfHash: json['pdf_hash'] as String,
      pdfSizeBytes: json['pdf_size_bytes'] as int,
    );
  }
  
  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'employee_id': employeeId,
      'manager_id': managerId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'status': status.value,
      'status_changed_at': statusChangedAt?.toIso8601String(),
      'manager_comment': managerComment,
      'manager_signature': managerSignature,
      'validated_at': validatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'pdf_path': pdfPath,
      'pdf_hash': pdfHash,
      'pdf_size_bytes': pdfSizeBytes,
    };
  }
  
  /// Crée un modèle depuis l'entité
  factory ValidationRequestModel.fromEntity(ValidationRequest entity) {
    return ValidationRequestModel(
      id: entity.id,
      organizationId: entity.organizationId,
      employeeId: entity.employeeId,
      managerId: entity.managerId,
      periodStart: entity.periodStart,
      periodEnd: entity.periodEnd,
      status: entity.status,
      statusChangedAt: entity.statusChangedAt,
      managerComment: entity.managerComment,
      managerSignature: entity.managerSignature,
      validatedAt: entity.validatedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      expiresAt: entity.expiresAt,
      pdfPath: entity.pdfPath,
      pdfHash: entity.pdfHash,
      pdfSizeBytes: entity.pdfSizeBytes,
    );
  }
}