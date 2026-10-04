# Railway deploy (GitHub + Dify Production topology)

This runbook targets the **[Deploy Dify Production](https://railway.com/template/dify-production)** style topology (gateway, api, worker, worker-beat, web, redis, sandbox, ssrf-proxy, plugin-daemon) with **external Supabase Postgres** instead of Railway Postgres.

Official references:

- [Railway Dify guide](https://docs.railway.com/guides/dify)
- [Deploy Dify Production template](https://railway.com/template/dify-production)

## Phase C1 — GitHub

1. Create GitHub repo `ajumrah-dify` (or `dify-railway`).
2. Push this repository.
3. Do **not** commit `.env` or Supabase passwords.

## Phase C1 — Railway project

1. [Railway](https://railway.com) → **New Project**.
2. **Deploy from GitHub repo** → select this repo.  
   The repo is primarily **documentation + env templates**; services are Docker images configured in Railway (template or manual).
3. Keep this project **separate** from CRM Railway project.

### Option A (recommended): Production template, then swap DB

1. Open [Deploy Dify Production](https://railway.com/template/dify-production) → **Deploy on Railway** (into your account).
2. If the template creates **Railway Postgres**, plan to **replace** `DB_*` and `PGVECTOR_*` with Supabase values from [supabase_setup.md](supabase_setup.md) and **remove or stop** the template Postgres service once Supabase is verified (avoid dual-writes).
3. Keep **Redis**, **gateway**, **bucket/S3**, sandbox, ssrf-proxy, plugin-daemon from the template unless you have a reason to rebuild manually.

### Option B: Manual multi-service

Follow [Railway manual Dify guide](https://docs.railway.com/guides/dify) for api/worker/web only — sufficient for experiments, **not** full production (no sandbox/plugins). Prefer Option A for ajumrah.

## Phase C2 — Service list

See [../railway/services.md](../railway/services.md). Summary:

| Service | Image | Public |
|---------|-------|--------|
| gateway | nginx/caddy (template) | **Yes** — custom domain |
| api | `langgenius/dify-api` | No (via gateway) |
| worker | `langgenius/dify-api` | No |
| worker-beat | `langgenius/dify-api` | No |
| web | `langgenius/dify-web` | No (via gateway) |
| redis | Railway Redis | No |
| sandbox | template image | No |
| ssrf-proxy | template image | No |
| plugin-daemon | template image | No |

**Postgres:** Supabase (external). **Not** Railway Postgres for production.

## Phase C3 — Environment variables

Copy from examples (no real secrets):

- [../railway/env.api.example](../railway/env.api.example)
- [../railway/env.worker.example](../railway/env.worker.example)
- [../railway/env.web.example](../railway/env.web.example)
- [../railway/env.gateway.example](../railway/env.gateway.example)

### Shared variables (Railway project → Shared Variables)

Use one shared group for api + worker + worker-beat:

| Variable | Notes |
|----------|--------|
| `SECRET_KEY` | `./scripts/generate_secret_key.sh` |
| `DB_*` | Supabase direct host — [supabase_setup.md](supabase_setup.md) |
| `PGVECTOR_*` | Same Supabase host as `DB_*` |
| `VECTOR_STORE` | `pgvector` |
| `REDIS_*` | From Railway Redis service references |
| `CELERY_BROKER_URL` | `redis://:password@redis-private:6379/1` |
| `STORAGE_TYPE` | `s3` with Railway bucket (recommended) |
| `S3_*` | Bucket credentials from Railway |
| `CODE_EXECUTION_*` | Point to sandbox private domain |
| `SSRF_PROXY_*` | Point to ssrf-proxy private domain |
| `PLUGIN_DAEMON_*` | Keys must match plugin-daemon service |
| `CONSOLE_API_URL`, `APP_API_URL`, `SERVICE_API_URL`, `CONSOLE_WEB_URL`, `APP_WEB_URL` | `https://<gateway-public-domain>` |
| `FILES_URL` | Often `http://${{api.RAILWAY_PRIVATE_DOMAIN}}:5001` |

Per-service overrides:

| Service | Extra |
|---------|--------|
| api | `MODE=api`, `MIGRATION_ENABLED=true` |
| worker | `MODE=worker` |
| worker-beat | `MODE=beat` |
| web | `CONSOLE_API_URL`, `APP_API_URL` = gateway public URL; **`PORT=3000`** explicitly (Railway may inject `8080`) |

Gateway routes (template): `/console/api`, `/api`, `/v1`, `/files` → api; UI → web.

### Reference variable style

Railway syntax: `${{serviceName.VAR}}` and `${{serviceName.RAILWAY_PRIVATE_DOMAIN}}`.

When using **external Supabase**, replace postgres references with literal host + secrets:

```text
DB_HOST=db.xxxx.supabase.co
DB_PASSWORD=${{shared.DIFY_DB_PASSWORD}}
```

Define `DIFY_DB_PASSWORD` as a shared secret once.

## Phase C4 — Storage

- **Preferred:** `STORAGE_TYPE=s3` + Railway Object Storage bucket (shared by api + worker).
- **Avoid:** `STORAGE_TYPE=local` with per-service volumes — volumes are **not** shared across Railway services; uploads from api may not be visible to worker.

## Phase C5 — Domains

1. First deploy: use Railway-generated gateway URL.
2. When stable, attach `dify.ajumrah.com` to the **gateway** service — see [operations.md](operations.md).

Update all `*_API_URL` / `*_WEB_URL` env vars to the final HTTPS origin and redeploy web + api.

## Phase C5 — First admin + smoke

1. Open gateway URL → complete Dify setup (create admin).
2. **Settings → Model Providers** → add temporary OpenAI/Anthropic/etc. key for smoke test only.
3. Create app (Chatflow) that echoes user input.
4. **API Access** → create API key.
5. Run:

   ```bash
   export DIFY_API_URL=https://your-gateway.up.railway.app/v1
   export DIFY_APP_API_KEY=app-...
   ./scripts/smoke_test_chat.sh "ping"
   ```

6. Create a Knowledge dataset, upload one FAQ, attach to app, ask a question that requires retrieval.

## Shared Variables vs per-service

| Pattern | Use for |
|---------|---------|
| Shared Variables | `SECRET_KEY`, Supabase passwords, Redis password, S3 keys, plugin keys |
| Service references | `FILES_URL`, sandbox/ssrf/plugin private URLs, gateway public domain |
| Per-service only | `MODE`, `MIGRATION_ENABLED`, web `PORT=3000` |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Console loads but API 502 | Check gateway upstreams; verify api private health |
| Web broken styling/API | `CONSOLE_API_URL` / `APP_API_URL` must match browser origin (gateway URL) |
| Worker not indexing | Redis broker URL; S3 storage; worker logs |
| RAG fails | Supabase `vector` extension; `PGVECTOR_*` matches `DB_*` |

Next: [operations.md](operations.md) and [handoff_to_crm.md](handoff_to_crm.md)
