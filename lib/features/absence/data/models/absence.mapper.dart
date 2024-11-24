import 'package:isar/isar.dart';

import '../../domain/entities/absence_entity.dart';
import 'absence.dart';

extension AbsenceMapper on Absence {
  AbsenceEntity toEntity() {
    return AbsenceEntity(
      id: id,
      userId: userId,
      date: date,
      type: type,
      description: description,
    );
  }

  static Absence fromEntity(AbsenceEntity entity) {
    return Absence(
      id: entity.id ?? Isar.autoIncrement,
      userId: entity.userId,
      date: entity.date,
      type: entity.type,
      description: entity.description,
    );
  }
}