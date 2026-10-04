# ajumrah-dify — Self-hosted Dify on Railway

Standalone infrastructure repo for deploying **Dify Community Edition** on [Railway](https://railway.com), with **PostgreSQL + pgvector on a dedicated Supabase project** (not the CRM database).

## What this repo is

- Deploy runbooks, env templates, and smoke-test scripts for Dify
- A place to store Chatflow DSL exports later (`exports/`)
- CRM handoff notes for [projectX](../) integration

## What this repo is not

- Haulers Track / CRM application code
- WhatsApp webhooks, Gupshup, or per-tenant LLM keys
- `llm-proxy`, package tools, or Roman Urdu chatbot logic (those live in CRM / projectX)

## Prerequisites

- GitHub account and a new repo (suggested name: `ajumrah-dify` or `dify-railway`)
- [Railway](https://railway.com) account (separate project from CRM)
- **New** Supabase project dedicated to Dify — see [docs/supabase_setup.md](docs/supabase_setup.md)
- Temporary LLM provider API key for smoke testing only (Settings → Model Providers in Dify)
- Custom domain optional: `dify.ajumrah.com`

## Quick start

1. Push this repo to GitHub.
2. Follow [docs/supabase_setup.md](docs/supabase_setup.md) (pgvector extension, connection strings in Railway only).
3. Follow [docs/railway_deploy.md](docs/railway_deploy.md) (Railway **Dify Production** template + external Supabase + Redis/bucket).
4. Complete first admin setup and run smoke tests below.
5. Fill [docs/handoff_to_crm.md](docs/handoff_to_crm.md) and copy values into projectX (secrets stay in Railway).

**Pinned images (verify on [Docker Hub](https://hub.docker.com/u/langgenius) before upgrade):**

| Service | Image (example pin) |
|---------|---------------------|
| api / worker / worker-beat | `langgenius/dify-api:1.4.3` |
| web | `langgenius/dify-web:1.4.3` |

Adjust version tags together when upgrading — see [docs/operations.md](docs/operations.md).

## Deploy checklist

Use this after Railway services are created and env vars are set.

- [ ] Dedicated Supabase project created; `create extension vector` applied
- [ ] Railway project connected to this GitHub repo (docs/config source of truth)
- [ ] Dify services up: gateway (public), api, worker, worker-beat, web, redis, sandbox, ssrf-proxy, plugin-daemon
- [ ] `VECTOR_STORE=pgvector` and `DB_*` / `PGVECTOR_*` point at Supabase **direct** host
- [ ] S3-compatible storage configured (Railway bucket recommended; not local-only across services)
- [ ] Public URL loads Dify console; first admin account created
- [ ] Temporary model provider key added (smoke test only)
- [ ] Trivial Chatflow created; app API key issued
- [ ] `scripts/smoke_test_chat.sh` returns a successful assistant reply
- [ ] One FAQ uploaded to Knowledge; retrieval verified in app or logs
- [ ] Custom domain `dify.ajumrah.com` attached (optional until stable)
- [ ] [docs/handoff_to_crm.md](docs/handoff_to_crm.md) updated with URLs/IDs (no secrets in git)

## Scripts

```bash
# Generate SECRET_KEY (also works in Git Bash on Windows)
./scripts/generate_secret_key.sh

# Chat smoke test (requires DIFY_API_URL, DIFY_APP_API_KEY in .env or env)
./scripts/smoke_test_chat.sh "Hello from smoke test"
```

On Windows without Bash, run the OpenSSL one-liner in [scripts/generate_secret_key.sh](scripts/generate_secret_key.sh) or use Railway’s variable generator.

## Documentation map

| Doc | Purpose |
|-----|---------|
| [docs/railway_deploy.md](docs/railway_deploy.md) | GitHub → Railway, services, env wiring |
| [docs/supabase_setup.md](docs/supabase_setup.md) | Dify-only database + pgvector |
| [docs/operations.md](docs/operations.md) | Domains, upgrades, backups, logs |
| [docs/handoff_to_crm.md](docs/handoff_to_crm.md) | Values for projectX / CRM Railway |
| [railway/services.md](railway/services.md) | Service topology reference |
| [CURSOR_PROMPT.md](CURSOR_PROMPT.md) | Original bootstrap brief |

## After Dify is live

Return to **projectX** and continue Phase 2+ in `docs/dify_whatsapp_rag_implementation_plan.md` (BYOK, turn adapter, tools, llm-proxy, Roman Urdu Chatflow).
