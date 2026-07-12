import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../manager/domain/use_cases/get_user_role_usecase.dart';

part 'validation_menu_event.dart';
part 'validation_menu_state.dart';

/// Rôles considérés comme "manager" pour l'affichage du menu de validation.
const _managerRoles = ['manager', 'admin', 'org_admin', 'super_admin'];

class ValidationMenuBloc
    extends Bloc<ValidationMenuEvent, ValidationMenuState> {
  final GetUserRoleUseCase getUserRoleUseCase;

  ValidationMenuBloc({required this.getUserRoleUseCase})
      : super(ValidationMenuLoading()) {
    on<CheckValidationMenuRole>(_onCheckRole);
  }

  Future<void> _onCheckRole(
    CheckValidationMenuRole event,
    Emitter<ValidationMenuState> emit,
  ) async {
    final result = await getUserRoleUseCase.execute();
    result.fold(
      // Comportement identique à l'ancienne page : en cas d'erreur,
      // l'utilisateur est traité comme un employé.
      (failure) => emit(const ValidationMenuLoaded(isManager: false)),
      (role) => emit(
        ValidationMenuLoaded(isManager: _managerRoles.contains(role)),
      ),
    );
  }
}
