import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';

class WeeklyProgressChart extends StatelessWidget {
  const WeeklyProgressChart({super.key});

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
                Icon(Icons.trending_up, color: Colors.teal, size: 24),
                SizedBox(width: 8),
                Text(
                  'Progression hebdomadaire',
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
                  final weekData = _generateWeekData(entries);
                  
                  return Column(
                    children: [
                      // Graphique
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 2,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.shade300,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    const days = ['L', 'Ma', 'Me', 'J', 'V', 'S', 'D'];
                                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                                      return Text(
                                        days[value.toInt()],
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 2,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()}h',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            maxY: 12,
                            lineBarsData: [
                              // Ligne des heures travaillées
                              LineChartBarData(
                                spots: weekData,
                                isCurved: true,
                                color: Colors.teal,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: Colors.teal,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.teal.withValues(alpha: 0.1),
                                ),
                              ),
                              // Ligne de référence (8h18)
                              LineChartBarData(
                                spots: List.generate(7, (index) => FlSpot(index.toDouble(), 8.3)),
                                isCurved: false,
                                color: Colors.orange,
                                barWidth: 2,
                                dashArray: [5, 5],
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Légende
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('Heures travaillées', Colors.teal),
                          const SizedBox(width: 20),
                          _buildLegendItem('Objectif (8h18)', Colors.orange),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Résumé de la semaine
                      _buildWeeklySummary(weekData),
                    ],
                  );
                }
                
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  List<FlSpot> _generateWeekData(List<dynamic> entries) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final weekData = <FlSpot>[];
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      
      // Trouver l'entrée correspondante à cette date
      final dayEntry = entries.where((entry) {
        return entry.date != null &&
               entry.date!.year == date.year &&
               entry.date!.month == date.month &&
               entry.date!.day == date.day;
      }).toList();
      
      double hours = 0;
      if (dayEntry.isNotEmpty) {
        final duration = dayEntry.first.calculateDailyTotal();
        hours = duration.inMinutes / 60.0;
      }
      
      weekData.add(FlSpot(i.toDouble(), hours));
    }
    
    return weekData;
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildWeeklySummary(List<FlSpot> weekData) {
    final totalHours = weekData.fold<double>(0, (sum, spot) => sum + spot.y);
    const targetHours = 8.3 * 5; // 5 jours de travail
    final progress = (totalHours / targetHours).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total semaine:',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              Text(
                '${totalHours.toStringAsFixed(1)}h',
                style: const TextStyle(
                  fontSize: 16,
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
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            '${(progress * 100).toStringAsFixed(0)}% de l\'objectif hebdomadaire',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}