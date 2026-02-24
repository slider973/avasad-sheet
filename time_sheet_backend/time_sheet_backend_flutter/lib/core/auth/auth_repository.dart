import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? organizationId,
  });

  /// Sign in with Google
  Future<Either<Failure, AppUser>> signInWithGoogle();

  /// Sign out
  Future<Either<Failure, void>> signOut();

  /// Get current authenticated user
  Future<Either<Failure, AppUser?>> getCurrentUser();

  /// Update user profile
  Future<Either<Failure, AppUser>> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? organizationId,
  });

  /// Send password reset email
  Future<Either<Failure, void>> resetPassword({required String email});

  /// Stream of auth state changes
  Stream<AppUser?> get authStateChanges;

  /// Whether user is currently authenticated
  bool get isAuthenticated;

  /// Current user ID
  String? get currentUserId;
}
