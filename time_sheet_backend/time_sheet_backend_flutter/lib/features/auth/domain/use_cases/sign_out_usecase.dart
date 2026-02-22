import 'package:fpdart/fpdart.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/error/failures.dart';

class SignOutUseCase {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  Future<Either<Failure, void>> execute() {
    return repository.signOut();
  }
}
