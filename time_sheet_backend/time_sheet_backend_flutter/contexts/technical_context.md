# Contexte Technique - time_sheet

## Stack Technologique
- **Framework**: Flutter (SDK >=3.1.2 <4.0.0)
- **Langage**: Dart
- **Base de données locale**: Isar (version ^3.1.0+1) pour le stockage local des données
- **Gestion d'état**: Provider/Riverpod ou setState selon les besoins
- **Architecture**: Modulaire avec séparation par features
- **UI**: Material Design avec thème personnalisé

## Contraintes Techniques
- **Plateformes Cibles**: Mobile (iOS & Android), Desktop (Windows, macOS, Linux), Web
- **Style de Code**: Suivre les conventions Dart/Flutter et les règles définies dans `analysis_options.yaml`
- **Performance**: Optimiser les animations du timer et la gestion mémoire
- **Dépendances**: Gérées via `pubspec.yaml`. Privilégier les packages officiels Flutter
- **Tests**: Couverture de tests unitaires et d'intégration requise
