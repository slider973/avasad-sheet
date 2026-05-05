# Time Sheet MCP Server

Serveur **MCP HTTP distant** (Streamable HTTP) pour pointer ton temps de travail
depuis un PC d'entreprise via [Claude Code](https://claude.com/claude-code) (ou
tout autre client MCP compatible).

```
PC entreprise ── HTTPS + Bearer PAT ──▶ mcp.staticflow.ch
                                              │
                                              ▼
                                          Supabase
```

---

## Outils exposés

| Outil | Action |
|---|---|
| `punch_in` | Pointe une **arrivée** (matin ou reprise après-midi) |
| `punch_out` | Pointe une **sortie** (pause de midi ou fin de journée) |
| `punch` | Pointe le prochain événement, quel qu'il soit |
| `status` | État détaillé du jour (4 slots, état, total) |
| `today_summary` | Résumé court d'une ligne |
| `server_now` | Heure et fuseau du serveur |

La logique suit fidèlement l'app Flutter : remplissage **strictement séquentiel**
des 4 slots `start_morning → end_morning → start_afternoon → end_afternoon`,
format `HH:mm` 24 h.

---

## Déploiement (Dokploy)

### 1. Appliquer la migration SQL

Dans Supabase Studio (SQL Editor) ou via psql :

```sh
psql -h <host> -p 5432 -U supabase_admin -d postgres \
  -f infrastructure/supabase/migrations/00014_mcp_tokens.sql
```

### 2. Créer le service Compose dans Dokploy

- Type : **Docker Compose**
- Source : ce dossier (`time_sheet_backend/mcp_server/`)
- Variables d'environnement (voir `.env.example`) :
  - `SUPABASE_URL` — URL interne du Kong (ex. `http://kong:8000`) ou publique
  - `SUPABASE_SERVICE_ROLE_KEY` — depuis Studio → Settings → API
  - `TIMEZONE` — `Europe/Zurich`

Le container expose le port **8787**.

### 3. Configurer le DNS

Ajouter un enregistrement A pour `mcp.staticflow.ch` pointant vers le
même serveur que les autres sous-domaines.

### 4. Émettre le certificat SSL

Étendre le certificat existant pour inclure le nouveau sous-domaine :

```sh
certbot certonly --webroot -w /var/www/certbot \
  -d timesheet.staticflow.ch \
  -d api.timesheet.staticflow.ch \
  -d studio.timesheet.staticflow.ch \
  -d sync.timesheet.staticflow.ch \
  -d mcp.staticflow.ch \
  --expand
```

### 5. Recharger Nginx

Le bloc `server` pour `mcp.staticflow.ch` est déjà ajouté à
`infrastructure/nginx/timesheet.conf`.

```sh
nginx -t && systemctl reload nginx
```

### 6. Vérifier

```sh
curl https://mcp.staticflow.ch/health
# {"status":"ok"}
```

---

## Génération d'un Personal Access Token (PAT)

Connecté en tant que ton utilisateur Supabase (depuis l'app ou Studio en mode
auth utilisateur), exécute :

```sql
SELECT * FROM create_mcp_token('PC bureau', 365);
-- id            | token                                     | expires_at
-- <uuid>        | tsmcp_a1b2c3d4...                          | 2027-...
```

**Le token n'est affiché qu'une seule fois.** Copie-le immédiatement.

Pour révoquer :

```sql
SELECT revoke_mcp_token('<token-id>');
```

---

## Configuration côté PC d'entreprise (Claude Code)

Dans `~/.claude.json` (ou `claude mcp add` selon ta version) :

```json
{
  "mcpServers": {
    "time-sheet": {
      "type": "http",
      "url": "https://mcp.staticflow.ch/mcp",
      "headers": {
        "Authorization": "Bearer tsmcp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      }
    }
  }
}
```

Ou en CLI :

```sh
claude mcp add --transport http time-sheet \
  https://mcp.staticflow.ch/mcp \
  --header "Authorization: Bearer tsmcp_..."
```

Redémarre Claude Code, puis :

> *« pointe mon arrivée »* → appelle `punch_in`
> *« quel est mon statut ? »* → appelle `status`

---

## Développement local

```sh
cd time_sheet_backend/mcp_server
cp .env.example .env   # remplir SUPABASE_URL + SERVICE_ROLE_KEY
npm install
npm run dev            # tsx watch sur src/index.ts
```

Test rapide avec curl (initialize) :

```sh
curl -X POST http://localhost:8787/mcp \
  -H "Authorization: Bearer tsmcp_..." \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc":"2.0","id":1,"method":"initialize",
    "params":{"protocolVersion":"2025-03-26","capabilities":{},
              "clientInfo":{"name":"curl","version":"1"}}
  }'
```

---

## Sécurité

- Les tokens sont stockés en **SHA-256** dans `mcp_tokens.token_hash` ; le secret
  en clair n'existe qu'au moment de la création.
- Le serveur utilise la **service-role key** Supabase, mais filtre **toujours**
  par `user_id` extrait du PAT — RLS reste un filet de sécurité côté DB.
- Rate limit Nginx : 30 req/s avec burst 20.
- Pour révoquer instantanément un PC perdu : `SELECT revoke_mcp_token(...)`.
