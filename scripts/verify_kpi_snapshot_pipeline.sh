#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 3 ]]; then
  echo "Usage: $0 <bearer_token> [base_url] [region]"
  echo "Example: $0 eyJ... https://staging.frenzybees.com ap-southeast-1"
  exit 1
fi

BEARER_TOKEN="$1"
BASE_URL="${2:-https://staging.frenzybees.com}"
REGION="${3:-ap-southeast-1}"
TABLE_NAME="${KPI_SNAPSHOTS_TABLE:-frenzybees-staging-kpi-snapshots}"
OUT_DIR="docs/planning/evidence"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="${OUT_DIR}/kpi_snapshot_pipeline_${TIMESTAMP}.json"

mkdir -p "$OUT_DIR"

before_count=$(aws dynamodb scan \
  --table-name "$TABLE_NAME" \
  --select COUNT \
  --region "$REGION" \
  --query 'Count' \
  --output text)

partner_file="${OUT_DIR}/kpi_partner_${TIMESTAMP}.json"
admin_file="${OUT_DIR}/kpi_admin_${TIMESTAMP}.json"
investor_file="${OUT_DIR}/kpi_investor_${TIMESTAMP}.json"

for endpoint in partner admin investor; do
  target_file="${OUT_DIR}/kpi_${endpoint}_${TIMESTAMP}.json"
  http_code=$(curl -sS \
    -H "Authorization: Bearer ${BEARER_TOKEN}" \
    -H "Accept: application/json" \
    -o "$target_file" \
    -w "%{http_code}" \
    "${BASE_URL}/api/kpis/${endpoint}")
  if [[ "$http_code" != "200" ]]; then
    echo "KPI endpoint /api/kpis/${endpoint} failed with HTTP ${http_code}."
    echo "Response captured at ${target_file}"
    exit 2
  fi
done

after_count=$(aws dynamodb scan \
  --table-name "$TABLE_NAME" \
  --select COUNT \
  --region "$REGION" \
  --query 'Count' \
  --output text)

delta=$((after_count - before_count))

if command -v jq >/dev/null 2>&1; then
  jq -n \
    --arg timestamp "$TIMESTAMP" \
    --arg table "$TABLE_NAME" \
    --argjson before "$before_count" \
    --argjson after "$after_count" \
    --argjson delta "$delta" \
    --slurpfile partner "$partner_file" \
    --slurpfile admin "$admin_file" \
    --slurpfile investor "$investor_file" \
    '{
      capturedAt: $timestamp,
      table: $table,
      snapshotCountBefore: $before,
      snapshotCountAfter: $after,
      snapshotDelta: $delta,
      acceptance: {
        snapshotPersisted: ($delta >= 1),
        partnerTrendAvailable: ((($partner[0].fulfilledOrdersTrend // []) | length) > 0),
        adminTrendAvailable: ((($admin[0].gmvTrend // []) | length) > 0),
        investorTrendAvailable: ((($investor[0].settlementRateTrend // []) | length) > 0)
      },
      partner: $partner[0],
      admin: $admin[0],
      investor: $investor[0]
    }' > "$OUT_FILE"
else
  cat > "$OUT_FILE" <<EOF
{
  "capturedAt": "$TIMESTAMP",
  "table": "$TABLE_NAME",
  "snapshotCountBefore": $before_count,
  "snapshotCountAfter": $after_count,
  "snapshotDelta": $delta,
  "partnerFile": "$partner_file",
  "adminFile": "$admin_file",
  "investorFile": "$investor_file"
}
EOF
fi

echo "Verification evidence saved to ${OUT_FILE}"
echo "Snapshot count before: ${before_count}"
echo "Snapshot count after: ${after_count}"
echo "Snapshot delta: ${delta}"

if command -v jq >/dev/null 2>&1; then
  echo "Acceptance summary:"
  jq '.acceptance' "$OUT_FILE"
fi
