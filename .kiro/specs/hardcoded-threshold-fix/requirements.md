# Requirements Document

## Introduction

Cette spécification vise à éliminer tous les seuils de travail journalier codés en dur (8h18) dans l'application et à les remplacer par l'utilisation du paramètre configurable `dailyWorkThresholdMinutes` stocké dans `OvertimeConfiguration`. Actuellement, plusieurs composants utilisent des valeurs codées en dur au lieu de respecter la configuration utilisateur.

## Glossary

- **System**: L'application Time Sheet Flutter
- **DailyWorkThreshold**: Le seuil d'heures de travail journalier au-delà duquel les heures sont considérées comme supplémentaires
- **OvertimeConfiguration**: Le modèle Isar qui stocke les paramètres de configuration des heures supplémentaires
- **HardcodedThreshold**: Une valeur de seuil définie directement dans le code (Duration(hours: 8, minutes: 18))

## Requirements

### Requirement 1

**User Story:** En tant qu'employé, je veux que tous les calculs d'heures supplémentaires utilisent le seuil que j'ai configuré dans mes paramètres, afin que mes heures soient calculées correctement selon mon contrat de travail.

#### Acceptance Criteria

1. WHEN le System calcule les heures supplémentaires THEN le System SHALL utiliser le DailyWorkThreshold configuré dans OvertimeConfiguration
2. WHEN un utilisateur modifie le DailyWorkThreshold dans les paramètres THEN le System SHALL appliquer immédiatement ce nouveau seuil à tous les calculs
3. WHEN le System affiche des indicateurs visuels d'heures supplémentaires THEN le System SHALL utiliser le DailyWorkThreshold configuré pour déterminer si les heures dépassent le seuil

### Requirement 2

**User Story:** En tant que développeur, je veux que tous les composants utilisent une source unique de vérité pour le seuil de travail journalier, afin d'éviter les incohérences dans l'application.

#### Acceptance Criteria

1. WHEN le System initialise un calculateur d'heures supplémentaires THEN le System SHALL charger le DailyWorkThreshold depuis OvertimeConfiguration
2. WHEN le System utilise une valeur par défaut THEN le System SHALL utiliser la constante définie dans OvertimeConfiguration.defaultConfig()
3. WHEN le System a besoin du DailyWorkThreshold THEN le System SHALL NOT utiliser de valeurs codées en dur dans le code

### Requirement 3

**User Story:** En tant qu'utilisateur, je veux que les indicateurs visuels dans le calendrier reflètent mon seuil configuré, afin de voir correctement quels jours j'ai dépassé mes heures normales.

#### Acceptance Criteria

1. WHEN le System affiche un rendez-vous dans le calendrier THEN le System SHALL utiliser le DailyWorkThreshold configuré pour déterminer la couleur d'affichage
2. WHEN un jour dépasse le DailyWorkThreshold configuré THEN le System SHALL afficher un indicateur visuel approprié
3. WHEN le DailyWorkThreshold est modifié THEN le System SHALL mettre à jour immédiatement les indicateurs visuels du calendrier

### Requirement 4

**User Story:** En tant qu'utilisateur, je veux que les widgets de configuration affichent et modifient le seuil réel stocké dans la base de données, afin que mes modifications soient persistées correctement.

#### Acceptance Criteria

1. WHEN le System affiche le widget de configuration weekend THEN le System SHALL charger le DailyWorkThreshold depuis OvertimeConfiguration
2. WHEN un utilisateur modifie le DailyWorkThreshold dans le widget THEN le System SHALL sauvegarder la nouvelle valeur dans OvertimeConfiguration
3. WHEN le System initialise le widget de configuration THEN le System SHALL NOT utiliser de valeurs par défaut codées en dur

### Requirement 5

**User Story:** En tant que développeur, je veux que les calculateurs d'heures supplémentaires (weekend et mensuel) acceptent le seuil en paramètre, afin de garantir la flexibilité et la testabilité du code.

#### Acceptance Criteria

1. WHEN le System appelle WeekendOvertimeCalculator THEN le System SHALL passer le DailyWorkThreshold en paramètre
2. WHEN le System appelle MonthlyOvertimeCalculator THEN le System SHALL passer le DailyWorkThreshold en paramètre
3. WHEN les calculateurs utilisent une valeur par défaut THEN les calculateurs SHALL utiliser la constante defaultStandardWorkDay définie dans leur classe
