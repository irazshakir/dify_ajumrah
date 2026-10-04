# Handoff to projectX (CRM)

Complete this file **after** Dify is deployed and smoke-tested. Store secrets in **Railway** and CRM Railway — **never** commit API keys or DB passwords to git.

Copy the values below into CRM / projectX (e.g. `infra/railway/dify.env.example` in projectX — values only in secret stores).

---

## Required values

| Key | Value (fill after deploy) |
|-----|---------------------------|
| `DIFY_PUBLIC_URL` | e.g. `https://dify.ajumrah.com` |
| `DIFY_API_URL` | e.g. `https://dify.ajumrah.com/v1` |
| `DIFY_APP_ID` | UUID from Dify app **API Access** or app settings |
| `DIFY_API_KEY` | App API key (`app-...`) — **Railway/CRM secret only** |
| `DIFY_WORKSPACE_NOTES` | Which workspace/app is for Umrah WhatsApp bot |

### Template (paste into CRM env)

```env
DIFY_PUBLIC_URL=
DIFY_API_URL=
DIFY_APP_ID=
DIFY_API_KEY=
DIFY_WORKSPACE_NOTES=
```

---

## Chatflow to build in Dify (later, may start in projectX)

- **App name (target):** `Umrah WhatsApp Qualifier (Roman Urdu)`
- **Type:** Chatflow (not Agent for v1 unless plan changes)
- **Model provider (production):** point Base URL at CRM llm-proxy (below), not a shared platform key

---

## Model provider (after CRM llm-proxy exists)

Switch Dify **Settings → Model Providers** (OpenAI-compatible provider) to:

```text
Base URL: https://crm.ajumrah.com/api/v1/chatbot/llm-proxy/v1
```

- CRM `tenant_settings` holds per-tenant LLM keys (BYOK).
- Remove reliance on the **temporary** smoke-test platform LLM key for tenant traffic.

---

## Package tools (implemented in projectX, not this repo)

Dify tools / HTTP nodes will call CRM:

```text
https://crm.ajumrah.com/api/v1/chatbot/tools/*
```

Examples (names may match projectX plan):

- Package catalog / pricing
- Availability / qualifiers
- Handoff to human agent

Authenticate per projectX design (service token, HMAC, etc.) — document in CRM, not here.

---

## Do not put in Dify long-term

- Per-tenant OpenAI / Gemini / Groq / Grok API keys (CRM `tenant_settings` owns those)
- CRM database credentials
- Gupshup WhatsApp secrets
- CRM admin JWTs or user PII exports

---

## Smoke test evidence (optional checklist)

- [ ] `scripts/smoke_test_chat.sh` succeeded against `DIFY_API_URL`
- [ ] Knowledge FAQ upload + retrieval verified
- [ ] Gateway custom domain TLS OK
- [ ] Temporary LLM key documented as **remove after llm-proxy**

---

## Next step in projectX

Open projectX and continue **Phase 2+** in `docs/dify_whatsapp_rag_implementation_plan.md`:

1. `tenant_settings` BYOK
2. `backend/services/chatbot` turn adapter + tools + **llm-proxy**
3. Point Dify model provider at CRM llm-proxy
4. Build Roman Urdu Chatflow + hybrid catalog/custom tools
5. Wire Gupshup WhatsApp → CRM → Dify `/v1/chat-messages`
