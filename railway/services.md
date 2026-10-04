# Railway service topology

Based on [Deploy Dify Production](https://railway.com/template/dify-production) with **external Supabase** for Postgres + pgvector.

## Image pins (update together on upgrade)

| Role | Docker image | Notes |
|------|--------------|--------|
| API | `langgenius/dify-api:1.4.3` | `MODE=api` |
| Worker | `langgenius/dify-api:1.4.3` | `MODE=worker` |
| Worker beat | `langgenius/dify-api:1.4.3` | `MODE=beat` |
| Web | `langgenius/dify-web:1.4.3` | Set `PORT=3000` |
| Gateway | Template image (nginx/caddy) | Only public HTTP entry |
| Redis | Railway managed Redis | Private only |
| Sandbox | Template | Code execution |
| SSRF proxy | Template | Egress control for sandbox |
| Plugin daemon | Template | Plugins / model tools |

Verify tags on Docker Hub before pinning; keep api/web on matching Dify versions.

## Postgres

| Source | Use |
|--------|-----|
| **Supabase** (this project) | `DB_*` + `PGVECTOR_*`, `VECTOR_STORE=pgvector` |
| Railway Postgres from template | Remove after cutover to Supabase |

## Public vs private

| Service | Public domain | Private networking |
|---------|---------------|-------------------|
| gateway | Yes (`dify.ajumrah.com`) | Upstreams to api:5001, web:3000 |
| web | No | Gateway only |
| api | No | Gateway + workers |
| worker / worker-beat | No | DB, Redis, S3, sandbox |
| redis | No | api, workers |
| sandbox, ssrf-proxy, plugin-daemon | No | api, workers |

## Gateway routing (typical)

| Path | Backend |
|------|---------|
| `/console/api`, `/api`, `/v1`, `/files` | api:5001 |
| `/` (UI) | web:3000 |
| Health | `/gateway-health` or template default |

## Env file map

| Service | Example file |
|---------|----------------|
| api | [env.api.example](env.api.example) |
| worker | [env.worker.example](env.worker.example) |
| worker-beat | Same as worker, `MODE=beat` |
| web | [env.web.example](env.web.example) |
| gateway | [env.gateway.example](env.gateway.example) |

## Storage

Use S3-compatible Railway bucket:

- `STORAGE_TYPE=s3`
- `S3_ADDRESS_STYLE=virtual` (common for Railway buckets)

Do not rely on local volumes for multi-service file sharing.
