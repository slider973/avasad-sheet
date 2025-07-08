import '../entities/timesheet_entry.dart';
import '../entities/anomaly_result.dart';

/// Interface abstraite pour toutes les règles de détection d'anomalies.
/// 
/// Chaque règle implémente cette interface pour définir sa logique
/// de validation spécifique et sa configuration par défaut.
abstract class AnomalyRule {
  /// Identifiant unique de la règle
  String get id;

  /// Nom affiché à l'utilisateur
  String get name;

  /// Description détaillée de ce que vérifie la règle
  String get description;

  /// Configuration par défaut de la règle
  Map<String, dynamic> get defaultConfiguration;

  /// Valide une entrée de pointage selon la règle.
  /// 
  /// [entry] - L'entrée de pointage à valider
  /// [config] - Configuration spécifique pour cette validation
  /// 
  /// Retourne un [AnomalyResult] si une anomalie est détectée,
  /// ou null si l'entrée est valide.
  Future<AnomalyResult?> validate(
    TimesheetEntry entry,
    Map<String, dynamic> config,
  );

  /// Valide avec la configuration par défaut
  Future<AnomalyResult?> validateWithDefaults(TimesheetEntry entry) {
    return validate(entry, defaultConfiguration);
  }

  /// Vérifie si la configuration fournie est valide
  bool isConfigurationValid(Map<String, dynamic> config) {
    return true; // Override dans les sous-classes si nécessaire
  }

  /// Fusionne la configuration fournie avec la configuration par défaut
  Map<String, dynamic> mergeConfiguration(Map<String, dynamic>? config) {
    if (config == null) return Map.from(defaultConfiguration);
    
    final merged = Map<String, dynamic>.from(defaultConfiguration);
    merged.addAll(config);
    return merged;
  }
}