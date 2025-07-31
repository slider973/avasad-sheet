import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';

/// Interface abstraite pour les cas d'utilisation
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Classe pour les cas d'utilisation sans paramètres
class NoParams extends Equatable {
  const NoParams();
  
  @override
  List<Object> get props => [];
}