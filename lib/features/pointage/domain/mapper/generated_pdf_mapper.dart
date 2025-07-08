import '../../data/models/generated_pdf/generated_pdf.dart';
import '../entities/generated_pdf.dart';

class GeneratedPdfMapper {
  static GeneratedPdf fromModel(GeneratedPdfModel model) {
    return GeneratedPdf(
      id: model.id,
      fileName: model.fileName,
      filePath: model.filePath,
      generatedDate: model.generatedDate,
    );
  }

  static GeneratedPdfModel toModel(GeneratedPdf entity) {
    return GeneratedPdfModel(
      fileName: entity.fileName,
      filePath: entity.filePath,
      generatedDate: entity.generatedDate,
    )..id = entity.id ?? 0;
  }

  static List<GeneratedPdf> fromModelList(List<GeneratedPdfModel> models) {
    return models.map(fromModel).toList();
  }

  static List<GeneratedPdfModel> toModelList(List<GeneratedPdf> entities) {
    return entities.map(toModel).toList();
  }
}