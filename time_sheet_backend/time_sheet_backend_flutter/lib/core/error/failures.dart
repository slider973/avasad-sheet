import 'package:equatable/equatable.dart';

/// Classe abstraite pour représenter les échecs
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Échec général
class GeneralFailure extends Failure {
  const GeneralFailure(super.message);
}

/// Échec serveur
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Échec réseau
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Échec de cache
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Échec inattendu
class UnexpectedFailure extends Failure {
  const UnexpectedFailure() : super('Une erreur inattendue s\'est produite');
}

/// Échec de validation
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
