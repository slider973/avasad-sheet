import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../widgets/dashboard/dashboard_header.dart';
import '../../widgets/dashboard/metrics_overview_card.dart';
import '../../widgets/dashboard/weekly_progress_chart.dart';
import '../../widgets/dashboard/monthly_summary_card.dart';
import '../../widgets/dashboard/recent_activities_card.dart';
import '../../widgets/dashboard/quick_actions_card.dart';
import '../time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';
import '../pdf/bloc/anomaly/anomaly_bloc.dart';
import '../../../../bottom_nav_tab/presentation/pages/app_drawer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Charger les données nécessaires pour le dashboard
    _loadDashboardData();
  }

  void _loadDashboardData() {
    // Charger la liste des entrées pour les métriques
    context.read<TimeSheetListBloc>().add(const FindTimesheetEntriesEvent());
    
    // Charger les anomalies pour les alertes
    context.read<AnomalyBloc>().add(const DetectAnomalies());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadDashboardData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec date et accueil
              const DashboardHeader(),
              
              const SizedBox(height: 20),
              
              // Vue d'ensemble des métriques principales
              const MetricsOverviewCard(),
              
              const SizedBox(height: 20),
              
              // Graphique de progression hebdomadaire
              const WeeklyProgressChart(),
              
              const SizedBox(height: 20),
              
              // Résumé mensuel et actions rapides - responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  // Si l'écran est trop petit, empiler verticalement
                  if (constraints.maxWidth < 600) {
                    return const Column(
                      children: [
                        MonthlySummaryCard(),
                        SizedBox(height: 16),
                        QuickActionsCard(),
                      ],
                    );
                  }
                  
                  // Sinon, disposition côte à côte
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Résumé mensuel
                      Expanded(
                        flex: 2,
                        child: MonthlySummaryCard(),
                      ),
                      
                      SizedBox(width: 16),
                      
                      // Actions rapides
                      Expanded(
                        flex: 1,
                        child: QuickActionsCard(),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Activités récentes
              const RecentActivitiesCard(),
              
              const SizedBox(height: 20),
              
              // Footer avec informations système
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dernière mise à jour: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}