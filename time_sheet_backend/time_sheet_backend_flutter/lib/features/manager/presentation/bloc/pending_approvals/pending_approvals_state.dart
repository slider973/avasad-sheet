part of 'pending_approvals_bloc.dart';

class PendingApprovalsState extends Equatable {
  final List<PendingValidation> validations;
  final List<PendingExpense> expenses;
  final bool isLoadingValidations;
  final bool isLoadingExpenses;

  /// Message d'erreur ponctuel (approbation/rejet), consommé par un
  /// [BlocListener] pour afficher un snackbar. Remis à null à chaque
  /// nouvelle émission.
  final String? actionError;

  const PendingApprovalsState({
    this.validations = const [],
    this.expenses = const [],
    this.isLoadingValidations = true,
    this.isLoadingExpenses = true,
    this.actionError,
  });

  PendingApprovalsState copyWith({
    List<PendingValidation>? validations,
    List<PendingExpense>? expenses,
    bool? isLoadingValidations,
    bool? isLoadingExpenses,
    String? actionError,
  }) {
    return PendingApprovalsState(
      validations: validations ?? this.validations,
      expenses: expenses ?? this.expenses,
      isLoadingValidations: isLoadingValidations ?? this.isLoadingValidations,
      isLoadingExpenses: isLoadingExpenses ?? this.isLoadingExpenses,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
        validations,
        expenses,
        isLoadingValidations,
        isLoadingExpenses,
        actionError,
      ];
}
