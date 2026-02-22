import 'package:fpdart/fpdart.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Either<Failure, AppUser>> execute({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) {
    return repository.signUpWithEmail(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }
}
