import 'package:equatable/equatable.dart';
import 'expense_category.dart';

/// Entity représentant une dépense/frais professionnel
class Expense extends Equatable {
  final int? id;
  final DateTime date;
  final ExpenseCategory category;
  final String description;
  final String currency;
  final double amount;

  // Pour les déplacements (mileage)
  final double? mileageRate; // Taux kilométrique (ex: 0.70 CHF/km)
  final int? distanceKm; // Distance en km
  final String? departureLocation;
  final String? arrivalLocation;

  // Métadonnées
  final String? attachmentPath; // Chemin vers un justificatif (photo, PDF)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced; // Synchronisé avec le serveur

  // Validation manager
  final bool isApproved;
  final String? managerComment;
  final DateTime? approvedAt;

  const Expense({
    this.id,
    required this.date,
    required this.category,
    required this.description,
    this.currency = 'CHF',
    required this.amount,
    this.mileageRate,
    this.distanceKm,
    this.departureLocation,
    this.arrivalLocation,
    this.attachmentPath,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.isApproved = false,
    this.managerComment,
    this.approvedAt,
  });

  /// Calcule le montant pour les déplacements (km × taux)
  double get calculatedAmount {
    if (category == ExpenseCategory.mileage &&
        mileageRate != null &&
        distanceKm != null) {
      return mileageRate! * distanceKm!;
    }
    return amount;
  }

  /// Vérifie si c'est un déplacement
  bool get isMileage => category == ExpenseCategory.mileage;

  /// Retourne une description complète pour les déplacements
  String get fullDescription {
    if (isMileage && departureLocation != null && arrivalLocation != null) {
      return '$description ($departureLocation → $arrivalLocation)';
    }
    return description;
  }

  Expense copyWith({
    int? id,
    DateTime? date,
    ExpenseCategory? category,
    String? description,
    String? currency,
    double? amount,
    double? mileageRate,
    int? distanceKm,
    String? departureLocation,
    String? arrivalLocation,
    String? attachmentPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isApproved,
    String? managerComment,
    DateTime? approvedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      mileageRate: mileageRate ?? this.mileageRate,
      distanceKm: distanceKm ?? this.distanceKm,
      departureLocation: departureLocation ?? this.departureLocation,
      arrivalLocation: arrivalLocation ?? this.arrivalLocation,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isApproved: isApproved ?? this.isApproved,
      managerComment: managerComment ?? this.managerComment,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        category,
        description,
        currency,
        amount,
        mileageRate,
        distanceKm,
        departureLocation,
        arrivalLocation,
        attachmentPath,
        createdAt,
        updatedAt,
        isSynced,
        isApproved,
        managerComment,
        approvedAt,
      ];
}
