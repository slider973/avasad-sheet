import 'package:intl/intl.dart';
import '../entities/anomaly.dart';
import '../entities/timesheet_entry.dart';
import '../repositories/timesheet_repository.dart';
import '../strategies/anomaly_detector.dart';
import 'weekly_compensation_detector.dart';

class DetectAnomaliesWithCompensationUseCase {
  final TimesheetRepository repository;
  final List<AnomalyDetector> detectors;
  final WeeklyCompensationDetector weeklyDetector;

  DetectAnomaliesWithCompensationUseCase(
    this.repository, 
    this.detectors,
    this.weeklyDetector,
  );

  Future<List<Anomaly>> execute(int month, int year) async {
    // Pour le debug, afficher les dates de la période
    final now = DateTime.now();
    print('Current date: ${now.day}/${now.month}/${now.year}');
    
    // Utiliser directement le mois demandé sans ajustement
    final entries = await repository.findEntriesFromMonthOf(month, year);
    
    print('DetectAnomaliesWithCompensation: Found ${entries.length} entries for month $month/$year');
    
    // Si pas d'entrées, retourner une liste vide
    if (entries.isEmpty) {
      print('No entries found, returning empty anomaly list');
      return [];
    }
    
    // Afficher quelques entrées pour debug
    for (var entry in entries.take(3)) {
      final total = entry.calculateDailyTotal();
      print('Entry ${entry.dayDate}: ${total.inHours}h${total.inMinutes % 60}min');
    }
    
    // Détecter toutes les anomalies journalières
    List<Anomaly> allAnomalies = _detectDailyAnomalies(entries);
    print('DetectAnomaliesWithCompensation: Detected ${allAnomalies.length} daily anomalies');
    
    // Appliquer la compensation hebdomadaire
    final result = _applyWeeklyCompensation(entries, allAnomalies);
    print('DetectAnomaliesWithCompensation: After compensation: ${result.length} anomalies');
    
    return result;
  }

  List<Anomaly> _detectDailyAnomalies(List<TimesheetEntry> entries) {
    List<Anomaly> anomalies = [];
    
    for (var entry in entries) {
      // Ignorer les entrées avec des absences
      if (entry.absenceReason != null && entry.absenceReason!.isNotEmpty) {
        print('Skipping entry ${entry.dayDate} - has absence: ${entry.absenceReason}');
        continue;
      }
      
      // Ignorer aussi les weekends
      final parsedDate = DateFormat('dd-MMM-yy').parse(entry.dayDate);
      if (parsedDate.weekday == DateTime.saturday || parsedDate.weekday == DateTime.sunday) {
        print('Skipping entry ${entry.dayDate} - weekend');
        continue;
      }
      
      for (var detector in detectors) {
        final anomalyMessage = detector.detect(entry);
        if (anomalyMessage.isNotEmpty) {
          anomalies.add(Anomaly(
            id: '${detector.id}_${entry.dayDate}',
            message: anomalyMessage,
            date: parsedDate,
            detectorId: detector.id,
            weekReference: _getWeekReference(parsedDate),
          ));
        }
      }
    }
    return anomalies;
  }

  List<Anomaly> _applyWeeklyCompensation(
    List<TimesheetEntry> entries, 
    List<Anomaly> anomalies
  ) {
    // Grouper les entrées par semaine
    Map<String, List<TimesheetEntry>> weekGroups = _groupByWeek(entries);
    print('WeeklyCompensation: Found ${weekGroups.length} weeks');
    
    // Pour chaque semaine, vérifier la compensation
    for (var weekKey in weekGroups.keys) {
      var weekEntries = weekGroups[weekKey]!;
      print('Week $weekKey: ${weekEntries.length} entries');
      
      // Vérifier qu'on a bien des entrées pour les jours ouvrés
      if (weekEntries.length >= 3) { // Au moins 3 jours travaillés dans la semaine
        var weeklyResult = weeklyDetector.detectWeekly(weekEntries);
        final totalHours = (weeklyResult['totalDuration'] as Duration).inHours;
        print('Week $weekKey: Total hours: $totalHours, Compensated: ${weeklyResult['isCompensated']}');
        
        if (weeklyResult['isCompensated']) {
          // Marquer les anomalies de cette semaine comme compensées
          anomalies = anomalies.map((anomaly) {
            if (anomaly.weekReference == weekKey && 
                anomaly.detectorId == 'insufficient_hours') {
              return anomaly.copyWith(
                isCompensated: true,
                compensationReason: weeklyResult['message'],
              );
            }
            return anomaly;
          }).toList();
        } else {
          // Ajouter une anomalie hebdomadaire si le total n'est pas atteint
          anomalies.add(Anomaly(
            id: 'weekly_$weekKey',
            message: weeklyResult['message'],
            date: _getWeekStartDate(weekKey),
            detectorId: 'weekly_insufficient',
            weekReference: weekKey,
          ));
        }
      } else {
        print('Week $weekKey: Not enough entries (${weekEntries.length} < 3)');
      }
    }
    
    return anomalies;
  }

  Map<String, List<TimesheetEntry>> _groupByWeek(List<TimesheetEntry> entries) {
    Map<String, List<TimesheetEntry>> weekGroups = {};
    
    for (var entry in entries) {
      final date = DateFormat('dd-MMM-yy').parse(entry.dayDate);
      final weekKey = _getWeekReference(date);
      
      weekGroups.putIfAbsent(weekKey, () => []);
      weekGroups[weekKey]!.add(entry);
    }
    
    return weekGroups;
  }

  String _getWeekReference(DateTime date) {
    // Trouver le lundi de la semaine
    final monday = date.subtract(Duration(days: date.weekday - 1));
    // Calculer le num\u00e9ro de semaine
    final weekNumber = _getWeekNumber(monday);
    return '${monday.year}-${weekNumber.toString().padLeft(2, '0')}';
  }
  
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  DateTime _getWeekStartDate(String weekReference) {
    final parts = weekReference.split('-');
    final year = int.parse(parts[0]);
    final week = int.parse(parts[1]);
    
    // Calculer la date du premier lundi de l'année
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysToFirstMonday = (8 - firstDayOfYear.weekday) % 7;
    final firstMonday = firstDayOfYear.add(Duration(days: daysToFirstMonday));
    
    // Ajouter le nombre de semaines
    return firstMonday.add(Duration(days: (week - 1) * 7));
  }

}