import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import '../entities/validation_request.dart';
import '../repositories/validation_repository.dart';
import 'package:time_sheet/services/logger_service.dart';

/// Use case pour créer une demande de validation
class CreateValidationRequestUseCase implements UseCase<ValidationRequest, CreateValidationParams> {
  final ValidationRepository repository;
  
  const CreateValidationRequestUseCase(this.repository);
  
  @override
  Future<Either<Failure, ValidationRequest>> call(CreateValidationParams params) async {
    // Validation des paramètres
    if (params.periodEnd.isBefore(params.periodStart)) {
      return Left(ValidationFailure('La date de fin doit être après la date de début'));
    }
    
    if (params.pdfBytes.isEmpty) {
      return Left(ValidationFailure('Le PDF ne peut pas être vide'));
    }
    
    if (params.employeeId == params.managerId) {
      return Left(ValidationFailure('Un employé ne peut pas s\'auto-valider'));
    }
    
    logger.i('CreateValidationRequestUseCase - Données reçues:');
    logger.i('- timesheetEntries: ${params.timesheetEntries?.length ?? 0} entrées');
    logger.i('- totalDays: ${params.totalDays}');
    logger.i('- totalHours: ${params.totalHours}');
    logger.i('- totalOvertimeHours: ${params.totalOvertimeHours}');
    
    return await repository.createValidationRequest(
      employeeId: params.employeeId,
      managerId: params.managerId,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
      pdfBytes: params.pdfBytes,
      employeeName: params.employeeName,
      employeeCompany: params.employeeCompany,
      timesheetEntries: params.timesheetEntries,
      totalDays: params.totalDays,
      totalHours: params.totalHours,
      totalOvertimeHours: params.totalOvertimeHours,
    );
  }
}

/// Paramètres pour créer une demande de validation
class CreateValidationParams {
  final String employeeId;
  final String managerId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Uint8List pdfBytes;
  // Données timesheet pour la régénération du PDF
  final String? employeeName;
  final String? employeeCompany;
  final List<Map<String, dynamic>>? timesheetEntries;
  final double? totalDays;
  final String? totalHours;
  final String? totalOvertimeHours;
  
  const CreateValidationParams({
    required this.employeeId,
    required this.managerId,
    required this.periodStart,
    required this.periodEnd,
    required this.pdfBytes,
    this.employeeName,
    this.employeeCompany,
    this.timesheetEntries,
    this.totalDays,
    this.totalHours,
    this.totalOvertimeHours,
  });
}

