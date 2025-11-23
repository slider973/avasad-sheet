import 'package:equatable/equatable.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_report.dart';

abstract class ExpenseListState extends Equatable {
  const ExpenseListState();

  @override
  List<Object?> get props => [];
}

/// État initial
class ExpenseListInitial extends ExpenseListState {
  const ExpenseListInitial();
}

/// Chargement en cours
class ExpenseListLoading extends ExpenseListState {
  const ExpenseListLoading();
}

/// Dépenses chargées avec succès
class ExpenseListLoaded extends ExpenseListState {
  final ExpenseReport report;
  final int selectedMonth;
  final int selectedYear;

  const ExpenseListLoaded({
    required this.report,
    required this.selectedMonth,
    required this.selectedYear,
  });

  List<Expense> get expenses => report.expenses;
  double get totalAmount => report.totalAmount;

  @override
  List<Object?> get props => [report, selectedMonth, selectedYear];
}

/// Erreur lors du chargement
class ExpenseListError extends ExpenseListState {
  final String message;

  const ExpenseListError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Dépense supprimée avec succès
class ExpenseDeleted extends ExpenseListState {
  const ExpenseDeleted();
}
