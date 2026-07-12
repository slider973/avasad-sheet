import '../../domain/entities/expense_category.dart';

/// Mapping unique entre [ExpenseCategory] et la colonne `expenses.category`
/// de PostgreSQL, dont la contrainte CHECK n'accepte que
/// ('mileage', 'meals', 'accommodation', 'transport', 'parking',
/// 'supplies', 'other').
///
/// Écrire `ExpenseCategory.meal.name` ('meal') violait la contrainte :
/// l'upload PowerSync était rejeté silencieusement.
extension ExpenseCategoryDb on ExpenseCategory {
  /// Valeur attendue par la contrainte CHECK côté PostgreSQL.
  String get dbValue {
    switch (this) {
      case ExpenseCategory.meal:
        return 'meals';
      case ExpenseCategory.mileage:
      case ExpenseCategory.accommodation:
      case ExpenseCategory.transport:
      case ExpenseCategory.parking:
      case ExpenseCategory.other:
        return name;
    }
  }

  /// Convertit une valeur lue en base vers [ExpenseCategory].
  ///
  /// Tolère 'meals' (valeur serveur), 'meal' (legacy local écrit avant la
  /// correction) et retombe sur [ExpenseCategory.other] pour toute valeur
  /// inconnue (ex. 'supplies', sans équivalent Dart).
  static ExpenseCategory fromDb(String? value) {
    switch (value) {
      case 'meals':
      case 'meal': // legacy (lignes locales)
        return ExpenseCategory.meal;
      default:
        return ExpenseCategory.values.firstWhere(
          (category) => category.name == value,
          orElse: () => ExpenseCategory.other,
        );
    }
  }
}
