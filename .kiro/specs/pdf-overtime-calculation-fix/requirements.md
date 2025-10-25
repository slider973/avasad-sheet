# Requirements Document

## Introduction

Cette spécification corrige un problème critique dans la génération des PDF de feuilles de temps où le total mensuel des heures supplémentaires est calculé incorrectement. Actuellement, le système additionne les heures supplémentaires brutes de chaque jour, mais il devrait additionner les totaux hebdomadaires qui incluent déjà les compensations et ajustements appropriés. Cette correction garantit que les rapports PDF reflètent fidèlement les calculs d'heures supplémentaires utilisés dans l'interface utilisateur.

## Requirements

### Requirement 1

**User Story:** En tant qu'employé, je veux que le total mensuel des heures supplémentaires dans mon PDF soit calculé correctement, afin que mes rapports soient cohérents avec ce que je vois dans l'application.

#### Acceptance Criteria

1. WHEN je génère un PDF de feuille de temps THEN le total mensuel des heures supplémentaires SHALL être la somme des totaux hebdomadaires
2. WHEN je compare le PDF avec l'interface utilisateur THEN les totaux d'heures supplémentaires SHALL être identiques
3. WHEN le PDF affiche les totaux hebdomadaires THEN chaque total hebdomadaire SHALL inclure les compensations et ajustements appropriés
4. WHEN je consulte le résumé mensuel dans le PDF THEN il SHALL refléter exactement les calculs utilisés dans l'application

### Requirement 2

**User Story:** En tant qu'employé, je veux que les totaux hebdomadaires dans le PDF soient calculés avec la même logique que dans l'application, afin d'avoir une cohérence complète entre tous les affichages.

#### Acceptance Criteria

1. WHEN le PDF calcule un total hebdomadaire THEN il SHALL utiliser le même algorithme que l'UnifiedOvertimeCalculator
2. WHEN une semaine contient des heures de weekend THEN le total hebdomadaire SHALL inclure les bonifications de weekend appropriées
3. WHEN une semaine contient des compensations mensuelles THEN le total hebdomadaire SHALL inclure ces ajustements
4. WHEN je consulte les détails d'une semaine dans le PDF THEN ils SHALL correspondre exactement aux calculs de l'interface utilisateur

### Requirement 3

**User Story:** En tant qu'employé, je veux que le PDF utilise les mêmes paramètres de configuration que l'application, afin que mes préférences personnelles soient respectées dans les rapports.

#### Acceptance Criteria

1. WHEN le PDF est généré THEN il SHALL utiliser mes paramètres de seuil d'heures normales configurés
2. WHEN j'ai activé la compensation mensuelle THEN le PDF SHALL appliquer cette logique dans ses calculs
3. WHEN j'ai configuré des paramètres de weekend THEN le PDF SHALL les respecter dans les totaux
4. WHEN j'ai désactivé les heures supplémentaires pour certains jours THEN le PDF SHALL respecter ces exceptions

### Requirement 4

**User Story:** En tant qu'employé, je veux que la structure du PDF reste identique, afin de maintenir la familiarité avec le format existant tout en corrigeant les calculs.

#### Acceptance Criteria

1. WHEN le PDF est généré THEN la mise en page et le design SHALL rester inchangés
2. WHEN je consulte les sections du PDF THEN elles SHALL apparaître dans le même ordre qu'avant
3. WHEN je regarde les tableaux hebdomadaires THEN ils SHALL conserver leur format actuel
4. WHEN je consulte le résumé mensuel THEN seuls les calculs SHALL être corrigés, pas la présentation

### Requirement 5

**User Story:** En tant que manager, je veux que les PDF générés par mes employés soient cohérents et fiables, afin de pouvoir les valider en toute confiance.

#### Acceptance Criteria

1. WHEN je reçois un PDF d'employé THEN les totaux SHALL être calculés de manière cohérente avec les autres rapports
2. WHEN je compare plusieurs PDF du même employé THEN la logique de calcul SHALL être identique
3. WHEN je valide un PDF THEN je SHALL pouvoir faire confiance aux totaux affichés
4. WHEN un employé régénère son PDF THEN les totaux SHALL rester identiques si aucune donnée n'a changé

### Requirement 6

**User Story:** En tant que développeur, je veux que la correction soit implémentée de manière robuste, afin d'éviter de futurs problèmes de cohérence.

#### Acceptance Criteria

1. WHEN le code de génération PDF est modifié THEN il SHALL réutiliser les services de calcul existants
2. WHEN de nouveaux types de calculs d'heures supplémentaires sont ajoutés THEN le PDF SHALL automatiquement les inclure
3. WHEN les paramètres de configuration changent THEN le PDF SHALL s'adapter automatiquement
4. WHEN des tests sont exécutés THEN ils SHALL vérifier la cohérence entre l'UI et le PDF
5. WHEN le code est refactorisé THEN la logique de calcul SHALL rester centralisée et réutilisable