import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import '../entities/validation_request.dart';
import '../repositories/validation_repository.dart';

/// Use case pour rejeter une demande de validation
class RejectValidationUseCase implements UseCase<ValidationRequest, RejectValidationParams> {
  final ValidationRepository repository;
  
  const RejectValidationUseCase(this.repository);
  
  @override
  Future<Either<Failure, ValidationRequest>> call(RejectValidationParams params) async {
    // Validation des paramètres
    if (params.comment.isEmpty) {
      return Left(ValidationFailure('Un commentaire est requis pour rejeter une validation'));
    }
    
    if (params.comment.length < 10) {
      return Left(ValidationFailure('Le commentaire doit contenir au moins 10 caractères'));
    }
    
    return await repository.rejectValidation(
      validationId: params.validationId,
      comment: params.comment,
    );
  }
}

/// Paramètres pour rejeter une validation
class RejectValidationParams {
  final String validationId;
  final String comment;
  
  const RejectValidationParams({
    required this.validationId,
    required this.comment,
  });
}