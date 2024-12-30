import '../domain/entities/timesheet_entry.dart';
import '../domain/repositories/timesheet_repository.dart';
import '../strategies/anomaly_detector.dart';

class DetectAnomaliesUseCase {
  final TimesheetRepository repository;
  List<AnomalyDetector> detectors;

  DetectAnomaliesUseCase(this.repository, this.detectors);

  Future<List<String>> execute(int month, int year) async {
    final monthToAsk =  DateTime.now().day > 20 ? month + 1 : month;
    final entries = await repository.findEntriesFromMonthOf(monthToAsk, year);
    return _detectAnomalies(entries);
  }

  List<String> _detectAnomalies(List<TimesheetEntry> entries) {
    List<String> anomalies = [];
    for (var entry in entries) {
      for (var detector in detectors) {
        final anomaly = detector.detect(entry);
        if (anomaly.isNotEmpty) {
          anomalies.add(anomaly);
        }
      }
    }
    return anomalies;
  }
}