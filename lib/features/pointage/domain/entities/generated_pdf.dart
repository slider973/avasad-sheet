class GeneratedPdf {
  final int? id;
  final String fileName;
  final String filePath;
  final DateTime generatedDate;

  const GeneratedPdf({
    this.id,
    required this.fileName,
    required this.filePath,
    required this.generatedDate,
  });

  GeneratedPdf copyWith({
    int? id,
    String? fileName,
    String? filePath,
    DateTime? generatedDate,
  }) {
    return GeneratedPdf(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      generatedDate: generatedDate ?? this.generatedDate,
    );
  }
}