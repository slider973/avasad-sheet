import 'package:shared_preferences/shared_preferences.dart';

/// Identifiants déposés par l'application pour l'isolate d'arrière-plan.
///
/// L'isolate du géorepérage n'a ni GetIt, ni client Supabase initialisé : il ne
/// peut donc pas interroger la session courante. Sans ces valeurs déposées à
/// l'avance, l'écriture directe est impossible et le pointage automatique
/// retombe sur la file d'attente — c'est-à-dire sur « rien tant que
/// l'application n'est pas ouverte », ce qui est précisément le défaut que
/// l'écriture directe corrige.
///
/// Seul le jeton d'accès est conservé, jamais le jeton de rafraîchissement :
/// l'isolate ne doit pas pouvoir prolonger une session, et un jeton
/// d'actualisation dans SharedPreferences serait un secret de trop longue vie
/// dans un stockage non chiffré.
class BackgroundCredentialsStore {
  const BackgroundCredentialsStore();

  static const String _userIdKey = 'geofencing_bg_user_id';
  static const String _tokenKey = 'geofencing_bg_access_token';
  static const String _expiryKey = 'geofencing_bg_token_expiry';

  /// Marge retirée à l'échéance.
  ///
  /// Un jeton valable encore quelques secondes sera refusé le temps que l'appel
  /// parte et revienne. Mieux vaut le traiter comme expiré et laisser la file
  /// d'attente faire son office.
  static const Duration _safetyMargin = Duration(seconds: 30);

  Future<void> save({
    required String userId,
    required String accessToken,
    required DateTime expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_expiryKey, expiresAt.toIso8601String());
  }

  /// Identifiant de l'utilisateur, lisible même lorsque le jeton est périmé :
  /// il reste nécessaire au rejeu par la file.
  Future<String?> readUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Jeton d'accès, ou `null` s'il est absent ou trop proche de l'échéance.
  Future<String?> readAccessToken({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;

    final brut = prefs.getString(_expiryKey);
    if (brut == null) return null;

    final expiry = DateTime.tryParse(brut);
    if (expiry == null) return null;

    final instant = now ?? DateTime.now();
    if (!instant.isBefore(expiry.subtract(_safetyMargin))) {
      return null;
    }
    return token;
  }

  /// À appeler à la déconnexion : sans cela, l'arrière-plan continuerait à
  /// pointer pour un compte dont l'utilisateur est sorti.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiryKey);
  }
}
