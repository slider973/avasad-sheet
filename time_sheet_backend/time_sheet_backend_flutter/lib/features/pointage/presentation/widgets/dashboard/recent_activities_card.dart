import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';

class RecentActivitiesCard extends StatelessWidget {
  const RecentActivitiesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.teal, size: 24),
                SizedBox(width: 8),
                Text(
                  'Activités récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            BlocBuilder<TimeSheetListBloc, TimeSheetListState>(
              builder: (context, state) {
                if (state is TimeSheetListFetchedState) {
                  final entries = state.entries;
                  
                  // Prendre les 5 dernières entrées
                  final recentEntries = entries.take(5).toList();
                  
                  if (recentEntries.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aucune activité récente',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: recentEntries.map((entry) {
                      return _buildActivityItem(entry);
                    }).toList(),
                  );
                }
                
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityItem(dynamic entry) {
    final date = entry.date;
    final totalTime = entry.calculateDailyTotal();
    final currentState = entry.currentState;
    
    // Déterminer l'icône et la couleur selon l'état
    IconData icon;
    Color color;
    String statusText;
    
    switch (currentState) {
      case 'Sortie':
        icon = Icons.check_circle;
        color = Colors.green;
        statusText = 'Journée terminée';
        break;
      case 'Entrée':
        icon = Icons.play_arrow;
        color = Colors.blue;
        statusText = 'En cours';
        break;
      case 'Pause':
        icon = Icons.pause;
        color = Colors.orange;
        statusText = 'En pause';
        break;
      case 'Reprise':
        icon = Icons.play_arrow;
        color = Colors.teal;
        statusText = 'Reprise en cours';
        break;
      default:
        icon = Icons.schedule;
        color = Colors.grey;
        statusText = 'Non commencé';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icône d'état
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Informations principales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date != null 
                          ? DateFormat('dd/MM/yyyy').format(date)
                          : 'Date inconnue',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDuration(totalTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      date != null 
                          ? DateFormat('EEEE', 'fr_FR').format(date)
                          : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}min';
    } else {
      return '${minutes}min';
    }
  }
}