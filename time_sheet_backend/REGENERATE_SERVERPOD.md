# 🔧 Régénération du code Serverpod

## Problème actuel

Les nouveaux modèles IA (`ai_anomaly_detection.yaml`, `ai_suggestion.yaml`, `ai_validation_result.yaml`) ne sont pas encore générés.

## Solution : Régénérer le code

### Étape 1 : Installer les dépendances

```bash
cd time_sheet_backend_server
dart pub get
```

### Étape 2 : Générer le code Serverpod

```bash
serverpod generate
```

Cette commande va générer :
- `lib/src/generated/ai_anomaly_detection.dart`
- `lib/src/generated/ai_suggestion.dart`
- `lib/src/generated/ai_validation_result.dart`
- Les endpoints côté client dans `time_sheet_backend_client`

### Étape 3 : Créer les migrations de base de données

```bash
serverpod create-migration
```

Cela va créer une migration pour les nouvelles tables :
- `ai_anomaly_detections`
- `ai_suggestions`

### Étape 4 : Appliquer les migrations (optionnel pour dev)

Si vous voulez créer les tables immédiatement :

```bash
serverpod migrate
```

### Étape 5 : Mettre à jour le client Flutter

```bash
cd ../time_sheet_backend_flutter
flutter pub get
```

## Après la régénération

Une fois le code généré, vous pourrez :

1. **Décommenter les champs dans `timesheet_endpoint.dart`** :
```dart
'isWeekendDay': e.isWeekendDay,
'isWeekendOvertimeEnabled': e.isWeekendOvertimeEnabled,
'overtimeType': e.overtimeType,
```

2. **Utiliser l'agent IA** :
```dart
final result = await client.aiValidation.validateTimesheetEntry(...);
```

## Vérification

Après `serverpod generate`, vérifiez que ces fichiers existent :
- ✅ `lib/src/generated/ai_anomaly_detection.dart`
- ✅ `lib/src/generated/ai_suggestion.dart`
- ✅ `lib/src/generated/ai_validation_result.dart`
- ✅ `lib/src/generated/endpoints.dart` (mis à jour avec aiValidation)

## En cas d'erreur

Si `serverpod generate` échoue :

1. Vérifiez que les fichiers `.yaml` sont bien dans `lib/src/protocol/`
2. Vérifiez la syntaxe YAML (indentation, etc.)
3. Consultez les logs d'erreur

## Note importante

⚠️ **N'oubliez pas de configurer la clé OpenAI** dans `config/passwords.yaml` :

```yaml
development:
  openaiApiKey: 'sk-VOTRE_CLE_API'
```

---

**Prêt ?** Exécutez les commandes ci-dessus ! 🚀
