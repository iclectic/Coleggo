#!/usr/bin/env bash
# Phase 3 smoke demo: audit events, capacity hints, export, legal hold, retention.
set -euo pipefail
BASE_URL="${BASE_URL:-http://127.0.0.1:3000}"

echo "== health =="
curl -sS "$BASE_URL/health"; echo

echo "== login asha =="
LOGIN=$(curl -sS -X POST "$BASE_URL/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"asha@northstar.example","password":"Password123!"}')
TOKEN=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' <<<"$LOGIN")
USER_ID=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["user"]["id"])' <<<"$LOGIN")

echo "== efficiency capacity hints =="
curl -sS "$BASE_URL/metrics/efficiency" -H "Authorization: Bearer $TOKEN"; echo

echo "== slo =="
curl -sS "$BASE_URL/metrics/slo" -H "Authorization: Bearer $TOKEN"; echo

echo "== export =="
curl -sS "$BASE_URL/auth/export" -H "Authorization: Bearer $TOKEN" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print({k:d[k] if k!="auditEvents" else len(d[k]) for k in ["exportedAt","user"]}); print("auditEvents", len(d.get("auditEvents",[])))'

echo "== apply retention =="
curl -sS -X POST "$BASE_URL/jobs/apply-retention" -H "Authorization: Bearer $TOKEN"; echo

echo "== Phase 3 demo complete (user=$USER_ID) =="
