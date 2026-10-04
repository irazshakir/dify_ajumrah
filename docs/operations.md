# Operations — domains, upgrades, backups, logs

## Custom domain (`dify.ajumrah.com`)

1. Railway → **gateway** service (public entry) → **Settings** → **Networking** → **Custom Domain**.
2. Add `dify.ajumrah.com`.
3. At your DNS provider, create a **CNAME**:
   - Name: `dify` (or `@` if apex — prefer subdomain)
   - Target: the hostname Railway shows (often `*.up.railway.app`).
4. Wait for TLS provisioning (Let’s Encrypt via Railway).
5. Update shared env vars to the final origin and redeploy **web**, **api**, **worker**, **worker-beat**:
   - `CONSOLE_API_URL=https://dify.ajumrah.com`
   - `APP_API_URL=https://dify.ajumrah.com`
   - `SERVICE_API_URL=https://dify.ajumrah.com`
   - `CONSOLE_WEB_URL=https://dify.ajumrah.com`
   - `APP_WEB_URL=https://dify.ajumrah.com`
6. Hard-refresh browser or clear site data if console still points at old Railway URL.

CRM stays on `crm.ajumrah.com` / `app.ajumrah.com` — do not merge DNS records.

## Upgrading Dify image versions

1. Check [Dify release notes](https://github.com/langgenius/dify/releases) and [Docker Hub tags](https://hub.docker.com/r/langgenius/dify-api/tags).
2. Pin **the same tag** on `dify-api` and `dify-web` (and any template-pinned auxiliary images).
3. Order:
   - Backup Supabase (dashboard or `pg_dump`).
   - Set api + worker + worker-beat to new `langgenius/dify-api:<tag>`.
   - Deploy api first; confirm migrations in logs (`MIGRATION_ENABLED=true` on api only).
   - Deploy worker + worker-beat.
   - Deploy web `langgenius/dify-web:<tag>`.
4. Smoke test: login, `./scripts/smoke_test_chat.sh`, one knowledge query.
5. Update pinned versions in [README.md](../README.md) and [../railway/services.md](../railway/services.md).

**Do not rotate `SECRET_KEY` casually** — it encrypts stored provider keys in Postgres.

## Backups

| Asset | Method |
|-------|--------|
| Postgres (apps, conversations, vectors) | Supabase backups / PITR; periodic logical dump |
| Object storage (uploads) | Railway bucket lifecycle / replication per Railway docs |
| Dify app definitions | Export Chatflow DSL to `exports/` (see [../exports/README.md](../exports/README.md)) |
| Env / secrets | Password manager + Railway variable export (never commit) |

Restore drill (quarterly recommended):

1. Restore Supabase to a scratch project or branch.
2. Point a staging Railway project at restored DB.
3. Run smoke test script.

## Logs and monitoring

- Railway → each service → **Deployments** → **View Logs**.
- Key services for incidents: **api**, **worker**, **gateway**, **plugin-daemon**, **sandbox**.
- Celery queue backlog: worker logs + Redis metrics in Railway.

## Scaling notes

- Increase worker replicas if indexing or chat workflows queue.
- Supabase connection limits: watch active connections from api + workers; use Supabase pooler **only** for stateless edge cases, not Dify workers.
- `REDIS_SOCKET_TIMEOUT`: production templates often set high values on api — do not lower without testing collaborative editing.

## Security operations

- Disable public sign-up: `ALLOW_REGISTER=false` (template default).
- Remove temporary platform LLM keys after CRM **llm-proxy** is wired ([handoff_to_crm.md](handoff_to_crm.md)).
- Rotate Dify **app API keys** if leaked; rotate Supabase password via Supabase + Railway secret update + redeploy.

## Incident checklist

1. Gateway 5xx → api health, recent deploy, env URL mismatch.
2. Knowledge not retrieving → worker logs, pgvector extension, embedding model config.
3. Plugin/tool failures → plugin-daemon + sandbox + ssrf-proxy logs.
