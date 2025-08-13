import '../entities/anomaly_result.dart';
import '../entities/timesheet_entry.dart';
import '../rules/anomaly_rule_registry.dart';
import '../rules/impl/weekly_compensation_rule.dart';
import '../use_cases/detect_anomalies_with_rules_usecase.dart';
import '../../../../utils/time_utils.dart';

export '../use_cases/detect_anomalies_with_rules_usecase.dart' show AnomalyStatistics;
export '../rules/anomaly_rule_registry.dart' show RuleInfo;

/// Service principal de détection d'anomalies utilisant le nouveau système de règles.
/// 
/// Ce service remplace l'ancienne logique de détection d'anomalies
/// et fournit une interface simple pour l'intégration dans l'application.
class AnomalyDetectionService {
  late final DetectAnomaliesWithRulesUseCase _detectAnomaliesUseCase;
  
  /// Configuration globale des règles (peut être personnalisée par utilisateur)
  Map<String, Map<String, dynamic>> _globalRuleConfigs = {};
  
  /// Règles activées globalement (toutes par défaut)
  List<String>? _enabledRules;
  
  AnomalyDetectionService() {
    _detectAnomaliesUseCase = DetectAnomaliesWithRulesUseCase();
    
    // Initialiser le registre des règles
    AnomalyRuleRegistry.initialize();
    
    // Configurer les règles par défaut
    _setupDefaultConfigurations();
  }
  
  /// Configure les paramètres par défaut pour les règles
  void _setupDefaultConfigurations() {
    _globalRuleConfigs = {
      'insufficient_hours': {
        'minHours': 8,
        'minMinutes': 18, // 8h18 avec pause légale
        'toleranceMinutes': 5,
      },
      'excessive_hours': {
        'maxHours': 12,
        'maxMinutes': 0,
        'toleranceMinutes': 15,
      },
      'invalid_times': {
        'checkPauseLogic': true,
        'maxBreakDuration': 120, // 2h max
        'minBreakDuration': 15,  // 15min min
      },
      'missing_break': {
        'minWorkHoursForBreak': 6,
        'minBreakDuration': 30,
      },
      'schedule_consistency': {
        'earliestStartTime': '06:00',
        'latestEndTime': '22:00',
        'standardStartTime': '08:00',
        'standardEndTime': '17:00',
        'toleranceMinutes': 30,
        'flagUnusualHours': true,
      },
      'weekly_compensation': {
        'weeklyRequiredMinutes': 2490,   // 41h30 par semaine (5 × 8h18)
        'compensationTolerance': 15,     // Tolérance de 15 minutes
        'maxDailyCompensation': 120,     // Max 2h de compensation par jour
        'minDailyHours': 6,              // Minimum 6h par jour même avec compensation
      },
    };
  }
  
  /// Détecte toutes les anomalies pour une entrée de pointage
  Future<List<AnomalyResult>> detectAnomalies(TimesheetEntry entry) async {
    return await _detectAnomaliesUseCase.detectAnomalies(
      entry,
      ruleConfigs: _globalRuleConfigs,
      enabledRuleIds: _enabledRules,
    );
  }
  
  /// Détecte les anomalies pour une liste d'entrées
  Future<Map<String, List<AnomalyResult>>> detectAnomaliesForEntries(
    List<TimesheetEntry> entries,
  ) async {
    return await _detectAnomaliesUseCase.detectAnomaliesForEntries(
      entries,
      ruleConfigs: _globalRuleConfigs,
      enabledRuleIds: _enabledRules,
    );
  }

  /// Détecte les anomalies pour une liste d'entrées avec compensation hebdomadaire
  Future<Map<String, List<AnomalyResult>>> detectAnomaliesWithWeeklyCompensation(
    List<TimesheetEntry> entries,
  ) async {
    // D'abord détecter les anomalies normalement
    final initialResults = await detectAnomaliesForEntries(entries);
    
    // Grouper les entrées par semaine
    final weekGroups = _groupEntriesByWeek(entries);
    
    // Créer la règle de compensation hebdomadaire
    final compensationRule = WeeklyCompensationRule();
    final compensationConfig = _globalRuleConfigs['weekly_compensation'] ?? 
        compensationRule.defaultConfiguration;
    
    final compensatedResults = <String, List<AnomalyResult>>{};
    
    // Appliquer la compensation pour chaque semaine
    for (final weekEntry in weekGroups.entries) {
      final weekEntries = weekEntry.value;
      final weekAnomalies = <AnomalyResult>[];
      
      // Rassembler toutes les anomalies de la semaine
      for (final entry in weekEntries) {
        final entryId = entry.id?.toString() ?? '';
        if (initialResults.containsKey(entryId)) {
          weekAnomalies.addAll(initialResults[entryId]!);
        }
      }
      
      // Appliquer la compensation hebdomadaire
      final compensatedWeekAnomalies = await compensationRule.validateWeek(
        weekEntries,
        weekAnomalies,
        compensationConfig,
      );
      
      // Redistribuer les anomalies compensées par entrée
      for (final entry in weekEntries) {
        final entryId = entry.id?.toString() ?? '';
        final entryAnomalies = compensatedWeekAnomalies
            .where((anomaly) => anomaly.timesheetEntryId == entryId)
            .toList();
        
        if (entryAnomalies.isNotEmpty) {
          compensatedResults[entryId] = entryAnomalies;
        }
      }
    }
    
    // Ajouter les entrées qui n'ont pas d'anomalies après compensation
    for (final entry in entries) {
      final entryId = entry.id?.toString() ?? '';
      if (!compensatedResults.containsKey(entryId)) {
        compensatedResults[entryId] = [];
      }
    }
    
    return compensatedResults;
  }
  
  /// Groupe les entrées par semaine (lundi à dimanche)
  Map<String, List<TimesheetEntry>> _groupEntriesByWeek(List<TimesheetEntry> entries) {
    final weekGroups = <String, List<TimesheetEntry>>{};
    
    for (final entry in entries) {
      if (entry.date != null) {
        // Calculer le début de la semaine (lundi)
        final weekStart = _getWeekStart(entry.date!);
        final weekKey = '${weekStart.year}-W${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
        
        weekGroups.putIfAbsent(weekKey, () => <TimesheetEntry>[]);
        weekGroups[weekKey]!.add(entry);
      }
    }
    
    return weekGroups;
  }
  
  /// Calcule le début de la semaine (lundi) pour une date donnée
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 = lundi, 7 = dimanche
    return date.subtract(Duration(days: weekday - 1));
  }
  
  /// Configure une règle spécifique
  void configureRule(String ruleId, Map<String, dynamic> config) {
    final rule = AnomalyRuleRegistry.createRule(ruleId);
    if (rule != null && rule.isConfigurationValid(config)) {
      _globalRuleConfigs[ruleId] = Map.from(config);
    }
  }
  
  /// Active/désactive une règle
  void setRuleEnabled(String ruleId, bool enabled) {
    _enabledRules ??= AnomalyRuleRegistry.getAvailableRuleIds();
    
    if (enabled && !_enabledRules!.contains(ruleId)) {
      _enabledRules!.add(ruleId);
    } else if (!enabled && _enabledRules!.contains(ruleId)) {
      _enabledRules!.remove(ruleId);
    }
  }
  
  /// Obtient la configuration actuelle d'une règle
  Map<String, dynamic>? getRuleConfiguration(String ruleId) {
    return _globalRuleConfigs[ruleId];
  }
  
  /// Obtient la liste des règles disponibles avec leurs informations
  List<RuleInfo> getAvailableRules() {
    return AnomalyRuleRegistry.getAvailableRulesInfo();
  }
  
  /// Vérifie si une règle est activée
  bool isRuleEnabled(String ruleId) {
    return _enabledRules?.contains(ruleId) ?? true;
  }
  
  /// Remet toutes les configurations à leurs valeurs par défaut
  void resetToDefaults() {
    _globalRuleConfigs.clear();
    _setupDefaultConfigurations();
    _enabledRules = null; // Réactive toutes les règles
  }
  
  /// Obtient des statistiques sur les anomalies d'une liste d'entrées
  Future<AnomalyStatistics> getAnomalyStatistics(
    List<TimesheetEntry> entries,
  ) async {
    final allAnomalies = <AnomalyResult>[];
    
    final results = await detectAnomaliesForEntries(entries);
    for (final anomaliesList in results.values) {
      allAnomalies.addAll(anomaliesList);
    }
    
    return _detectAnomaliesUseCase.calculateStatistics(allAnomalies);
  }
  
  /// Export de la configuration actuelle (pour sauvegarde utilisateur)
  Map<String, dynamic> exportConfiguration() {
    return {
      'ruleConfigs': Map.from(_globalRuleConfigs),
      'enabledRules': _enabledRules != null ? List.from(_enabledRules!) : null,
    };
  }
  
  /// Import d'une configuration (pour restauration utilisateur)
  void importConfiguration(Map<String, dynamic> config) {
    if (config.containsKey('ruleConfigs')) {
      final ruleConfigs = config['ruleConfigs'] as Map;
      _globalRuleConfigs = <String, Map<String, dynamic>>{};
      
      for (final entry in ruleConfigs.entries) {
        _globalRuleConfigs[entry.key as String] = 
          Map<String, dynamic>.from(entry.value as Map);
      }
    }
    
    if (config.containsKey('enabledRules') && config['enabledRules'] != null) {
      _enabledRules = List<String>.from(config['enabledRules'] as List);
    }
  }
}

