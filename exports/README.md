# Dify exports

Store **Chatflow / Workflow DSL YAML** exports here after building apps in the Dify console.

## Naming convention

```text
exports/
  umrah-whatsapp-qualifier-<YYYY-MM-DD>.yml
```

Target app name: **Umrah WhatsApp Qualifier (Roman Urdu)**.

## How to export

1. Dify console → open the app → **Export DSL** (or equivalent in your Dify version).
2. Save the file into this folder.
3. Commit exports to git (no API keys inside DSL — review before commit).

## Do not export here

- Environment files with secrets
- Knowledge base document binaries (use Dify + object storage; document dataset IDs in [../docs/handoff_to_crm.md](../docs/handoff_to_crm.md))
