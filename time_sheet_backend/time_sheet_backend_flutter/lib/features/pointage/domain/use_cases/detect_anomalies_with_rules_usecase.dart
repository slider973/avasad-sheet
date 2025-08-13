import '../entities/anomaly_result.dart';
import '../entities/timesheet_entry.dart';
import '../rules/anomaly_rule_registry.dart';

/// Use case qui utilise le nouveau système de règles d'anomalies.
/// 
/// Remplace l'ancien système de détection d'anomalies par une approche
/// basée sur des règles configurables et extensibles.
class DetectAnomaliesWithRulesUseCase {
  
  /// Détecte toutes les anomalies pour une entrée de pointage donnée.
  /// 
  /// [entry] - L'entrée de pointage à analyser
  /// [ruleConfigs] - Configuration optionnelle pour chaque règle (Map[ruleId -> config])
  /// [enabledRuleIds] - Liste des IDs de règles à exécuter (toutes si null)
  /// 
  /// Retourne une liste de tous les résultats d'anomalies détectées.
  Future<List<AnomalyResult>> detectAnomalies(
    TimesheetEntry entry, {
    Map<String, Map<String, dynamic>>? ruleConfigs,
    List<String>? enabledRuleIds,
  }) async {
    final anomalies = <AnomalyResult>[];
    
    // Obtenir toutes les règles disponibles
    final allRules = AnomalyRuleRegistry.createAllRules();
    
    // Filtrer par les règles activées si spécifié
    final rulesToExecute = enabledRuleIds != null
        ? Map.fromEntries(
            allRules.entries.where((entry) => enabledRuleIds.contains(entry.key))
          )
        : allRules;
    
    // Exécuter chaque règle
    for (final ruleEntry in rulesToExecute.entries) {
      final ruleId = ruleEntry.key;
      final rule = ruleEntry.value;
      
      try {
        // Obtenir la configuration pour cette règle
        final config = ruleConfigs?[ruleId] ?? {};
        
        // Valider la configuration
        if (!rule.isConfigurationValid(rule.mergeConfiguration(config))) {
          // Log warning ou throw exception selon les besoins
          continue;
        }
        
        // Exécuter la validation
        final result = await rule.validate(entry, config);
        
        if (result != null) {
          anomalies.add(result);
        }
      } catch (e) {
        // Log l'erreur et continuer avec les autres règles
        // Vous pouvez ajouter un logger ici
        continue;
      }
    }
    
    // Trier par sévérité (critique d'abord)
    anomalies.sort((a, b) => b.severity.priority.compareTo(a.severity.priority));
    
    return anomalies;
  }
  
  /// Détecte les anomalies avec les configurations par défaut
  Future<List<AnomalyResult>> detectAnomaliesWithDefaults(TimesheetEntry entry) {
    return detectAnomalies(entry);
  }
  
  /// Détecte les anomalies pour une liste d'entrées de pointage
  Future<Map<String, List<AnomalyResult>>> detectAnomaliesForEntries(
    List<TimesheetEntry> entries, {
    Map<String, Map<String, dynamic>>? ruleConfigs,
    List<String>? enabledRuleIds,
  }) async {
    final results = <String, List<AnomalyResult>>{};
    
    for (final entry in entries) {
      final entryId = entry.id?.toString() ?? entry.dayDate;
      results[entryId] = await detectAnomalies(
        entry,
        ruleConfigs: ruleConfigs,
        enabledRuleIds: enabledRuleIds,
      );
    }
    
    return results;
  }
  
  /// Obtient des statistiques sur les anomalies détectées
  AnomalyStatistics calculateStatistics(List<AnomalyResult> anomalies) {
    final statsByType = <String, int>{};
    final statsBySeverity = <String, int>{};
    
    for (final anomaly in anomalies) {
      // Compter par type
      final typeKey = anomaly.type.id;
      statsByType[typeKey] = (statsByType[typeKey] ?? 0) + 1;
      
      // Compter par sévérité
      final severityKey = anomaly.severity.name;
      statsBySeverity[severityKey] = (statsBySeverity[severityKey] ?? 0) + 1;
    }
    
    return AnomalyStatistics(
      totalAnomalies: anomalies.length,
      byType: statsByType,
      bySeverity: statsBySeverity,
    );
  }
}

/// Statistiques sur les anomalies détectées
class AnomalyStatistics {
  final int totalAnomalies;
  final Map<String, int> byType;
  final Map<String, int> bySeverity;
  
  const AnomalyStatistics({
    required this.totalAnomalies,
    required this.byType,
    required this.bySeverity,
  });
  
  @override
  String toString() {
    return 'AnomalyStatistics{total: $totalAnomalies, byType: $byType, bySeverity: $bySeverity}';
  }
}