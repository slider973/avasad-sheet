# Environnement DEV - Supabase + PowerSync

Stack de developpement completement isolee de la production, deployee sur le meme serveur Dokploy.

## Architecture

```
PROD: supabase.timesheet.staticflow.ch     --> Kong prod --> services prod (DB prod)
DEV:  dev-supabase.timesheet.staticflow.ch --> Kong dev  --> services dev (DB dev separee)
```

Chaque environnement possede :
- Sa propre base de donnees PostgreSQL (volumes Docker separes)
- Ses propres secrets JWT (ANON_KEY, SERVICE_ROLE_KEY)
- Son propre MongoDB pour PowerSync
- Son propre reseau Docker interne (`dev-supabase-net`)

## Domaines

| Service | Domaine | Description |
|---------|---------|-------------|
| API Gateway (Kong) | `dev-supabase.timesheet.staticflow.ch` | Point d'entree principal (auth, rest, realtime, storage) |
| PowerSync | `dev-powersync.timesheet.staticflow.ch` | Sync engine pour le offline-first |
| App Web | `dev.timesheet.staticflow.ch` | Application web React (optionnel) |

Tous les domaines pointent vers `72.61.195.143` (serveur Dokploy) via des enregistrements DNS A.

---

## Services (9 containers)

| Service | Image | Container | Port interne | Role |
|---------|-------|-----------|-------------|------|
| PostgreSQL | `supabase/postgres:15.6.1.143` | timesheet-dev-db | 5432 | Base de donnees principale |
| GoTrue (Auth) | `supabase/gotrue:v2.164.0` | timesheet-dev-auth | 9999 | Authentification (email, Google, PKCE) |
| PostgREST | `postgrest/postgrest:v12.2.3` | timesheet-dev-rest | 3000 | API REST auto-generee depuis le schema |
| Realtime | `supabase/realtime:v2.33.58` | timesheet-dev-realtime | 4000 | WebSocket pour les changements en temps reel |
| Storage API | `supabase/storage-api:v1.11.13` | timesheet-dev-storage | 5000 | Stockage fichiers (PDFs, signatures, recus) |
| imgproxy | `darthsim/imgproxy:v3.8.0` | timesheet-dev-imgproxy | 5001 | Redimensionnement d'images pour Storage |
| Kong | `kong:2.8.1` | timesheet-dev-kong | 8000 | API Gateway + routage + auth par API key |
| MongoDB | `mongo:7.0` | timesheet-dev-mongo | 27017 | Storage interne pour PowerSync |
| PowerSync | `journeyapps/powersync-service:latest` | timesheet-dev-powersync | 8080 | Sync bidirectionnelle SQLite <-> PostgreSQL |

### Services exclus (economie ~500MB RAM)

- **Studio** : utiliser le SQL directement via `psql`
- **postgres-meta** : requis uniquement par Studio
- **Edge Functions** : peut etre ajoute plus tard si besoin
- **DocuSeal** : pas necessaire en dev

---

## Structure des fichiers

```
infrastructure/dev/
  .env                              # Variables d'environnement (secrets, URLs)
  docker-compose.yml                # Definition des 9+ services
  volumes/
    kong/
      kong.yml                      # Config declarative Kong (routage API)
  powersync/
    powersync.yaml                  # Config PowerSync (replication, sync rules)
```

---

## Prerequis

### 1. DNS Records

3 enregistrements DNS A pointant vers `72.61.195.143` :

| Sous-domaine | Type | Valeur |
|---|---|---|
| `dev.timesheet.staticflow.ch` | A | `72.61.195.143` |
| `dev-supabase.timesheet.staticflow.ch` | A | `72.61.195.143` |
| `dev-powersync.timesheet.staticflow.ch` | A | `72.61.195.143` |

### 2. Acces SSH au serveur

```bash
ssh -i ~/.ssh/contabo root@72.61.195.143
```

### 3. Configurer le .env

Editer `infrastructure/dev/.env` :
- Verifier `POSTGRES_PASSWORD`
- Ajouter les credentials SMTP si besoin (sinon `GOTRUE_MAILER_AUTOCONFIRM=true` permet de bypasser la confirmation email)
- Les cles JWT sont deja generees

---

## Deploiement

### Etape 1 : Creer le service Compose dans Dokploy

Le service est deja cree dans Dokploy sous le nom `supabase-stack-dev` (composeId: `F94CDSU46Vb8wO4R34HQw`, appName: `supabase-stack-dev-hjppd7`).

Le chemin sur le serveur est :
```
/etc/dokploy/compose/supabase-stack-dev-hjppd7/code/
```

### Etape 2 : Copier les fichiers de configuration sur le serveur

```bash
# Depuis la racine du projet (machine locale)
COMPOSE_PATH=/etc/dokploy/compose/supabase-stack-dev-hjppd7/code
SERVER=root@72.61.195.143
SSH_KEY=~/.ssh/contabo

# Creer les repertoires
ssh -i $SSH_KEY $SERVER "mkdir -p $COMPOSE_PATH/volumes/kong $COMPOSE_PATH/powersync"

# Copier les fichiers
scp -i $SSH_KEY infrastructure/dev/docker-compose.yml $SERVER:$COMPOSE_PATH/docker-compose.yml
scp -i $SSH_KEY infrastructure/dev/.env $SERVER:$COMPOSE_PATH/.env
scp -i $SSH_KEY infrastructure/dev/volumes/kong/kong.yml $SERVER:$COMPOSE_PATH/volumes/kong/kong.yml
scp -i $SSH_KEY infrastructure/dev/powersync/powersync.yaml $SERVER:$COMPOSE_PATH/powersync/powersync.yaml
```

### Etape 3 : Demarrer la stack

```bash
ssh -i $SSH_KEY $SERVER "cd $COMPOSE_PATH && docker compose -p supabase-stack-dev-hjppd7 up -d"
```

### Etape 4 : Initialiser la base de donnees

Avant d'appliquer les migrations, creer les schemas et roles necessaires :

```bash
ssh -i $SSH_KEY $SERVER "docker exec -e PGPASSWORD=dev-super-secret-postgres-password-2024 timesheet-dev-db psql -U supabase_admin -d supabase -c \"
CREATE SCHEMA IF NOT EXISTS _realtime;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA extensions;
DO \\\$\\\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN CREATE ROLE service_role NOLOGIN; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN CREATE ROLE supabase_auth_admin NOLOGIN; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN CREATE ROLE supabase_storage_admin NOLOGIN; END IF;
END
\\\$\\\$;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON SCHEMA _realtime TO supabase_admin;
CREATE PUBLICATION powersync FOR ALL TABLES;
\""
```

### Etape 5 : Appliquer les migrations SQL

```bash
# Copier les migrations sur le serveur
scp -i $SSH_KEY infrastructure/supabase/migrations/*.sql $SERVER:/tmp/

# Appliquer toutes les migrations
ssh -i $SSH_KEY $SERVER 'for f in /tmp/000*.sql; do
  echo "=== Applying $f ==="
  docker exec -i -e PGPASSWORD=dev-super-secret-postgres-password-2024 timesheet-dev-db psql -U supabase_admin -d supabase < $f
  echo
done'
```

Migrations appliquees (12 fichiers) :

| Fichier | Description |
|---------|-------------|
| `00001_create_schema.sql` | 11 tables + triggers + publication powersync |
| `00002_rls_policies.sql` | Row Level Security sur toutes les tables |
| `00003_storage_buckets.sql` | Buckets Storage (pdfs, signatures, receipts) |
| `00004_multi_tenant_roles.sql` | Multi-tenant, roles employee/manager/admin |
| `00005_docuseal_columns.sql` | Colonnes DocuSeal sur validation_requests |
| `00006_org_hierarchy.sql` | Hierarchie d'organisations (parent_id) |
| `00007_signing_tokens.sql` | Table signing_tokens |
| `00008_manager_same_org_read.sql` | Politique RLS manager meme organisation |
| `00009_generated_pdfs_delete_update.sql` | Politiques delete/update pour generated_pdfs |
| `00010_list_child_orgs_rpc.sql` | Fonction RPC list_child_orgs |
| `00011_get_managers_for_employee_rpc.sql` | Fonction RPC get_managers_for_employee |
| `00012_storage_update_delete_policies.sql` | Politiques update/delete pour Storage buckets |

---

## Verification

```bash
# 1. Containers tournent
ssh -i $SSH_KEY $SERVER "docker ps --format 'table {{.Names}}\t{{.Status}}' | grep timesheet-dev"

# 2. Auth health (doit retourner le nom GoTrue)
curl -s -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.MdkUvagcXQ9cs5hO-fw0FkENVVq6vskG3wBR-P5gR58" \
  https://dev-supabase.timesheet.staticflow.ch/auth/v1/health

# 3. REST API (doit retourner le schema OpenAPI ou un tableau vide)
curl -s -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.MdkUvagcXQ9cs5hO-fw0FkENVVq6vskG3wBR-P5gR58" \
  https://dev-supabase.timesheet.staticflow.ch/rest/v1/profiles

# 4. PowerSync liveness (doit retourner ready: true)
curl -s https://dev-powersync.timesheet.staticflow.ch/probes/liveness

# 5. Isolation des donnees
# Creer un compte sur dev -> verifier qu'il n'existe pas en prod
```

---

## Flutter : basculer entre dev et prod

La configuration multi-environnement est geree dans `lib/core/config/environment.dart` :

```dart
enum Environment { dev, prod }

class AppConfig {
  static Environment current = Environment.prod;

  static String get supabaseUrl => switch (current) {
    Environment.dev  => 'https://dev-supabase.timesheet.staticflow.ch',
    Environment.prod => 'https://supabase.timesheet.staticflow.ch',
  };

  static String get powersyncUrl => switch (current) {
    Environment.dev  => 'https://dev-powersync.timesheet.staticflow.ch',
    Environment.prod => 'https://powersync.timesheet.staticflow.ch',
  };

  static String get anonKey => switch (current) {
    Environment.dev  => '<DEV_ANON_KEY>',
    Environment.prod => '<PROD_ANON_KEY>',
  };
}
```

L'environnement est selectionne au demarrage dans `main.dart` via `--dart-define=ENV=dev` :

```dart
const envName = String.fromEnvironment('ENV', defaultValue: 'prod');
AppConfig.current = envName == 'dev' ? Environment.dev : Environment.prod;
```

### Commandes Flutter

```bash
# Dev
flutter run --dart-define=ENV=dev

# Prod (defaut)
flutter run

# Build dev
flutter build apk --dart-define=ENV=dev
flutter build ios --dart-define=ENV=dev
flutter build web --dart-define=ENV=dev
```

### Fichiers Flutter modifies pour le multi-env

| Fichier | Modification |
|---------|-------------|
| `lib/core/config/environment.dart` | Nouveau : enum Environment + AppConfig |
| `lib/core/services/supabase/supabase_service.dart` | Utilise `AppConfig.supabaseUrl` et `AppConfig.anonKey` |
| `lib/core/database/supabase_connector.dart` | Utilise `AppConfig.powersyncUrl` |
| `lib/main.dart` | Lecture de `--dart-define=ENV` et initialisation de `AppConfig.current` |

---

## App Web DEV (optionnel)

Pour deployer l'app web React sur `dev.timesheet.staticflow.ch`, creer un service Docker separe dans Dokploy :

```yaml
image: ghcr.io/slider973/timesheet-web:latest
environment:
  VITE_SUPABASE_URL: https://dev-supabase.timesheet.staticflow.ch
  VITE_SUPABASE_ANON_KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.MdkUvagcXQ9cs5hO-fw0FkENVVq6vskG3wBR-P5gR58
```

---

## Notes techniques

### Pourquoi les valeurs sont en dur dans kong.yml et powersync.yaml ?

- **Kong** (mode declaratif `KONG_DATABASE=off`) ne fait **pas** de substitution de variables d'environnement dans `kong.yml`. Les API keys doivent etre en dur.
- **PowerSync** ne fait **pas** de substitution `${VAR}` dans son fichier YAML. Les credentials PostgreSQL et le JWT secret doivent etre en dur.
- Seul `docker-compose.yml` supporte la syntaxe `${VAR}` (via le `.env`).

### PowerSync : config importante

- Le fichier YAML doit etre monte a `/powersync-config/powersync.yaml`
- La commande de demarrage doit etre : `["start", "-c", "/powersync-config/powersync.yaml"]`
- Le format `sync_rules` doit utiliser `content: |` (string YAML multi-lignes), pas un objet `bucket_definitions` directement
- Utiliser `supabase_jwt_secret` (pas un bloc `jwks` avec array)
- Le champ telemetry est `disable_telemetry_sharing` (pas `disable_telemetry`)

### Realtime : schema _realtime

Le service Realtime a besoin du schema `_realtime` dans PostgreSQL. Il est cree automatiquement par l'image Supabase Postgres, mais si la DB est creee sans les init scripts, il faut le creer manuellement :

```sql
CREATE SCHEMA IF NOT EXISTS _realtime;
GRANT ALL ON SCHEMA _realtime TO supabase_admin;
```

### Reseau Docker

- `dev-supabase-net` : reseau bridge interne pour la communication inter-services
- `dokploy-network` : reseau overlay externe (Traefik/Dokploy) - seuls Kong et PowerSync y sont connectes car ils ont besoin d'etre accessibles depuis l'exterieur via Traefik

### Traefik (SSL/TLS)

Les certificats HTTPS sont generes automatiquement par Traefik via Let's Encrypt (`certresolver=letsencrypt`). Les labels Traefik sont definis sur `dev-kong` et `dev-powersync` dans le `docker-compose.yml`.

---

## Operations courantes

### Redemarrer un service

```bash
ssh -i $SSH_KEY $SERVER "docker restart timesheet-dev-auth"
```

### Voir les logs

```bash
ssh -i $SSH_KEY $SERVER "docker logs timesheet-dev-powersync --tail 50"
ssh -i $SSH_KEY $SERVER "docker logs timesheet-dev-auth --tail 50"
```

### Redemarrer toute la stack

```bash
ssh -i $SSH_KEY $SERVER "cd /etc/dokploy/compose/supabase-stack-dev-hjppd7/code && docker compose -p supabase-stack-dev-hjppd7 restart"
```

### Arreter la stack (liberer la RAM)

```bash
ssh -i $SSH_KEY $SERVER "cd /etc/dokploy/compose/supabase-stack-dev-hjppd7/code && docker compose -p supabase-stack-dev-hjppd7 stop"
```

### Supprimer la stack completement

```bash
ssh -i $SSH_KEY $SERVER "cd /etc/dokploy/compose/supabase-stack-dev-hjppd7/code && docker compose -p supabase-stack-dev-hjppd7 down -v"
```

> **Attention** : `-v` supprime aussi les volumes (donnees DB, fichiers storage, MongoDB).

### Acceder a la base de donnees

```bash
ssh -i $SSH_KEY $SERVER "docker exec -it -e PGPASSWORD=dev-super-secret-postgres-password-2024 timesheet-dev-db psql -U supabase_admin -d supabase"
```

### Verifier l'espace disque

```bash
ssh -i $SSH_KEY $SERVER "df -h && docker system df"
```

### Verifier la RAM

```bash
ssh -i $SSH_KEY $SERVER "free -h && docker stats --no-stream | grep timesheet-dev"
```

---

## Secrets DEV

| Cle | Valeur |
|-----|--------|
| JWT_SECRET | `258aaf499791cf8223ad9ac340beefa43787eb2dc8e0b7f66f3deb6948172555` |
| ANON_KEY | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.MdkUvagcXQ9cs5hO-fw0FkENVVq6vskG3wBR-P5gR58` |
| SERVICE_ROLE_KEY | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UiLCJpYXQiOjE3MDAwMDAwMDAsImV4cCI6MTkwMDAwMDAwMH0.zheZxgxRiZiJixMqXTyWUWoOTpZrEDjzgUuYCJFT4TE` |
| POSTGRES_PASSWORD | `dev-super-secret-postgres-password-2024` |

> Ces secrets sont specifiques a l'environnement DEV et n'ont aucun impact sur la production.

---

## Troubleshooting

### PowerSync crash loop "Config file not found"

Le fichier `powersync.yaml` n'est pas monte au bon endroit. Verifier :
```bash
docker exec timesheet-dev-powersync ls -la /powersync-config/
```
Doit contenir `powersync.yaml`. Si absent, recopier le fichier et restart.

### PowerSync "Publication 'powersync' does not exist"

Les migrations n'ont pas ete appliquees. Appliquer les migrations SQL (voir Etape 5 ci-dessus).

### Realtime crash "no schema has been selected to create in"

Le schema `_realtime` n'existe pas. Le creer :
```bash
docker exec -e PGPASSWORD=dev-super-secret-postgres-password-2024 timesheet-dev-db \
  psql -U supabase_admin -d supabase -c "CREATE SCHEMA IF NOT EXISTS _realtime;"
docker restart timesheet-dev-realtime
```

### Kong "Invalid authentication credentials"

Les API keys dans `kong.yml` ne correspondent pas aux JWT generes. Verifier que `kong.yml` contient les bonnes valeurs ANON_KEY et SERVICE_ROLE_KEY en dur (pas des `${VAR}`).

### Certificat SSL non genere

Verifier que les DNS pointent bien vers le serveur :
```bash
dig dev-supabase.timesheet.staticflow.ch +short
# Doit retourner 72.61.195.143
```
Traefik genere le certificat automatiquement au premier acces HTTPS.

### Container qui ne demarre pas (conflit de port/nom)

```bash
# Verifier les conflits
docker ps -a | grep timesheet-dev
# Supprimer les containers orphelins
docker compose -p supabase-stack-dev-hjppd7 down
docker compose -p supabase-stack-dev-hjppd7 up -d
```
