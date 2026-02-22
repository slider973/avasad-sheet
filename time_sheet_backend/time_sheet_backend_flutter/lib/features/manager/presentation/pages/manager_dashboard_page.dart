import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/manager_dashboard_bloc.dart';
import '../widgets/employee_status_card.dart';
import '../widgets/team_overview_chart.dart';
import 'team_timesheet_page.dart';
import 'pending_approvals_page.dart';
import 'team_anomalies_page.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<ManagerDashboardBloc>().add(LoadManagerDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ManagerDashboardBloc>().add(RefreshManagerDashboard());
      },
      child: BlocBuilder<ManagerDashboardBloc, ManagerDashboardState>(
        builder: (context, state) {
          if (state is ManagerDashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ManagerDashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${state.message}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ManagerDashboardBloc>().add(LoadManagerDashboard());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is ManagerDashboardLoaded) {
            return _buildDashboard(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ManagerDashboardLoaded state) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Espace Manager'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          floating: true,
          pinned: false,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: 'Menu',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<ManagerDashboardBloc>().add(RefreshManagerDashboard());
              },
              tooltip: 'Actualiser',
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Team overview chart
              TeamOverviewChart(
                presentCount: state.presentCount,
                absentCount: state.absentCount,
                totalCount: state.employees.length,
              ),
              const SizedBox(height: 16),

              // Quick action cards
              _buildActionCards(context, state),
              const SizedBox(height: 20),

              // Team members list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mon équipe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${state.employees.length} employé${state.employees.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (state.employees.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.group_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text(
                          'Aucun employé assigné',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...state.employees.map((employee) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EmployeeStatusCard(
                        employee: employee,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<ManagerDashboardBloc>(),
                                child: TeamTimesheetPage(employee: employee),
                              ),
                            ),
                          );
                        },
                      ),
                    )),

              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards(BuildContext context, ManagerDashboardLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.pending_actions,
            label: 'Validations',
            count: state.pendingValidations,
            color: Colors.blue,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ManagerDashboardBloc>(),
                    child: const PendingApprovalsPage(),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionCard(
            icon: Icons.receipt_long,
            label: 'Dépenses',
            count: state.pendingExpenses,
            color: Colors.orange,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ManagerDashboardBloc>(),
                    child: const PendingApprovalsPage(initialTab: 1),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionCard(
            icon: Icons.warning_amber,
            label: 'Anomalies',
            count: state.teamAnomalies,
            color: Colors.red,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ManagerDashboardBloc>(),
                    child: const TeamAnomaliesPage(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 28, color: color),
                  if (count > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
