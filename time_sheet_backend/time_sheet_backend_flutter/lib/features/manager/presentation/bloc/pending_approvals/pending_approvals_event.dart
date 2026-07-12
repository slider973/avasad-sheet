part of 'pending_approvals_bloc.dart';

abstract class PendingApprovalsEvent extends Equatable {
  const PendingApprovalsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingValidations extends PendingApprovalsEvent {}

class LoadPendingExpenses extends PendingApprovalsEvent {}

class ApproveExpenseRequested extends PendingApprovalsEvent {
  final String expenseId;

  const ApproveExpenseRequested(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

class RejectExpenseRequested extends PendingApprovalsEvent {
  final String expenseId;

  const RejectExpenseRequested(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}
