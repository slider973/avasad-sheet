# CLAUDE.md — Racine du monorepo

Ce fichier donne les règles transverses du repo. Tout le code vit dans `time_sheet_backend/` :

- `time_sheet_backend/CLAUDE.md` — architecture backend (Supabase self-hosted, PowerSync, Edge Functions, migrations)
- `time_sheet_backend/time_sheet_backend_flutter/CLAUDE.md` — application Flutter (Clean Architecture + BLoC)

**Produit** : « Planet Time sheet » — gestion de feuilles de temps (pointage, absences, notes de frais, validation manager, PDF signés). Bundle iOS `com.jonathanlemaine.timeSheet`.

## Conventions

- **Commits en français**, format conventionnel : `feat(scope): …`, `fix(ci): …`, `refactor: …`.
- Réponses, commentaires et docs en français ; identifiants de code en anglais.
- Ne jamais committer de secrets (`.env`, clés `.p8`, mots de passe). `infrastructure/.env` et `ios/fastlane/.env` sont non versionnés (templates `.env.example`).
- Jamais de `sudo rm` ni de suppression hors du repo sans demande explicite.

## Déploiement iOS (TestFlight)

- **Voie normale : Codemagic** (`codemagic.yaml` à la racine, workflow `ios-testflight`). Déclenché par un push sur `main` ou via l'UI Codemagic. Build number auto = dernier build TestFlight + 1, publication TestFlight automatique. ~9 min.
- **Le build iOS local échoue** : Apple exige le SDK iOS 26 (Xcode 26), non installable sur ce Mac (macOS 14.6). Ne pas tenter `flutter build ipa` en local pour une release.
- Détails, signature (certificat persistant), clés API : skill projet `deploy-ios` et `ios/fastlane/README.md`.
- Version (`X.Y.Z`) : source de vérité = `pubspec.yaml`. Ne jamais réintroduire `increment_build_number` dans le Fastfile.

## Production (self-hosted)

- La prod tourne **self-hosted via Dokploy** sur `72.61.195.143` (SSH `~/.ssh/noche_server`, user `root`). Endpoints : `supabase.timesheet.staticflow.ch`, `powersync.timesheet.staticflow.ch`, `timesheet.staticflow.ch`.
- ⚠️ Le projet Supabase **cloud** nommé « time-sheet » est INACTIF — ne pas l'utiliser pour débugger la prod.
- Base applicative = `supabase` (pas `postgres`) ; `pgcrypto` dans le schéma `extensions` ; utiliser le rôle `supabase_admin` pour toucher `auth.*`.

## Legacy — ne pas toucher

- `time_sheet_backend_server/` et `time_sheet_backend_client/` : ancien backend **Serverpod, en cours de suppression**. Ne rien y développer.
- Les nombreux `*.md` historiques à la racine de `time_sheet_backend/` (AI_*, EXPENSE_*, etc.) sont des archives de plans, pas des specs à jour.
