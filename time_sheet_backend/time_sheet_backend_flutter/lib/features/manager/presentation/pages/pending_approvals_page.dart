import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/powersync_database.dart';
import '../../../../core/services/supabase/supabase_service.dart';

class PendingApprovalsPage extends StatefulWidget {
  final int initialTab;

  const PendingApprovalsPage({super.key, this.initialTab = 0});

  @override
  State<PendingApprovalsPage> createState() => _PendingApprovalsPageState();
}

class _PendingApprovalsPageState extends State<PendingApprovalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _validations = [];
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoadingValidations = true;
  bool _isLoadingExpenses = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadValidations();
    _loadExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadValidations() async {
    setState(() => _isLoadingValidations = true);

    try {
      final db = PowerSyncDatabaseManager.database;
      final managerId = SupabaseService.instance.currentUserId ?? '';

      final rows = await db.getAll(
        '''SELECT vr.*, p.first_name, p.last_name
           FROM validation_requests vr
           JOIN profiles p ON p.id = vr.employee_id
           WHERE vr.manager_id = ? AND vr.status = 'pending'
           ORDER BY vr.created_at DESC''',
        [managerId],
      );

      setState(() {
        _validations = rows;
        _isLoadingValidations = false;
      });
    } catch (e) {
      setState(() => _isLoadingValidations = false);
    }
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoadingExpenses = true);

    try {
      final db = PowerSyncDatabaseManager.database;
      final managerId = SupabaseService.instance.currentUserId ?? '';

      final rows = await db.getAll(
        '''SELECT e.*, p.first_name, p.last_name
           FROM expenses e
           JOIN manager_employees me ON me.employee_id = e.user_id
           JOIN profiles p ON p.id = e.user_id
           WHERE me.manager_id = ? AND e.is_approved = 0
           ORDER BY e.date DESC''',
        [managerId],
      );

      setState(() {
        _expenses = rows;
        _isLoadingExpenses = false;
      });
    } catch (e) {
      setState(() => _isLoadingExpenses = false);
    }
  }

  Future<void> _approveExpense(String expenseId) async {
    try {
      final db = PowerSyncDatabaseManager.database;
      final managerId = SupabaseService.instance.currentUserId ?? '';

      await db.execute(
        'UPDATE expenses SET is_approved = 1, approved_by = ?, approved_at = ? WHERE id = ?',
        [managerId, DateTime.now().toIso8601String(), expenseId],
      );
      _loadExpenses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  if (_validations.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _Badge(count: _validations.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Dépenses'),
                  if (_expenses.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _Badge(count: _expenses.length),
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
          _buildValidationsTab(),
          _buildExpensesTab(),
        ],
      ),
    );
  }

  Widget _buildValidationsTab() {
    if (_isLoadingValidations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_validations.isEmpty) {
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
      onRefresh: () async => _loadValidations(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _validations.length,
        itemBuilder: (context, index) {
          return _buildValidationCard(_validations[index]);
        },
      ),
    );
  }

  Widget _buildValidationCard(Map<String, dynamic> validation) {
    final firstName = validation['first_name'] as String? ?? '';
    final lastName = validation['last_name'] as String? ?? '';
    final periodStart = validation['period_start'] as String? ?? '';
    final periodEnd = validation['period_end'] as String? ?? '';
    final createdAt = validation['created_at'] as String? ?? '';

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
                    '$firstName $lastName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  _formatDate(createdAt),
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
                'Période: ${_formatDate(periodStart)} - ${_formatDate(periodEnd)}',
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
                    // Navigate to validation detail (uses existing validation feature)
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

  Widget _buildExpensesTab() {
    if (_isLoadingExpenses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_expenses.isEmpty) {
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
      onRefresh: () async => _loadExpenses(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          return _buildExpenseCard(_expenses[index]);
        },
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final firstName = expense['first_name'] as String? ?? '';
    final lastName = expense['last_name'] as String? ?? '';
    final category = expense['category'] as String? ?? '';
    final amount = expense['amount'];
    final currency = expense['currency'] as String? ?? 'CHF';
    final date = expense['date'] as String? ?? '';
    final description = expense['description'] as String? ?? '';
    final expenseId = expense['id'] as String;

    final amountValue = amount is num ? amount.toDouble() : double.tryParse(amount?.toString() ?? '') ?? 0.0;

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
                Icon(_categoryIcon(category), color: Colors.orange.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _categoryLabel(category),
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
                      '${amountValue.toStringAsFixed(2)} $currency',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatDate(date),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: reject expense
                  },
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Refuser'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approveExpense(expenseId),
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
