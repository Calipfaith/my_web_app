#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <checkout_session_id> <bearer_token> [base_url]"
  echo "Example: $0 cs_test_123 eyJ... https://staging.frenzybees.com"
  exit 1
fi

SESSION_ID="$1"
BEARER_TOKEN="$2"
BASE_URL="${3:-https://staging.frenzybees.com}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="docs/planning/evidence"
VERIFY_FILE="${OUT_DIR}/checkout_verify_${SESSION_ID}_${TIMESTAMP}.json"
SUMMARY_FILE="${OUT_DIR}/checkout_evidence_${SESSION_ID}_${TIMESTAMP}.json"

mkdir -p "$OUT_DIR"

VERIFY_CODE=$(curl -sS \
  -H "Authorization: Bearer ${BEARER_TOKEN}" \
  -H "Content-Type: application/json" \
  -o "$VERIFY_FILE" \
  -w "%{http_code}" \
  -X POST \
  "${BASE_URL}/api/checkout-sessions/verify" \
  -d "{\"sessionId\":\"${SESSION_ID}\"}")

if [[ "$VERIFY_CODE" != "200" ]]; then
  echo "Checkout verification failed with HTTP ${VERIFY_CODE}."
  echo "Response saved to ${VERIFY_FILE}"
  exit 2
fi

if command -v jq >/dev/null 2>&1; then
  ORDER_ID="$(jq -r '.orderId // empty' "$VERIFY_FILE")"
else
  ORDER_ID="$(grep -o '"orderId"[[:space:]]*:[[:space:]]*"[^"]*"' "$VERIFY_FILE" | head -n 1 | sed -E 's/.*"orderId"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')"
fi

if [[ -z "$ORDER_ID" ]]; then
  echo "orderId not found in checkout verification response."
  echo "Response saved to ${VERIFY_FILE}"
  exit 3
fi

SETTLEMENT_FILE="${OUT_DIR}/settlement_${ORDER_ID}_${TIMESTAMP}.json"
SETTLEMENT_CODE=$(curl -sS \
  -H "Authorization: Bearer ${BEARER_TOKEN}" \
  -H "Accept: application/json" \
  -o "$SETTLEMENT_FILE" \
  -w "%{http_code}" \
  "${BASE_URL}/api/orders/${ORDER_ID}/settlement")

if [[ "$SETTLEMENT_CODE" != "200" ]]; then
  echo "Settlement lookup failed with HTTP ${SETTLEMENT_CODE}."
  echo "Checkout response: ${VERIFY_FILE}"
  echo "Settlement response: ${SETTLEMENT_FILE}"
  exit 4
fi

if command -v jq >/dev/null 2>&1; then
  jq -n \
    --arg sessionId "$SESSION_ID" \
    --arg orderId "$ORDER_ID" \
    --arg verifyFile "$VERIFY_FILE" \
    --arg settlementFile "$SETTLEMENT_FILE" \
    --slurpfile verify "$VERIFY_FILE" \
    --slurpfile settlement "$SETTLEMENT_FILE" \
    '{
      capturedAt: now | todate,
      sessionId: $sessionId,
      orderId: $orderId,
      files: {checkoutVerify: $verifyFile, settlement: $settlementFile},
      checkoutVerify: $verify[0],
      settlement: $settlement[0],
      acceptance: {
        hasLiveAttribution: ($settlement[0].hasLiveAttribution == true),
        hasSettlement: ($settlement[0].hasSettlement == true)
      }
    }' > "$SUMMARY_FILE"
else
  cat > "$SUMMARY_FILE" <<EOF
{
  "sessionId": "${SESSION_ID}",
  "orderId": "${ORDER_ID}",
  "checkoutVerifyFile": "${VERIFY_FILE}",
  "settlementFile": "${SETTLEMENT_FILE}"
}
EOF
fi

echo "Evidence captured:"
echo "  - ${VERIFY_FILE}"
echo "  - ${SETTLEMENT_FILE}"
echo "  - ${SUMMARY_FILE}"
if command -v jq >/dev/null 2>&1; then
  echo "Acceptance summary:"
  jq '{orderId, hasLiveAttribution: .acceptance.hasLiveAttribution, hasSettlement: .acceptance.hasSettlement}' "$SUMMARY_FILE"
fi
