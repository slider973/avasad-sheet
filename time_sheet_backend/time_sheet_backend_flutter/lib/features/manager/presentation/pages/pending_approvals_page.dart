import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/validation/presentation/bloc/validation_detail/validation_detail_bloc.dart';
import 'package:time_sheet/features/validation/presentation/pages/validation_detail_page.dart';
import 'package:time_sheet/services/injection_container.dart' as di;

import '../../domain/entities/pending_expense.dart';
import '../../domain/entities/pending_validation.dart';
import '../bloc/pending_approvals/pending_approvals_bloc.dart';

class PendingApprovalsPage extends StatefulWidget {
  final int initialTab;

  const PendingApprovalsPage({super.key, this.initialTab = 0});

  @override
  State<PendingApprovalsPage> createState() => _PendingApprovalsPageState();
}

class _PendingApprovalsPageState extends State<PendingApprovalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PendingApprovalsBloc, PendingApprovalsState>(
      listenWhen: (previous, current) => current.actionError != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${state.actionError}')),
        );
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Approbations'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Validations'),
                      if (state.validations.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        _Badge(count: state.validations.length),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Dépenses'),
                      if (state.expenses.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        _Badge(count: state.expenses.length),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildValidationsTab(context, state),
              _buildExpensesTab(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildValidationsTab(
      BuildContext context, PendingApprovalsState state) {
    if (state.isLoadingValidations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.validations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, size: 64, color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text(
              'Aucune validation en attente',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => context
          .read<PendingApprovalsBloc>()
          .add(LoadPendingValidations()),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.validations.length,
        itemBuilder: (context, index) {
          return _buildValidationCard(context, state.validations[index]);
        },
      ),
    );
  }

  Widget _buildValidationCard(
      BuildContext context, PendingValidation validation) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.blue.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${validation.employeeFirstName} ${validation.employeeLastName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  _formatDate(validation.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Période: ${_formatDate(validation.periodStart)} - ${_formatDate(validation.periodEnd)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final id = validation.id;
                    if (id.isEmpty) return;
                    final bloc = context.read<PendingApprovalsBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => di.getIt<ValidationDetailBloc>(),
                          child: ValidationDetailPage(
                            validationId: id,
                            isManager: true,
                          ),
                        ),
                      ),
                    ).then((_) => bloc.add(LoadPendingValidations()));
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Voir détail'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesTab(BuildContext context, PendingApprovalsState state) {
    if (state.isLoadingExpenses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text(
              'Aucune dépense en attente',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<PendingApprovalsBloc>().add(LoadPendingExpenses()),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.expenses.length,
        itemBuilder: (context, index) {
          return _buildExpenseCard(context, state.expenses[index]);
        },
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, PendingExpense expense) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_categoryIcon(expense.category),
                    color: Colors.orange.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${expense.employeeFirstName} ${expense.employeeLastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _categoryLabel(expense.category),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${expense.amount.toStringAsFixed(2)} ${expense.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatDate(expense.date),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
            if (expense.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                expense.description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => context
                      .read<PendingApprovalsBloc>()
                      .add(RejectExpenseRequested(expense.id)),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Refuser'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => context
                      .read<PendingApprovalsBloc>()
                      .add(ApproveExpenseRequested(expense.id)),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approuver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'mileage':
        return Icons.directions_car;
      case 'meals':
        return Icons.restaurant;
      case 'accommodation':
        return Icons.hotel;
      case 'transport':
        return Icons.train;
      case 'parking':
        return Icons.local_parking;
      case 'supplies':
        return Icons.shopping_bag;
      default:
        return Icons.receipt;
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'mileage':
        return 'Kilométrage';
      case 'meals':
        return 'Repas';
      case 'accommodation':
        return 'Hébergement';
      case 'transport':
        return 'Transport';
      case 'parking':
        return 'Parking';
      case 'supplies':
        return 'Fournitures';
      default:
        return 'Autre';
    }
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
