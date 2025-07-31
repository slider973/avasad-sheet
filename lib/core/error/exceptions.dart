/// Exception serveur
class ServerException implements Exception {
  final String message;
  
  const ServerException(this.message);
}

/// Exception réseau
class NetworkException implements Exception {
  final String message;
  
  const NetworkException([this.message = 'Pas de connexion internet']);
}

/// Exception de cache
class CacheException implements Exception {
  final String message;
  
  const CacheException(this.message);
}