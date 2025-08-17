import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/validation/presentation/bloc/validation_list/validation_list_bloc.dart';
import 'package:time_sheet/features/validation/presentation/bloc/validation_detail/validation_detail_bloc.dart';
import 'package:time_sheet/features/validation/presentation/pages/create_validation_page.dart';
import 'package:time_sheet/features/validation/presentation/pages/validation_detail_page.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/services/injection_container.dart' as di;

/// Page de liste des validations
class ValidationListPage extends StatefulWidget {
  final ValidationViewType viewType;

  const ValidationListPage({
    super.key,
    required this.viewType,
  });

  @override
  State<ValidationListPage> createState() => _ValidationListPageState();
}

class _ValidationListPageState extends State<ValidationListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ValidationListBloc>().add(
          LoadValidations(viewType: widget.viewType),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.viewType == ValidationViewType.employee ? 'Mes validations' : 'Validations à traiter',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: BlocBuilder<ValidationListBloc, ValidationListState>(
        builder: (context, state) {
          if (state is ValidationListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ValidationListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ValidationListBloc>().add(
                          LoadValidations(viewType: widget.viewType),
                        ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is ValidationListLoaded) {
            if (state.validations.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                _buildStatistics(state),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<ValidationListBloc>().add(const RefreshValidations());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.validations.length,
                      itemBuilder: (context, index) {
                        final validation = state.validations[index];
                        return _buildValidationCard(validation);
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: widget.viewType == ValidationViewType.employee
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateValidationPage(),
                  ),
                ).then((_) {
                  // Recharger la liste après création
                  context.read<ValidationListBloc>().add(
                        LoadValidations(viewType: widget.viewType),
                      );
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle validation'),
            )
          : null,
    );
  }

  Widget _buildStatistics(ValidationListLoaded state) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'En attente',
              state.pendingCount,
              Colors.orange,
              Icons.schedule,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Approuvées',
              state.approvedCount,
              Colors.green,
              Icons.check_circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Rejetées',
              state.rejectedCount,
              Colors.red,
              Icons.cancel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Card(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationCard(ValidationRequest validation) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final color = _getStatusColor(validation.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => di.getIt<ValidationDetailBloc>(),
                child: ValidationDetailPage(
                  validationId: validation.id,
                  isManager: widget.viewType == ValidationViewType.manager,
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Période : ${dateFormat.format(validation.periodStart)} - ${dateFormat.format(validation.periodEnd)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(validation.status),
                ],
              ),
              const SizedBox(height: 8),
              // Afficher le nom de l'employé pour les managers
              if (widget.viewType == ValidationViewType.manager && validation.employeeName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Employé: ${validation.employeeName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Créé le ${dateFormat.format(validation.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (validation.isExpired) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Expiré',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (validation.managerComment != null && validation.managerComment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.comment, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        validation.managerComment!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ValidationStatus status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return Chip(
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Color _getStatusColor(ValidationStatus status) {
    switch (status) {
      case ValidationStatus.pending:
        return Colors.orange;
      case ValidationStatus.approved:
        return Colors.green;
      case ValidationStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusLabel(ValidationStatus status) {
    switch (status) {
      case ValidationStatus.pending:
        return 'En attente';
      case ValidationStatus.approved:
        return 'Approuvée';
      case ValidationStatus.rejected:
        return 'Rejetée';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.viewType == ValidationViewType.employee ? Icons.assignment_outlined : Icons.inbox_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            widget.viewType == ValidationViewType.employee
                ? 'Aucune validation trouvée'
                : 'Aucune validation à traiter',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            widget.viewType == ValidationViewType.employee
                ? 'Créez une nouvelle demande de validation'
                : 'Vous n\'avez pas de validations en attente',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final bloc = context.read<ValidationListBloc>();
    final currentState = bloc.state;

    if (currentState is ValidationListLoaded) {
      showDialog(
        context: context,
        builder: (context) => _FilterDialog(
          currentFilters: currentState.currentFilters,
          onApply: (filters) {
            bloc.add(FilterValidations(filters));
          },
        ),
      );
    }
  }
}

/// Dialog de filtrage
class _FilterDialog extends StatefulWidget {
  final ValidationFilters currentFilters;
  final Function(ValidationFilters) onApply;

  const _FilterDialog({
    required this.currentFilters,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late ValidationStatus? _selectedStatus;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late SortBy _sortBy;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentFilters.status;
    _startDate = widget.currentFilters.startDate;
    _endDate = widget.currentFilters.endDate;
    _sortBy = widget.currentFilters.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrer les validations'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ValidationStatus?>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous')),
                DropdownMenuItem(
                  value: ValidationStatus.pending,
                  child: Text('En attente'),
                ),
                DropdownMenuItem(
                  value: ValidationStatus.approved,
                  child: Text('Approuvées'),
                ),
                DropdownMenuItem(
                  value: ValidationStatus.rejected,
                  child: Text('Rejetées'),
                ),
              ],
              onChanged: (value) => setState(() => _selectedStatus = value),
            ),
            const SizedBox(height: 16),
            const Text('Période', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Du',
                    _startDate,
                    (date) => setState(() => _startDate = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    'Au',
                    _endDate,
                    (date) => setState(() => _endDate = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Trier par', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<SortBy>(
              initialValue: _sortBy,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(
                  value: SortBy.dateDesc,
                  child: Text('Date création (récent)'),
                ),
                DropdownMenuItem(
                  value: SortBy.dateAsc,
                  child: Text('Date création (ancien)'),
                ),
                DropdownMenuItem(
                  value: SortBy.periodDesc,
                  child: Text('Période (récent)'),
                ),
                DropdownMenuItem(
                  value: SortBy.periodAsc,
                  child: Text('Période (ancien)'),
                ),
              ],
              onChanged: (value) => setState(() => _sortBy = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedStatus = null;
              _startDate = null;
              _endDate = null;
              _sortBy = SortBy.dateDesc;
            });
          },
          child: const Text('Réinitialiser'),
        ),
        ElevatedButton(
          onPressed: () {
            final filters = ValidationFilters(
              status: _selectedStatus,
              startDate: _startDate,
              endDate: _endDate,
              sortBy: _sortBy,
            );
            widget.onApply(filters);
            Navigator.pop(context);
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(
          value != null ? DateFormat('dd/MM/yyyy').format(value) : 'Sélectionner',
          style: TextStyle(
            color: value != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }
}
