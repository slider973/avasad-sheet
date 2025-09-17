import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:time_sheet_backend_client/time_sheet_backend_client.dart';
import 'package:get_it/get_it.dart';

class ServerpodService {
  static Client? _client;
  static final _getIt = GetIt.instance;
  
  static Client get client {
    if (_client == null) {
      throw Exception('ServerpodService not initialized. Call initialize() first.');
    }
    return _client!;
  }
  
  static Future<void> initialize() async {
    String serverUrl;
    
    // Configuration basée sur l'environnement (debug vs release)
    if (kDebugMode) {
      // Mode développement - serveur local
      if (Platform.isAndroid) {
        // Pour l'émulateur Android
        serverUrl = 'http://10.0.2.2:8080/';
      } else if (Platform.isIOS) {
        // Pour le simulateur iOS
        serverUrl = 'http://localhost:8080/';
      } else {
        // Pour Web, macOS, Windows, Linux
        serverUrl = 'http://localhost:8080/';
      }
    } else {
      // Mode production - serveur déployé
      serverUrl = 'https://api-timesheet.wefamily.ch/';
    }
    
    _client = Client(serverUrl);
    
    // Enregistrer le client dans GetIt pour l'injection de dépendances
    if (!_getIt.isRegistered<Client>()) {
      _getIt.registerSingleton<Client>(_client!);
    }
    
    // Note: Endpoints will be registered when the client is properly configured
    // with the generated Serverpod client code
  }
  
  static Future<void> dispose() async {
    _client?.close();
    _client = null;
  }
  
  // Méthode helper pour gérer les erreurs Serverpod
  static Future<T> handleServerpodCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ServerpodClientException catch (e) {
      // Convertir les exceptions Serverpod en exceptions de domaine
      throw _mapServerpodException(e);
    } catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    }
  }
  
  static Exception _mapServerpodException(ServerpodClientException e) {
    // Mapper les codes d'erreur Serverpod vers nos exceptions de domaine
    switch (e.statusCode) {
      case 401:
        return Exception('Non autorisé');
      case 403:
        return Exception('Accès refusé');
      case 404:
        return Exception('Ressource introuvable');
      case 500:
        return Exception('Erreur serveur');
      default:
        return Exception(e.message);
    }
  }
}