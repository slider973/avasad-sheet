import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/failures.dart';
import '../../features/auth/domain/entities/app_user.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    required SupabaseClient supabaseClient,
    GoogleSignIn? googleSignIn,
  })  : _supabaseClient = supabaseClient,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']);

  @override
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const Left(ServerFailure('Échec de la connexion'));
      }

      final profile = await _fetchProfile(response.user!.id);
      return Right(profile);
    } on AuthException catch (e) {
      return Left(ServerFailure(_mapAuthError(e)));
    } catch (e) {
      return Left(GeneralFailure('Erreur de connexion: $e'));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      if (response.user == null) {
        return const Left(ServerFailure('Échec de l\'inscription'));
      }

      // The profile is created automatically by the DB trigger
      final profile = AppUser(
        id: response.user!.id,
        email: email,
        firstName: firstName,
        lastName: lastName,
      );

      return Right(profile);
    } on AuthException catch (e) {
      return Left(ServerFailure(_mapAuthError(e)));
    } catch (e) {
      return Left(GeneralFailure('Erreur d\'inscription: $e'));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Left(GeneralFailure('Connexion Google annulée'));
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return const Left(ServerFailure('Impossible d\'obtenir le token Google'));
      }

      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        return const Left(ServerFailure('Échec de la connexion Google'));
      }

      // Update profile with Google info
      final user = response.user!;
      final metadata = user.userMetadata;
      await _supabaseClient.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'first_name': metadata?['full_name']?.toString().split(' ').first ?? '',
        'last_name': metadata?['full_name']?.toString().split(' ').skip(1).join(' ') ?? '',
      });

      final profile = await _fetchProfile(user.id);
      return Right(profile);
    } on AuthException catch (e) {
      return Left(ServerFailure(_mapAuthError(e)));
    } catch (e) {
      return Left(GeneralFailure('Erreur Google Sign-In: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabaseClient.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(GeneralFailure('Erreur de déconnexion: $e'));
    }
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) return const Right(null);

      final profile = await _fetchProfile(user.id);
      return Right(profile);
    } catch (e) {
      return Left(GeneralFailure('Erreur lors de la récupération du profil: $e'));
    }
  }

  @override
  Future<Either<Failure, AppUser>> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? organizationId,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure('Utilisateur non connecté'));
      }

      final updates = <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
      };
      if (phone != null) updates['phone'] = phone;
      if (organizationId != null) updates['organization_id'] = organizationId;

      await _supabaseClient.from('profiles').update(updates).eq('id', userId);

      final profile = await _fetchProfile(userId);
      return Right(profile);
    } catch (e) {
      return Left(GeneralFailure('Erreur de mise à jour du profil: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(ServerFailure(_mapAuthError(e)));
    } catch (e) {
      return Left(GeneralFailure('Erreur de réinitialisation: $e'));
    }
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _supabaseClient.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) return null;

      try {
        return await _fetchProfile(user.id);
      } catch (e) {
        debugPrint('Error fetching profile in auth stream: $e');
        return null;
      }
    });
  }

  @override
  bool get isAuthenticated => _supabaseClient.auth.currentUser != null;

  @override
  String? get currentUserId => _supabaseClient.auth.currentUser?.id;

  Future<AppUser> _fetchProfile(String userId) async {
    final response = await _supabaseClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return AppUser.fromMap(response);
  }

  String _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'Email ou mot de passe incorrect';
    }
    if (message.contains('email not confirmed')) {
      return 'Veuillez confirmer votre email avant de vous connecter';
    }
    if (message.contains('user already registered') ||
        message.contains('already registered')) {
      return 'Un compte existe déjà avec cet email';
    }
    if (message.contains('password')) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    if (message.contains('rate limit')) {
      return 'Trop de tentatives. Veuillez réessayer plus tard';
    }
    return 'Erreur d\'authentification: ${e.message}';
  }
}
