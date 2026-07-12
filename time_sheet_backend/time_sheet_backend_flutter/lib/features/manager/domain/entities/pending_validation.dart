import 'package:equatable/equatable.dart';

/// Demande de validation de timesheet en attente d'approbation manager.
///
/// Les dates sont conservées telles que stockées (ISO 8601) : le formatage
/// est une responsabilité de la présentation.
class PendingValidation extends Equatable {
  final String id;
  final String employeeFirstName;
  final String employeeLastName;
  final String periodStart;
  final String periodEnd;
  final String createdAt;

  const PendingValidation({
    required this.id,
    required this.employeeFirstName,
    required this.employeeLastName,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        employeeFirstName,
        employeeLastName,
        periodStart,
        periodEnd,
        createdAt,
      ];
}
