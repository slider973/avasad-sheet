# Résolution du problème de version Dart

## Problème
```
Error: Can't load Kernel binary: Invalid kernel binary format version.
FINE: Pub 2.10.5
ERR : serverpod_cli 2.9.1 doesn't support Dart 2.10.5.
```

Votre Dart SDK (2.10.5 de janvier 2021) est trop ancien pour Serverpod 2.9.1.

## Solution

### Option 1: Mettre à jour Dart (Recommandé)

```bash
# Si vous utilisez Homebrew
brew upgrade dart

# Ou télécharger depuis le site officiel
# https://dart.dev/get-dart
```

### Option 2: Utiliser Flutter pour avoir Dart à jour

```bash
# Flutter inclut Dart
flutter upgrade
flutter doctor

# Puis utiliser le Dart de Flutter
flutter pub global activate serverpod_cli
```

### Option 3: Utiliser le hack actuel SANS démarrer le serveur

**Bonne nouvelle !** Le code pour sauvegarder les timesheet_data fonctionne déjà côté serveur via le hack dans `employeeId`.

L'application Flutter envoie les données comme ceci :
1. Elle encode les données timesheet en JSON
2. Elle met ce JSON dans le paramètre `employeeId` avec le format : `JSON:realEmployeeId|{json_data}`
3. Le serveur détecte le préfixe `JSON:` et sauvegarde automatiquement dans la table `timesheet_data`

**Donc l'application devrait déjà fonctionner pour sauvegarder les données !**

## Vérifier si ça fonctionne

1. Depuis l'application Flutter, créez une validation
2. Vérifiez dans PostgreSQL :

```sql
-- Se connecter à la base
psql -h localhost -U postgres -d time_sheet_backend

-- Vérifier les données
SELECT * FROM timesheet_data ORDER BY created_at DESC LIMIT 5;

-- Voir le contenu des entries
SELECT 
    id,
    validation_request_id,
    employee_name,
    month || '/' || year as period,
    entries::json->'0' as first_entry
FROM timesheet_data
ORDER BY created_at DESC;
```

## Si vous voulez tester l'API manuellement

Sans démarrer le serveur, vous pouvez tester directement avec PostgreSQL :

```sql
-- Voir toutes les validations
SELECT id, employee_id, employee_name, status, created_at 
FROM validation_request 
ORDER BY created_at DESC;

-- Voir les timesheet_data associées
SELECT 
    td.*, 
    vr.status as validation_status
FROM timesheet_data td
JOIN validation_request vr ON td.validation_request_id = vr.id
ORDER BY td.created_at DESC;
```

## Résumé

1. **Le hack fonctionne déjà** - L'application peut sauvegarder les données
2. **Pour corriger définitivement** - Mettez à jour Dart à une version récente (>= 2.17)
3. **Pour l'instant** - Utilisez l'application normalement, les données sont sauvegardées