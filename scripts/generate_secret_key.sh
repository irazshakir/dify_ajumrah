#!/usr/bin/env bash
# Generate a Dify SECRET_KEY (32 bytes hex). Use once per environment; store in Railway Shared Variables.
set -euo pipefail

if command -v openssl >/dev/null 2>&1; then
  openssl rand -hex 32
else
  echo "openssl not found. On Windows PowerShell: -join ((1..32 | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) }))" >&2
  exit 1
fi
