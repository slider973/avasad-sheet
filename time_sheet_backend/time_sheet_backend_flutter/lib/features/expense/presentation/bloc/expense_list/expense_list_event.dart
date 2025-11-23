import 'package:equatable/equatable.dart';

abstract class ExpenseListEvent extends Equatable {
  const ExpenseListEvent();

  @override
  List<Object?> get props => [];
}

/// Charge les dépenses d'un mois
class LoadExpensesForMonth extends ExpenseListEvent {
  final int month;
  final int year;

  const LoadExpensesForMonth({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}

/// Supprime une dépense
class DeleteExpense extends ExpenseListEvent {
  final int expenseId;

  const DeleteExpense({required this.expenseId});

  @override
  List<Object?> get props => [expenseId];
}

/// Rafraîchit la liste
class RefreshExpenses extends ExpenseListEvent {
  const RefreshExpenses();
}
