import 'package:isar/isar.dart';

import '../../domain/entities/absence_entity.dart';
import 'absence.dart';

extension AbsenceMapper on Absence {
  AbsenceEntity toEntity() {
    return AbsenceEntity(
      id: id,
      startDate: startDate,
      endDate: endDate,
      type: type,
      motif: motif,
    );
  }

  static Absence fromEntity(AbsenceEntity entity) {
    return Absence()..id = entity.id ?? Isar.autoIncrement
      ..startDate = entity.startDate
      ..endDate = entity.endDate
      ..type = entity.type
      ..motif = entity.motif;
  }
}