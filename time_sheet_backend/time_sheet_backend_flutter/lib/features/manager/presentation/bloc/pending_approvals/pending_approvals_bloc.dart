import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/pending_expense.dart';
import '../../../domain/entities/pending_validation.dart';
import '../../../domain/use_cases/approve_expense_usecase.dart';
import '../../../domain/use_cases/get_pending_expenses_usecase.dart';
import '../../../domain/use_cases/get_pending_validations_usecase.dart';
import '../../../domain/use_cases/reject_expense_usecase.dart';

part 'pending_approvals_event.dart';
part 'pending_approvals_state.dart';

class PendingApprovalsBloc
    extends Bloc<PendingApprovalsEvent, PendingApprovalsState> {
  final GetPendingValidationsUseCase getPendingValidationsUseCase;
  final GetPendingExpensesUseCase getPendingExpensesUseCase;
  final ApproveExpenseUseCase approveExpenseUseCase;
  final RejectExpenseUseCase rejectExpenseUseCase;

  PendingApprovalsBloc({
    required this.getPendingValidationsUseCase,
    required this.getPendingExpensesUseCase,
    required this.approveExpenseUseCase,
    required this.rejectExpenseUseCase,
  }) : super(const PendingApprovalsState()) {
    on<LoadPendingValidations>(_onLoadValidations);
    on<LoadPendingExpenses>(_onLoadExpenses);
    on<ApproveExpenseRequested>(_onApproveExpense);
    on<RejectExpenseRequested>(_onRejectExpense);
  }

  Future<void> _onLoadValidations(
    LoadPendingValidations event,
    Emitter<PendingApprovalsState> emit,
  ) async {
    emit(state.copyWith(isLoadingValidations: true));

    final result = await getPendingValidationsUseCase.execute();
    result.fold(
      // Comportement identique à l'ancienne page : en cas d'échec de
      // chargement, on arrête simplement le loader.
      (failure) => emit(state.copyWith(isLoadingValidations: false)),
      (validations) => emit(state.copyWith(
        validations: validations,
        isLoadingValidations: false,
      )),
    );
  }

  Future<void> _onLoadExpenses(
    LoadPendingExpenses event,
    Emitter<PendingApprovalsState> emit,
  ) async {
    emit(state.copyWith(isLoadingExpenses: true));

    final result = await getPendingExpensesUseCase.execute();
    result.fold(
      (failure) => emit(state.copyWith(isLoadingExpenses: false)),
      (expenses) => emit(state.copyWith(
        expenses: expenses,
        isLoadingExpenses: false,
      )),
    );
  }

  Future<void> _onApproveExpense(
    ApproveExpenseRequested event,
    Emitter<PendingApprovalsState> emit,
  ) async {
    final result = await approveExpenseUseCase.execute(event.expenseId);
    await result.fold(
      (failure) async => emit(state.copyWith(actionError: failure.message)),
      (_) async => _onLoadExpenses(LoadPendingExpenses(), emit),
    );
  }

  Future<void> _onRejectExpense(
    RejectExpenseRequested event,
    Emitter<PendingApprovalsState> emit,
  ) async {
    final result = await rejectExpenseUseCase.execute(event.expenseId);
    await result.fold(
      (failure) async => emit(state.copyWith(actionError: failure.message)),
      (_) async => _onLoadExpenses(LoadPendingExpenses(), emit),
    );
  }
}
