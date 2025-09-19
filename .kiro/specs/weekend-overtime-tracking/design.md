# Design Document - Weekend Overtime Tracking

## Overview

Cette conception étend le système existant de gestion des heures supplémentaires pour inclure automatiquement le travail effectué le weekend. Le système détectera automatiquement les jours de weekend (samedi/dimanche) et appliquera les règles d'heures supplémentaires appropriées.

## Architecture

### Composants Modifiés

1. **TimesheetEntry Entity** - Ajout de propriétés pour la gestion du weekend
2. **TimeUtils Service** - Extension des calculs pour les heures de weekend
3. **TimerService** - Détection automatique des jours de weekend
4. **PDF Generator** - Séparation des heures supplémentaires par type
5. **Settings/Configuration** - Paramètres de configuration du weekend

### Nouveaux Composants

1. **WeekendOvertimeCalculator** - Service de calcul spécialisé pour le weekend
2. **WeekendDetectionService** - Service de détection des jours de weekend
3. **OvertimeConfigurationService** - Gestion des paramètres d'heures supplémentaires

## Components and Interfaces

### 1. Enhanced TimesheetEntry Entity

```dart
class TimesheetEntry {
  // Propriétés existantes...
  final bool hasOvertimeHours;
  
  // Nouvelles propriétés
  final bool isWeekendDay;
  final bool isWeekendOvertimeEnabled;
  final OvertimeType overtimeType; // WEEKDAY, WEEKEND, BOTH
  
  // Méthodes étendues
  bool get isWeekend => _isWeekendDay(date);
  Duration get weekendHours => isWeekend ? calculateDailyTotal() : Duration.zero;
  Duration get weekdayOvertimeHours => !isWeekend && hasOvertimeHours ? calculateOvertimeHours() : Duration.zero;
  Duration get weekendOvertimeHours => isWeekend ? calculateDailyTotal() : Duration.zero;
}

enum OvertimeType {
  NONE,
  WEEKDAY_ONLY,
  WEEKEND_ONLY,
  BOTH
}
```

### 2. WeekendDetectionService

```dart
class WeekendDetectionService {
  static const List<int> DEFAULT_WEEKEND_DAYS = [DateTime.saturday, DateTime.sunday];
  
  bool isWeekend(DateTime date, {List<int>? customWeekendDays});
  List<int> getConfiguredWeekendDays();
  Future<void> updateWeekendConfiguration(List<int> weekendDays);
  
  // Détection intelligente basée sur les paramètres utilisateur
  bool shouldApplyWeekendOvertime(DateTime date);
}
```

### 3. WeekendOvertimeCalculator

```dart
class WeekendOvertimeCalculator {
  Duration calculateWeekendOvertime(TimesheetEntry entry);
  Duration calculateWeekdayOvertime(TimesheetEntry entry);
  
  OvertimeSummary calculateMonthlyOvertime(List<TimesheetEntry> entries);
  
  // Configuration des taux de majoration
  double getWeekendOvertimeRate();
  double getWeekdayOvertimeRate();
}

class OvertimeSummary {
  final Duration weekdayOvertime;
  final Duration weekendOvertime;
  final Duration totalOvertime;
  final double weekendOvertimeRate;
  final double weekdayOvertimeRate;
}
```

### 4. Enhanced TimeUtils

```dart
class TimeUtils {
  // Méthodes existantes...
  
  // Nouvelles méthodes pour le weekend
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
  
  static Duration calculateWeekendHours(List<TimesheetEntry> entries) {
    return entries
        .where((entry) => entry.isWeekend)
        .fold(Duration.zero, (total, entry) => total + entry.calculateDailyTotal());
  }
  
  static Duration calculateWeekdayOvertimeHours(List<TimesheetEntry> entries) {
    return entries
        .where((entry) => !entry.isWeekend && entry.hasOvertimeHours)
        .fold(Duration.zero, (total, entry) => total + entry.calculateOvertimeHours());
  }
}
```

### 5. Configuration Service

```dart
class OvertimeConfigurationService {
  // Configuration du weekend
  Future<bool> isWeekendOvertimeEnabled();
  Future<void> setWeekendOvertimeEnabled(bool enabled);
  
  // Configuration des jours de weekend
  Future<List<int>> getWeekendDays();
  Future<void> setWeekendDays(List<int> days);
  
  // Configuration des taux
  Future<double> getWeekendOvertimeRate();
  Future<void> setWeekendOvertimeRate(double rate);
  
  // Seuils d'heures normales
  Future<Duration> getDailyWorkThreshold();
  Future<void> setDailyWorkThreshold(Duration threshold);
}
```

## Data Models

### Enhanced TimeSheetEntryModel (Isar)

```dart
@collection
class TimeSheetEntryModel {
  // Propriétés existantes...
  
  @Index()
  bool hasOvertimeHours = false;
  
  // Nouvelles propriétés
  @Index()
  bool isWeekendDay = false;
  
  @Index()
  bool isWeekendOvertimeEnabled = true;
  
  @Enumerated(EnumType.name)
  OvertimeType overtimeType = OvertimeType.NONE;
  
  // Calculs automatiques lors de la sauvegarde
  void updateWeekendStatus() {
    isWeekendDay = dayDate.weekday == DateTime.saturday || 
                   dayDate.weekday == DateTime.sunday;
    
    if (isWeekendDay && isWeekendOvertimeEnabled) {
      overtimeType = hasOvertimeHours ? OvertimeType.BOTH : OvertimeType.WEEKEND_ONLY;
    } else if (hasOvertimeHours) {
      overtimeType = OvertimeType.WEEKDAY_ONLY;
    } else {
      overtimeType = OvertimeType.NONE;
    }
  }
}
```

### Configuration Model

```dart
@collection
class OvertimeConfiguration {
  Id id = Isar.autoIncrement;
  
  bool weekendOvertimeEnabled = true;
  List<int> weekendDays = [DateTime.saturday, DateTime.sunday];
  double weekendOvertimeRate = 1.5; // 150%
  double weekdayOvertimeRate = 1.25; // 125%
  int dailyWorkThresholdMinutes = 480; // 8 heures
  
  DateTime lastUpdated = DateTime.now();
}
```

## Error Handling

### Validation Rules

1. **Weekend Day Validation**
   - Vérifier que les jours de weekend configurés sont valides (1-7)
   - Au moins un jour doit être configuré comme jour de travail normal

2. **Overtime Rate Validation**
   - Les taux de majoration doivent être >= 1.0
   - Les taux ne peuvent pas être négatifs

3. **Time Threshold Validation**
   - Le seuil d'heures normales doit être entre 1 et 24 heures
   - Validation des formats de temps

### Error Types

```dart
abstract class WeekendOvertimeError extends Failure {
  const WeekendOvertimeError(String message) : super(message);
}

class InvalidWeekendConfigurationError extends WeekendOvertimeError {
  const InvalidWeekendConfigurationError(String message) : super(message);
}

class InvalidOvertimeRateError extends WeekendOvertimeError {
  const InvalidOvertimeRateError(String message) : super(message);
}

class WeekendCalculationError extends WeekendOvertimeError {
  const WeekendCalculationError(String message) : super(message);
}
```

## Testing Strategy

### Unit Tests

1. **WeekendDetectionService Tests**
   - Test de détection des jours de weekend avec différentes configurations
   - Test des cas limites (changement d'heure, fuseaux horaires)

2. **WeekendOvertimeCalculator Tests**
   - Test des calculs d'heures supplémentaires weekend vs semaine
   - Test des différents taux de majoration
   - Test des cas avec heures supplémentaires mixtes

3. **Configuration Service Tests**
   - Test de sauvegarde/chargement des configurations
   - Test de validation des paramètres
   - Test de migration des données existantes

### Integration Tests

1. **End-to-End Weekend Workflow**
   - Pointage un samedi → Vérification automatique des heures supplémentaires
   - Génération PDF avec séparation weekend/semaine
   - Validation manager avec heures de weekend

2. **Configuration Changes**
   - Modification des jours de weekend → Recalcul automatique
   - Changement des taux → Mise à jour des rapports existants

### Widget Tests

1. **Weekend Indicator UI**
   - Affichage des badges weekend dans la liste des pointages
   - Interface de configuration des paramètres weekend

2. **PDF Preview**
   - Vérification de la séparation des sections dans le PDF
   - Test de l'affichage des totaux par catégorie

## Implementation Flow

### Phase 1: Core Weekend Detection
1. Implémenter WeekendDetectionService
2. Étendre TimesheetEntry avec propriétés weekend
3. Mettre à jour TimeUtils pour la détection

### Phase 2: Overtime Calculation
1. Implémenter WeekendOvertimeCalculator
2. Étendre les calculs existants
3. Ajouter les tests unitaires

### Phase 3: Configuration System
1. Implémenter OvertimeConfigurationService
2. Créer l'interface de configuration
3. Gérer la migration des données existantes

### Phase 4: UI Updates
1. Ajouter les indicateurs visuels weekend
2. Mettre à jour les écrans de résumé
3. Étendre l'interface de paramètres

### Phase 5: PDF Integration
1. Modifier le générateur PDF pour séparer les catégories
2. Ajouter les sections weekend dans les rapports
3. Mettre à jour les templates de validation

### Phase 6: Manager Validation
1. Étendre l'interface de validation manager
2. Ajouter les alertes pour heures weekend
3. Mettre à jour le workflow d'approbation

## Migration Strategy

### Existing Data Migration

```dart
class WeekendOvertimeMigration {
  Future<void> migrateExistingEntries() async {
    final entries = await getAllTimesheetEntries();
    
    for (final entry in entries) {
      // Détecter si c'était un jour de weekend
      entry.isWeekendDay = TimeUtils.isWeekend(entry.date);
      
      // Si c'était un weekend, marquer comme heures supplémentaires
      if (entry.isWeekendDay && entry.calculateDailyTotal() > Duration.zero) {
        entry.overtimeType = OvertimeType.WEEKEND_ONLY;
      }
      
      await saveTimesheetEntry(entry);
    }
  }
}
```

### Configuration Defaults

- Weekend automatique activé par défaut
- Samedi et dimanche comme jours de weekend par défaut
- Taux de majoration weekend: 150%
- Taux de majoration semaine: 125%
- Seuil journalier: 8 heures