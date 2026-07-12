import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/manager_repository.dart';

/// Use case pour récupérer le rôle de l'utilisateur courant
/// ('employee', 'manager', 'admin', 'org_admin', 'super_admin').
class GetUserRoleUseCase {
  final ManagerRepository repository;

  GetUserRoleUseCase({required this.repository});

  Future<Either<Failure, String>> execute() {
    return repository.getCurrentUserRole();
  }
}
