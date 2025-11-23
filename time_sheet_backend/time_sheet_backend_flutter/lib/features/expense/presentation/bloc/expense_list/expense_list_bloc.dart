import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/use_cases/get_monthly_report_usecase.dart';
import '../../../domain/use_cases/delete_expense_usecase.dart';
import 'expense_list_event.dart';
import 'expense_list_state.dart';

class ExpenseListBloc extends Bloc<ExpenseListEvent, ExpenseListState> {
  final GetMonthlyReportUseCase getMonthlyReport;
  final DeleteExpenseUseCase deleteExpense;

  ExpenseListBloc({
    required this.getMonthlyReport,
    required this.deleteExpense,
  }) : super(const ExpenseListInitial()) {
    on<LoadExpensesForMonth>(_onLoadExpensesForMonth);
    on<DeleteExpense>(_onDeleteExpense);
    on<RefreshExpenses>(_onRefreshExpenses);
  }

  Future<void> _onLoadExpensesForMonth(
    LoadExpensesForMonth event,
    Emitter<ExpenseListState> emit,
  ) async {
    emit(const ExpenseListLoading());

    final result = await getMonthlyReport.execute(event.month, event.year);

    result.fold(
      (failure) => emit(ExpenseListError(message: failure.toString())),
      (report) => emit(ExpenseListLoaded(
        report: report,
        selectedMonth: event.month,
        selectedYear: event.year,
      )),
    );
  }

  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseListState> emit,
  ) async {
    if (state is! ExpenseListLoaded) return;

    final currentState = state as ExpenseListLoaded;

    final result = await deleteExpense.execute(event.expenseId);

    result.fold(
      (failure) => emit(ExpenseListError(message: failure.toString())),
      (_) {
        // Recharger les dépenses après suppression
        add(LoadExpensesForMonth(
          month: currentState.selectedMonth,
          year: currentState.selectedYear,
        ));
      },
    );
  }

  Future<void> _onRefreshExpenses(
    RefreshExpenses event,
    Emitter<ExpenseListState> emit,
  ) async {
    if (state is! ExpenseListLoaded) return;

    final currentState = state as ExpenseListLoaded;
    add(LoadExpensesForMonth(
      month: currentState.selectedMonth,
      year: currentState.selectedYear,
    ));
  }
}
