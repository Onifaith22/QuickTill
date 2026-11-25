#!/usr/bin/env bash
# QuickTill health gate. Exits non-zero if any check fails.
# Used by CI (against local containers) and by the deploy workflow (against the staging slot)
# so the check that blocks a swap is the same one tested on every PR.
#
# Usage: scripts/health-check.sh <API_BASE_URL> [FRONTEND_URL]
# Example: scripts/health-check.sh http://localhost:5000 http://localhost:8080

set -euo pipefail

API="${1:?Usage: $0 <API_BASE_URL> [FRONTEND_URL]}"
WEB="${2:-}"
API="${API%/}"
fail=0

check() {
  local name="$1"; shift
  if "$@"; then echo "PASS  $name"; else echo "FAIL  $name"; fail=1; fi
}

# 1. Service is up and reports healthy
health_ok() { curl -fsS --max-time 5 "$API/health" | grep -q '"status":"healthy"'; }

# 2. Version endpoint answers (shows which release is running)
version_ok() { curl -fsS --max-time 5 "$API/version" | grep -q '"version"'; }

# 3. Real checkout code path works: 2 x Coffee (1500) must total 3000
checkout_ok() {
  curl -fsS --max-time 5 -X POST "$API/api/checkout" \
    -H 'Content-Type: application/json' \
    -d '{"items":[{"name":"Coffee","quantity":2}]}' | grep -q '"total":3000'
}

# 4. Bad input is rejected, not accepted
empty_basket_rejected() {
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 -X POST "$API/api/checkout" \
    -H 'Content-Type: application/json' -d '{"items":[]}')
  [ "$code" = "400" ]
}

# 5. Frontend is being served (optional)
frontend_ok() { curl -fsS --max-time 5 "$WEB/" | grep -qi '<div id="root">'; }

check "GET /health returns healthy"            health_ok
check "GET /version returns a version"         version_ok
check "POST /api/checkout totals correctly"    checkout_ok
check "POST /api/checkout rejects empty basket" empty_basket_rejected
[ -n "$WEB" ] && check "Frontend page is served" frontend_ok

if [ "$fail" -ne 0 ]; then
  echo "Health gate FAILED"
  exit 1
fi
echo "Health gate PASSED"
