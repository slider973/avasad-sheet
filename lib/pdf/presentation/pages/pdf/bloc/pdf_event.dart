part of 'pdf_bloc.dart';

abstract class PdfEvent extends Equatable {
  const PdfEvent();
}

class GeneratePdfEvent extends PdfEvent {
  @override
  List<Object> get props => [];
}
