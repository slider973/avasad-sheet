# Time Sheet Backend - Serverpod

## Structure du Projet

Ce projet utilise la structure standard de Serverpod avec 3 sous-projets :

```
time_sheet_backend/
├── time_sheet_backend_server/    # Serveur backend Serverpod
├── time_sheet_backend_client/    # Client généré automatiquement
└── time_sheet_backend_flutter/   # Application Flutter principale
```

### time_sheet_backend_server
Le serveur backend qui contient :
- Les modèles de données (protocol/)
- Les endpoints API
- La logique métier côté serveur

### time_sheet_backend_client
Le client Dart généré automatiquement par Serverpod. Il est utilisé par l'app Flutter pour communiquer avec le serveur.

### time_sheet_backend_flutter
L'application Flutter principale (Time Sheet pour HeyTalent) qui était auparavant à la racine du projet.

## Commandes Utiles

### Générer le code Serverpod
```bash
cd time_sheet_backend_server
serverpod generate
```

### Lancer le serveur
```bash
cd time_sheet_backend_server
dart bin/main.dart
```

### Lancer l'application Flutter
```bash
cd time_sheet_backend_flutter
flutter run
```

### Docker (PostgreSQL + Redis)
```bash
cd time_sheet_backend_server
docker-compose up -d
```

## Migration depuis Supabase

Ce projet est en cours de migration depuis Supabase vers Serverpod pour réduire les coûts d'hébergement. Voir `time_sheet_backend_flutter/SERVERPOD_MIGRATION_PLAN.md` pour plus de détails.