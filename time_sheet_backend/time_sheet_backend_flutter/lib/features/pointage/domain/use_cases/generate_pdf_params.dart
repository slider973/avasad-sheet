import 'package:equatable/equatable.dart';

/// Paramètres pour la génération d'un PDF
class GeneratePdfParams extends Equatable {
  final int monthNumber;
  final int year;
  final String? managerSignature; // Signature du manager en base64
  final String? managerName; // Nom du manager qui a validé

  const GeneratePdfParams({
    required this.monthNumber,
    required this.year,
    this.managerSignature,
    this.managerName,
  });

  @override
  List<Object?> get props => [monthNumber, year, managerSignature, managerName];
}