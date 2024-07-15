import 'package:isar/isar.dart';

part 'generated_pdf.g.dart';

@collection
class GeneratedPdfModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String fileName;

  late String filePath;
  late DateTime generatedDate;

  GeneratedPdfModel({
    required this.fileName,
    required this.filePath,
    required this.generatedDate,
  });
}