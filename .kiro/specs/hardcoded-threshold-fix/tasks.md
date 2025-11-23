# Plan d'implémentation

- [x] 1. Ajouter le paramètre dailyThreshold aux calculateurs
  - [x] 1.1 Modifier WeekendOvertimeCalculator
    - Ajouter le paramètre optionnel `dailyThreshold` à `calculateWeekdayOvertime`
    - Ajouter le paramètre optionnel `dailyThreshold` à `calculateMonthlyOvertime`
    - Ajouter le paramètre optionnel `dailyThreshold` à `determineOvertimeType`
    - Utiliser `dailyThreshold ?? defaultStandardWorkDay` dans toutes les méthodes
    - _Requirements: 1.1, 2.1, 5.1_

  - [x] 1.2 Vérifier MonthlyOvertimeCalculator
    - Confirmer que le paramètre `dailyThreshold` existe déjà dans `calculateMonthlyOvertime`
    - Confirmer que le paramètre `dailyThreshold` existe déjà dans `calculateWeeklyBreakdown`
    - Vérifier que toutes les méthodes utilisent correctement le paramètre
    - _Requirements: 1.1, 2.1, 5.2_

- [x] 2. Mettre à jour les use cases pour charger la configuration
  - [x] 2.1 Modifier CalculateOvertimeHoursUseCase
    - Injecter `OvertimeConfigurationRepository` dans le constructeur
    - Dans `executeMonthly`, charger la configuration avec `getOrCreateDefaultConfiguration()`
    - Extraire `dailyWorkThreshold` de la configuration
    - Passer `dailyThreshold` aux appels de `calculateMonthlyOvertime`
    - Passer `weekdayRate` et `weekendRate` depuis la configuration
    - _Requirements: 1.1, 1.2, 2.1_

  - [x] 2.2 Modifier GeneratePdfUseCase
    - Injecter `OvertimeConfigurationRepository` dans le constructeur
    - Charger la configuration au début de la méthode `call`
    - Extraire `dailyWorkThreshold` de la configuration
    - Passer `dailyThreshold` aux appels de `calculateWeeklyBreakdown`
    - Passer les taux d'heures supplémentaires depuis la configuration
    - _Requirements: 1.1, 1.2, 2.1_

- [x] 3. Mettre site-dns.bolt.hostà jour CustomAppointmentBuilder pour utiliser la configuration
  - [x] 3.1 Modifier la signature de buildAppointment
    - Changer le paramètre `normalHoursThreshold` de type `double` à `Duration?`
    - Renommer le paramètre en `dailyThreshold` pour cohérence
    - Utiliser une valeur par défaut `const Duration(hours: 8, minutes: 18)` si null
    - _Requirements: 3.1, 3.3_

  - [x] 3.2 Modifier _hasExcessHours pour accepter le threshold
    - Ajouter un paramètre `Duration threshold` à la méthode
    - Utiliser ce paramètre au lieu de la constante codée en dur
    - Mettre à jour tous les appels à cette méthode pour passer le threshold
    - _Requirements: 3.1, 3.3_

  - [x] 3.3 Mettre à jour les appels dans _buildDetailedAppointment
    - Passer le `dailyThreshold` aux méthodes qui en ont besoin
    - Corriger les erreurs de compilation liées au nombre d'arguments
    - _Requirements: 3.1, 3.3_

- [x] 4. Mettre à jour les widgets de configuration
  - [x] 4.1 Modifier WeekendConfigurationWidget
    - Dans `initState`, charger la configuration avec `getConfiguration()`
    - Extraire `dailyWorkThreshold` de la configuration chargée
    - Mettre à jour `_dailyWorkThreshold` avec la valeur chargée
    - Dans `_saveConfiguration`, sauvegarder `_dailyWorkThreshold.inMinutes`
    - _Requirements: 4.1, 4.2_

  - [x] 4.2 Modifier OvertimeConfigurationWidget
    - Dans `initState`, charger la configuration avec `getConfiguration()`
    - Extraire `dailyWorkThreshold` de la configuration chargée
    - Mettre à jour `_dailyWorkThreshold` avec la valeur chargée
    - Dans `_saveConfiguration`, sauvegarder `_dailyWorkThreshold.inMinutes`
    - _Requirements: 4.1, 4.2_

- [x] 5. Mettre à jour les widgets de calendrier pour charger la configuration
  - [x] 5.1 Identifier le widget parent qui utilise CustomAppointmentBuilder
    - Trouver où `appointmentBuilder` est défini dans le code
    - Identifier le widget qui contient le `SfCalendar`
    - _Requirements: 3.1, 3.2_

  - [x] 5.2 Ajouter le chargement de configuration au widget parent
    - Ajouter une variable d'état `Duration? _dailyThreshold`
    - Injecter `OvertimeConfigurationRepository` via le contexte ou DI
    - Dans `initState`, charger la configuration et extraire le threshold
    - Passer `dailyThreshold: _dailyThreshold` à `CustomAppointmentBuilder.buildAppointment`
    - _Requirements: 3.1, 3.2, 3.3_

- [x] 6. Ajouter la gestion d'erreurs pour le chargement de configuration
  - [x] 6.1 Ajouter try-catch dans les use cases
    - Entourer le chargement de configuration d'un try-catch
    - En cas d'erreur, utiliser la valeur par défaut `Duration(hours: 8, minutes: 18)`
    - Logger l'erreur pour le débogage
    - _Requirements: 2.2_

  - [x] 6.2 Ajouter try-catch dans les widgets
    - Entourer le chargement de configuration d'un try-catch
    - En cas d'erreur, utiliser la valeur par défaut
    - Afficher un message d'erreur à l'utilisateur si approprié
    - _Requirements: 4.1, 4.2_

- [ ] 7. Mettre à jour les tests existants
  - [ ]* 7.1 Mettre à jour les tests de WeekendOvertimeCalculator
    - Ajouter des tests avec différents `dailyThreshold` (7h, 8h, 8h18, 9h)
    - Vérifier que les calculs sont corrects pour chaque threshold
    - Tester le comportement par défaut quand `dailyThreshold` est null
    - _Requirements: 1.1, 5.1_

  - [ ]* 7.2 Mettre à jour les tests de MonthlyOvertimeCalculator
    - Vérifier que les tests existants passent toujours
    - Ajouter des tests avec différents thresholds si nécessaire
    - _Requirements: 1.1, 5.2_

  - [ ]* 7.3 Mettre à jour les tests des use cases
    - Mocker `OvertimeConfigurationRepository`
    - Configurer le mock pour retourner une configuration de test
    - Vérifier que les use cases passent le threshold aux calculateurs
    - _Requirements: 1.1, 1.2, 2.1_

  - [ ]* 7.4 Mettre à jour les tests des widgets
    - Mocker le chargement de configuration
    - Tester que les widgets chargent la configuration au démarrage
    - Tester que les widgets sauvegardent correctement les modifications
    - _Requirements: 4.1, 4.2_

- [ ] 8. Créer des tests d'intégration
  - [ ]* 8.1 Test end-to-end de modification du threshold
    - Créer un test qui modifie le threshold dans les paramètres
    - Vérifier que les calculs utilisent le nouveau threshold
    - Vérifier que les indicateurs visuels reflètent le nouveau threshold
    - _Requirements: 1.1, 1.2, 3.1, 3.2, 3.3_

  - [ ]* 8.2 Test de configuration par défaut
    - Créer un test simulant le premier lancement de l'app
    - Vérifier que la configuration par défaut est créée
    - Vérifier que le threshold par défaut (8h18) est utilisé
    - _Requirements: 2.1, 2.2_

- [x] 9. Vérifier et nettoyer le code
  - [x] 9.1 Rechercher toutes les occurrences de Duration(hours: 8, minutes: 18)
    - Utiliser grep pour trouver toutes les occurrences
    - Vérifier que chaque occurrence est soit remplacée soit justifiée (constante par défaut)
    - Documenter les constantes par défaut comme fallbacks
    - _Requirements: 2.3_

  - [x] 9.2 Vérifier la cohérence des noms de paramètres
    - S'assurer que tous les paramètres s'appellent `dailyThreshold`
    - Éviter les noms comme `normalHoursThreshold` ou `threshold`
    - Mettre à jour la documentation des méthodes
    - _Requirements: 2.1, 2.2_

  - [x] 9.3 Ajouter des commentaires de documentation
    - Documenter que les constantes par défaut sont des fallbacks
    - Expliquer que le threshold devrait être chargé depuis la configuration
    - Ajouter des exemples d'utilisation dans les commentaires
    - _Requirements: 2.1, 2.2_
