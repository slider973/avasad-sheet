# Time Sheet - Application Flutter

Application de gestion des feuilles de temps pour HeyTalent. Multi-plateforme (iOS, Android, Web, Desktop).

## Architecture

```
time_sheet_backend/
├── infrastructure/                  # Supabase + PowerSync (Docker)
│   ├── docker-compose.yml           # Services backend
│   ├── .env.example                 # Template de configuration
│   ├── nginx/timesheet.conf         # Reverse proxy SSL
│   ├── powersync/powersync.yaml     # Sync rules
│   ├── volumes/kong/kong.yml        # API Gateway
│   └── supabase/
│       ├── migrations/              # Schéma SQL + RLS + Storage
│       └── functions/               # Edge Functions (TypeScript)
├── time_sheet_backend_flutter/      # Application Flutter
├── time_sheet_backend_server/       # [Legacy] Serverpod (en cours de suppression)
└── time_sheet_backend_client/       # [Legacy] Client Serverpod
```

**Stack technique :**
- **Backend** : Supabase self-hosted (PostgreSQL, Auth, Storage, Realtime)
- **Sync** : PowerSync self-hosted (offline-first, SQLite local <-> PostgreSQL)
- **Frontend** : Flutter + BLoC + Clean Architecture
- **Edge Functions** : Deno/TypeScript (validations, notifications, cron)

---

## Prerequis

- Flutter SDK >= 3.x
- Docker & Docker Compose
- Un VPS ou machine locale pour l'infrastructure
- (Optionnel) Nginx avec certificat SSL pour la production

---

## 1. Demarrer l'infrastructure (Supabase + PowerSync)

### Configuration

```bash
cd infrastructure

# Copier le template et remplir les valeurs
cp .env.example .env
```

Editer `.env` avec vos valeurs :
- `POSTGRES_PASSWORD` : mot de passe PostgreSQL
- `JWT_SECRET` : generer avec `openssl rand -hex 32`
- `ANON_KEY` / `SERVICE_ROLE_KEY` : generer depuis le JWT_SECRET ([doc Supabase](https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys))
- `SITE_URL`, `API_EXTERNAL_URL` : vos URLs de domaine
- `GOTRUE_SMTP_*` : configuration SMTP pour les emails de confirmation
- `POWERSYNC_DB_PASSWORD` : meme que `POSTGRES_PASSWORD`

### Lancer les services

```bash
cd infrastructure

# Demarrer tous les services
docker compose up -d

# Verifier que tout tourne
docker compose ps
```

Services disponibles :
| Service | Port | Description |
|---------|------|-------------|
| PostgreSQL | 5432 | Base de donnees |
| Supabase Studio | 3000 | Dashboard admin web |
| Kong (API Gateway) | 8000 | API REST + Auth |
| PowerSync | 8080 | Moteur de synchronisation |
| GoTrue | 9999 | Authentification |
| Realtime | 4000 | Websockets temps reel |

### Appliquer le schema de base de donnees

Les migrations SQL se trouvent dans `infrastructure/supabase/migrations/`. Appliquez-les dans l'ordre via Supabase Studio (SQL Editor) ou directement avec psql :

```bash
# Via psql (remplacer les valeurs)
psql -h localhost -p 5432 -U supabase_admin -d supabase \
  -f infrastructure/supabase/migrations/00001_create_schema.sql

psql -h localhost -p 5432 -U supabase_admin -d supabase \
  -f infrastructure/supabase/migrations/00002_rls_policies.sql

psql -h localhost -p 5432 -U supabase_admin -d supabase \
  -f infrastructure/supabase/migrations/00003_storage_buckets.sql
```

### Deployer les Edge Functions

```bash
# Depuis la racine du projet, deployer chaque function
supabase functions deploy create-validation \
  --project-ref <votre-ref> \
  --import-map infrastructure/supabase/functions/create-validation/index.ts

supabase functions deploy approve-validation \
  --project-ref <votre-ref> \
  --import-map infrastructure/supabase/functions/approve-validation/index.ts

supabase functions deploy check-expired \
  --project-ref <votre-ref> \
  --import-map infrastructure/supabase/functions/check-expired/index.ts
```

### (Production) Configurer Nginx

Copier `infrastructure/nginx/timesheet.conf` dans votre config Nginx et adapter les domaines :
- `api.timesheet.votredomaine.ch` -> Kong (port 8000)
- `studio.timesheet.votredomaine.ch` -> Studio (port 3000)
- `sync.timesheet.votredomaine.ch` -> PowerSync (port 8080)

---

## 2. Demarrer l'application Flutter

### Installation

```bash
cd time_sheet_backend_flutter

# Installer les dependances
flutter pub get
```

### Configuration Supabase dans l'app

L'app se connecte a Supabase via `lib/core/services/supabase/supabase_service.dart`. Les URLs et cles sont configurees dans ce fichier. Pour pointer vers votre instance :

```dart
// Dans supabase_service.dart, modifier :
static const String _supabaseUrl = 'https://api.timesheet.votredomaine.ch';
static const String _supabaseAnonKey = 'votre-anon-key';
```

La configuration PowerSync se fait dans `lib/core/database/powersync_database.dart` :

```dart
// URL de votre instance PowerSync
static const String _powerSyncUrl = 'https://sync.timesheet.votredomaine.ch';
```

### Lancer l'app

```bash
cd time_sheet_backend_flutter

# Mobile (iOS/Android)
flutter run

# Web
flutter run -d chrome

# Desktop
flutter run -d macos    # ou windows, linux
```

### Generer le code (si modification des modeles Isar)

```bash
cd time_sheet_backend_flutter
flutter packages pub run build_runner build --delete-conflicting-outputs
```

---

## 3. Flux d'utilisation

### Premier lancement

1. L'app demarre -> ecran de login (email/mot de passe ou Google)
2. Inscription -> email de confirmation
3. Apres confirmation -> onboarding (nom, entreprise, signature)
4. Acces au dashboard principal

### Roles

- **Employe** : 5 onglets (Dashboard, Pointage, Time Sheet, Calendrier, Anomalies)
- **Manager** : 6 onglets (les 5 + onglet Manager avec vue equipe, validations, depenses)
- **Admin** : acces complet + Supabase Studio

### Migration des donnees existantes (Isar -> PowerSync)

Si l'utilisateur avait des donnees dans l'ancienne version (Isar local), la migration se fait automatiquement au premier lancement apres la mise a jour. Le script `lib/core/migration/isar_to_powersync_migration.dart` :
1. Detecte la presence d'une base Isar
2. Migre toutes les donnees vers PowerSync (qui sync vers Supabase)
3. Marque la migration comme terminee

---

## 4. Structure du code Flutter

```
lib/
├── core/
│   ├── auth/                    # Repository d'authentification
│   ├── database/                # PowerSync (schema, connector, manager)
│   ├── error/                   # Classes d'erreur (Failure)
│   ├── migration/               # Migration Isar -> PowerSync
│   ├── responsive/              # Layout responsive (mobile/tablet/desktop)
│   └── services/
│       ├── supabase/            # Service Supabase (auth, client)
│       └── storage/             # Service Storage (PDFs, signatures, receipts)
├── features/
│   ├── auth/                    # Login, Register, Forgot Password
│   ├── pointage/                # Pointage, Dashboard, Calendrier, Anomalies, PDF
│   ├── absence/                 # Gestion des absences
│   ├── expense/                 # Notes de frais
│   ├── validation/              # Workflow de validation manager
│   ├── preference/              # Preferences utilisateur, onboarding
│   ├── manager/                 # Dashboard manager (equipe, approbations)
│   └── bottom_nav_tab/          # Navigation (BottomNav + Drawer)
└── services/
    ├── injection_container.dart # GetIt (dependency injection)
    └── service_factory.dart     # MultiBlocProvider
```

---

## 5. Tests

```bash
cd time_sheet_backend_flutter

# Tous les tests
flutter test

# Un fichier specifique
flutter test test/nom_du_test.dart

# Tests d'integration
flutter test test/integration/
```

---

## 6. Build de production

```bash
cd time_sheet_backend_flutter

# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web (deployer le contenu de build/web/ sur votre serveur)
flutter build web --release

# macOS
flutter build macos --release
```

Pour le web, servir les fichiers statiques de `build/web/` avec Nginx (ajouter un bloc dans `timesheet.conf` pour `web.timesheet.votredomaine.ch`).

---

## Arreter l'infrastructure

```bash
cd infrastructure
docker compose stop     # Arreter les services
docker compose down     # Arreter et supprimer les containers
docker compose down -v  # Arreter et supprimer les volumes (PERTE DE DONNEES)
```
