import '../strategies/anomaly_detector.dart';
import '../use_cases/insufficient_hours_detector.dart';
import '../use_cases/weekly_compensation_detector.dart';

class AnomalyDetectorFactory {
  static AnomalyDetector createDetector(String type) {
    switch (type) {
      case 'insufficient_hours':
        return InsufficientHoursDetector();
      case 'weekly_compensation':
        return WeeklyCompensationDetector();
      default:
        throw ArgumentError('Détecteur non reconnu: $type');
    }
  }

  static Map<String, AnomalyDetector> getAllDetectors() {
    final List<String> activeDetectors = ['insufficient_hours'];
    return activeDetectors.fold({}, (detectors, detector) {
      detectors[detector] = createDetector(detector);
      return detectors;
    });
  }

  static WeeklyCompensationDetector getWeeklyCompensationDetector() {
    return WeeklyCompensationDetector();
  }
}