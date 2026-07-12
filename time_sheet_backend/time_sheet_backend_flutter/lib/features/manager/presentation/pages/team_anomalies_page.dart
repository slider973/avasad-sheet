import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/team_anomaly.dart';
import '../bloc/team_anomalies/team_anomalies_bloc.dart';

class TeamAnomaliesPage extends StatelessWidget {
  const TeamAnomaliesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anomalies de l'équipe"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<TeamAnomaliesBloc, TeamAnomaliesState>(
        listenWhen: (previous, current) => current.actionError != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${state.actionError}')),
          );
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.anomalies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      size: 64, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune anomalie non résolue',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<TeamAnomaliesBloc>().add(LoadTeamAnomalies()),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.anomalies.length,
              itemBuilder: (context, index) {
                return _buildAnomalyCard(context, state.anomalies[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnomalyCard(BuildContext context, TeamAnomaly anomaly) {
    final type = anomaly.typeCode;

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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _getAnomalyColor(type).withValues(alpha: 0.2),
                  child: Icon(
                    _getAnomalyIcon(type),
                    size: 16,
                    color: _getAnomalyColor(type),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${anomaly.employeeFirstName} ${anomaly.employeeLastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _anomalyTypeLabel(type),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getAnomalyColor(type),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(anomaly.detectedDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            if (anomaly.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                anomaly.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context
                    .read<TeamAnomaliesBloc>()
                    .add(ResolveTeamAnomalyRequested(anomaly.id)),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Résoudre'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAnomalyColor(String type) {
    switch (type) {
      case 'insufficient_hours':
        return Colors.orange;
      case 'missing_entry':
        return Colors.red;
      case 'invalid_times':
        return Colors.red.shade700;
      case 'excessive_hours':
        return Colors.purple;
      case 'missing_break':
        return Colors.amber.shade700;
      case 'schedule_inconsistency':
        return Colors.blue;
      case 'weekly_compensation':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getAnomalyIcon(String type) {
    switch (type) {
      case 'insufficient_hours':
        return Icons.hourglass_empty;
      case 'missing_entry':
        return Icons.event_busy;
      case 'invalid_times':
        return Icons.error_outline;
      case 'excessive_hours':
        return Icons.timer_off;
      case 'missing_break':
        return Icons.free_breakfast;
      case 'schedule_inconsistency':
        return Icons.swap_horiz;
      case 'weekly_compensation':
        return Icons.balance;
      default:
        return Icons.warning;
    }
  }

  String _anomalyTypeLabel(String type) {
    switch (type) {
      case 'insufficient_hours':
        return 'Heures insuffisantes';
      case 'missing_entry':
        return 'Pointage manquant';
      case 'invalid_times':
        return 'Horaires invalides';
      case 'excessive_hours':
        return 'Heures excessives';
      case 'missing_break':
        return 'Pause manquante';
      case 'schedule_inconsistency':
        return 'Incohérence horaire';
      case 'weekly_compensation':
        return 'Compensation hebdomadaire';
      default:
        return type;
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
