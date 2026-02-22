import 'package:fpdart/fpdart.dart';
import '../../../../core/auth/auth_repository.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<Either<Failure, AppUser>> execute({
    required String email,
    required String password,
  }) {
    return repository.signInWithEmail(email: email, password: password);
  }
}
