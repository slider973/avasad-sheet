import 'package:time_sheet/features/pointage/domain/entities/generated_pdf.dart';
import 'package:time_sheet/features/pointage/domain/repositories/timesheet_repository.dart';

/// Use case pour récupérer la liste des PDFs générés
class GetGeneratedPdfsUseCase {
  final TimesheetRepository repository;

  GetGeneratedPdfsUseCase(this.repository);

  Future<List<GeneratedPdf>> execute() async {
    return await repository.getGeneratedPdfs();
  }
}