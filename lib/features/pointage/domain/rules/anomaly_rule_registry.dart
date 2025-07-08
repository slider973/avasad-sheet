import 'anomaly_rule.dart';
import 'impl/insufficient_hours_rule.dart';
import 'impl/excessive_hours_rule.dart';
import 'impl/invalid_times_rule.dart';
import 'impl/missing_break_rule.dart';
import 'impl/schedule_consistency_rule.dart';

/// Registre centralisé pour toutes les règles d'anomalies.
/// 
/// Permet un ajout facile de nouvelles règles sans modification
/// du code existant. Utilise le pattern Registry pour découpler
/// la création des règles de leur utilisation.
class AnomalyRuleRegistry {
  static final Map<String, AnomalyRule Function()> _ruleFactories = {};

  /// Initialise le registre avec toutes les règles disponibles
  static void initialize() {
    // Enregistrer toutes les règles disponibles
    register<InsufficientHoursRule>(
      'insufficient_hours',
      () => InsufficientHoursRule(),
    );
    
    register<ExcessiveHoursRule>(
      'excessive_hours',
      () => ExcessiveHoursRule(),
    );
    
    register<InvalidTimesRule>(
      'invalid_times',
      () => InvalidTimesRule(),
    );
    
    register<MissingBreakRule>(
      'missing_break',
      () => MissingBreakRule(),
    );
    
    register<ScheduleConsistencyRule>(
      'schedule_consistency',
      () => ScheduleConsistencyRule(),
    );
    
    // AJOUTER NOUVELLES RÈGLES ICI:
    // register<MaReglePersonnalisee>(
    //   'ma_regle_id',
    //   () => MaReglePersonnalisee(),
    // );
  }

  /// Enregistre une nouvelle règle dans le registre
  /// 
  /// [T] - Type de la règle (doit étendre AnomalyRule)
  /// [id] - Identifiant unique de la règle
  /// [factory] - Factory function pour créer une instance de la règle
  static void register<T extends AnomalyRule>(
    String id,
    T Function() factory,
  ) {
    _ruleFactories[id] = factory;
  }

  /// Crée une instance d'une règle par son ID
  /// 
  /// [id] - Identifiant de la règle à créer
  /// 
  /// Retourne une instance de la règle ou null si l'ID n'existe pas
  static AnomalyRule? createRule(String id) {
    final factory = _ruleFactories[id];
    return factory?.call();
  }

  /// Crée toutes les instances des règles enregistrées
  /// 
  /// Retourne une Map avec l'ID comme clé et l'instance comme valeur
  static Map<String, AnomalyRule> createAllRules() {
    final rules = <String, AnomalyRule>{};
    
    for (final entry in _ruleFactories.entries) {
      rules[entry.key] = entry.value();
    }
    
    return rules;
  }

  /// Retourne la liste de tous les IDs de règles disponibles
  static List<String> getAvailableRuleIds() {
    return _ruleFactories.keys.toList()..sort();
  }

  /// Vérifie si une règle avec cet ID existe
  static bool hasRule(String id) {
    return _ruleFactories.containsKey(id);
  }

  /// Retourne les informations sur toutes les règles disponibles
  /// 
  /// Utile pour afficher une liste de règles dans l'interface utilisateur
  static List<RuleInfo> getAvailableRulesInfo() {
    final rulesInfo = <RuleInfo>[];
    
    for (final id in getAvailableRuleIds()) {
      final rule = createRule(id);
      if (rule != null) {
        rulesInfo.add(RuleInfo(
          id: id,
          name: rule.name,
          description: rule.description,
          defaultConfig: rule.defaultConfiguration,
        ));
      }
    }
    
    return rulesInfo;
  }

  /// Réinitialise le registre (utile pour les tests)
  static void reset() {
    _ruleFactories.clear();
  }
}

/// Information sur une règle d'anomalie
class RuleInfo {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> defaultConfig;

  const RuleInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultConfig,
  });

  @override
  String toString() => 'RuleInfo{id: $id, name: $name}';
}