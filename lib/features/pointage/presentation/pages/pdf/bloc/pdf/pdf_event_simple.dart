part of 'pdf_bloc_simple.dart';

abstract class PdfEventSimple extends Equatable {
  const PdfEventSimple();
  
  @override
  List<Object> get props => [];
}

class GeneratePdfEventSimple extends PdfEventSimple {
  final GeneratePdfParams params;
  
  const GeneratePdfEventSimple(this.params);
  
  @override
  List<Object> get props => [params];
}