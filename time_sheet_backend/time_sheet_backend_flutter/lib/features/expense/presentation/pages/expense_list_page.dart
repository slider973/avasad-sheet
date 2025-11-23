import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../../../services/injection_container.dart';
import '../../domain/use_cases/generate_expense_pdf_usecase.dart';
import '../bloc/expense_list/expense_list_bloc.dart';
import '../bloc/expense_list/expense_list_event.dart';
import '../bloc/expense_list/expense_list_state.dart';
import '../widgets/expense_card.dart';
import 'add_expense_page.dart';

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExpenseListBloc>()
        ..add(LoadExpensesForMonth(
          month: DateTime.now().month,
          year: DateTime.now().year,
        )),
      child: const _ExpenseListView(),
    );
  }
}

class _ExpenseListView extends StatelessWidget {
  const _ExpenseListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes de frais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdf(context),
            tooltip: 'Générer PDF',
          ),
        ],
      ),
      body: BlocBuilder<ExpenseListBloc, ExpenseListState>(
        builder: (context, state) {
          if (state is ExpenseListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ExpenseListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ExpenseListBloc>().add(const RefreshExpenses());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is ExpenseListLoaded) {
            return Column(
              children: [
                _buildMonthSelector(context, state),
                _buildSummaryCard(state),
                Expanded(
                  child: state.expenses.isEmpty
                      ? _buildEmptyState(context)
                      : _buildExpenseList(context, state),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddExpense(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, ExpenseListLoaded state) {
    final monthName = DateFormat('MMMM yyyy', 'fr_FR')
        .format(DateTime(state.selectedYear, state.selectedMonth));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(context, state, -1),
          ),
          Text(
            monthName.toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(context, state, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ExpenseListLoaded state) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  '${state.expenses.length}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('Dépenses'),
              ],
            ),
            Column(
              children: [
                Text(
                  '${state.totalAmount.toStringAsFixed(2)} CHF',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const Text('Total'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, ExpenseListLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ExpenseListBloc>().add(const RefreshExpenses());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.expenses.length,
        itemBuilder: (context, index) {
          final expense = state.expenses[index];
          return ExpenseCard(
            expense: expense,
            onDelete: () => _deleteExpense(context, expense.id!),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune dépense ce mois-ci',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddExpense(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une dépense'),
          ),
        ],
      ),
    );
  }

  void _changeMonth(BuildContext context, ExpenseListLoaded state, int delta) {
    var newMonth = state.selectedMonth + delta;
    var newYear = state.selectedYear;

    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }

    context.read<ExpenseListBloc>().add(
          LoadExpensesForMonth(month: newMonth, year: newYear),
        );
  }

  void _navigateToAddExpense(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddExpensePage()),
    );

    if (result == true && context.mounted) {
      context.read<ExpenseListBloc>().add(const RefreshExpenses());
    }
  }

  void _deleteExpense(BuildContext context, int expenseId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la dépense'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette dépense ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ExpenseListBloc>().add(DeleteExpense(expenseId: expenseId));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _generatePdf(BuildContext context) async {
    final state = context.read<ExpenseListBloc>().state;

    if (state is! ExpenseListLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune donnée à exporter')),
      );
      return;
    }

    if (state.expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune dépense ce mois-ci')),
      );
      return;
    }

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final generatePdfUseCase = getIt<GenerateExpensePdfUseCase>();
      final result = await generatePdfUseCase.execute(
        month: state.selectedMonth,
        year: state.selectedYear,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Fermer le dialog de chargement

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (pdfPath) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF généré avec succès !'),
              backgroundColor: Colors.green,
            ),
          );

          // Ouvrir le PDF
          OpenFile.open(pdfPath);
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Fermer le dialog de chargement

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
