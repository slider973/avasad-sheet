import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:time_sheet/core/config/environment.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase with self-hosted or cloud configuration
  Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.anonKey,
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
  }

  /// Whether the user is currently authenticated
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => client.auth.currentUser?.id;

  /// Get current user email
  String? get currentUserEmail => client.auth.currentUser?.email;

  /// Get current access token (for PowerSync JWT)
  String? get currentAccessToken => client.auth.currentSession?.accessToken;

  /// Refresh session
  Future<void> refreshSession() async {
    await client.auth.refreshSession();
  }
}
