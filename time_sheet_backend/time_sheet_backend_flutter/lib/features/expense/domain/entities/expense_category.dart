/// Catégories de frais disponibles
enum ExpenseCategory {
  mileage('Déplacement', 'mileage'),
  meal('Frais de repas', 'meal'),
  accommodation('Hébergement', 'accommodation'),
  transport('Transport public', 'transport'),
  parking('Parking', 'parking'),
  other('Autre', 'other');

  final String label;
  final String value;

  const ExpenseCategory(this.label, this.value);

  static ExpenseCategory fromValue(String value) {
    return ExpenseCategory.values.firstWhere(
      (cat) => cat.value == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}
