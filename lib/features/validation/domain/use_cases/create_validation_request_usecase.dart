import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import '../entities/validation_request.dart';
import '../repositories/validation_repository.dart';

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
    
    return await repository.createValidationRequest(
      employeeId: params.employeeId,
      managerId: params.managerId,
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
      pdfBytes: params.pdfBytes,
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
  
  const CreateValidationParams({
    required this.employeeId,
    required this.managerId,
    required this.periodStart,
    required this.periodEnd,
    required this.pdfBytes,
  });
}

/// Failure spécifique aux validations
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}