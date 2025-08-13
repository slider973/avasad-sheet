import 'dart:convert';

import '../features/preference/presentation/manager/preferences_bloc.dart';


class AnomalyDetectorConfig {
  static const String _key = 'active_anomaly_detectors';

  static Future<List<String>> getActiveDetectors(PreferencesBloc preferencesBloc) async {
    final state = preferencesBloc.state;
    if (state is PreferencesLoaded) {
      final detectorString = await preferencesBloc.getUserPreferenceUseCase.execute(_key);
      if (detectorString != null) {
        return List<String>.from(json.decode(detectorString));
      }
    }
    // Détecteurs par défaut si aucune configuration n'est trouvée
    return ['insufficient_hours'];
  }

  static Future<void> setActiveDetectors(PreferencesBloc preferencesBloc, List<String> detectors) async {
    await preferencesBloc.setUserPreferenceUseCase.execute(_key, json.encode(detectors));
    preferencesBloc.add(LoadPreferences());
  }

  static Future<void> addDetector(PreferencesBloc preferencesBloc, String detectorId) async {
    final detectors = await getActiveDetectors(preferencesBloc);
    if (!detectors.contains(detectorId)) {
      detectors.add(detectorId);
      await setActiveDetectors(preferencesBloc, detectors);
    }
  }

  static Future<void> removeDetector(PreferencesBloc preferencesBloc, String detectorId) async {
    final detectors = await getActiveDetectors(preferencesBloc);
    detectors.remove(detectorId);
    await setActiveDetectors(preferencesBloc, detectors);
  }
}