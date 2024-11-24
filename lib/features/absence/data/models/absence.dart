
import 'package:isar/isar.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence.dart';
part 'absence.g.dart';
@collection
class Absence {
  Id id = Isar.autoIncrement;
  final String userId;
  final String date;
  @enumerated
  final AbsenceType type;
  final String description;

  Absence({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.description,
  });
}