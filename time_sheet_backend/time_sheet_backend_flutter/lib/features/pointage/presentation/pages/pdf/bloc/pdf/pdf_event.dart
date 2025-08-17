part of 'pdf_bloc.dart';

abstract class PdfEvent extends Equatable {
  const PdfEvent();

  @override
  List<Object> get props => [];
}

class GeneratePdfEvent extends PdfEvent {
  final int monthNumber;
  final int year;

  const GeneratePdfEvent(this.monthNumber, this.year);

  @override
  List<Object> get props => [monthNumber, year];
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

  const SignPdfEvent(this.filePath, this.signature);

  @override
  List<Object> get props => [filePath, signature];
}

class ClosePdfEvent extends PdfEvent {}

class GenerateExcelEvent extends PdfEvent {
  final int monthNumber;
  final int year;

  const GenerateExcelEvent(this.monthNumber, this.year);

  @override
  List<Object> get props => [monthNumber, year];
}
