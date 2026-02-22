import 'package:isar/isar.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';

part 'expense_model.g.dart';

@collection
class ExpenseModel {
  Id? id;

  /// UUID from PowerSync/Supabase (ignored by Isar)
  @ignore
  String? uuid;

  @Index()
  late DateTime date;

  @Enumerated(EnumType.name)
  late ExpenseCategory category;

  late String description;

  late String currency;

  late double amount;

  // Déplacements
  double? mileageRate;

  int? distanceKm;

  String? departureLocation;

  String? arrivalLocation;

  // Métadonnées
  String? attachmentPath;

  late DateTime createdAt;

  late DateTime updatedAt;

  late bool isSynced;

  // Validation
  late bool isApproved;

  String? managerComment;

  DateTime? approvedAt;

  /// Convertit le modèle Isar en entity domain
  Expense toEntity() {
    return Expense(
      id: id,
      date: date,
      category: category,
      description: description,
      currency: currency,
      amount: amount,
      mileageRate: mileageRate,
      distanceKm: distanceKm,
      departureLocation: departureLocation,
      arrivalLocation: arrivalLocation,
      attachmentPath: attachmentPath,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: isSynced,
      isApproved: isApproved,
      managerComment: managerComment,
      approvedAt: approvedAt,
    );
  }

  /// Crée un modèle Isar depuis une entity domain
  static ExpenseModel fromEntity(Expense expense) {
    return ExpenseModel()
      ..id = expense.id
      ..date = expense.date
      ..category = expense.category
      ..description = expense.description
      ..currency = expense.currency
      ..amount = expense.amount
      ..mileageRate = expense.mileageRate
      ..distanceKm = expense.distanceKm
      ..departureLocation = expense.departureLocation
      ..arrivalLocation = expense.arrivalLocation
      ..attachmentPath = expense.attachmentPath
      ..createdAt = expense.createdAt
      ..updatedAt = expense.updatedAt
      ..isSynced = expense.isSynced
      ..isApproved = expense.isApproved
      ..managerComment = expense.managerComment
      ..approvedAt = expense.approvedAt;
  }
}
