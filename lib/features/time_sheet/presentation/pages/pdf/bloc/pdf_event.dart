part of 'pdf_bloc.dart';

abstract class PdfEvent extends Equatable {
  const PdfEvent();

  @override
  List<Object> get props => [];
}

class GeneratePdfEvent extends PdfEvent {
  final int monthNumber;

  const GeneratePdfEvent(this.monthNumber);

  @override
  List<Object> get props => [monthNumber];
}

class LoadGeneratedPdfsEvent extends PdfEvent {}

class OpenPdfEvent extends PdfEvent {
  final String filePath;

  const OpenPdfEvent(this.filePath);

  @override
  List<Object> get props => [filePath];
}

class DeletePdfEvent extends PdfEvent {
  final int pdfId;

  const DeletePdfEvent(this.pdfId);

  @override
  List<Object> get props => [pdfId];
}

class SignPdfEvent extends PdfEvent {
  final String filePath;
  final Uint8List signature;

  SignPdfEvent(this.filePath, this.signature);

  @override
  List<Object> get props => [filePath, signature];
}

