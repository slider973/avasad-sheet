# 🔍 Système de Règles d'Anomalies

## Vue d'ensemble

Le système de règles d'anomalies permet de détecter automatiquement les problèmes dans les entrées de pointage. Il est conçu selon les principes de Clean Architecture et offre une extensibilité maximale pour ajouter de nouvelles règles sans modifier le code existant.

## 🏗️ Architecture

```
lib/features/pointage/domain/rules/
├── anomaly_rule.dart              # Interface abstraite
├── anomaly_rule_registry.dart     # Registre centralisé
├── impl/                          # Implémentations des règles
│   ├── insufficient_hours_rule.dart
│   ├── excessive_hours_rule.dart
│   ├── invalid_times_rule.dart
│   ├── missing_break_rule.dart
│   └── schedule_consistency_rule.dart
└── README.md                      # Ce fichier
```

## 🚀 Ajouter une Nouvelle Règle

### Étape 1: Créer la Classe de Règle

Créez un nouveau fichier dans `impl/` (ex: `ma_nouvelle_regle.dart`):

```dart
import '../../entities/anomaly_result.dart';
import '../../entities/timesheet_entry.dart';
import '../../value_objects/anomaly_type.dart';
import '../../value_objects/anomaly_severity.dart';
import '../anomaly_rule.dart';

/// Description de votre règle
/// 
/// Expliquez ici ce que vérifie votre règle et dans quels cas
/// elle déclenche une anomalie.
class MaNouvelleRegle extends AnomalyRule {
  @override
  String get id => 'ma_nouvelle_regle';

  @override
  String get name => 'Ma Nouvelle Règle';

  @override
  String get description => 
      'Description détaillée de ce que fait votre règle';

  @override
  Map<String, dynamic> get defaultConfiguration => {
    'parametre1': 'valeur_par_defaut',
    'parametre2': 42,
    'seuil_tolerance': 15,
  };

  @override
  Future<AnomalyResult?> validate(
    TimesheetEntry entry,
    Map<String, dynamic> config,
  ) async {
    // 1. Récupérer la configuration fusionnée
    final mergedConfig = mergeConfiguration(config);
    final parametre1 = mergedConfig['parametre1'] as String;
    final parametre2 = mergedConfig['parametre2'] as int;
    
    // 2. Implémenter votre logique de validation
    bool anomalieDetectee = false;
    String descriptionAnomalie = '';
    
    // Exemple: vérifier une condition
    if (/* votre condition */) {
      anomalieDetectee = true;
      descriptionAnomalie = 'Description de l\'anomalie détectée';
    }
    
    // 3. Retourner le résultat
    if (anomalieDetectee) {
      return AnomalyResult(
        ruleId: id,
        ruleName: name,
        type: AnomalyType.votreType, // Voir types disponibles
        severity: AnomalySeverity.medium, // low, medium, high, critical
        description: descriptionAnomalie,
        detectedDate: DateTime.now(),
        timesheetEntryId: entry.id?.toString() ?? '',
        metadata: {
          'config': mergedConfig,
          'donnees_supplementaires': 'valeur',
        },
      );
    }
    
    return null; // Pas d'anomalie
  }

  @override
  bool isConfigurationValid(Map<String, dynamic> config) {
    // Valider que la configuration est correcte
    if (!config.containsKey('parametre1') || 
        !config.containsKey('parametre2')) {
      return false;
    }
    
    final parametre1 = config['parametre1'];
    final parametre2 = config['parametre2'];
    
    return parametre1 is String && 
           parametre2 is int && parametre2 > 0;
  }
}
```

### Étape 2: Ajouter au Registre

Dans `anomaly_rule_registry.dart`, ajoutez votre règle dans la méthode `initialize()`:

```dart
static void initialize() {
  // ... règles existantes ...
  
  // VOTRE NOUVELLE RÈGLE:
  register<MaNouvelleRegle>(
    'ma_nouvelle_regle',
    () => MaNouvelleRegle(),
  );
}
```

### Étape 3: Ajouter le Type d'Anomalie (optionnel)

Si votre règle nécessite un nouveau type d'anomalie, ajoutez-le dans `../value_objects/anomaly_type.dart`:

```dart
enum AnomalyType {
  // ... types existants ...
  monNouveauType('mon_nouveau_type', 'Mon Nouveau Type'),
}
```

### Étape 4: Créer des Tests

Créez des tests dans `test/` pour votre nouvelle règle:

```dart
group('Ma Nouvelle Règle', () {
  late MaNouvelleRegle rule;
  
  setUp(() {
    rule = MaNouvelleRegle();
  });
  
  test('should detect anomaly when condition is met', () async {
    // Arrange
    final entry = TimesheetEntry(/* données de test */);
    
    // Act
    final result = await rule.validateWithDefaults(entry);
    
    // Assert
    expect(result, isNotNull);
    expect(result!.type, equals(AnomalyType.monNouveauType));
  });
  
  test('should not detect anomaly for valid entry', () async {
    // Arrange
    final entry = TimesheetEntry(/* données valides */);
    
    // Act
    final result = await rule.validateWithDefaults(entry);
    
    // Assert
    expect(result, isNull);
  });
});
```

## 📋 Règles Existantes

### InsufficientHoursRule
- **ID**: `insufficient_hours`
- **Fonction**: Détecte les journées avec moins de 8h18 de travail
- **Configuration**:
  - `minHours`: Heures minimum (défaut: 8)
  - `minMinutes`: Minutes supplémentaires (défaut: 18)
  - `toleranceMinutes`: Tolérance (défaut: 5)

### ExcessiveHoursRule
- **ID**: `excessive_hours`
- **Fonction**: Détecte les journées avec plus de 12h de travail
- **Configuration**:
  - `maxHours`: Heures maximum (défaut: 12)
  - `maxMinutes`: Minutes supplémentaires (défaut: 0)
  - `toleranceMinutes`: Tolérance (défaut: 15)

### InvalidTimesRule
- **ID**: `invalid_times`
- **Fonction**: Détecte les incohérences temporelles
- **Configuration**:
  - `checkPauseLogic`: Vérifier la logique des pauses (défaut: true)
  - `maxBreakDuration`: Pause maximum en minutes (défaut: 120)
  - `minBreakDuration`: Pause minimum en minutes (défaut: 15)

### MissingBreakRule
- **ID**: `missing_break`
- **Fonction**: Détecte l'absence de pause obligatoire
- **Configuration**:
  - `minWorkHoursForBreak`: Heures avant pause obligatoire (défaut: 6)
  - `minBreakDuration`: Durée minimum de pause (défaut: 30)

### ScheduleConsistencyRule
- **ID**: `schedule_consistency`
- **Fonction**: Détecte les horaires inhabituels
- **Configuration**:
  - `earliestStartTime`: Heure de début la plus tôt (défaut: "06:00")
  - `latestEndTime`: Heure de fin la plus tard (défaut: "22:00")
  - `standardStartTime`: Heure de début standard (défaut: "08:00")
  - `standardEndTime`: Heure de fin standard (défaut: "17:00")
  - `toleranceMinutes`: Tolérance en minutes (défaut: 30)
  - `flagUnusualHours`: Signaler les horaires inhabituels (défaut: true)

## 🔧 Utilisation

### Service Principal

```dart
// Obtenir le service
final anomalyService = getIt<AnomalyDetectionService>();

// Détecter toutes les anomalies
final anomalies = await anomalyService.detectAnomalies(entry);

// Configurer une règle
anomalyService.configureRule('ma_nouvelle_regle', {
  'parametre1': 'nouvelle_valeur',
  'parametre2': 50,
});

// Activer/désactiver une règle
anomalyService.setRuleEnabled('ma_nouvelle_regle', false);
```

### Use Case Direct

```dart
final useCase = DetectAnomaliesWithRulesUseCase();

// Détecter avec règles spécifiques
final anomalies = await useCase.detectAnomalies(
  entry,
  enabledRuleIds: ['insufficient_hours', 'ma_nouvelle_regle'],
  ruleConfigs: {
    'ma_nouvelle_regle': {'parametre1': 'valeur_custom'},
  },
);
```

### Registre Direct

```dart
// Lister toutes les règles disponibles
final ruleIds = AnomalyRuleRegistry.getAvailableRuleIds();

// Créer une instance de règle
final rule = AnomalyRuleRegistry.createRule('ma_nouvelle_regle');

// Obtenir les informations des règles
final rulesInfo = AnomalyRuleRegistry.getAvailableRulesInfo();
```

## 📊 Types d'Anomalies Disponibles

```dart
enum AnomalyType {
  insufficientHours,     // Heures insuffisantes
  excessiveHours,        // Heures excessives
  missingEntry,          // Entrée manquante
  invalidTimes,          // Heures invalides
  scheduleInconsistency, // Incohérence d'horaire
  overtime,              // Heures supplémentaires
  missingBreak,          // Pause manquante
  weekendWork,           // Travail en week-end
  holidayWork,           // Travail en jour férié
}
```

## 🎯 Niveaux de Sévérité

```dart
enum AnomalySeverity {
  low,      // Faible - Couleur: Jaune
  medium,   // Moyenne - Couleur: Orange
  high,     // Élevée - Couleur: Rouge
  critical, // Critique - Couleur: Violet foncé
}
```

## 💡 Bonnes Pratiques

### 1. **Nommage**
- ID en snake_case: `ma_nouvelle_regle`
- Nom lisible: "Ma Nouvelle Règle"
- Fichier en snake_case: `ma_nouvelle_regle.dart`

### 2. **Configuration**
- Toujours fournir des valeurs par défaut sensées
- Valider la configuration dans `isConfigurationValid()`
- Documenter chaque paramètre

### 3. **Performance**
- Éviter les calculs lourds dans `validate()`
- Retourner `null` dès que possible si pas d'anomalie
- Utiliser `mergeConfiguration()` pour éviter les erreurs

### 4. **Tests**
- Tester au minimum: détection + non-détection + validation config
- Utiliser des données réalistes
- Tester les cas limites

### 5. **Documentation**
- Commenter la logique métier complexe
- Expliquer les seuils et tolérances
- Donner des exemples dans la description

## 🔍 Exemples d'Idées de Règles

### Règles Temporelles
- **OvertimeRule**: Détection automatique des heures supplémentaires
- **WeekendWorkRule**: Signaler le travail en week-end
- **NightWorkRule**: Détecter le travail de nuit
- **LateArrivalRule**: Signaler les retards fréquents

### Règles Comportementales
- **InconsistentScheduleRule**: Détecter les horaires très variables
- **ShortDayRule**: Signaler les journées très courtes
- **NoBreakPatternRule**: Détecter les employés qui ne prennent jamais de pause
- **EarlyLeaveRule**: Signaler les départs précoces

### Règles Légales/RH
- **MaxWeeklyHoursRule**: Vérifier le respect des 48h/semaine
- **MinRestTimeRule**: Vérifier le repos minimum entre journées
- **VacationConflictRule**: Détecter les pointages pendant les congés
- **HolidayWorkRule**: Signaler le travail en jours fériés

## 🐛 Debug et Troubleshooting

### Problèmes Courants

1. **Règle non détectée**
   ```bash
   # Vérifier l'enregistrement
   final hasRule = AnomalyRuleRegistry.hasRule('mon_id');
   ```

2. **Configuration invalide**
   ```dart
   // Tester la validation
   final isValid = rule.isConfigurationValid(monConfig);
   ```

3. **Exception lors de la validation**
   ```dart
   // Ajouter des try-catch dans validate()
   try {
     // logique de validation
   } catch (e) {
     // log l'erreur et retourner null
     return null;
   }
   ```

### Logs Utiles

```dart
// Dans votre règle
@override
Future<AnomalyResult?> validate(TimesheetEntry entry, Map<String, dynamic> config) async {
  print('Validation de ${entry.dayDate} avec config: $config');
  
  // ... logique ...
  
  if (result != null) {
    print('Anomalie détectée: ${result.description}');
  }
  
  return result;
}
```

## 📈 Métriques et Statistiques

Le système fournit automatiquement des statistiques sur les anomalies détectées:

```dart
final stats = await anomalyService.getAnomalyStatistics(entries);

print('Total: ${stats.totalAnomalies}');
print('Par type: ${stats.byType}');
print('Par sévérité: ${stats.bySeverity}');
```

---

## 🚀 Démarrage Rapide

1. **Copier** une règle existante comme modèle
2. **Modifier** l'ID, le nom et la logique
3. **Ajouter** au registre
4. **Tester** avec quelques entrées
5. **Documenter** dans ce README si c'est une règle générique

**Votre règle sera immédiatement disponible dans toute l'application!**