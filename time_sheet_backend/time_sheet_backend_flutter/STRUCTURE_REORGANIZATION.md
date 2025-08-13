# Plan de Réorganisation de la Structure du Projet

## Problème Actuel

La structure actuelle est confuse avec :
- Le projet Flutter principal à la racine
- Le backend Serverpod dans un sous-dossier
- Des projets générés automatiquement par Serverpod qui ne sont pas nécessaires

## Structure Actuelle
```
time_sheet/                          # Projet Flutter principal
├── lib/                            # Code Flutter de l'app
├── android/
├── ios/
├── ...
└── time_sheet_backend/             # Backend Serverpod imbriqué
    ├── time_sheet_backend_server/  # Le vrai serveur
    ├── time_sheet_backend_client/  # Client généré (utile)
    └── time_sheet_backend_flutter/ # App Flutter exemple (inutile)
```

## Structure Recommandée

### Option 1: Monorepo Organisé (Recommandé)
```
time_sheet_project/                 # Dossier racine du projet
├── apps/
│   └── time_sheet/                # Application Flutter
│       ├── lib/
│       ├── android/
│       ├── ios/
│       └── pubspec.yaml
├── backend/
│   ├── server/                    # Serveur Serverpod
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── endpoints/
│   │   │   │   ├── protocol/
│   │   │   │   └── generated/
│   │   │   └── server.dart
│   │   └── pubspec.yaml
│   └── client/                    # Client Serverpod généré
│       └── lib/
├── shared/                        # Code partagé (si nécessaire)
├── docs/                          # Documentation
│   ├── CLAUDE.md
│   ├── DEPLOYMENT.md
│   └── SERVERPOD_MIGRATION_PLAN.md
└── README.md
```

### Option 2: Projets Séparés
```
time_sheet/                        # Application Flutter
├── lib/
├── android/
├── ios/
└── pubspec.yaml

time_sheet_backend/                # Backend Serverpod
├── server/
├── client/
└── docker/
```

## Actions à Effectuer

### 1. Supprimer les Fichiers Inutiles
```bash
# Supprimer l'app Flutter exemple de Serverpod
rm -rf time_sheet_backend/time_sheet_backend_flutter
```

### 2. Restructurer les Dossiers
```bash
# Créer la nouvelle structure
mkdir -p time_sheet_project/{apps,backend,docs,shared}

# Déplacer l'app Flutter
mv time_sheet time_sheet_project/apps/

# Déplacer le serveur
mv time_sheet_backend/time_sheet_backend_server time_sheet_project/backend/server

# Déplacer le client
mv time_sheet_backend/time_sheet_backend_client time_sheet_project/backend/client

# Déplacer la documentation
mv time_sheet/*.md time_sheet_project/docs/

# Nettoyer
rm -rf time_sheet_backend
```

### 3. Mettre à Jour les Chemins

#### Dans `apps/time_sheet/pubspec.yaml`:
```yaml
dependencies:
  # Pointer vers le client Serverpod local
  time_sheet_backend_client:
    path: ../../backend/client
```

#### Dans `backend/server/config/development.yaml`:
```yaml
# Mettre à jour les chemins si nécessaire
```

### 4. Adapter les Scripts de Build

Créer un `Makefile` ou des scripts npm à la racine pour faciliter le développement :

```makefile
# Makefile à la racine
.PHONY: generate run-server run-app

generate:
	cd backend/server && serverpod generate

run-server:
	cd backend/server && dart bin/main.dart

run-app:
	cd apps/time_sheet && flutter run

docker-up:
	cd backend && docker-compose up -d
```

## Avantages de la Réorganisation

1. **Clarté**: Structure claire et logique
2. **Scalabilité**: Facile d'ajouter d'autres apps ou services
3. **Maintenance**: Séparation claire entre frontend et backend
4. **CI/CD**: Plus facile de configurer des pipelines séparés
5. **Documentation**: Centralisation de la documentation

## Ordre de Priorité

1. D'abord finir la configuration du backend actuel
2. Tester que tout fonctionne
3. Ensuite faire la réorganisation
4. Mettre à jour tous les chemins et imports
5. Vérifier que tout compile et fonctionne

Cette réorganisation peut attendre que le système de validation soit fonctionnel pour éviter de casser le travail en cours.