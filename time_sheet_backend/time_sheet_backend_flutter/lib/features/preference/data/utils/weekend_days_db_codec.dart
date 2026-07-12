import 'dart:convert';

/// Encode/décode la colonne `overtime_configurations.weekend_days`
/// (`INTEGER[]` côté PostgreSQL).
///
/// - Écriture : littéral PostgreSQL `{6,7}`. PostgREST caste une chaîne vers
///   `int4[]` uniquement via cette syntaxe littérale ; écrire du JSON
///   (`[6,7]` via `jsonEncode`) provoquait une erreur 22P02 et l'upload
///   PowerSync était rejeté silencieusement.
/// - Lecture : tolère les DEUX formats — `[6,7]` (flux descendant PowerSync,
///   JSON) et `{6,7}` (valeur locale que l'app vient d'écrire).
class WeekendDaysDbCodec {
  const WeekendDaysDbCodec._();

  /// Encode la liste de jours en littéral tableau PostgreSQL, ex. `{6,7}`.
  static String encode(List<int> days) => '{${days.join(',')}}';

  /// Décode une valeur lue en base ; retourne `null` si la valeur est
  /// absente, vide ou illisible (l'appelant conserve alors sa valeur par
  /// défaut).
  static List<int>? decode(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final inner = trimmed.substring(1, trimmed.length - 1).trim();
        if (inner.isEmpty) return <int>[];
        return inner.split(',').map((day) => int.parse(day.trim())).toList();
      }
      return List<int>.from(jsonDecode(trimmed) as List);
    } catch (_) {
      return null;
    }
  }
}
