import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import '../entities/validation_request.dart';
import '../repositories/validation_repository.dart';

/// Use case pour approuver une demande de validation
class ApproveValidationUseCase implements UseCase<ValidationRequest, ApproveValidationParams> {
  final ValidationRepository repository;
  
  const ApproveValidationUseCase(this.repository);
  
  @override
  Future<Either<Failure, ValidationRequest>> call(ApproveValidationParams params) async {
    return await repository.approveValidation(
      validationId: params.validationId,
      managerSignature: params.managerSignature,
      comment: params.comment,
    );
  }
}

/// Paramètres pour approuver une validation
class ApproveValidationParams {
  final String validationId;
  final String managerSignature;
  final String? comment;
  
  const ApproveValidationParams({
    required this.validationId,
    required this.managerSignature,
    this.comment,
  });
}

