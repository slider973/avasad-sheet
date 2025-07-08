import '../value_objects/absence_type.dart';

class AbsenceEntity {
  final int? id;
  final DateTime startDate;
  final DateTime endDate;
  final AbsenceType type;
  final String motif;

  AbsenceEntity({
    this.id,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.motif,
  });

  @override
  String toString() {
    return 'Absence{id: $id, startDate: $startDate, endDate: $endDate, type: $type, description: $motif}';
  }

  /// Retourne une instance modifiée d'AbsenceEntity.
  AbsenceEntity copyWith({
    int? id,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    AbsenceType? type,
    String? motif,
  }) {
    return AbsenceEntity(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      motif: motif ?? this.motif,
    );
  }
}
