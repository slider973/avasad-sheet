---
name: db-migration
description: >
  Créer et appliquer une migration de schéma (PostgreSQL + PowerSync + Flutter).
  Utiliser quand l'utilisateur demande d'ajouter une table/colonne, modifier le
  schéma, écrire une migration SQL, des policies RLS, ou synchroniser une
  nouvelle donnée dans l'app.
---

# Migration de schéma — workflow complet

Une modification de schéma traverse TOUJOURS ces 5 couches, dans cet ordre. En oublier une casse la synchro silencieusement.

## 1. Migration SQL

- Créer `infrastructure/supabase/migrations/000NN_description.sql` (numéro suivant ; dernier connu : `00015_harden_validation_rls.sql`).
- Inclure dans le même fichier : DDL + policies RLS + grants. Regarder `00002_rls_policies.sql` et `00015` pour le style (multi-tenant : filtrer par organisation, rôles `employee`/`manager`/`admin` dans `profiles.role`).
- Idempotence : `IF NOT EXISTS` / `DROP POLICY IF EXISTS` avant `CREATE POLICY`.

## 2. Appliquer en base

**Prod (self-hosted Dokploy, `72.61.195.143`, SSH `~/.ssh/noche_server` user `root`)** — pièges connus :
- Base applicative = **`supabase`** (pas `postgres`).
- `pgcrypto` est dans le schéma **`extensions`** → `extensions.crypt(...)`, `extensions.gen_salt('bf')`.
- Pour toucher `auth.*` : rôle **`supabase_admin`** (le rôle `postgres` n'est pas owner). Mot de passe dans l'env du conteneur auth : `docker exec <stack>-auth-1 env | grep GOTRUE_DB_DATABASE_URL`. Se connecter avec `-h 127.0.0.1` + `PGPASSWORD`.
- Conteneurs : `timesheetsupabase-supabasestack-ggqzyc-*`.
- ⚠️ Le projet Supabase cloud « time-sheet » est INACTIF — ne pas y appliquer les migrations prod.

**Local (docker compose dans `infrastructure/`)** : `psql -h localhost -p 5432 -U supabase_admin -d supabase -f supabase/migrations/000NN_....sql`

## 3. Sync rules PowerSync

Si la table/colonne doit atteindre l'app : éditer `infrastructure/powersync/powersync.yaml`.
- Buckets existants : `user_data` (données de l'employé), `manager_data` (équipe du manager), `org_data` (données partagées d'organisation).
- Choisir le bucket selon QUI doit voir la donnée. Redémarrer le conteneur PowerSync après modification.

## 4. Schéma local Flutter

`time_sheet_backend_flutter/lib/core/database/schema.dart` : ajouter la `Table`/`Column` PowerSync correspondante. Les noms de tables/colonnes doivent matcher PostgreSQL exactement (PowerSync mappe 1:1). Types SQLite : `text`, `integer`, `real` — les UUID/dates deviennent `text`.

## 5. Data source + repository Flutter

- Data source dans `lib/features/<feature>/data/` : requêtes SQL sur la DB locale (`db.getAll`, `db.execute`, `db.watch`).
- Les écritures locales se synchronisent automatiquement vers PostgreSQL — mais elles seront REJETÉES à l'upload si la policy RLS ne les autorise pas : tester le rôle concerné.

## Vérification

1. `flutter analyze` puis lancer l'app, vérifier les logs PowerSync (pas d'erreur de sync/upload).
2. Vérifier côté SQL que la ligne écrite depuis l'app arrive en PostgreSQL.
3. Tester avec un compte du bon rôle (employee vs manager) : un bucket mal choisi = donnée invisible, une RLS trop stricte = upload silencieusement en échec (visible dans les logs du conteneur PowerSync).
