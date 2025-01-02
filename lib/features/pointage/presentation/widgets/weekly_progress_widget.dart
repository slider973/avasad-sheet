import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/timesheet_entry.dart';

class WeeklyProgressWidget extends StatelessWidget {
  final List<TimesheetEntry> entries;

  const WeeklyProgressWidget({Key? key, required this.entries}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = _generateWeeklyData();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progression Hebdomadaire',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                borderWidth: 0,
                tooltipBehavior: TooltipBehavior(enable: true),
                primaryXAxis: const CategoryAxis(
                  majorGridLines: MajorGridLines(width: 0),
                  labelPlacement: LabelPlacement.onTicks,
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  title: AxisTitle(text: '', alignment: ChartAlignment.near),
                ),
                primaryYAxis: const NumericAxis(
                  minimum: 0,
                  maximum: 13,
                  interval: 2,
                  majorGridLines: MajorGridLines(width: 0.5, dashArray: [5, 5]),
                  axisLine: AxisLine(width: 0.5),
                  title: AxisTitle(text: '', alignment: ChartAlignment.near),
                ),
                series: <SplineAreaSeries<_ChartData, String>>[
                  SplineAreaSeries<_ChartData, String>(
                    dataSource: data,
                    xValueMapper: (_ChartData data, _) => data.day,
                    yValueMapper: (_ChartData data, _) => data.hours,
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderColor: Theme.of(context).primaryColor,
                    borderWidth: 3,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      borderWidth: 2,
                      shape: DataMarkerType.circle,
                      color: Colors.white,
                    ),
                  ),
                ],
                annotations: <CartesianChartAnnotation>[
                  CartesianChartAnnotation(
                    widget: Container(
                      child: const Text(
                        '8.3h cible',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                    coordinateUnit: CoordinateUnit.point,
                    region: AnnotationRegion.plotArea,
                    x: 'Mar',
                    y: 8.3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ChartData> _generateWeeklyData() {
    final List<_ChartData> data = [];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Lundi

    // Créer une liste de jours de la semaine
    for (int i = 0; i < 5; i++) {
      final date = startOfWeek.add(Duration(days: i)); // Jours de lundi à vendredi

      // Trouver les entrées pour le jour spécifique
      final double hoursForDay = entries.where((entry) {
        final entryDate = DateFormat("dd-MMM-yy").parse(entry.dayDate);
        return _isSameDay(entryDate, date);
      }).fold(0.0, (total, entry) => total + _calculateDailyHours(entry));

      // Ajouter les données, même si `hoursForDay` est 0
      data.add(_ChartData(DateFormat.E('fr_FR').format(date), hoursForDay));
    }

    return data;
  }


  double _calculateDailyHours(TimesheetEntry entry) {
    try {
      final DateTime? startMorning = _parseTime(entry.startMorning);
      final DateTime? endAfternoon = _parseTime(entry.endAfternoon);

      if (startMorning == null || endAfternoon == null) {
        return 0.0;
      }

      final DateTime limitTime = DateTime(
        endAfternoon.year,
        endAfternoon.month,
        endAfternoon.day,
        19,
      );

      final effectiveEnd = endAfternoon.isAfter(limitTime) ? limitTime : endAfternoon;
      final duration = effectiveEnd.difference(startMorning);

      return duration.inMinutes.toDouble() / 60.0;
    } catch (e) {
      print('Erreur dans _calculateDailyHours: $e');
      return 0.0;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  DateTime? _parseTime(String time) {
    try {
      if (time.isEmpty) return null;
      final format = DateFormat.Hm();
      return format.parse(time);
    } catch (e) {
      print('Erreur dans _parseTime pour $time: $e');
      return null;
    }
  }
}

class _ChartData {
  final String day;
  final double hours;

  _ChartData(this.day, this.hours);
}
