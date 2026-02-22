import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense.dart';
import '../entities/expense_category.dart';
import '../repositories/expense_repository.dart';

/// Use case pour mettre à jour une dépense existante
class UpdateExpenseUseCase {
  final ExpenseRepository repository;

  UpdateExpenseUseCase({required this.repository});

  Future<Either<Failure, Expense>> execute({
    required int id,
    required DateTime date,
    required String description,
    required ExpenseCategory category,
    double? amount,
    String? currency,
    double? mileageRate,
    int? distanceKm,
    String? departureLocation,
    String? arrivalLocation,
  }) async {
    // Validation pour les dépenses de type déplacement
    if (category == ExpenseCategory.mileage) {
      if (mileageRate == null || distanceKm == null) {
        return const Left(ValidationFailure(
          'Le taux kilométrique et la distance sont requis pour les déplacements',
        ));
      }
      if (departureLocation == null || departureLocation.isEmpty) {
        return const Left(ValidationFailure('Le lieu de départ est requis'));
      }
      if (arrivalLocation == null || arrivalLocation.isEmpty) {
        return const Left(ValidationFailure('Le lieu d\'arrivée est requis'));
      }
      // Calculer automatiquement le montant pour les déplacements
      amount = mileageRate * distanceKm;
    } else {
      // Pour les autres catégories, le montant est requis
      if (amount == null || amount <= 0) {
        return const Left(ValidationFailure('Le montant est requis'));
      }
    }

    // Validation du montant calculé
    if (amount <= 0) {
      return const Left(ValidationFailure('Le montant doit être supérieur à zéro'));
    }

    // Créer l'entité mise à jour
    final expense = Expense(
      id: id,
      date: date,
      description: description,
      amount: amount,
      category: category,
      currency: currency ?? 'CHF',
      mileageRate: mileageRate,
      distanceKm: distanceKm,
      departureLocation: departureLocation,
      arrivalLocation: arrivalLocation,
      isSynced: false, // Reset sync status on update
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return repository.updateExpense(expense);
  }
}
