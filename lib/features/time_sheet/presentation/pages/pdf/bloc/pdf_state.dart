part of 'pdf_bloc.dart';

abstract class PdfState extends Equatable {
  const PdfState();

  @override
  List<Object> get props => [];
}

class PdfInitial extends PdfState {}

class PdfGenerating extends PdfState {}

class PdfGenerated extends PdfState {
  final String filePath;

  const PdfGenerated(this.filePath);

  @override
  List<Object> get props => [filePath];
}

class PdfGenerationError extends PdfState {
  final String error;

  const PdfGenerationError(this.error);

  @override
  List<Object> get props => [error];
}

class PdfLoading extends PdfState {}

class PdfListLoaded extends PdfState {
  final List<GeneratedPdfModel> pdfs;

  const PdfListLoaded(this.pdfs);

  @override
  List<Object> get props => [pdfs];
}

class PdfLoadError extends PdfState {
  final String error;

  const PdfLoadError(this.error);

  @override
  List<Object> get props => [error];
}

class PdfOpening extends PdfState {}

class PdfOpenError extends PdfState {
  final String error;

  const PdfOpenError(this.error);

  @override
  List<Object> get props => [error];
}

class PdfDeleteError extends PdfState {
  final String error;

  const PdfDeleteError(this.error);

  @override
  List<Object> get props => [error];
}

class PdfOpened extends PdfState {
  final String filePath;

  const PdfOpened(this.filePath);

  @override
  List<Object> get props => [filePath];
}

class PdfSigning extends PdfState {}

class PdfSigned extends PdfState {
  final String filePath;

  const PdfSigned(this.filePath);

  @override
  List<Object> get props => [filePath];
}

class PdfSignError extends PdfState {
  final String error;

  const PdfSignError(this.error);

  @override
  List<Object> get props => [error];
}
