# Guide API Timesheet

## Problème actuel avec Serverpod

Le serveur ne peut pas démarrer à cause d'une incompatibilité avec Dart 2.10.5. 

## Solutions disponibles

### 1. Mettre à jour Dart

```bash
# Installer une version plus récente de Dart
brew upgrade dart
# ou
dart upgrade
```

### 2. Utiliser le test direct

```bash
cd /Users/jonathanlemaine/StudioProjects/time_sheet/time_sheet_backend
dart test_timesheet_direct.dart
```

### 3. Tester avec PostgreSQL directement

```bash
psql -h localhost -U postgres -d time_sheet_backend
```

Puis exécuter le script SQL :
```sql
\i bruno_collection/database/test_timesheet_data.sql
```

## Architecture de l'API

### Endpoint unique professionnel

`POST /timesheet/processTimesheet`

Ce endpoint gère toutes les opérations timesheet via un paramètre `action` :

#### Actions disponibles

1. **save** - Créer ou mettre à jour des données
   - Vérifie si les données existent déjà (par validationRequestId)
   - Met à jour si existe, crée sinon
   - Retourne l'ID et les métadonnées

2. **get** - Récupérer des données
   - Recherche par validationRequestId
   - Retourne toutes les données incluant les entries décodées

3. **update** - Mise à jour partielle
   - Mise à jour par ID
   - Seuls les champs fournis sont mis à jour

4. **generatePdf** - Générer un PDF (TODO)
   - Accepte les signatures en base64
   - Retournera le PDF généré

### Structure de la table timesheet_data

```sql
CREATE TABLE timesheet_data (
    id SERIAL PRIMARY KEY,
    validation_request_id INTEGER NOT NULL UNIQUE,
    employee_id VARCHAR(255) NOT NULL,
    employee_name VARCHAR(255) NOT NULL,
    employee_company VARCHAR(255),
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    entries TEXT NOT NULL,  -- JSON stocké comme texte
    total_days DOUBLE PRECISION NOT NULL,
    total_hours VARCHAR(50) NOT NULL,
    total_overtime_hours VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Format des données entries

Les entries sont stockées en JSON :

```json
[
  {
    "dayDate": "21-Jun-24",
    "startMorning": "08:00",
    "endMorning": "12:00",
    "startAfternoon": "13:00",
    "endAfternoon": "17:00",
    "isAbsence": false,
    "hasOvertimeHours": false
  }
]
```

## Utilisation avec Bruno

Les fichiers Bruno sont dans `/bruno_collection/timesheet/` :

1. `timesheet_api.bru` - Documentation complète + save
2. `get_timesheet.bru` - Récupération
3. `update_timesheet.bru` - Mise à jour
4. `generate_pdf.bru` - Génération PDF

## Points clés de l'implémentation

1. **Pattern Command** : Une seule méthode `processTimesheet` qui route vers des méthodes privées
2. **Gestion d'erreurs** : Try-catch à tous les niveaux avec logs détaillés
3. **Validation** : Vérification des paramètres requis
4. **Idempotence** : Les sauvegardes sont idempotentes (UPSERT)
5. **Format uniforme** : Toutes les réponses suivent le format `{success, data, error, message}`

## Pourquoi cette architecture ?

1. **Simplicité** : Un seul endpoint à documenter et maintenir
2. **Extensibilité** : Facile d'ajouter de nouvelles actions
3. **Cohérence** : Format de requête/réponse uniforme
4. **Performance** : Réutilisation de la connexion DB
5. **Sécurité** : Validation centralisée
6. **Maintenabilité** : Code organisé et modulaire

## Prochaines étapes

1. Mettre à jour Dart pour faire fonctionner Serverpod
2. Implémenter la génération PDF côté serveur
3. Ajouter des tests unitaires
4. Documenter l'API avec OpenAPI/Swagger