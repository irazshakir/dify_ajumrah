#!/usr/bin/env bash
# Smoke test: POST /v1/chat-messages (blocking mode)
# Requires: DIFY_API_URL, DIFY_APP_API_KEY
# Optional: DIFY_USER (default smoke-test-user), QUERY as $1
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${ROOT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
  set +a
fi

DIFY_API_URL="${DIFY_API_URL:-}"
DIFY_APP_API_KEY="${DIFY_APP_API_KEY:-}"
DIFY_USER="${DIFY_USER:-smoke-test-user}"
QUERY="${1:-Hello from ajumrah-dify smoke test}"
CURL_INSECURE="${CURL_INSECURE:-0}"

if [[ -z "${DIFY_API_URL}" || -z "${DIFY_APP_API_KEY}" ]]; then
  echo "Set DIFY_API_URL and DIFY_APP_API_KEY (in .env or environment)." >&2
  echo "Example: DIFY_API_URL=https://dify.ajumrah.com/v1" >&2
  exit 1
fi

BASE="${DIFY_API_URL%/}"
URL="${BASE}/chat-messages"

CURL_OPTS=(-sS -w "\nHTTP_STATUS:%{http_code}\n" -X POST "${URL}" \
  -H "Authorization: Bearer ${DIFY_APP_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg q "${QUERY}" \
    --arg u "${DIFY_USER}" \
    '{inputs:{}, query: $q, response_mode: "blocking", user: $u}')")

if [[ "${CURL_INSECURE}" == "1" ]]; then
  CURL_OPTS=(-k "${CURL_OPTS[@]}")
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for smoke_test_chat.sh" >&2
  exit 1
fi

RESPONSE="$(curl "${CURL_OPTS[@]}")"
BODY="$(echo "${RESPONSE}" | sed '/^HTTP_STATUS:/d')"
STATUS="$(echo "${RESPONSE}" | grep '^HTTP_STATUS:' | cut -d: -f2)"

echo "${BODY}" | jq . 2>/dev/null || echo "${BODY}"

if [[ "${STATUS}" != "200" ]]; then
  echo "Smoke test FAILED (HTTP ${STATUS})" >&2
  exit 1
fi

ANSWER="$(echo "${BODY}" | jq -r '.answer // empty')"
if [[ -z "${ANSWER}" ]]; then
  echo "Smoke test FAILED: no answer field in response" >&2
  exit 1
fi

echo "---"
echo "Smoke test OK. Answer preview:"
echo "${ANSWER}" | head -c 500
echo ""
