part of 'validation_menu_bloc.dart';

abstract class ValidationMenuEvent extends Equatable {
  const ValidationMenuEvent();

  @override
  List<Object?> get props => [];
}

class CheckValidationMenuRole extends ValidationMenuEvent {}
