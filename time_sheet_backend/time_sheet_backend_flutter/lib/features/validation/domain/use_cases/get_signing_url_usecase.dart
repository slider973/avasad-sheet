import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/use_cases/use_case.dart';
import '../repositories/validation_repository.dart';

/// Use case pour générer un lien de signature externe
class GetSigningUrlUseCase implements UseCase<String, GetSigningUrlParams> {
  final ValidationRepository repository;

  const GetSigningUrlUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(GetSigningUrlParams params) async {
    if (params.validationId.isEmpty) {
      return const Left(ValidationFailure('L\'ID de la validation est requis'));
    }
    if (params.signerRole.isEmpty) {
      return const Left(ValidationFailure('Le rôle du signataire est requis'));
    }
    if (params.signerName.isEmpty) {
      return const Left(ValidationFailure('Le nom du signataire est requis'));
    }

    return await repository.getSigningUrl(
      validationId: params.validationId,
      signerRole: params.signerRole,
      signerName: params.signerName,
      signerEmail: params.signerEmail,
    );
  }
}

/// Paramètres pour générer un lien de signature
class GetSigningUrlParams {
  final String validationId;
  final String signerRole;
  final String signerName;
  final String? signerEmail;

  const GetSigningUrlParams({
    required this.validationId,
    required this.signerRole,
    required this.signerName,
    this.signerEmail,
  });
}
