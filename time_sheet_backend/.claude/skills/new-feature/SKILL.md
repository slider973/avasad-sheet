---
name: new-feature
description: >
  Scaffolder une nouvelle feature Flutter selon les conventions du projet
  (Clean Architecture + BLoC + GetIt + fpdart). Utiliser quand l'utilisateur
  demande d'ajouter une feature, un écran avec logique métier, ou un nouveau
  module dans l'app.
---

# Nouvelle feature — conventions du projet

Structure cible dans `time_sheet_backend_flutter/lib/features/<ma_feature>/` :

```
ma_feature/
├── domain/
│   ├── entities/            # Entités pures (aucun import data/PowerSync/Supabase)
│   ├── repositories/        # Interfaces abstraites
│   └── use_cases/           # 1 classe = 1 responsabilité, execute() -> Either<Failure, T>
├── data/
│   ├── models/              # Mapping SQL row <-> entité
│   ├── data_sources/        # SQL sur PowerSync local (db.getAll / execute / watch)
│   └── repositories/        # Implémentations des interfaces domain
└── presentation/
    ├── bloc/                # <feature>_bloc/event/state.dart
    ├── pages/
    └── widgets/
```

## Règles non négociables

1. **Domain n'importe jamais** `powersync`, `supabase_flutter`, ni rien de `data/`. C'est la règle la plus violée en review — vérifier les imports à la fin.
2. **Erreurs via fpdart** : tout use case retourne `Future<Either<Failure, T>>` (`Failure` de `lib/core/error/`). Pas d'exception métier qui traverse les couches, pas de `throw` dans les repositories.
3. **Pas de `print`** : utiliser le logger du projet.
4. **BLoC** : la page ne parle qu'au BLoC ; le BLoC n'appelle que des use cases (jamais un repository directement).
5. Prendre `lib/features/expense/` comme modèle de référence (feature complète et récente).

## Enregistrement (obligatoire, souvent oublié)

- `lib/services/injection_container.dart` : data source, repository (lazy singletons), use cases (singletons), BLoC (**factory** — nouvelle instance par widget).
- `lib/services/service_factory.dart` : seulement si le BLoC doit être global (MultiBlocProvider).
- Navigation : `lib/features/bottom_nav_tab/` si la feature a son propre onglet (attention au rôle : employee 5 onglets, manager/admin 6).

## Si la feature a besoin d'une nouvelle table

Suivre le skill `db-migration` (migration SQL → RLS → sync rules PowerSync → `schema.dart` → data source) AVANT d'écrire la data source.

## Données temps réel

Pour une liste qui doit se rafraîchir automatiquement (notifications, validations en attente…) : `db.watch(...)` dans la data source, exposé en `Stream` jusqu'au BLoC (`emit.forEach` / subscription annulée dans `close()`).

## Finir proprement

1. `flutter analyze` sans nouveau warning.
2. Tests unitaires des use cases (mock du repository) dans `test/features/<ma_feature>/` — suivre les patterns existants de `test/`.
3. Vérifier les imports domain (règle 1) avant de conclure.
