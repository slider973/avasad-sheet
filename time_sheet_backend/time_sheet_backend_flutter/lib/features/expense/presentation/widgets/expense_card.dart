import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const ExpenseCard({
    Key? key,
    required this.expense,
    this.onDelete,
    this.onEdit,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône selon la catégorie
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(),
                  color: _getCategoryColor(),
                ),
              ),
              const SizedBox(width: 16),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (expense.isMileage && expense.distanceKm != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${expense.distanceKm} km × ${expense.mileageRate?.toStringAsFixed(2)} CHF/km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (expense.departureLocation != null &&
                        expense.arrivalLocation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${expense.departureLocation} → ${expense.arrivalLocation}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy', 'fr_FR').format(expense.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildApprovalChip(),
                        if (expense.attachmentPath != null &&
                            expense.attachmentPath!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.attach_file, size: 14, color: Colors.grey[500]),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Montant et actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${expense.calculatedAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    expense.currency,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (onEdit != null || onDelete != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            color: Colors.blue,
                            onPressed: onEdit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        if (onEdit != null && onDelete != null)
                          const SizedBox(width: 8),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: Colors.red,
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalChip() {
    if (expense.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 12, color: Colors.green.shade600),
            const SizedBox(width: 2),
            Text(
              'Approuvé',
              style: TextStyle(fontSize: 10, color: Colors.green.shade700),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty, size: 12, color: Colors.orange.shade600),
          const SizedBox(width: 2),
          Text(
            'En attente',
            style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (expense.category) {
      case ExpenseCategory.mileage:
        return Icons.directions_car;
      case ExpenseCategory.meal:
        return Icons.restaurant;
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.transport:
        return Icons.train;
      case ExpenseCategory.parking:
        return Icons.local_parking;
      case ExpenseCategory.other:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor() {
    switch (expense.category) {
      case ExpenseCategory.mileage:
        return Colors.blue;
      case ExpenseCategory.meal:
        return Colors.orange;
      case ExpenseCategory.accommodation:
        return Colors.purple;
      case ExpenseCategory.transport:
        return Colors.green;
      case ExpenseCategory.parking:
        return Colors.teal;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }
}
