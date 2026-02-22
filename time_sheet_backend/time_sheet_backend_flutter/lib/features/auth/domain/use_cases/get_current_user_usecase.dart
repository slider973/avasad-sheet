import 'package:fpdart/fpdart.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, AppUser?>> execute() {
    return repository.getCurrentUser();
  }
}
