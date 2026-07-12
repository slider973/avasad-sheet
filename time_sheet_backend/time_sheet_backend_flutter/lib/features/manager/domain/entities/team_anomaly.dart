import 'package:equatable/equatable.dart';

/// Anomalie non résolue détectée sur un membre de l'équipe.
///
/// [typeCode] est le code snake_case de la colonne `anomalies.type`
/// ('insufficient_hours', 'missing_entry', 'excessive_hours', ...), normalisé
/// par la couche data (les valeurs camelCase legacy sont converties).
class TeamAnomaly extends Equatable {
  final String id;
  final String employeeFirstName;
  final String employeeLastName;
  final String typeCode;
  final String description;
  final String detectedDate;

  const TeamAnomaly({
    required this.id,
    required this.employeeFirstName,
    required this.employeeLastName,
    required this.typeCode,
    required this.description,
    required this.detectedDate,
  });

  @override
  List<Object?> get props => [
        id,
        employeeFirstName,
        employeeLastName,
        typeCode,
        description,
        detectedDate,
      ];
}
