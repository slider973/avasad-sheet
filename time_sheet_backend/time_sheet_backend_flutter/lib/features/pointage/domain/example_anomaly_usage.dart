// EXEMPLE D'UTILISATION DU NOUVEAU SYSTÈME D'ANOMALIES
//
// Ce fichier montre comment utiliser le nouveau système extensible
// de détection d'anomalies avec des règles configurables.

import 'entities/timesheet_entry.dart';
import 'services/anomaly_detection_service.dart';
import 'rules/anomaly_rule_registry.dart';

/// Exemple d'utilisation basique du service de détection d'anomalies
Future<void> exempleUtilisationBasique() async {
  // 1. Créer le service
  final anomalyService = AnomalyDetectionService();

  // 2. Créer une entrée de test
  final entry = TimesheetEntry(
    dayDate: '06-Nov-24',
    dayOfWeekDate: 'Mercredi',
    startMorning: '09:00',
    endMorning: '12:00',
    startAfternoon: '13:00',
    endAfternoon: '16:00', // Seulement 6h de travail -> anomalie
  );

  // 3. Détecter les anomalies avec configuration par défaut
  final anomalies = await anomalyService.detectAnomalies(entry);

  // 4. Afficher les résultats
  print('=== DÉTECTION D\'ANOMALIES ===');
  print('Nombre d\'anomalies détectées: ${anomalies.length}');

  for (final anomaly in anomalies) {
    print('• ${anomaly.type.displayName}: ${anomaly.description}');
    print('  Sévérité: ${anomaly.severity.displayName}');
    print('  Règle: ${anomaly.ruleName}');
    print('');
  }
}

/// Exemple de configuration personnalisée des règles
Future<void> exempleConfigurationPersonnalisee() async {
  final anomalyService = AnomalyDetectionService();

  // 1. Configurer des règles spécifiques
  anomalyService.configureRule('insufficient_hours', {
    'minHours': 7, // Réduire à 7h au lieu de 8h18
    'minMinutes': 30,
    'toleranceMinutes': 10,
  });

  anomalyService.configureRule('excessive_hours', {
    'maxHours': 10, // Limiter à 10h au lieu de 12h
    'maxMinutes': 0,
    'toleranceMinutes': 30,
  });

  // 2. Désactiver certaines règles
  anomalyService.setRuleEnabled('schedule_consistency', false);

  // 3. Tester avec la nouvelle configuration
  final entry = TimesheetEntry(
    dayDate: '06-Nov-24',
    dayOfWeekDate: 'Mercredi',
    startMorning: '07:30',
    endMorning: '12:00',
    startAfternoon: '13:00',
    endAfternoon: '17:30', // 8h30 de travail
  );

  final anomalies = await anomalyService.detectAnomalies(entry);

  print('=== CONFIGURATION PERSONNALISÉE ===');
  print('Anomalies avec config personnalisée: ${anomalies.length}');

  for (final anomaly in anomalies) {
    print('• ${anomaly.ruleName}: ${anomaly.description}');
  }
}

/// Exemple d'analyse d'une semaine complète
Future<void> exempleAnalyseSemaine() async {
  final anomalyService = AnomalyDetectionService();

  // 1. Créer une semaine de données avec différents problèmes
  final semaine = [
    TimesheetEntry(
      dayDate: '04-Nov-24', dayOfWeekDate: 'Lundi',
      startMorning: '08:00', endMorning: '12:00',
      startAfternoon: '13:00', endAfternoon: '17:00', // Normal
    ),
    TimesheetEntry(
      dayDate: '05-Nov-24', dayOfWeekDate: 'Mardi',
      startMorning: '08:00', endMorning: '12:00',
      startAfternoon: '13:00', endAfternoon: '15:00', // Heures insuffisantes
    ),
    TimesheetEntry(
      dayDate: '06-Nov-24', dayOfWeekDate: 'Mercredi',
      startMorning: '06:00', endMorning: '12:00',
      startAfternoon: '13:00', endAfternoon: '20:00', // Heures excessives + horaires inhabituels
    ),
    TimesheetEntry(
      dayDate: '07-Nov-24', dayOfWeekDate: 'Jeudi',
      startMorning: '08:00', endMorning: '', // Pas de fin de matinée
      startAfternoon: '14:00', endAfternoon: '17:00',
    ),
    TimesheetEntry(
      dayDate: '08-Nov-24', dayOfWeekDate: 'Vendredi',
      startMorning: '08:00', endMorning: '12:00',
      startAfternoon: '12:05', endAfternoon: '17:00', // Pause trop courte
    ),
  ];

  // 2. Analyser toute la semaine
  final resultats = await anomalyService.detectAnomaliesForEntries(semaine);

  // 3. Obtenir des statistiques
  final allAnomalies = resultats.values.expand((list) => list).toList();
  final stats = await anomalyService.getAnomalyStatistics(semaine);

  print('=== ANALYSE DE SEMAINE ===');
  print('Total anomalies: ${stats.totalAnomalies}');
  print('Par type: ${stats.byType}');
  print('Par sévérité: ${stats.bySeverity}');
  print('');

  for (final entry in resultats.entries) {
    final jour = entry.key;
    final anomalies = entry.value;

    if (anomalies.isNotEmpty) {
      print('$jour: ${anomalies.length} anomalie(s)');
      for (final anomaly in anomalies) {
        print('  • ${anomaly.type.displayName}: ${anomaly.description}');
      }
      print('');
    }
  }
}

/// Exemple de création d'une règle personnalisée
Future<void> exempleReglePersonnalisee() async {
  // Pour ajouter une nouvelle règle, il suffit de:

  // 1. Créer la classe de règle (voir missing_break_rule.dart comme exemple)
  // 2. L'ajouter au registre dans anomaly_rule_registry.dart

  print('=== RÈGLES DISPONIBLES ===');

  // Lister toutes les règles disponibles
  final rulesInfo = AnomalyRuleRegistry.getAvailableRulesInfo();

  for (final rule in rulesInfo) {
    print('ID: ${rule.id}');
    print('Nom: ${rule.name}');
    print('Description: ${rule.description}');
    print('Config par défaut: ${rule.defaultConfig}');
    print('---');
  }
}

/// Exemple d'export/import de configuration
Future<void> exempleExportImportConfig() async {
  final anomalyService = AnomalyDetectionService();

  // 1. Personnaliser la configuration
  anomalyService.configureRule('insufficient_hours', {
    'minHours': 7,
    'minMinutes': 0,
    'toleranceMinutes': 15,
  });

  anomalyService.setRuleEnabled('schedule_consistency', false);

  // 2. Exporter la configuration
  final config = anomalyService.exportConfiguration();
  print('=== EXPORT CONFIG ===');
  print('Configuration exportée: $config');

  // 3. Réinitialiser
  anomalyService.resetToDefaults();

  // 4. Réimporter
  anomalyService.importConfiguration(config);

  print('Configuration réimportée avec succès!');
}

/// Point d'entrée pour tous les exemples
Future<void> demonstrationCompleteAnomalies() async {
  print('🔍 DÉMONSTRATION DU SYSTÈME D\'ANOMALIES\n');

  await exempleUtilisationBasique();
  print('\n${'=' * 50}\n');

  await exempleConfigurationPersonnalisee();
  print('\n${'=' * 50}\n');

  await exempleAnalyseSemaine();
  print('\n${'=' * 50}\n');

  await exempleReglePersonnalisee();
  print('\n${'=' * 50}\n');

  await exempleExportImportConfig();

  print('\n✅ Démonstration terminée!');
}

/*
COMMENT AJOUTER UNE NOUVELLE RÈGLE:

1. Créer le fichier de règle dans lib/features/pointage/domain/rules/impl/
   Par exemple: ma_nouvelle_regle.dart

2. Implémenter AnomalyRule:

class MaNouvelleRegle extends AnomalyRule {
  @override
  String get id => 'ma_nouvelle_regle';
  
  @override
  String get name => 'Ma Nouvelle Règle';
  
  @override
  String get description => 'Description de ce que fait ma règle';
  
  @override
  Map<String, dynamic> get defaultConfiguration => {
    'parametre1': 'valeur1',
    'parametre2': 42,
  };
  
  @override
  Future<AnomalyResult?> validate(TimesheetEntry entry, Map<String, dynamic> config) async {
    // Logique de validation ici
    // Retourner AnomalyResult si anomalie détectée, null sinon
  }
  
  @override
  bool isConfigurationValid(Map<String, dynamic> config) {
    // Valider les paramètres de configuration
    return true;
  }
}

3. Ajouter dans anomaly_rule_registry.dart:

Dans la méthode initialize(), ajouter:
register<MaNouvelleRegle>(
  'ma_nouvelle_regle',
  () => MaNouvelleRegle(),
);

4. Ajouter le type d'anomalie dans anomaly_type.dart si nécessaire

5. C'est tout! La règle sera automatiquement disponible
*/
