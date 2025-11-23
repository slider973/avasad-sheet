import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense.dart';
import '../entities/expense_category.dart';
import '../repositories/expense_repository.dart';

/// Use case pour créer une nouvelle dépense
class CreateExpenseUseCase {
  final ExpenseRepository repository;

  CreateExpenseUseCase({required this.repository});

  Future<Either<Failure, Expense>> execute({
    required DateTime date,
    required ExpenseCategory category,
    required String description,
    String currency = 'CHF',
    double? amount,
    double? mileageRate,
    int? distanceKm,
    String? departureLocation,
    String? arrivalLocation,
    String? attachmentPath,
  }) async {
    // Validation pour les déplacements
    if (category == ExpenseCategory.mileage) {
      if (mileageRate == null || distanceKm == null) {
        return Left(ValidationFailure(
            'Le taux kilométrique et la distance sont requis pour un déplacement'));
      }
      // Calculer automatiquement le montant
      amount = mileageRate * distanceKm;
    }

    // Validation du montant
    if (amount == null || amount <= 0) {
      return Left(ValidationFailure('Le montant doit être supérieur à zéro'));
    }

    // Création de l'entité
    final expense = Expense(
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      isApproved: false,
    );

    return repository.createExpense(expense);
  }
}
