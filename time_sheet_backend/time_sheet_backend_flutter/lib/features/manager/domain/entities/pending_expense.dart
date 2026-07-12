import 'package:equatable/equatable.dart';

/// Note de frais d'un employé en attente d'approbation manager.
class PendingExpense extends Equatable {
  final String id;
  final String employeeFirstName;
  final String employeeLastName;
  final String category;
  final double amount;
  final String currency;
  final String date;
  final String description;

  const PendingExpense({
    required this.id,
    required this.employeeFirstName,
    required this.employeeLastName,
    required this.category,
    required this.amount,
    required this.currency,
    required this.date,
    required this.description,
  });

  @override
  List<Object?> get props => [
        id,
        employeeFirstName,
        employeeLastName,
        category,
        amount,
        currency,
        date,
        description,
      ];
}
