# Prompt d'implémentation - Système de Validation Manager

Tu es un **Dev Flutter Senior** avec 10 ans d'expérience sur le projet time_sheet. Tu vas implémenter le système de validation des timesheets par le Delivery Manager en suivant la proposition technique détaillée.

## Contexte de la proposition

### Architecture globale
- **Frontend Flutter** : Application mobile existante avec Isar pour le stockage local
- **Backend Supabase** : PostgreSQL avec RLS pour le stockage temporaire des validations
- **Firebase** : Cloud Messaging pour les notifications push
- **Sécurité** : Chiffrement AES-256-GCM pour tous les PDFs

### Documents de référence
La proposition technique complète se trouve dans `/proposals/validation-manager-signature/` avec :
- Architecture technique détaillée
- Structure de base de données Supabase
- Configuration Firebase
- Exemples de code Flutter
- Stratégie de sécurité et chiffrement

## Mission

Implémenter le système de validation en suivant ces phases :

### Phase 1 : Infrastructure (2.5 jours)
1. **Configuration Supabase**
   - Créer le projet Supabase
   - Implémenter les tables selon `/proposals/validation-manager-signature/03-structure-database.md`
   - Configurer les Row Level Security policies
   - Créer les buckets de storage pour les PDFs

2. **Configuration Firebase**
   - Configurer Firebase Cloud Messaging
   - Implémenter les Cloud Functions selon `/proposals/validation-manager-signature/04-configuration-firebase.md`
   - Configurer les topics de notification

3. **Services de base**
   - Implémenter `EncryptionService` avec AES-256-GCM
   - Créer `SupabaseService` pour l'authentification
   - Implémenter `FirebaseService` pour les notifications

### Phase 2 : Backend (3 jours)
1. **Repository Pattern**
   - Créer `ValidationRepository` avec interface et implémentation
   - Implémenter les méthodes CRUD pour les validations
   - Ajouter la gestion du cache local avec Isar

2. **Use Cases**
   - `SubmitValidationUseCase` : Soumettre une timesheet pour validation
   - `ValidateTimesheetUseCase` : Valider et signer une timesheet
   - `SendFeedbackUseCase` : Envoyer des commentaires/erreurs

3. **Services métier**
   - Service de génération PDF avec double signature
   - Service de synchronisation offline
   - Service de gestion des notifications

### Phase 3 : Frontend (5 jours)
1. **BLoCs**
   - `ValidationBloc` pour la gestion des états de validation
   - `ManagerValidationBloc` pour les actions manager
   - Intégration avec les BLoCs existants

2. **Pages principales**
   - `SubmitValidationPage` : Interface de soumission employé
   - `ManagerValidationPage` : Interface de validation manager
   - `ValidationDetailsPage` : Détails et historique

3. **Widgets réutilisables**
   - `ValidationCard` : Carte d'affichage des validations
   - `SignaturePadWidget` : Zone de signature réutilisable
   - `FeedbackForm` : Formulaire de feedback manager

### Phase 4 : Intégration (2.5 jours)
1. **Synchronisation offline**
   - Queue de synchronisation avec retry automatique
   - Gestion des conflits de données
   - Cache local avec Isar

2. **Tests**
   - Tests unitaires (coverage > 80%)
   - Tests d'intégration
   - Tests de sécurité

## Structure de code attendue

```
lib/features/validation/
├── domain/
│   ├── entities/
│   │   ├── validation.dart
│   │   ├── validation_feedback.dart
│   │   └── manager_assignment.dart
│   ├── repositories/
│   │   └── validation_repository.dart
│   └── use_cases/
│       ├── submit_validation_usecase.dart
│       ├── validate_timesheet_usecase.dart
│       └── send_feedback_usecase.dart
├── data/
│   ├── models/
│   │   ├── validation_model.dart
│   │   └── feedback_model.dart
│   ├── datasources/
│   │   ├── validation_remote_datasource.dart
│   │   └── validation_local_datasource.dart
│   └── repositories/
│       └── validation_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── validation_bloc.dart
    │   └── manager_validation_bloc.dart
    ├── pages/
    │   ├── submit_validation_page.dart
    │   ├── manager_validation_page.dart
    │   └── validation_details_page.dart
    └── widgets/
        ├── validation_card.dart
        ├── signature_pad_widget.dart
        └── feedback_form.dart
```

## Contraintes techniques

1. **Architecture existante**
   - Respecter l'architecture Clean Architecture existante
   - Utiliser GetIt pour l'injection de dépendances
   - Conserver Isar comme base de données principale

2. **Sécurité**
   - Implémenter le chiffrement selon `/proposals/validation-manager-signature/05-securite-chiffrement.md`
   - Certificate pinning pour toutes les connexions
   - Validation des entrées utilisateur

3. **Performance**
   - Upload PDF < 2 secondes
   - Notifications < 5 secondes
   - Support offline complet

4. **Compatibilité**
   - iOS 12+ et Android 6+
   - Support des tablettes
   - Mode portrait et paysage

## Livrables attendus

Pour chaque phase, fournir :
1. **Code source** complet et documenté
2. **Tests** unitaires et d'intégration
3. **Documentation** technique
4. **Scripts** de configuration (Supabase, Firebase)

## Ordre d'implémentation recommandé

1. Commencer par les services de base (chiffrement, auth)
2. Implémenter le repository et les use cases
3. Créer les interfaces utilisateur
4. Ajouter la synchronisation offline
5. Finaliser avec les tests et la documentation

## Notes importantes

- Utiliser les exemples de code de `/proposals/validation-manager-signature/06-implementation-flutter.md`
- Suivre les patterns de sécurité définis dans la proposition
- Respecter le planning de `/proposals/validation-manager-signature/08-planning-estimations.md`
- Consulter régulièrement la user story `/user_stories/US-008-signature-delivery-manager.md`

## Commandes utiles

```bash
# Générer les modèles Isar
flutter packages pub run build_runner build --delete-conflicting-outputs

# Lancer les tests
flutter test

# Vérifier la couverture
flutter test --coverage

# Analyser le code
flutter analyze
```

---

**Important** : Toujours se référer aux documents de la proposition dans `/proposals/validation-manager-signature/` pour les détails d'implémentation. Chaque fichier contient des exemples de code et des spécifications précises à suivre.