import '../../../pointage/presentation/widgets/pointage_widget/pointage_absence.dart';

class AbsenceEntity {
  final int? id;
  final String userId;
  final String date;
  final AbsenceType type;
  final String description;

  AbsenceEntity({
    this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.description,
  });

  @override
  String toString() {
    return 'Absence{id: $id, userId: $userId, date: $date, type: $type, description: $description}';
  }

  /// Retourne une instance modifiée d'AbsenceEntity.
  AbsenceEntity copyWith({
    int? id,
    String? userId,
    String? date,
    AbsenceType? type,
    String? description,
  }) {
    return AbsenceEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      type: type ?? this.type,
      description: description ?? this.description,
    );
  }
}