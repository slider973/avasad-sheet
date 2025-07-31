import 'package:equatable/equatable.dart';

/// Paramètres pour la génération d'un PDF
class GeneratePdfParams extends Equatable {
  final int monthNumber;
  final int year;

  const GeneratePdfParams({
    required this.monthNumber,
    required this.year,
  });

  @override
  List<Object> get props => [monthNumber, year];
}