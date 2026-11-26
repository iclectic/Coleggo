#!/usr/bin/env bash
# Phase 2 smoke demo: invites, messaging, organiser pause/resume, corridor density.
set -euo pipefail
BASE_URL="${BASE_URL:-http://127.0.0.1:3000}"

echo "== health =="
curl -sS "$BASE_URL/health"
echo

echo "== redeem invitation NORTH-PILOT =="
curl -sS -X POST "$BASE_URL/auth/redeem-invite" \
  -H 'Content-Type: application/json' \
  -d '{"invitationCode":"NORTH-PILOT"}'
echo

echo "== login asha =="
LOGIN=$(curl -sS -X POST "$BASE_URL/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"asha@northstar.example","password":"Password123!"}')
TOKEN=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' <<<"$LOGIN")
echo "accessToken acquired"

CIRCLE=$(curl -sS "$BASE_URL/circles" -H "Authorization: Bearer $TOKEN" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["circles"][0]["id"])')
echo "circle=$CIRCLE"

echo "== send message =="
curl -sS -X POST "$BASE_URL/circles/$CIRCLE/messages" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"body":"See you at the usual pick-up."}'
echo

echo "== pause circle =="
curl -sS -X POST "$BASE_URL/circles/$CIRCLE/pause" \
  -H "Authorization: Bearer $TOKEN"
echo

echo "== resume circle =="
curl -sS -X POST "$BASE_URL/circles/$CIRCLE/resume" \
  -H "Authorization: Bearer $TOKEN"
echo

echo "== efficiency metrics (corridor density) =="
curl -sS "$BASE_URL/metrics/efficiency" -H "Authorization: Bearer $TOKEN"
echo
echo "== Phase 2 demo complete =="
