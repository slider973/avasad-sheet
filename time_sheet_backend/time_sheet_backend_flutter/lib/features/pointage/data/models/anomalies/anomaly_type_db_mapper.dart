import 'anomalies.dart';

/// Mapping unique entre [AnomalyType] et la colonne `anomalies.type` de
/// PostgreSQL, dont la contrainte CHECK n'accepte que des valeurs snake_case
/// ('insufficient_hours', 'missing_entry', 'invalid_times', ...).
///
/// Écrire `AnomalyType.name` (camelCase) violait la contrainte : l'upload
/// PowerSync était rejeté silencieusement par le connecteur.
extension AnomalyTypeDb on AnomalyType {
  /// Valeur snake_case attendue par la contrainte CHECK côté PostgreSQL.
  String get dbValue {
    switch (this) {
      case AnomalyType.insufficientHours:
        return 'insufficient_hours';
      case AnomalyType.missingEntry:
        return 'missing_entry';
      case AnomalyType.invalidTimes:
        return 'invalid_times';
    }
  }

  /// Convertit une valeur lue en base vers [AnomalyType].
  ///
  /// Tolère les deux formats : snake_case (valeurs serveur) et camelCase
  /// legacy (lignes locales écrites avant la correction, ex.
  /// 'insufficientHours'). Toute valeur inconnue retombe sur
  /// [AnomalyType.missingEntry] (comportement historique).
  static AnomalyType fromDb(String? value) {
    if (value == null) return AnomalyType.missingEntry;
    for (final type in AnomalyType.values) {
      if (type.dbValue == value || type.name == value) return type;
    }
    return AnomalyType.missingEntry;
  }
}
