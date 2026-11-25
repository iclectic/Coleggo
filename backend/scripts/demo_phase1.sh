#!/usr/bin/env bash
# End-to-end Phase 1 demonstration against a running API.
set -euo pipefail

BASE_URL="${COLEGGO_API_BASE_URL:-http://127.0.0.1:3000}"
OUT="${1:-/tmp/coleggo_phase1_demo.txt}"

{
  echo "Coleggo Phase 1 function demonstration"
  echo "API: $BASE_URL"
  echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo

  echo "== health =="
  curl -sS "$BASE_URL/health"
  echo -e "\n"

  echo "== workplaces =="
  curl -sS "$BASE_URL/workplaces" | python3 -m json.tool | head -40
  echo

  WORKSITE_ID=$(curl -sS "$BASE_URL/workplaces" | python3 -c 'import json,sys; print(json.load(sys.stdin)["workplaces"][0]["worksites"][0]["id"])')
  SUFFIX=$(date +%s)

  echo "== register organiser =="
  ORG=$(curl -sS -X POST "$BASE_URL/auth/register" -H 'Content-Type: application/json' -d "{
    \"email\":\"demo.driver+$SUFFIX@northstar.example\",
    \"password\":\"Password123!\",
    \"firstName\":\"Dana\",
    \"initials\":\"DA\",
    \"worksiteId\":\"$WORKSITE_ID\",
    \"homeArea\":\"Solihull\",
    \"corridor\":\"Solihull to city centre\",
    \"days\":[1,3,5],
    \"arrivalMinutes\":510,
    \"departureMinutes\":1050,
    \"role\":\"driver\",
    \"availableSeats\":3,
    \"vehicleSummary\":\"Green hatchback\"
  }")
  echo "$ORG" | python3 -m json.tool | head -30
  ORG_TOKEN=$(echo "$ORG" | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])')
  echo

  echo "== register passenger =="
  PAS=$(curl -sS -X POST "$BASE_URL/auth/register" -H 'Content-Type: application/json' -d "{
    \"email\":\"demo.passenger+$SUFFIX@northstar.example\",
    \"password\":\"Password123!\",
    \"firstName\":\"Pat\",
    \"initials\":\"PA\",
    \"worksiteId\":\"$WORKSITE_ID\",
    \"homeArea\":\"Solihull\",
    \"corridor\":\"Solihull to city centre\",
    \"days\":[1,3,5],
    \"arrivalMinutes\":515,
    \"departureMinutes\":1045,
    \"role\":\"passenger\",
    \"availableSeats\":0
  }")
  PAS_TOKEN=$(echo "$PAS" | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])')
  echo "passenger registered"
  echo

  ORG_EMAIL="demo.driver+$SUFFIX@northstar.example"
  echo "== verify workplace =="
  curl -sS -X POST "$BASE_URL/auth/verify-workplace" \
    -H "Authorization: Bearer $ORG_TOKEN" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$ORG_EMAIL\"}" | python3 -m json.tool
  echo

  echo "== matches =="
  curl -sS "$BASE_URL/matches" -H "Authorization: Bearer $PAS_TOKEN" | python3 -m json.tool | head -50
  echo

  echo "== create circle via migrate =="
  curl -sS -X POST "$BASE_URL/auth/migrate" -H "Authorization: Bearer $ORG_TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"circles":[{"name":"Demo Solihull Circle","shiftLabel":"Early","days":[1,3,5],"departureWindow":"07:00-07:20","seats":3}]}' \
    | python3 -m json.tool | head -20
  echo

  CIRCLE_ID=$(curl -sS "$BASE_URL/circles" -H "Authorization: Bearer $PAS_TOKEN" | python3 -c '
import json,sys
circles=json.load(sys.stdin)["circles"]
wanted=next(c for c in circles if c["name"]=="Demo Solihull Circle")
print(wanted["id"])
')
  echo "circle=$CIRCLE_ID"

  echo "== join (idempotent) =="
  JOIN=$(curl -sS -X POST "$BASE_URL/circles/$CIRCLE_ID/join" \
    -H "Authorization: Bearer $PAS_TOKEN" -H 'Content-Type: application/json' \
    -H 'Idempotency-Key: demo-join-1' \
    -d '{"message":"Same corridor every Mon/Wed/Fri"}')
  echo "$JOIN" | python3 -m json.tool
  REQUEST_ID=$(echo "$JOIN" | python3 -c 'import json,sys; print(json.load(sys.stdin)["request"]["id"])')
  echo

  echo "== accept =="
  curl -sS -X POST "$BASE_URL/circles/$CIRCLE_ID/accept" \
    -H "Authorization: Bearer $ORG_TOKEN" -H 'Content-Type: application/json' \
    -H 'Idempotency-Key: demo-accept-1' \
    -d "{\"requestId\":\"$REQUEST_ID\"}" | python3 -m json.tool | head -20
  echo

  echo "== generate journeys + open confirmation windows =="
  curl -sS -X POST "$BASE_URL/jobs/generate-journeys" -H "Authorization: Bearer $ORG_TOKEN" | python3 -m json.tool
  curl -sS -X POST "$BASE_URL/jobs/advance-confirmation-windows" -H "Authorization: Bearer $ORG_TOKEN" | python3 -m json.tool
  echo

  echo "== next journey + confirm =="
  NEXT=$(curl -sS "$BASE_URL/journeys/next" -H "Authorization: Bearer $PAS_TOKEN")
  echo "$NEXT" | python3 -m json.tool | head -40
  JOURNEY_ID=$(echo "$NEXT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["journey"]["id"])')
  curl -sS -X POST "$BASE_URL/journeys/$JOURNEY_ID/confirm" \
    -H "Authorization: Bearer $PAS_TOKEN" -H 'Content-Type: application/json' \
    -H 'Idempotency-Key: demo-confirm-1' \
    -d '{"status":"travelling"}' | python3 -m json.tool
  echo

  echo "== cancel + backup candidates =="
  curl -sS -X POST "$BASE_URL/journeys/$JOURNEY_ID/cancel" \
    -H "Authorization: Bearer $ORG_TOKEN" -H 'Content-Type: application/json' \
    -H 'Idempotency-Key: demo-cancel-1' \
    -d '{"reason":"School run overrun"}' | python3 -m json.tool | head -40
  echo

  echo "== reliability + efficiency metrics =="
  curl -sS "$BASE_URL/reliability/me" -H "Authorization: Bearer $PAS_TOKEN" | python3 -m json.tool
  curl -sS "$BASE_URL/metrics/efficiency" -H "Authorization: Bearer $ORG_TOKEN" | python3 -m json.tool
  echo

  echo "Completed: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "PHASE1_DEMO_OK"
} | tee "$OUT"
