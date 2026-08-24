#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <order_id> <bearer_token> [base_url]"
  echo "Example: $0 9f5c-order-id eyJ... https://staging.frenzybees.com"
  exit 1
fi

ORDER_ID="$1"
BEARER_TOKEN="$2"
BASE_URL="${3:-https://staging.frenzybees.com}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="docs/planning/evidence"
OUT_FILE="${OUT_DIR}/settlement_${ORDER_ID}_${TIMESTAMP}.json"

mkdir -p "$OUT_DIR"

HTTP_CODE=$(curl -sS \
  -H "Authorization: Bearer ${BEARER_TOKEN}" \
  -H "Accept: application/json" \
  -o "$OUT_FILE" \
  -w "%{http_code}" \
  "${BASE_URL}/api/orders/${ORDER_ID}/settlement")

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "Request failed with HTTP ${HTTP_CODE}. Response saved to ${OUT_FILE}"
  exit 2
fi

echo "Evidence captured: ${OUT_FILE}"
if command -v jq >/dev/null 2>&1; then
  echo "Summary:"
  jq '{orderId, status, sessionId, hostId, hasLiveAttribution, hasSettlement}' "$OUT_FILE"
fi
