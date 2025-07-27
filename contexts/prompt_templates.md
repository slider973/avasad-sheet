# Prompt Templates (Flutter)

Ces modèles aident l’IA à générer du code cohérent, idiomatique et prêt pour la production dans l’application **time_sheet** (Flutter SDK >=3.1.2, Dart, Isar DB, Material Design).

---
## Instructions générales (valables pour chaque template)
1. Respecter les conventions décrites dans **technical_context.md** et **project_context.md**.
2. Utiliser **Dart** avec les conventions Flutter et Material Design.
3. Préférer les **StatelessWidget** et `async/await` pour les opérations asynchrones.
4. Documenter les API publiques via **DartDoc** succinct.
5. Limiter les dépendances tierces et mettre à jour **pubspec.yaml** si nécessaire.
6. Ne jamais exposer de secrets ni de valeurs sensibles.
7. Le code doit passer `flutter analyze && flutter test`.

---
## 1. Widget Flutter (Écran ou Composant)
```prompt
Vous générez un nouveau widget Flutter.
Input :
  • Nom du widget : {{WidgetName}}
  • Type : StatelessWidget | StatefulWidget
  • Description fonctionnelle : {{featureDescription}}
  • Props requises : {{props}}
Output :
  • Fichier `lib/features/{{feature}}/{{widget_name}}.dart` contenant le widget.
  • Widgets enfants éventuels dans le même dossier.
Guidelines :
  – Préférer StatelessWidget quand possible.
  – Utiliser Material Design components.
  – Implémenter la navigation avec Navigator.push ou GoRouter.
  – Styliser avec ThemeData et styles cohérents.
```

---
## 2. Service de données Isar
```prompt
Input :
  • Nom de l'entité : {{Entity}}
  • Opérations requises : create | read | update | delete
  • Champs de l'entité : {{fields}}
Output :
  • Fichier `lib/services/{{entity}}_service.dart` implémentant le service.
  • Modèle Isar dans `lib/models/{{entity}}.dart`.
  • Gestion des erreurs et validation des données.
```

---
## 3. Service utilitaire Flutter
```prompt
Input :
  • Service : {{serviceName}}
  • Fonctionnalités requises : {{features}}
Output :
  • Fichier `lib/services/{{service_name}}.dart` exportant des fonctions `async`.
  • Gestion des erreurs unifiée avec exceptions personnalisées.
  • Tests unitaires avec flutter_test.
```

---
## 4. Tests unitaires Flutter
```prompt
Input :
  • Fichier à tester : {{filePath}}
  • Cas critiques : {{cases}}
Output :
  • `test/{{basename}}_test.dart` utilisant `flutter_test`.
  • Mocks des services via `mockito` ou `mocktail`.
```

---
## 5. Tests d'intégration Flutter
```prompt
Input :
  • User Story : {{userStory}}
  • Widget de départ : {{startWidget}}
Output :
  • `integration_test/{{slug}}_test.dart` automatisant le scénario.
  • Utilisation de `flutter_driver` ou `integration_test`.
  • Sélecteurs `Key` dans les widgets si manquants.
```

---
## 6. Storybook Story (facultatif)
```prompt
Input :
  • Composant : {{ComponentName}}
  • Variantes : {{variants}}
Output :
  • `storybook/stories/{{ComponentName}}.stories.tsx` avec contrôles interactifs.
```

---
## 7. Documentation MDX
```prompt
Input :
  • Sujet : {{topic}}
  • Exemple d’usage : {{example}}
Output :
  • `docs/{{slug}}.mdx` structuré : ## Aperçu, ## Props, ## Exemples, ## Accessibilité.
```

---
## 8. Entrée de changelog
```prompt
Input :
  • Version : {{version}}
  • Type : feat | fix | perf | refactor | docs | chore
  • Description : {{description}}
Output :
  • Nouvelle entrée en tête de `CHANGELOG.md` (Conventional Commits).
```

---
### Utilisation
Fournissez les champs **Input**. L’IA renverra un patch contenant les fichiers **Output** complets.

---
_Dernière mise à jour : 2025-07-19_
