import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import '../repositories/validation_repository.dart';
import './get_employee_validations_usecase.dart';

/// Use case pour télécharger le PDF d'une validation
class DownloadValidationPdfUseCase implements UseCase<Uint8List, String> {
  final ValidationRepository repository;
  
  const DownloadValidationPdfUseCase(this.repository);
  
  @override
  Future<Either<Failure, Uint8List>> call(String validationId) async {
    if (validationId.isEmpty) {
      return Left(ValidationFailure('L\'ID de la validation est requis'));
    }
    
    return await repository.downloadValidationPdf(validationId);
  }
}