import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';

class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({super.key});

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
                Icon(Icons.calendar_month, color: Colors.teal, size: 24),
                SizedBox(width: 8),
                Text(
                  'Résumé mensuel',
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
                  final now = DateTime.now();
                  
                  // Filtrer les entrées du mois courant
                  final monthEntries = entries.where((entry) {
                    return entry.date != null &&
                           entry.date!.year == now.year &&
                           entry.date!.month == now.month;
                  }).toList();
                  
                  // Calculer les statistiques mensuelles
                  final totalHours = monthEntries.fold<Duration>(
                    Duration.zero,
                    (total, entry) => total + entry.calculateDailyTotal(),
                  );
                  
                  final workingDays = monthEntries.length;
                  final targetHours = Duration(hours: 168); // 21 jours × 8h
                  final averagePerDay = workingDays > 0 
                      ? Duration(minutes: totalHours.inMinutes ~/ workingDays)
                      : Duration.zero;
                  
                  final progress = targetHours.inMinutes > 0
                      ? (totalHours.inMinutes / targetHours.inMinutes).clamp(0.0, 1.0)
                      : 0.0;
                  
                  return Column(
                    children: [
                      // Total mensuel
                      _buildStatRow(
                        'Total du mois',
                        _formatDuration(totalHours),
                        Icons.access_time,
                        Colors.blue,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Moyenne par jour
                      _buildStatRow(
                        'Moyenne/jour',
                        _formatDuration(averagePerDay),
                        Icons.trending_up,
                        Colors.green,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Jours travaillés
                      _buildStatRow(
                        'Jours travaillés',
                        '$workingDays jours',
                        Icons.event_available,
                        Colors.orange,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Progression vers l'objectif
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Objectif mensuel',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress >= 1.0 ? Colors.green : Colors.teal,
                              ),
                            ),
                            
                            const SizedBox(height: 4),
                            
                            Text(
                              '${_formatDuration(totalHours)} / ${_formatDuration(targetHours)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                
                return const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Chargement des données...'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
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