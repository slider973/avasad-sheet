# Implementation Plan

- [x] 1. Créer les services de base pour la détection du weekend
  - Implémenter WeekendDetectionService avec méthodes de détection des jours de weekend
  - Créer les énumérations et types nécessaires (OvertimeType)
  - Écrire les tests unitaires pour la détection des jours de weekend
  - _Requirements: 1.1, 4.1_

- [x] 2. Étendre le modèle TimesheetEntry pour le support du weekend
- [x] 2.1 Modifier l'entité TimesheetEntry domain
  - Ajouter les propriétés isWeekendDay, isWeekendOvertimeEnabled, overtimeType
  - Implémenter les getters pour weekendHours, weekdayOvertimeHours, weekendOvertimeHours
  - Ajouter la méthode isWeekend et les calculs associés
  - _Requirements: 1.1, 2.1_

- [x] 2.2 Mettre à jour le modèle Isar TimeSheetEntryModel
  - Ajouter les nouvelles propriétés avec les annotations Isar appropriées
  - Implémenter la méthode updateWeekendStatus pour les calculs automatiques
  - Créer la migration de base de données pour les nouvelles colonnes
  - _Requirements: 1.1, 2.1_

- [x] 3. Implémenter le service de calcul des heures supplémentaires weekend
- [x] 3.1 Créer WeekendOvertimeCalculator
  - Implémenter calculateWeekendOvertime et calculateWeekdayOvertime
  - Créer la classe OvertimeSummary avec les totaux par catégorie
  - Implémenter calculateMonthlyOvertime avec séparation weekend/semaine
  - _Requirements: 2.1, 2.2_

- [x] 3.2 Étendre TimeUtils pour les calculs weekend
  - Ajouter les méthodes isWeekend, calculateWeekendHours, calculateWeekdayOvertimeHours
  - Modifier calculateTotalHours pour prendre en compte le type d'heures supplémentaires
  - Écrire les tests unitaires pour tous les nouveaux calculs
  - _Requirements: 2.1, 2.2_

- [x] 4. Créer le système de configuration des heures supplémentaires
- [x] 4.1 Implémenter OvertimeConfigurationService
  - Créer les méthodes de gestion des paramètres weekend (enabled/disabled)
  - Implémenter la configuration des jours de weekend personnalisés
  - Ajouter la gestion des taux de majoration weekend vs semaine
  - _Requirements: 3.1, 3.2, 6.1, 6.2_

- [x] 4.2 Créer le modèle Isar OvertimeConfiguration
  - Définir la structure de données pour les paramètres d'heures supplémentaires
  - Implémenter les valeurs par défaut et la validation
  - Créer les méthodes de sauvegarde et chargement des configurations
  - _Requirements: 3.1, 6.1, 6.2_

- [x] 5. Mettre à jour l'interface utilisateur pour le weekend
- [x] 5.1 Ajouter les indicateurs visuels weekend dans l'interface de pointage
  - Modifier l'écran de pointage pour afficher un badge "Weekend" les samedi/dimanche
  - Ajouter une couleur ou icône distinctive pour les jours de weekend
  - Implémenter l'affichage automatique du statut "heures supplémentaires" le weekend
  - _Requirements: 1.2, 4.2_

- [x] 5.2 Créer l'interface de configuration des paramètres weekend
  - Ajouter un écran de paramètres pour activer/désactiver les heures supplémentaires weekend
  - Implémenter l'interface de sélection des jours de weekend personnalisés
  - Créer les champs de configuration des taux de majoration
  - _Requirements: 3.1, 3.2, 6.1, 6.2_

- [x] 6. Mettre à jour l'affichage des résumés et historiques
- [x] 6.1 Modifier l'écran d'historique des pointages
  - Ajouter la distinction visuelle entre heures supplémentaires semaine et weekend
  - Implémenter l'affichage des totaux séparés par catégorie
  - Créer des filtres pour voir uniquement les heures de weekend
  - _Requirements: 2.1, 2.2, 4.3_

- [x] 6.2 Étendre les écrans de résumé mensuel
  - Ajouter les sections séparées pour heures supplémentaires weekend et semaine
  - Implémenter l'affichage des taux de majoration appliqués
  - Créer des graphiques ou indicateurs visuels pour les différents types d'heures
  - _Requirements: 2.2, 2.3_

- [x] 7. Modifier le générateur PDF pour inclure les heures de weekend
- [x] 7.1 Étendre le template PDF avec les sections weekend
  - Ajouter une section "Heures supplémentaires - Weekend" dans le PDF
  - Séparer les totaux entre "Heures supplémentaires semaine" et "Heures supplémentaires weekend"
  - Inclure les taux de majoration appliqués dans le rapport
  - _Requirements: 1.3, 2.2_

- [x] 7.2 Mettre à jour la logique de génération PDF
  - Modifier les calculs pour utiliser WeekendOvertimeCalculator
  - Implémenter la séparation des données par type d'heures supplémentaires
  - Ajouter la validation des données avant génération PDF
  - _Requirements: 1.3, 2.2_

- [x] 8. Étendre le système de validation manager
- [x] 8.1 Modifier l'interface de validation pour les heures weekend
  - Ajouter des alertes visuelles pour les employés ayant travaillé le weekend
  - Implémenter l'affichage du récapitulatif des heures weekend avant validation
  - Créer des filtres pour identifier rapidement les feuilles avec heures weekend
  - _Requirements: 5.1, 5.2_

- [x] 8.2 Mettre à jour le workflow d'approbation
  - Inclure les heures de weekend dans le calcul total des heures supplémentaires
  - Ajouter la validation des taux de majoration avant signature
  - Implémenter les notifications pour les heures weekend exceptionnelles
  - _Requirements: 5.2, 5.3_

- [x] 9. Créer le système de migration des données existantes
- [x] 9.1 Implémenter WeekendOvertimeMigration
  - Créer le script de migration pour identifier les anciens pointages de weekend
  - Implémenter la logique de conversion des heures weekend existantes
  - Ajouter la validation et les logs de migration
  - _Requirements: 6.3_

- [x] 9.2 Mettre à jour le TimerService pour la détection automatique
  - Modifier TimerService pour détecter automatiquement les jours de weekend
  - Implémenter l'application automatique des règles d'heures supplémentaires weekend
  - Ajouter la sauvegarde des paramètres weekend dans les préférences
  - _Requirements: 4.1, 4.2_

- [x] 10. Créer les tests d'intégration complets
- [x] 10.1 Tests end-to-end du workflow weekend
  - Créer des tests simulant un pointage complet le weekend
  - Tester la génération PDF avec heures de weekend
  - Valider le workflow de validation manager avec heures weekend
  - _Requirements: 1.1, 1.2, 1.3, 5.1, 5.2_

- [x] 10.2 Tests de configuration et migration
  - Tester les changements de configuration et leur impact sur les calculs
  - Valider la migration des données existantes
  - Tester les cas limites et la gestion d'erreurs
  - _Requirements: 3.1, 3.2, 6.1, 6.2, 6.3_