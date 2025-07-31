part of 'pdf_bloc_simple.dart';

abstract class PdfStateSimple extends Equatable {
  const PdfStateSimple();
  
  @override
  List<Object?> get props => [];
}

class PdfInitialSimple extends PdfStateSimple {}

class PdfGeneratingSimple extends PdfStateSimple {}

class PdfGeneratedSimple extends PdfStateSimple {
  final Uint8List pdfBytes;
  
  const PdfGeneratedSimple(this.pdfBytes);
  
  @override
  List<Object> get props => [pdfBytes];
}

class PdfGenerationErrorSimple extends PdfStateSimple {
  final String error;
  
  const PdfGenerationErrorSimple(this.error);
  
  @override
  List<Object> get props => [error];
}