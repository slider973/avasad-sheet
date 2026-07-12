import '../../domain/value_objects/absence_type.dart';

/// Mapping unique entre [AbsenceType] et la colonne `absences.type` de
/// PostgreSQL, dont la contrainte CHECK n'accepte que
/// ('vacation', 'sick', 'holiday', 'unpaid', 'training', 'other').
///
/// Écrire `AbsenceType.name` (ex. 'publicHoliday', 'sickLeave') violait la
/// contrainte : l'upload PowerSync était rejeté silencieusement.
extension AbsenceTypeDb on AbsenceType {
  /// Valeur attendue par la contrainte CHECK côté PostgreSQL.
  String get dbValue {
    switch (this) {
      case AbsenceType.vacation:
        return 'vacation';
      case AbsenceType.publicHoliday:
        return 'holiday';
      case AbsenceType.sickLeave:
        return 'sick';
      case AbsenceType.other:
        return 'other';
    }
  }

  /// Convertit une valeur lue en base vers [AbsenceType].
  ///
  /// Tolère les valeurs serveur ('holiday', 'sick', 'unpaid', 'training'),
  /// les valeurs legacy camelCase écrites localement avant la correction
  /// ('publicHoliday', 'sickLeave') et retombe sur [AbsenceType.other]
  /// pour toute valeur inconnue.
  static AbsenceType fromDb(String? value) {
    switch (value) {
      case 'vacation':
        return AbsenceType.vacation;
      case 'holiday':
      case 'publicHoliday': // legacy camelCase (lignes locales)
        return AbsenceType.publicHoliday;
      case 'sick':
      case 'sickLeave': // legacy camelCase (lignes locales)
        return AbsenceType.sickLeave;
      // 'unpaid', 'training' (valeurs serveur sans équivalent Dart),
      // 'other' et toute valeur inconnue.
      default:
        return AbsenceType.other;
    }
  }
}
