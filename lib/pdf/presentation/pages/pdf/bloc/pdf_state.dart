part of 'pdf_bloc.dart';

abstract class PdfState extends Equatable {
  const PdfState();
}

class PdfInitial extends PdfState {
  @override
  List<Object> get props => [];
}
