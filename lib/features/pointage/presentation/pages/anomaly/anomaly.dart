// Dans /features/pointage/presentation/pages/anomaly/anomaly.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../bottom_nav_tab/presentation/pages/bloc/bottom_navigation_bar_bloc.dart';
import '../../../data/models/anomalies/anomalies.dart';
import '../../widgets/pointage_widget/pointage_widget.dart';
import '../pdf/bloc/anomaly/anomaly_bloc.dart';

class AnomalyView extends StatefulWidget {
  @override
  State<AnomalyView> createState() => _AnomalyViewState();
}


class _AnomalyViewState extends State<AnomalyView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _typeFilter = 'all';
  String _dateFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<AnomalyBloc>().add(const DetectAnomalies());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomalies'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'À résoudre'),
            Tab(text: 'Résolues'),
          ],
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildFilterBar(),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnomaliesTab(resolved: false),
          _buildAnomaliesTab(resolved: true),
        ],
      ),
    );
  }

  Widget _buildAnomaliesTab({required bool resolved}) {
    return RefreshIndicator(
      onRefresh: _refreshAnomalies,
      child: BlocBuilder<AnomalyBloc, AnomalyState>(
        builder: (context, state) {
          if (state is AnomalyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AnomalyLoaded) {
            final filteredAnomalies = _filterAnomalies(state.anomalies)
                .where((a) => a.isResolved == resolved)
                .toList();

            if (filteredAnomalies.isEmpty) {
              return _buildEmptyState(resolved);
            }

            return _buildAnomaliesList(context, filteredAnomalies);
          }

          if (state is AnomalyError) {
            return Center(child: Text(state.message));
          }

          return const Center(
              child: Text('Aucune donnée à afficher pour le moment.'));
        },
      ),
    );
  }

  Widget _buildEmptyState(bool resolved) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            resolved ? Icons.task_alt : Icons.check_circle_outline,
            size: 64,
            color: resolved ? Colors.green : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            resolved
                ? 'Aucune anomalie résolue'
                : 'Aucune anomalie à résoudre',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tirez vers le bas pour rafraîchir',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  value: _typeFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tous les types')),
                    DropdownMenuItem(
                        value: 'AnomalyType.insufficientHours',
                        child: Text('Heures insuffisantes')
                    ),
                    DropdownMenuItem(
                        value: 'AnomalyType.missingEntry',
                        child: Text('Entrée manquante')
                    ),
                    DropdownMenuItem(
                        value: 'AnomalyType.invalidTimes',
                        child: Text('Horaires invalides')
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _typeFilter = value!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Période',
              border: OutlineInputBorder(),
            ),
            value: _dateFilter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Toutes les périodes')),
              DropdownMenuItem(value: 'today', child: Text('Aujourd\'hui')),
              DropdownMenuItem(value: 'week', child: Text('Cette semaine')),
              DropdownMenuItem(value: 'month', child: Text('Ce mois')),
            ],
            onChanged: (value) {
              setState(() => _dateFilter = value!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesList(BuildContext context, List<AnomalyModel> anomalies) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: anomalies.length,
      itemBuilder: (context, index) {
        final anomaly = anomalies[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            onTap: () => _navigateToCorrection(context, anomaly),
            leading: _getAnomalyIcon(anomaly.type),
            title: Text(
              anomaly.type.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(anomaly.description),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(anomaly.detectedDate),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            trailing: !anomaly.isResolved
                ? ElevatedButton(
              onPressed: () {
                context.read<AnomalyBloc>().add(
                  MarkAnomalyResolved(anomaly.id),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Résoudre'),
            )
                : const Chip(
              label: Text('Résolu'),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  List<AnomalyModel> _filterAnomalies(List<AnomalyModel> anomalies) {
    return anomalies.where((anomaly) {
      if (_typeFilter != 'all' &&
          _typeFilter != 'AnomalyType.${anomaly.type.toString().split('.').last}') {
        return false;
      }
      if (_dateFilter != 'all') {
        final now = DateTime.now();
        final anomalyDate = anomaly.detectedDate;
        switch (_dateFilter) {
          case 'today':
            return anomalyDate.year == now.year &&
                anomalyDate.month == now.month &&
                anomalyDate.day == now.day;
          case 'week':
            final weekAgo = now.subtract(const Duration(days: 7));
            return anomalyDate.isAfter(weekAgo);
          case 'month':
            return anomalyDate.year == now.year &&
                anomalyDate.month == now.month;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _refreshAnomalies() async {
    context.read<AnomalyBloc>().add(const DetectAnomalies());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Widget _getAnomalyIcon(AnomalyType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case AnomalyType.insufficientHours:
        iconData = Icons.access_time;
        iconColor = Colors.orange;
        break;
      case AnomalyType.missingEntry:
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      case AnomalyType.invalidTimes:
        iconData = Icons.error_outline;
        iconColor = Colors.purple;
        break;
    }

    return Icon(iconData, color: iconColor);
  }
  void _navigateToCorrection(BuildContext context, AnomalyModel anomaly) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Détails du pointage'),
            backgroundColor: Colors.teal,
          ),
          body: SingleChildScrollView(
            child: PointageWidget(
              entry: null, // Vous voudrez peut-être passer l'entrée si disponible
              selectedDate: anomaly.detectedDate,
            ),
          ),
        ),
      ),
    )
        .then(
          (value) {
        // Recharger les anomalies au retour de la page de correction
        context.read<AnomalyBloc>().add(const DetectAnomalies());
      },
    );
  }
}