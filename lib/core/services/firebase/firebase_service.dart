import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Service Firebase minimal sans notifications
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// Initialise Firebase Core uniquement
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('Firebase Core initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur d\'initialisation Firebase: $e');
      // L'app peut continuer sans Firebase
    }
  }
  
  /// Placeholder pour la synchronisation du token FCM
  Future<void> syncFCMToken() async {
    debugPrint('Firebase Messaging désactivé - pas de token FCM');
  }
  
  /// Placeholder pour les analytics
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    debugPrint('Firebase Analytics désactivé - événement: $name');
  }
  
  /// Placeholder pour les propriétés utilisateur
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    debugPrint('Firebase Analytics désactivé - propriété: $name = $value');
  }
  
  /// Placeholder pour l'ID utilisateur
  Future<void> setUserId(String? userId) async {
    debugPrint('Firebase Analytics désactivé - userId: $userId');
  }
}