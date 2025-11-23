# 🚀 Démarrage Rapide - Agent IA de Validation

## ⚡ En 5 minutes

### 1. Installation des dépendances (2 min)

```bash
# Backend
cd time_sheet_backend_server
dart pub get

# Flutter
cd ../time_sheet_backend_flutter
flutter pub get
```

### 2. Configuration OpenAI (1 min)

Créez `time_sheet_backend_server/config/passwords.yaml` :

```yaml
development:
  openaiApiKey: 'sk-VOTRE_CLE_API_ICI'
```

🔑 **Obtenir une clé API** : https://platform.openai.com/api-keys

### 3. Génération du code Serverpod (1 min)

```bash
cd time_sheet_backend_server
serverpod generate
serverpod create-migration
```

### 4. Démarrer le serveur (30 sec)

```bash
cd time_sheet_backend_server
dart run bin/main.dart
```

✅ Le serveur démarre sur `http://localhost:8080`

### 5. Intégration dans Flutter (30 sec)

Dans votre écran de timesheet, ajoutez :

```dart
import 'package:time_sheet/services/ai_validation_service.dart';
import 'package:time_sheet/features/validation/presentation/widgets/ai_validation_button.dart';

// Dans votre widget
final aiService = AiValidationService(client);

// Ajoutez le bouton
AiValidationButton(
  entryId: entry.id,
  date: entry.dayDate,
  startMorning: entry.startMorning,
  endMorning: entry.endMorning,
  startAfternoon: entry.startAfternoon,
  endAfternoon: entry.endAfternoon,
  aiService: aiService,
)
```

## 🎯 Utilisation

### Validation rapide
**Appui long** sur le bouton → Validation en 2 secondes avec snackbar

### Analyse détaillée
**Appui simple** sur le bouton → Page complète avec anomalies et suggestions

## 🎨 Personnalisation

### Bouton compact (pour les listes)

```dart
AiValidationButton(
  // ... paramètres
  compact: true,  // Mode icône uniquement
)
```

### Callback après validation

```dart
AiValidationButton(
  // ... paramètres
  onValidationComplete: () {
    print('Validation terminée !');
    // Rafraîchir la liste, etc.
  },
)
```

## 📊 Exemples de résultats

### ✅ Validation réussie (Score: 100/100)
```
✓ Aucune anomalie détectée
✓ Horaires conformes
✓ Pause adéquate
```

### ⚠️ Corrections nécessaires (Score: 75/100)
```
⚠ Heures insuffisantes: 7h45 au lieu de 8h18
💡 Suggestion: Terminez à 17:51 au lieu de 17:18
```

### ❌ Anomalies critiques (Score: 45/100)
```
❌ Heures excessives: 12h30 de travail
❌ Pause insuffisante: 20 minutes
💡 Suggestion: Ajoutez 10 minutes de pause
💡 Suggestion: Vérifiez la conformité légale
```

## 🔧 Dépannage Express

### Erreur "API Key not found"
→ Vérifiez `config/passwords.yaml` et redémarrez le serveur

### Erreur "Connection refused"
→ Le serveur Serverpod n'est pas démarré

### Timeout
→ Première requête OpenAI peut être lente (cold start)

## 💰 Coûts

- **1 validation** = ~$0.0004 (0.04 centime)
- **100 validations/jour** = ~$1.20/mois
- **1000 validations/jour** = ~$12/mois

## 🎉 C'est tout !

Votre agent IA est maintenant opérationnel. Pour plus de détails, consultez `AI_VALIDATION_SETUP.md`.

---

### 🆘 Besoin d'aide ?

1. Vérifiez les logs du serveur : `tail -f time_sheet_backend_server/server.log`
2. Activez le mode debug Flutter
3. Consultez la documentation complète

### 📚 Prochaines étapes

- [ ] Personnaliser les règles de détection
- [ ] Ajouter des règles métier spécifiques
- [ ] Configurer le monitoring
- [ ] Déployer en production
