# Dify Railway Deploy Repo — Bootstrap Prompt (copy this file OUT of projectX)

> **How to use**
>
> 1. Outside `projectX`, create a new folder (example: `d:\projects\ajumrah-dify`).
> 2. Copy **this entire file** into that folder as `CURSOR_PROMPT.md` (or paste it into a new Cursor chat as the project brief).
> 3. Open that folder in Cursor and ask the agent: *“Follow CURSOR_PROMPT.md and scaffold + document the Dify Railway GitHub deploy.”*
> 4. When Dify is live and smoke-tested, copy the **Handoff values** section back into projectX and continue chatbot work there using `docs/dify_whatsapp_rag_implementation_plan.md`.

---

## Who you are / what this repo is

You are setting up a **standalone GitHub repo** whose only job is to deploy **self-hosted Dify Community Edition** on **Railway**, with **Postgres + pgvector on a dedicated Supabase project** (not the CRM database).

This repo must **NOT** contain:

- The Haulers Track / projectX CRM code
- Per-tenant WhatsApp or CRM package logic
- Per-tenant LLM API keys (those live in CRM later via BYOK + llm-proxy)

This repo **SHOULD** contain:

- Infra-as-code / env templates / Railway service docs
- Scripts and checklists to deploy and operate Dify
- A Chatflow export placeholder folder for later
- Clear handoff notes for the CRM team

Official images (pin versions in docs when you choose them):

- `langgenius/dify-api`
- `langgenius/dify-web`
- Plus worker/beat/sandbox/plugin/gateway as required by the Railway Dify production topology you adopt

Reference: [Railway Dify guide](https://docs.railway.com/guides/dify) and Railway “Deploy Dify Production” template.

---

## Product context (do not implement CRM here)

CRM (separate repo / projectX) will later:

1. Receive WhatsApp via Gupshup
2. Call Dify Chatflow API (`/v1/chat-messages`)
3. Expose package tools + an OpenAI-compatible **llm-proxy** so each CRM tenant uses **their own** LLM key

For **this** repo’s smoke-test only, a temporary platform LLM key in Dify console is OK. Production tenant traffic must **not** depend on that key long-term.

Target public URL example: `https://dify.ajumrah.com`  
CRM remains: `https://crm.ajumrah.com` / `https://app.ajumrah.com`

---

## Goal for the Cursor agent in THIS folder

Create a clean git repo that a human can connect to Railway from GitHub and bring Dify up. Prefer **documented, repeatable deploy** over inventing a full fork of the Dify application source.

### Preferred approach (in order)

1. **Primary:** Repo documents + config for Railway multi-service deploy using official Docker images, with Postgres pointing at **external Supabase** (`VECTOR_STORE=pgvector`).
2. **OK:** Use Railway one-click Dify template first, then commit into this repo the exact env var names, service list, and operational runbook that match what was deployed (so it is reproducible).
3. **Avoid:** Cloning the entire `langgenius/dify` monorepo into this project unless absolutely required for a pinned custom patch (not needed for v1).

---

## Target repo layout (create these)

Create the following structure (adjust only if Railway tooling requires it; keep it thin):

```text
.
├── README.md                 # Human deploy guide (from this prompt)
├── CURSOR_PROMPT.md          # This file (keep a copy)
├── .gitignore
├── .env.example              # All required vars; NO real secrets
├── docs/
│   ├── railway_deploy.md     # Step-by-step Railway + GitHub
│   ├── supabase_setup.md     # Dedicated Dify DB + pgvector
│   ├── operations.md         # Upgrades, backups, logs, domains
│   └── handoff_to_crm.md     # Values projectX needs
├── railway/
│   ├── services.md           # Service list, images, MODE, public/private
│   ├── env.api.example
│   ├── env.worker.example
│   ├── env.web.example
│   └── env.gateway.example   # if using nginx/caddy gateway
├── scripts/
│   ├── generate_secret_key.sh    # openssl rand -hex 32
│   └── smoke_test_chat.sh        # curl /v1/chat-messages example
└── exports/
    └── README.md             # Later: Dify Chatflow DSL exports
```

If you add `docker-compose.yml` for **local** smoke only, mark it clearly as local-dev, not the Railway source of truth.

---

## Phase A — Git repo bootstrap

Do this first in the new folder:

1. `git init` (if not already a repo).
2. Create `.gitignore` ignoring `.env`, `*.pem`, local storage, IDE junk.
3. Create all folders/files listed above with real content (not empty stubs).
4. Write `README.md` with:
   - What this repo is / is not
   - Prerequisites
   - Link to `docs/railway_deploy.md`
   - Handoff pointer to `docs/handoff_to_crm.md`
5. Commit: `chore: scaffold Dify Railway deploy repo`

Suggested GitHub repo name: `ajumrah-dify` or `dify-railway`.

---

## Phase B — Supabase (Dify database only)

Document and execute (human may create the Supabase project; agent writes the checklist):

1. Create a **new** Supabase project dedicated to Dify (never reuse CRM DB).
2. Enable extension:

   ```sql
   create extension if not exists vector;
   ```

3. Prefer **direct / session** connection string for Dify API + workers (avoid transaction pooler for long-lived workers).
4. Record in `docs/supabase_setup.md`:
   - Host, port, database, user
   - That password lives only in Railway secrets
   - `VECTOR_STORE=pgvector` requirement
5. Do **not** commit real connection strings.

---

## Phase C — Railway project via GitHub

### C1 — Create Railway project

1. New Railway project (separate from CRM).
2. Connect this GitHub repo (even if services are mostly Docker images — the repo holds config/docs; image-based services can still be defined/documented here).
3. Prefer private networking between Dify services; only expose the public gateway / web entry.

### C2 — Services to provision

Document and configure at minimum (match Railway Dify production template if available):

| Service | Image / role | Public? |
|---------|----------------|---------|
| gateway (nginx/caddy) | Public routing to API/web | Yes (custom domain) |
| api | `langgenius/dify-api`, `MODE=api` | Via gateway |
| worker | `langgenius/dify-api`, `MODE=worker` | No |
| worker-beat | `langgenius/dify-api`, `MODE=beat` (if used) | No |
| web | `langgenius/dify-web` | Via gateway |
| redis | Railway Redis | No |
| sandbox / plugin-daemon / ssrf-proxy | Per production template | No |

**Postgres:** use **Supabase**, not Railway Postgres, unless temporary. Document how `DB_*` vars point to Supabase.

**Storage:** prefer S3-compatible / Railway bucket for shared API+worker files. If using local volumes, document the Railway limitation that volumes are not shared across services.

### C3 — Core environment variables

Put complete examples under `railway/*.example`. Include at least:

**API + worker (shared secrets):**

- `MODE` = `api` | `worker` | `beat`
- `SECRET_KEY` = random (`openssl rand -hex 32`)
- `DB_HOST` / `DB_PORT` / `DB_USERNAME` / `DB_PASSWORD` / `DB_DATABASE` → Supabase
- `VECTOR_STORE=pgvector` (and any template-specific vector settings)
- Redis host/port/password
- `STORAGE_TYPE` and object-storage settings if not local
- `CONSOLE_API_URL` / `APP_API_URL` / `SERVICE_API_URL` as required by your Dify version
- CORS / web URL vars pointing at `https://dify.ajumrah.com` (or Railway preview URL first)

**Web:**

- `CONSOLE_API_URL`
- `APP_API_URL`

Never commit real secrets. Document Shared Variables vs per-service vars in `docs/railway_deploy.md`.

### C4 — Domain

1. First bring-up: Railway-generated domains OK.
2. Then attach custom domain `dify.ajumrah.com` to the public gateway (or web, if no gateway).
3. Document DNS (CNAME) steps in `docs/operations.md`.

### C5 — First admin + smoke test

1. Open Dify console → create first admin.
2. Settings → Model Providers → add **temporary** smoke-test LLM key (any supported provider).
3. Create a trivial Chatflow that echoes input.
4. Create an API key for the app.
5. Run `scripts/smoke_test_chat.sh` against `/v1/chat-messages`.
6. Upload one sample FAQ to a Knowledge dataset; confirm retrieval.

Checklist in README must be tickable.

---

## Phase D — Document CRM handoff (critical)

Fill `docs/handoff_to_crm.md` with placeholders the human will complete after deploy:

```markdown
## Handoff to projectX (CRM)

Copy these into CRM Railway / `infra/railway/dify.env.example` (values only in secrets):

- DIFY_PUBLIC_URL=
- DIFY_API_URL=          # e.g. https://dify.ajumrah.com/v1
- DIFY_APP_ID=
- DIFY_API_KEY=
- DIFY_WORKSPACE_NOTES=  # which workspace/app is for Umrah WhatsApp bot

### Model provider (after CRM llm-proxy exists)

- Switch Dify model provider Base URL to:
  https://crm.ajumrah.com/api/v1/chatbot/llm-proxy/v1
- Remove reliance on the temporary platform LLM key for tenant traffic.

### Do not put in Dify long-term

- Per-tenant OpenAI/Gemini/Groq/Grok keys (CRM `tenant_settings` owns those)
- CRM database credentials
- Gupshup WhatsApp secrets
```

Also list:

- Exact Chatflow app name to create later: e.g. `Umrah WhatsApp Qualifier (Roman Urdu)`
- That package tools will call CRM `https://crm.ajumrah.com/api/v1/chatbot/tools/*` (implemented in projectX, not here)

---

## Phase E — What NOT to build in this repo

- No FastAPI chatbot turn adapter
- No WhatsApp webhooks
- No `tenant_settings` / llm-proxy
- No Umrah package calculator
- No frontend CRM pages

When those are needed, stop and tell the human: **return to projectX** and follow `dify_whatsapp_rag_implementation_plan.md` Phase 2+.

---

## Acceptance criteria (this repo is “done” when)

- [ ] GitHub repo exists with the layout above
- [ ] Railway project deploys Dify from documented process
- [ ] Dify uses dedicated Supabase Postgres with `pgvector`
- [ ] Public URL loads console; admin can log in
- [ ] `/v1/chat-messages` smoke test succeeds
- [ ] Knowledge upload/retrieval smoke test succeeds
- [ ] `docs/handoff_to_crm.md` filled with real URLs/IDs (keys stored as Railway secrets, not committed)
- [ ] README explains how to upgrade Dify image versions safely

---

## Suggested commit messages

- `chore: scaffold Dify Railway deploy repo`
- `docs: add Supabase pgvector and Railway service env templates`
- `docs: add smoke test script and CRM handoff checklist`

---

## After this repo is done — human next step

1. Keep this Dify repo for infra only.
2. Open **projectX** again.
3. Continue from Phase 2 in `docs/dify_whatsapp_rag_implementation_plan.md`:
   - `tenant_settings` BYOK
   - `backend/services/chatbot` turn adapter + tools + llm-proxy
   - Point Dify model provider at CRM llm-proxy
   - Build Roman Urdu Chatflow + hybrid catalog/custom tools

---

## Agent execution rules

- Write only what this prompt asks; do not invent CRM features.
- Prefer official `langgenius/*` images; pin versions in docs.
- Never commit API keys, DB passwords, or `.env` files with secrets.
- If Railway UI steps cannot be automated, write exact click-path instructions.
- If a choice is required (template vs manual services), pick the **Railway Dify production template + external Supabase**, document deviations, and continue.
- End with a short “Handoff summary” listing URLs created and which file the human should open next in projectX.
