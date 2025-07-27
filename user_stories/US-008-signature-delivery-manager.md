# User Story : Signature Électronique par le Delivery Manager

## User Story
**En tant que** delivery manager  
**Je veux** pouvoir recevoir et signer électroniquement les timesheets de mes collaborateurs  
**Afin de** valider leurs heures avant de les transmettre au responsable de service pour signature finale

## Contexte
Actuellement, le processus de validation des timesheets nécessite :
1. L'employé a sa signature stockée localement dans l'app (créée lors du onboarding)
2. Lors de la génération du PDF, la signature de l'employé est automatiquement apposée
3. L'employé envoie ce PDF pré-signé par email au delivery manager
4. Le delivery manager signe le PDF et l'envoie au responsable de service
5. Le responsable de service utilise un outil tiers pour la signature finale

**Objectif** : Simplifier les étapes 3 et 4 en permettant :
- À l'employé de partager facilement sa timesheet au delivery manager
- Au delivery manager de signer et de signaler d'éventuelles erreurs
- Le delivery manager transmettra ensuite au responsable de service (hors scope)

**Points importants** :
- Les données restent locales mais on peut utiliser Supabase/Firebase pour faciliter le partage
- Notifications push via Firebase pour alerter le delivery manager
- Le développement s'arrête après la signature du delivery manager

## Critères d'acceptation

### Scénario 1 : Soumission de timesheet pour validation (MVP - QR Code)
```gherkin
Given je suis un employé avec une timesheet complète stockée localement dans Isar
And ma signature (créée lors du onboarding) est stockée localement
And le PDF a été généré avec ma signature automatiquement apposée
When je clique sur "Partager pour validation" depuis la page PDF
Then l'app génère un QR code contenant le PDF pré-signé et les données de la timesheet
And je peux montrer ce QR code à mon delivery manager
And le QR code expire après 24h pour des raisons de sécurité
```

### Scénario 2 : Réception et validation via QR Code (Delivery Manager)
```gherkin
Given je suis un delivery manager avec l'app Time Sheet installée
And j'ai ma propre signature stockée localement (créée lors de mon onboarding)
When je scanne le QR code de mon collaborateur via l'app
Then la timesheet et le PDF pré-signé sont importés temporairement (sans écraser mes données)
And je peux visualiser le PDF avec la signature de l'employé déjà présente
And je peux ajouter MA signature stockée localement au PDF
And le PDF final contient les deux signatures (employé + manager)

```

### Scénario 3 : Signalement d'erreur par le Delivery Manager
```gherkin
Given je suis un delivery manager consultant une timesheet avec des erreurs
When je clique sur "Signaler une erreur"
Then je peux sélectionner les jours problématiques
And je peux ajouter un commentaire détaillé
And l'employé reçoit une notification push (via Firebase)
And la timesheet est marquée comme "À corriger" dans l'app de l'employé
```

### Scénario 4 : Transmission au responsable de service
```gherkin
Given le delivery manager a signé la timesheet
When il clique sur "Transmettre"
Then un PDF avec double signature est généré
And il peut l'exporter via les options natives (email, WhatsApp, etc.)
And le responsable de service recevra ce PDF pour signature finale (hors app)
```

### Scénario 5 : Solution avec Supabase/Firebase
```gherkin
Given l'entreprise a configuré une instance Supabase
When l'employé soumet sa timesheet pour validation
Then la timesheet est uploadée temporairement sur Supabase (chiffrée)
And le delivery manager reçoit une notification push via Firebase
And il peut télécharger et signer la timesheet dans son app
And après signature, le PDF est disponible sur Supabase pour le responsable
And les données sont supprimées automatiquement après 30 jours
```

### Scénario 6 : Gestion des profils multiples (Manager)
```gherkin
Given je suis un delivery manager validant plusieurs timesheets
When j'active le "Mode Manager" dans les paramètres
Then l'app crée un espace séparé pour les validations
And mes propres pointages restent isolés des timesheets à valider
And je peux basculer entre "Mes pointages" et "Validations"
```

### Scénario 7 : Mode hors ligne avec synchronisation
```gherkin
Given je suis en mode hors ligne
When je valide une timesheet
Then la validation est stockée localement
And dès que la connexion revient, la synchronisation avec Supabase se fait
And les notifications Firebase sont envoyées automatiquement
And le mode offline-first garantit qu'aucune validation n'est perdue
```

## Contraintes architecturales

### Stockage local
- **Important** : Toutes les données de pointage sont stockées localement sur le téléphone de l'employé (base Isar)
- Pas de serveur centralisé pour stocker les timesheets
- Chaque employé a ses propres données isolées sur son appareil

### Solutions proposées

### Solution 1 : MVP Sans Backend (Court terme)
- **Partage par QR Code** : Timesheet chiffrée dans le QR code
- **Import/Export de fichiers** : Format .timesheet sécurisé
- **Pas de serveur nécessaire** : Tout reste local
- **Inconvénient** : Notifications manuelles, partage limité

### Solution 2 : Avec Supabase + Firebase (Recommandée)
- **Supabase** : 
  - Stockage temporaire des timesheets à valider
  - Base de données pour les relations employé/manager
  - Authentification des utilisateurs
  - API REST automatique
- **Firebase** :
  - Notifications push pour alerter le delivery manager
  - Analytics pour suivre l'usage
- **Avantages** :
  - Notifications automatiques
  - Partage simplifié
  - Historique des validations
  - Fonctionne offline avec sync
- **Sécurité** :
  - Chiffrement des données
  - Suppression automatique après 30 jours
  - RLS (Row Level Security) sur Supabase

### Flux recommandé avec Supabase/Firebase
1. L'employé soumet sa timesheet → Upload chiffré sur Supabase
2. Notification push au delivery manager via Firebase
3. Le manager télécharge, signe et upload le PDF signé
4. Le PDF est disponible pour le responsable de service
5. Suppression automatique après traitement

## Notes techniques
- L'architecture actuelle avec Isar (base locale) doit être respectée
- Les signatures sont stockées localement lors du onboarding (employé et manager)
- Le PDF est signé automatiquement par l'employé lors de la génération
- Le manager ajoute sa signature au PDF déjà signé (double signature)
- Pas de migration forcée vers une architecture serveur
- Les solutions doivent fonctionner en mode offline
- Compatibilité avec l'architecture Flutter existante
- Utilisation des capacités natives (partage iOS/Android)
- Format de stockage des signatures compatible avec le package 'signature' existant

## Valeur / Effort / Priorité
- **Valeur Business** : Très Élevée - Élimine un point de friction majeur dans le processus
- **Effort** : 
  - Solution 1 (Sans backend) : M (Medium) - 5-7 jours
  - Solution 2 (Avec Supabase/Firebase) : L (Large) - 10-15 jours
- **Priorité** : Must Have - Problème critique soulevé par les utilisateurs
- **Recommandation** : Commencer par la solution 2 pour une meilleure expérience utilisateur

## Dépendances
- Module de génération PDF (existant)
- Module de signature électronique (existant)
- Package QR code pour Flutter
- Supabase Flutter SDK (si solution 2)
- Firebase SDK pour notifications (si solution 2)
- Configuration des services cloud (Supabase + Firebase)

## Risques et Mitigation
- **Coût des services cloud** : Supabase et Firebase ont des plans gratuits généreux
- **Complexité d'implémentation** : Documentation claire et exemples fournis
- **Sécurité des données** : Chiffrement et suppression automatique
- **Adoption par les managers** : Interface simple et notifications automatiques

## Périmètre de développement
- ✅ Partage facile de la timesheet employé → delivery manager
- ✅ Signature du delivery manager
- ✅ Signalement d'erreurs avec notifications
- ✅ Export du PDF doublement signé
- ❌ Signature du responsable de service (hors scope - outil tiers)
- ❌ Workflow complet de validation (future évolution)