# 🤖 Configuration de l'Agent IA de Validation

## Vue d'ensemble

L'agent IA de validation utilise **Serverpod** comme backend et **OpenAI GPT-4** pour analyser intelligemment les feuilles de temps. Il détecte automatiquement les anomalies, suggère des corrections et valide la conformité.

## 🎯 Fonctionnalités

### Détection d'anomalies
- ✅ Heures insuffisantes (< 8h18)
- ✅ Heures excessives (> 10h)
- ✅ Pause déjeuner trop courte (< 30 min)
- ✅ Pause déjeuner trop longue (> 2h)
- ✅ Début de journée très tôt (< 6h)
- ✅ Fin de journée très tard (> 20h)
- ✅ Format invalide des horaires

### Suggestions intelligentes
- 💡 Ajustement automatique des horaires
- 💡 Optimisation de la pause déjeuner
- 💡 Détection de patterns hebdomadaires
- 💡 Recommandations personnalisées

### Score de validation
- 📊 Score global de 0 à 100
- 📊 Niveau de confiance de l'IA
- 📊 Statistiques détaillées

## 📦 Installation

### 1. Backend Serverpod

#### Installer les dépendances

```bash
cd time_sheet_backend_server
dart pub get
```

#### Configurer la clé API OpenAI

Ajoutez votre clé API OpenAI dans le fichier de configuration :

**`config/passwords.yaml`** (créez-le si nécessaire) :
```yaml
development:
  openaiApiKey: 'sk-votre-cle-api-openai'
  
production:
  openaiApiKey: 'sk-votre-cle-api-openai-production'
```

⚠️ **Important** : Ajoutez `config/passwords.yaml` à votre `.gitignore` !

#### Générer le code Serverpod

```bash
cd time_sheet_backend_server
serverpod generate
```

Cela va générer :
- Les modèles de protocole (AiAnomalyDetection, AiSuggestion, AiValidationResult)
- Les endpoints côté client
- Les migrations de base de données

#### Créer les tables dans la base de données

```bash
cd time_sheet_backend_server
serverpod create-migration
serverpod migrate
```

#### Démarrer le serveur

```bash
cd time_sheet_backend_server
dart run bin/main.dart
```

Le serveur démarre sur `http://localhost:8080`

### 2. Application Flutter

#### Régénérer le client Serverpod

```bash
cd time_sheet_backend_flutter
flutter pub get
```

#### Utiliser l'agent IA dans votre code

```dart
import 'package:time_sheet/services/ai_validation_service.dart';
import 'package:time_sheet/features/validation/presentation/pages/ai_validation_page.dart';

// Initialiser le service
final aiService = AiValidationService(client);

// Naviguer vers la page de validation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AiValidationPage(
      entryId: entry.id,
      date: entry.dayDate,
      startMorning: entry.startMorning,
      endMorning: entry.endMorning,
      startAfternoon: entry.startAfternoon,
      endAfternoon: entry.endAfternoon,
      notes: entry.notes,
      aiService: aiService,
    ),
  ),
);
```

## 🎨 Interface Utilisateur

### Composants disponibles

#### 1. **AiValidationCard**
Card principale affichant le résultat de validation avec :
- Score global animé
- Gradient de couleur selon le score
- Statistiques (anomalies, suggestions, temps de traitement)
- Bouton pour voir les détails

#### 2. **AiAnomalyList**
Liste animée des anomalies avec :
- Badge de sévérité (critique, élevée, moyenne, faible)
- Description détaillée
- Suggestion de l'IA
- Niveau de confiance
- Actions (résoudre, voir détails)

#### 3. **AiSuggestionList**
Liste animée des suggestions avec :
- Type de suggestion (correction, pause, optimisation)
- Valeur suggérée
- Raisonnement de l'IA
- Badge de confiance
- Actions (appliquer, ignorer)

#### 4. **AiValidationPage**
Page complète avec :
- État de chargement animé
- Gestion d'erreurs
- Onglets (Anomalies / Suggestions)
- Pull-to-refresh
- Modales de détails

## 🔧 Configuration avancée

### Personnaliser les règles de détection

Éditez `ai_timesheet_analyzer_service.dart` :

```dart
// Ajouter une nouvelle règle
if (totalMinutes > 720) {  // Plus de 12h
  anomalies.add(AiAnomalyDetection(
    // ...
    anomalyType: 'extreme_overtime',
    severity: 'critical',
    // ...
  ));
}
```

### Changer le modèle OpenAI

Dans `ai_timesheet_analyzer_service.dart` :

```dart
final chatCompletion = await OpenAI.instance.chat.create(
  model: 'gpt-4o',  // ou 'gpt-4-turbo', 'gpt-3.5-turbo'
  // ...
);
```

### Ajuster le seuil de confiance

```dart
static const double _minConfidenceThreshold = 0.7;  // 70%
```

### Personnaliser le prompt IA

Modifiez la méthode `_buildAnalysisPrompt()` pour adapter le contexte envoyé à l'IA.

## 📊 API Endpoints

### Valider une entrée

```dart
final result = await client.aiValidation.validateTimesheetEntry(
  entryId: 123,
  date: DateTime.now(),
  startMorning: '08:00',
  endMorning: '12:00',
  startAfternoon: '13:00',
  endAfternoon: '17:18',
);
```

### Valider plusieurs entrées

```dart
final results = await client.aiValidation.validateMultipleEntries([
  {'id': 1, 'date': '2025-01-20', ...},
  {'id': 2, 'date': '2025-01-21', ...},
]);
```

### Récupérer les anomalies non résolues

```dart
final anomalies = await client.aiValidation.getUnresolvedAnomalies(
  startDate: DateTime(2025, 1, 1),
  endDate: DateTime(2025, 1, 31),
);
```

### Récupérer les suggestions

```dart
final suggestions = await client.aiValidation.getPendingSuggestions(
  entryId: 123,
);
```

### Résoudre une anomalie

```dart
final success = await client.aiValidation.resolveAnomaly(
  anomalyId,
  'userId',
);
```

### Appliquer une suggestion

```dart
final success = await client.aiValidation.applySuggestion(
  suggestionId,
  'accepted',  // ou 'rejected', 'modified'
);
```

### Statistiques

```dart
final stats = await client.aiValidation.getAnomalyStatistics(
  startDate: DateTime(2025, 1, 1),
  endDate: DateTime(2025, 1, 31),
);
// Retourne: { total, bySeverity, byType, averageConfidence }
```

## 🎯 Exemples d'utilisation

### Validation automatique avant soumission

```dart
Future<bool> validateBeforeSubmit(TimeSheetEntry entry) async {
  final result = await aiService.validateEntry(
    entryId: entry.id,
    date: entry.date,
    startMorning: entry.startMorning,
    endMorning: entry.endMorning,
    startAfternoon: entry.startAfternoon,
    endAfternoon: entry.endAfternoon,
  );
  
  if (!result.isValid) {
    // Afficher les anomalies à l'utilisateur
    showValidationDialog(result);
    return false;
  }
  
  return true;
}
```

### Validation en temps réel

```dart
TextFormField(
  onChanged: (value) async {
    // Débounce pour éviter trop d'appels
    _debouncer.run(() async {
      final result = await aiService.validateEntry(...);
      setState(() {
        _validationResult = result;
      });
    });
  },
)
```

### Dashboard d'anomalies

```dart
class AnomalyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AiAnomalyDetection>>(
      future: aiService.getUnresolvedAnomalies(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return AiAnomalyList(
            anomalies: snapshot.data!,
            onResolve: (anomaly) => _resolveAnomaly(anomaly),
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## 🚀 Déploiement

### Variables d'environnement

Pour la production, configurez :

```bash
export OPENAI_API_KEY="sk-votre-cle-production"
```

### Docker

Le serveur Serverpod inclut déjà un `Dockerfile`. Ajoutez la clé API :

```dockerfile
ENV OPENAI_API_KEY="sk-votre-cle"
```

### Monitoring

Les logs incluent :
- Temps de traitement de chaque validation
- Erreurs d'API OpenAI
- Statistiques d'utilisation

## 💰 Coûts OpenAI

### Estimation

- **GPT-4o-mini** : ~$0.15 / 1M tokens d'entrée, ~$0.60 / 1M tokens de sortie
- Une validation = ~500 tokens = **$0.0004** (~0.04 centime)
- 1000 validations/jour = **$0.40/jour** = **$12/mois**

### Optimisation

1. Utilisez `gpt-4o-mini` pour les validations simples
2. Cachez les résultats pour les entrées identiques
3. Limitez les appels avec un debounce
4. Utilisez la validation par règles quand possible

## 🔒 Sécurité

- ✅ Clé API stockée côté serveur uniquement
- ✅ Pas d'exposition de la clé au client
- ✅ Validation des entrées utilisateur
- ✅ Rate limiting recommandé
- ✅ Logs d'audit des validations

## 🐛 Dépannage

### Erreur "API Key not found"

Vérifiez que `config/passwords.yaml` existe et contient la clé.

### Erreur "Model not found"

Vérifiez que vous avez accès au modèle GPT-4. Utilisez `gpt-3.5-turbo` en alternative.

### Timeout

Augmentez le timeout dans la configuration OpenAI :

```dart
OpenAI.requestsTimeOut = const Duration(seconds: 60);
```

### Trop d'anomalies détectées

Ajustez les seuils dans `_detectRuleBasedAnomalies()`.

## 📚 Ressources

- [Documentation Serverpod](https://docs.serverpod.dev/)
- [Documentation OpenAI](https://platform.openai.com/docs)
- [Flutter Animate](https://pub.dev/packages/flutter_animate)
- [Dart OpenAI](https://pub.dev/packages/dart_openai)

## 🎉 Prochaines étapes

1. ✅ Générer le code Serverpod
2. ✅ Créer les migrations de base de données
3. ✅ Configurer la clé API OpenAI
4. ✅ Tester la validation
5. ✅ Intégrer dans votre UI existante
6. ✅ Déployer en production

---

**Besoin d'aide ?** Consultez les logs du serveur ou activez le mode debug dans l'application Flutter.
