import 'package:shared_preferences/shared_preferences.dart';

/// Mémoire des demandes de pointage déjà appliquées.
///
/// Elle existe pour un cas précis et peu intuitif : une demande émise par
/// l'Apple Watch arrive par deux canaux (`sendMessage` immédiat et
/// `applicationContext` persistant), et surtout **le contexte d'application est
/// relu à chaque lancement de l'application iOS**. Sans cette mémoire, le
/// dernier pointage de la montre serait rejoué à chaque redémarrage.
///
/// La persistance n'est donc pas un confort : elle est la raison d'être de la
/// classe, puisque le cas protégé est précisément le redémarrage.
class WatchRequestLedger {
  /// Nombre d'identifiants conservés. Au-delà, un rejeu est assez improbable
  /// pour ne pas justifier une liste qui croît sans fin.
  static const int maxRetained = 50;

  static const String storageKey = 'watch_handled_request_ids';

  final Future<SharedPreferences> Function() _prefs;
  final List<String> _seen = <String>[];

  WatchRequestLedger({Future<SharedPreferences> Function()? preferences})
      : _prefs = preferences ?? SharedPreferences.getInstance;

  /// Identifiants retenus, du plus ancien au plus récent.
  List<String> get retained => List.unmodifiable(_seen);

  Future<void> load() async {
    try {
      final prefs = await _prefs();
      _seen
        ..clear()
        ..addAll(prefs.getStringList(storageKey) ?? const []);
    } catch (_) {
      // Sans historique on risque un doublon, pas une perte de pointage :
      // démarrer avec une mémoire vide est le moindre mal.
      _seen.clear();
    }
  }

  bool alreadyHandled(String requestId) => _seen.contains(requestId);

  /// Enregistre l'identifiant et renvoie `true` s'il était nouveau.
  ///
  /// Un identifiant déjà connu n'est pas déplacé en fin de liste : sa position
  /// reflète le moment où il a été traité, pas celui où on l'a revu.
  Future<bool> remember(String requestId) async {
    if (_seen.contains(requestId)) return false;

    _seen.add(requestId);
    if (_seen.length > maxRetained) {
      _seen.removeRange(0, _seen.length - maxRetained);
    }

    try {
      final prefs = await _prefs();
      await prefs.setStringList(storageKey, _seen);
    } catch (_) {
      // L'écriture a échoué : la mémoire en RAM protège la session courante,
      // le prochain démarrage repartira sans historique.
    }
    return true;
  }
}
