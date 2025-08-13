# Timesheet API - Guide d'utilisation

## Problème actuel
Le serveur Serverpod ne peut pas démarrer à cause d'une incompatibilité avec Dart 2.10.5.

## Solution temporaire
Utilisez Bruno ou cURL pour tester l'API directement.

## Endpoint unique : processTimesheet

URL: `http://localhost:8080/timesheet/processTimesheet`

### Architecture professionnelle
- Un seul endpoint qui gère toutes les opérations via un paramètre `action`
- Pattern Command pour une architecture extensible
- Réponses standardisées avec `success`, `data`, `error`, `message`
- Gestion d'erreurs centralisée
- Logs détaillés côté serveur

### Actions disponibles

#### 1. Sauvegarder des données (CREATE/UPDATE)
```json
{
  "action": "save",
  "data": {
    "validationRequestId": 1,
    "employeeId": "john_doe",
    "employeeName": "John Doe",
    "employeeCompany": "Avasad",
    "month": 7,
    "year": 2024,
    "entries": [...],
    "totalDays": 20.0,
    "totalHours": "160:00",
    "totalOvertimeHours": "0:00"
  }
}
```

#### 2. Récupérer des données (READ)
```json
{
  "action": "get",
  "data": {
    "validationRequestId": 1
  }
}
```

#### 3. Mettre à jour partiellement (UPDATE)
```json
{
  "action": "update",
  "data": {
    "id": 1,
    "totalHours": "168:00",
    "totalOvertimeHours": "8:00"
  }
}
```

#### 4. Générer un PDF
```json
{
  "action": "generatePdf",
  "data": {
    "validationRequestId": 1,
    "employeeSignature": "base64_signature",
    "managerSignature": "base64_signature",
    "managerName": "Jane Smith"
  }
}
```

## Structure de réponse

### Succès
```json
{
  "success": true,
  "data": {...},
  "message": "Opération réussie"
}
```

### Erreur
```json
{
  "success": false,
  "error": "Description de l'erreur"
}
```

## Avantages de cette approche

1. **Simplicité** : Un seul endpoint à maintenir
2. **Flexibilité** : Facile d'ajouter de nouvelles actions
3. **Cohérence** : Format de requête/réponse uniforme
4. **Sécurité** : Validation centralisée des paramètres
5. **Performance** : Réutilisation de la session de base de données
6. **Maintenabilité** : Code organisé avec des méthodes privées

## Test avec cURL

```bash
# Sauvegarder des données
curl -X POST http://localhost:8080/timesheet/processTimesheet \
  -H "Content-Type: application/json" \
  -d '{
    "action": "save",
    "data": {
      "validationRequestId": 1,
      "employeeId": "john_doe",
      "employeeName": "John Doe",
      "employeeCompany": "Avasad",
      "month": 7,
      "year": 2024,
      "entries": [],
      "totalDays": 20.0,
      "totalHours": "160:00",
      "totalOvertimeHours": "0:00"
    }
  }'
```

## Notes pour le développeur

1. Les données `entries` sont stockées en JSON dans la base de données
2. La mise à jour vérifie l'existence des données avant de créer
3. Les champs optionnels ont des valeurs par défaut sensées
4. Tous les erreurs sont loggées côté serveur
5. L'endpoint est conçu pour être facilement étendu