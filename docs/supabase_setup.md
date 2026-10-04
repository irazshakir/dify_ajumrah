# Supabase setup (Dify database only)

Use a **new Supabase project** for Dify. Do **not** reuse the CRM / Haulers Track database.

## 1. Create project

1. [Supabase Dashboard](https://supabase.com/dashboard) → **New project**.
2. Choose region close to Railway (e.g. US East / EU West — match CRM latency goals).
3. Save the database password in a password manager; you will paste it only into **Railway secrets**, never into this repo.

Suggested project name: `ajumrah-dify` or `dify-pgvector`.

## 2. Enable pgvector

In **SQL Editor**, run:

```sql
create extension if not exists vector;
```

Verify:

```sql
select extname, extversion from pg_extension where extname = 'vector';
```

## 3. Connection strings (what Dify needs)

Dify API and workers use long-lived connections. Prefer the **direct** (session) Postgres host:

- Supabase → **Project Settings** → **Database** → **Connection string** → **URI** or **Session mode**
- Host looks like: `db.<project-ref>.supabase.co`
- Port: `5432`
- Database: `postgres` (default) unless you created a dedicated DB name
- User: `postgres` (default)

**Avoid** the transaction pooler (`pooler.supabase.com`, port `6543`) for API/worker/beat services — it can break migrations and long Celery tasks.

Record for yourself (not in git):

| Field | Example / notes |
|-------|-----------------|
| Host | `db.xxxx.supabase.co` |
| Port | `5432` |
| Database | `postgres` |
| User | `postgres` |
| Password | Railway secret only |

## 4. Railway mapping

Set the same Supabase host for both relational and vector settings:

```bash
VECTOR_STORE=pgvector

DB_HOST=db.xxxx.supabase.co
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=<Railway secret>
DB_DATABASE=postgres

PGVECTOR_HOST=db.xxxx.supabase.co
PGVECTOR_PORT=5432
PGVECTOR_USER=postgres
PGVECTOR_PASSWORD=<same as DB_PASSWORD>
PGVECTOR_DATABASE=postgres
```

Apply these on **api**, **worker**, and **worker-beat** (shared variables recommended).

## 5. Network access

Supabase free/pro projects accept connections from the public internet when using the direct host. Restrict IP allowlists if your Supabase plan supports it; otherwise rely on strong passwords and Railway-only secret storage.

Optional: Supabase **Network Restrictions** → allow Railway egress IPs if you document stable IPs (Railway may vary — check current Railway docs).

## 6. Migrations and schema

Dify runs migrations on the API service when `MIGRATION_ENABLED=true` (typical production template). First deploy may take several minutes while tables and indexes are created on Supabase.

## 7. Backups

- Enable Supabase **Point-in-time recovery** / backups per your plan.
- Document restore drill in [operations.md](operations.md).
- This repo does not store dumps; export via Supabase dashboard or `pg_dump` using credentials from Railway.

## 8. Security checklist

- [ ] Project is separate from CRM Supabase
- [ ] `vector` extension enabled
- [ ] Password only in Railway (Shared Variable or secret reference)
- [ ] No connection string committed to GitHub
- [ ] CRM credentials never used here

## 9. When something fails

| Symptom | Likely cause |
|---------|----------------|
| Migration timeout | Pooler URL used instead of direct host |
| Vector / RAG errors | `vector` extension missing or `VECTOR_STORE` not `pgvector` |
| SSL errors | Ensure Dify/your driver uses SSL to Supabase (default for cloud) |

Next: [railway_deploy.md](railway_deploy.md)
