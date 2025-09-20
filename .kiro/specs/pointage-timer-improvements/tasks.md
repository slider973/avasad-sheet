# Plan d'Implémentation - Améliorations du Chronomètre de Pointage

- [x] 1. Créer les nouveaux modèles de données pour les calculs automatiques
  - Créer la classe WorkTimeInfo pour les calculs temps réel (heure de fin, temps restant)
  - Créer la classe WorkTimeConfiguration pour les paramètres configurables
  - Créer la classe ExtendedTimerState pour combiner TimerService avec les calculs
  - Écrire les tests unitaires complets (18 tests créés)
  - _Exigences: 2.1, 2.2, 3.1, 6.4_

- [x] 2. Créer le WorkTimeCalculatorService
  - Créer le service qui utilise les nouveaux modèles pour les calculs
  - Implémenter calculateWorkTimeInfo() qui génère WorkTimeInfo depuis TimerService
  - Ajouter la gestion des pauses et du suivi du temps de travail effectif
  - Intégrer avec WorkTimeConfiguration pour les paramètres personnalisables
  - Écrire les tests unitaires pour tous les scénarios de calcul
  - _Exigences: 2.1, 2.2, 2.3, 2.4, 3.1_

- [x] 3. Étendre le TimerService existant avec les calculs automatiques
  - Ajouter WorkTimeCalculatorService comme dépendance dans TimerService
  - Créer une méthode getExtendedTimerState() qui retourne ExtendedTimerState
  - Intégrer les calculs automatiques dans les getters existants
  - Ajouter le suivi des pauses pour calculer le temps de travail effectif
  - Préserver toute la logique existante (weekend, sauvegarde, etc.)
  - Écrire des tests d'intégration TimerService + WorkTimeCalculatorService
  - _Exigences: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 6.1, 6.2_

- [x] 4. Créer le service d'affichage pour l'interface utilisateur
  - Créer TimerDisplayService pour formater les données d'affichage
  - Implémenter formatDuration(), formatEndTime(), formatOvertimeStatus()
  - Ajouter calculateProgressPercentages() pour l'affichage circulaire
  - Implémenter getSegmentColors() pour les couleurs selon l'état
  - Écrire les tests pour tous les formats d'affichage
  - _Exigences: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 5. Modifier l'interface utilisateur PointageTimer
- [x] 5.1 Ajouter l'affichage de l'heure de fin prévue
  - Modifier PointageTimer pour inclure l'heure de fin dans l'affichage central
  - Créer EndTimeDisplay widget pour l'heure de fin
  - Implémenter la mise à jour temps réel de l'heure de fin
  - Préserver le design existant du chronomètre circulaire
  - _Exigences: 5.1, 4.2_

- [-] 5.2 Implémenter l'indicateur visuel des heures supplémentaires
  - Créer OvertimeIndicator widget pour signaler les heures supplémentaires
  - Modifier TimerPainter pour changer les couleurs en mode heures supplémentaires
  - Ajouter des animations pour les transitions d'état
  - Tester l'affichage avec différents scénarios d'heures supplémentaires
  - _Exigences: 3.2, 5.2, 5.5_

- [x] 5.3 Améliorer l'affichage des détails des segments
  - Modifier _showSegmentDetails() pour inclure les nouvelles informations
  - Ajouter l'affichage du temps restant et de l'heure de fin
  - Inclure l'état des heures supplémentaires dans les détails
  - Améliorer le formatage des informations affichées
  - _Exigences: 5.3, 5.4_

- [x] 6. Intégrer avec TimeSheetBloc et PointageWidget
  - Étendre TimeSheetBloc pour utiliser ExtendedTimerState
  - Modifier les événements et états pour inclure WorkTimeInfo
  - Intégrer TimerService amélioré dans les handlers d'événements
  - Modifier PointageWidget pour afficher les nouvelles informations
  - Préserver toutes les fonctionnalités existantes (absence, modification, etc.)
  - _Exigences: 4.1, 4.2, 4.3, 4.4, 6.4_

- [ ] 7. Implémenter les tests d'intégration complets
- [ ] 7.1 Tester les flux complets de pointage
  - Tester le flux : Entrée → Pause → Reprise → Sortie avec calculs automatiques
  - Vérifier les calculs à chaque étape et la persistance des données
  - Tester la récupération après fermeture/réouverture de l'application
  - Valider l'affichage des informations calculées dans l'interface
  - _Exigences: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3_

- [ ] 7.2 Tester les scénarios d'heures supplémentaires
  - Tester le passage aux heures supplémentaires après 8 heures
  - Vérifier le comportement avec les heures supplémentaires désactivées
  - Tester le travail en weekend avec heures supplémentaires
  - Valider les calculs avec pauses longues et configurations personnalisées
  - _Exigences: 3.1, 3.2, 3.4, 3.5_

- [ ] 8. Optimiser et finaliser
  - Optimiser les performances des calculs temps réel
  - Implémenter la mise en cache des calculs coûteux
  - Finaliser la documentation des nouvelles APIs
  - Effectuer les tests de régression complets
  - Valider la compatibilité avec toutes les fonctionnalités existantes
  - _Exigences: Performance, Documentation, Tests, Toutes les exigences_