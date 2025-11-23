import 'package:equatable/equatable.dart';
import 'expense.dart';
import 'expense_category.dart';

/// Rapport mensuel de frais regroupant toutes les dépenses
class ExpenseReport extends Equatable {
  final int month;
  final int year;
  final List<Expense> expenses;

  const ExpenseReport({
    required this.month,
    required this.year,
    required this.expenses,
  });

  /// Calcule le montant total de toutes les dépenses
  double get totalAmount {
    return expenses.fold(0.0, (sum, expense) => sum + expense.calculatedAmount);
  }

  /// Regroupe les montants par catégorie
  Map<ExpenseCategory, double> get amountByCategory {
    final Map<ExpenseCategory, double> result = {};

    for (final expense in expenses) {
      final category = expense.category;
      result[category] = (result[category] ?? 0.0) + expense.calculatedAmount;
    }

    return result;
  }

  /// Nombre total de dépenses
  int get expenseCount => expenses.length;

  /// Vérifie si toutes les dépenses sont approuvées
  bool get isFullyApproved {
    return expenses.isNotEmpty && expenses.every((e) => e.isApproved);
  }

  /// Vérifie si au moins une dépense est approuvée
  bool get hasApprovedExpenses {
    return expenses.any((e) => e.isApproved);
  }

  /// Retourne les dépenses non approuvées
  List<Expense> get pendingExpenses {
    return expenses.where((e) => !e.isApproved).toList();
  }

  /// Retourne les dépenses approuvées
  List<Expense> get approvedExpenses {
    return expenses.where((e) => e.isApproved).toList();
  }

  @override
  List<Object?> get props => [month, year, expenses];
}
