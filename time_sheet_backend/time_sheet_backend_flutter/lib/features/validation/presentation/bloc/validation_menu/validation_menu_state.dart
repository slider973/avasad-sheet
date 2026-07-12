part of 'validation_menu_bloc.dart';

abstract class ValidationMenuState extends Equatable {
  const ValidationMenuState();

  @override
  List<Object?> get props => [];
}

class ValidationMenuLoading extends ValidationMenuState {}

class ValidationMenuLoaded extends ValidationMenuState {
  final bool isManager;

  const ValidationMenuLoaded({required this.isManager});

  @override
  List<Object?> get props => [isManager];
}
