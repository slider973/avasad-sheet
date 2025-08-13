# Plan de Réorganisation du Projet

## Structure Actuelle
```
time_sheet/
├── lib/                    # App Flutter actuelle
├── android/
├── ios/
├── supabase/              # Ancienne config Supabase
└── time_sheet_backend/    # Nouveau backend Serverpod
```

## Structure Proposée
```
time_sheet/
├── time_sheet_backend/        # Backend Serverpod (déjà créé)
│   ├── time_sheet_backend_server/
│   ├── time_sheet_backend_client/
│   └── time_sheet_backend_flutter/
└── time_sheet_app/           # App Flutter (à déplacer)
    ├── lib/
    ├── android/
    ├── ios/
    └── ...
```

## Options :

### Option 1 : Garder la structure actuelle
- L'app Flutter reste à la racine
- Le backend Serverpod dans son sous-dossier
- Plus simple, moins de changements

### Option 2 : Réorganiser pour plus de clarté
- Créer `time_sheet_app/` pour l'app Flutter
- Déplacer tous les fichiers Flutter dedans
- Structure plus propre et organisée

## Recommandation
Je recommande l'**Option 1** pour l'instant car :
- Moins de risques de casser les configurations
- Plus rapide à implémenter
- On peut toujours réorganiser plus tard

## Prochaines Étapes
1. Générer le code Serverpod
2. Créer les endpoints
3. Intégrer le client Serverpod dans l'app Flutter existante