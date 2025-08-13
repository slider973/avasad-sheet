import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firebase_service.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  /// Initialise Supabase avec les configurations
  Future<void> initialize() async {
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://ryxhkomnfdwsbfqdtvtv.supabase.co',
      ),
      anonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5eGhrb21uZmR3c2JmcWR0dnR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2MzY1MDMsImV4cCI6MjA2OTIxMjUwM30.TpRS4bvYZGgvmyDQ6FnStT_ArkMxfHLmhpkcy0aYqy0',
      ),
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: kDebugMode ? RealtimeLogLevel.info : RealtimeLogLevel.error,
        eventsPerSecond: 10,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 3,
      ),
    );

    // Configuration de l'authentification
    _setupAuthListener();
  }

  /// Configure les listeners d'authentification
  void _setupAuthListener() {
    client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          await _onUserSignedIn(session);
          break;
        case AuthChangeEvent.signedOut:
          await _onUserSignedOut();
          break;
        case AuthChangeEvent.tokenRefreshed:
          debugPrint('Token refreshed');
          break;
        case AuthChangeEvent.userUpdated:
          await _onUserUpdated(session);
          break;
        default:
          break;
      }
    });
  }

  /// Actions lors de la connexion
  Future<void> _onUserSignedIn(Session? session) async {
    if (session == null) return;

    try {
      // Synchroniser le FCM token pour les notifications
      await FirebaseService.instance.syncFCMToken();

      // Mettre à jour les informations utilisateur
      await updateUserInfo();

      debugPrint('User signed in: ${session.user.id}');
    } catch (e) {
      debugPrint('Error on sign in: $e');
    }
  }

  /// Actions lors de la déconnexion
  Future<void> _onUserSignedOut() async {
    try {
      // Nettoyer le FCM token
      await removeFCMToken();

      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Error on sign out: $e');
    }
  }

  /// Actions lors de la mise à jour utilisateur
  Future<void> _onUserUpdated(Session? session) async {
    if (session == null) return;

    try {
      await updateUserInfo();
      debugPrint('User updated: ${session.user.id}');
    } catch (e) {
      debugPrint('Error on user update: $e');
    }
  }

  /// Met à jour les informations utilisateur dans Supabase
  Future<void> updateUserInfo() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      await client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating user info: $e');
    }
  }

  /// Met à jour le FCM token dans la base
  Future<void> updateFCMToken(String token) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await client.from('users').update({
        'fcm_token': token,
        'fcm_updated_at': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name.toLowerCase(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Supprime le FCM token
  Future<void> removeFCMToken() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await client.from('users').update({
        'fcm_token': null,
        'fcm_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Récupère l'ID utilisateur actuel
  String? get currentUserId => client.auth.currentUser?.id;

  /// Récupère l'email utilisateur actuel
  String? get currentUserEmail => client.auth.currentUser?.email;

  /// Récupère le token JWT actuel
  String? get currentAccessToken => client.auth.currentSession?.accessToken;

  /// Connexion avec email/password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Inscription avec email/password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  /// Déconnexion
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Rafraîchit la session
  Future<void> refreshSession() async {
    await client.auth.refreshSession();
  }

  /// Récupère l'organisation de l'utilisateur
  Future<String?> getUserOrganizationId() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final response = await client
          .from('users')
          .select('organization_id')
          .eq('id', userId)
          .single();

      return response['organization_id'] as String?;
    } catch (e) {
      debugPrint('Error getting organization ID: $e');
      return null;
    }
  }

  /// Récupère le rôle de l'utilisateur
  Future<String?> getUserRole() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final response =
          await client.from('users').select('role').eq('id', userId).single();

      return response['role'] as String?;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }
}
