# Système de Calcul des Heures Supplémentaires avec Compensation Mensuelle

## Problème Résolu

L'ancien système calculait les heures supplémentaires jour par jour, ce qui pouvait être injuste :
- Un employé travaillant 6h un jour et 10h le lendemain avait 2h d'heures supplémentaires
- Alors qu'au total, il avait travaillé 16h pour 16h36 attendues (déficit de 36 minutes)

## Solution Implémentée

### 1. Nouveau Calculateur Mensuel (`MonthlyOvertimeCalculator`)

**Principe :** Compensation des déficits d'heures par les excès sur le mois

**Fonctionnement :**
- Calcule le total d'heures travaillées sur le mois
- Compare avec le total d'heures attendues (nombre de jours × 8h18)
- Les excès d'heures compensent d'abord les déficits
- Seul le surplus après compensation devient des heures supplémentaires

**Exemple :**
```
Semaine : Lundi 6h, Mardi 10h30
- Total travaillé : 16h30
- Total attendu : 16h36 (2 × 8h18)
- Résultat : 0h sup (déficit de 6 minutes)

Ancien système : 2h12 d'heures sup (seulement le mardi)
Nouveau système : 0h sup (compensation du déficit du lundi)
```

### 2. Service Unifié (`UnifiedOvertimeCalculator`)

**Fonctionnalités :**
- Utilise le bon calculateur selon la configuration utilisateur
- Permet de comparer les deux modes de calcul
- Interface unique pour toute l'application

**Modes disponibles :**
- **Journalier** : Ancien système (jour par jour)
- **Mensuel avec compensation** : Nouveau système (compensation des déficits)

### 3. Configuration Utilisateur

**Service de Configuration (`OvertimeCalculationModeService`) :**
- Stockage du mode choisi dans SharedPreferences
- Mode journalier par défaut (compatibilité)
- Possibilité de changer de mode à tout moment

**Widget de Configuration (`OvertimeCalculationModeWidget`) :**
- Interface utilisateur pour choisir le mode
- Explication des différences avec exemples
- Comparaison visuelle des résultats

### 4. Interface Utilisateur

**Widget de Résumé (`UnifiedOvertimeSummaryWidget`) :**
- Affichage adapté selon le mode choisi
- Informations de compensation pour le mode mensuel
- Barre de progression de compensation des déficits

**Widget de Comparaison (`OvertimeComparisonWidget`) :**
- Compare les résultats des deux modes
- Affiche les différences et recommandations
- Alerte en cas de déficit non compensé

## Avantages du Nouveau Système

### 1. Plus Équitable
- Tient compte des variations naturelles d'horaires
- Évite de pénaliser les employés qui rattrapent leurs heures

### 2. Plus Réaliste
- Reflète mieux la réalité du travail (certains jours plus chargés que d'autres)
- Encourage la flexibilité des horaires

### 3. Transparent
- Affiche clairement les déficits et leur compensation
- Permet de voir l'impact des choix d'horaires

### 4. Configurable
- L'utilisateur peut choisir le mode qui lui convient
- Possibilité de comparer les deux approches

## Structure des Fichiers

```
lib/services/
├── monthly_overtime_calculator.dart          # Nouveau calculateur mensuel
├── unified_overtime_calculator.dart          # Service unifié
├── overtime_calculation_mode_service.dart    # Configuration du mode
└── weekend_overtime_calculator.dart          # Ancien calculateur (conservé)

lib/features/preference/presentation/widgets/
└── overtime_calculation_mode_widget.dart     # Widget de configuration

lib/features/pointage/presentation/widgets/
└── unified_overtime_summary_widget.dart      # Widgets d'affichage

test/
├── monthly_overtime_calculator_test.dart     # Tests du nouveau calculateur
├── unified_overtime_calculator_test.dart     # Tests du service unifié
└── monthly_overtime_integration_test.dart    # Tests d'intégration
```

## Classes Principales

### `MonthlyOvertimeSummary`
```dart
class MonthlyOvertimeSummary {
  final Duration regularHours;              // Heures régulières
  final Duration weekdayOvertime;           // Heures sup weekday après compensation
  final Duration weekendOvertime;           // Heures sup weekend (inchangées)
  final Duration deficitHours;              // Total des déficits
  final Duration compensatedDeficitHours;   // Déficits compensés
  final double deficitCompensationPercentage; // % de compensation
}
```

### `UnifiedOvertimeSummary`
```dart
class UnifiedOvertimeSummary {
  final OvertimeCalculationMode mode;       // Mode utilisé
  final Duration uncompensatedDeficitHours; // Déficit restant
  final bool hasUncompensatedDeficit;       // Indicateur de déficit
}
```

## Tests Implémentés

### Tests Unitaires
- **`monthly_overtime_calculator_test.dart`** : Logique de compensation
- **`unified_overtime_calculator_test.dart`** : Service unifié et comparaisons

### Tests d'Intégration
- **`monthly_overtime_integration_test.dart`** : Scénarios réels complexes
- Cas avec déficits partiellement compensés
- Cas avec vraies heures supplémentaires après compensation
- Gestion des weekends et absences

## Migration et Compatibilité

### Rétrocompatibilité
- Mode journalier par défaut (ancien comportement)
- Aucun impact sur les utilisateurs existants
- Migration progressive possible

### Données Existantes
- Aucune modification des données stockées
- Calculs effectués à la volée selon le mode choisi
- Possibilité de revenir à l'ancien mode à tout moment

## Utilisation

### Configuration du Mode
```dart
final modeService = OvertimeCalculationModeService();
await modeService.setCalculationMode(OvertimeCalculationMode.monthlyWithCompensation);
```

### Calcul des Heures Supplémentaires
```dart
final calculator = UnifiedOvertimeCalculator();
final summary = await calculator.calculateOvertime(entries);

print('Mode: ${summary.mode.displayName}');
print('Heures sup: ${summary.formattedTotalOvertime}');
if (summary.hasUncompensatedDeficit) {
  print('Déficit restant: ${summary.formattedUncompensatedDeficitHours}');
}
```

### Comparaison des Modes
```dart
final comparison = await calculator.compareCalculationModes(entries);
print('Différence: ${comparison.overtimeDifference}');
print('Mode avantageux: ${comparison.modeWithMoreOvertime.displayName}');
```

## Conclusion

Ce nouveau système offre une approche plus équitable et réaliste du calcul des heures supplémentaires, tout en préservant la compatibilité avec l'ancien système. Les utilisateurs peuvent choisir l'approche qui correspond le mieux à leur situation de travail.