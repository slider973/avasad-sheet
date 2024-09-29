import '../strategies/anomaly_detector.dart';
import '../use_cases/insufficient_hours_detector.dart';

class AnomalyDetectorFactory {
  static AnomalyDetector createDetector(String type) {
    switch (type) {
      case 'insufficient_hours':
        return InsufficientHoursDetector();
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
}