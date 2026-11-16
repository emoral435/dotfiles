#!/usr/bin/env bash
# Collect Datadog monitors and SLOs the user created or changed in a window.
# Fail-soft: with no credentials it prints {"skipped":true} and exits 0 so the
# recap still runs. Usage: datadog.sh [WEEKS]
# Env: DD_API_KEY, DD_APP_KEY required; DD_SITE (default datadoghq.com),
#      DD_USER_EMAIL (default: git config user.email) optional.
set -euo pipefail

WEEKS="${1:-1}"
SITE="${DD_SITE:-datadoghq.com}"
EMAIL="${DD_USER_EMAIL:-$(git config user.email 2>/dev/null || true)}"

if [ -z "${DD_API_KEY:-}" ] || [ -z "${DD_APP_KEY:-}" ]; then
  jq -n '{skipped: true, reason: "DD_API_KEY and DD_APP_KEY not set"}'
  exit 0
fi

if date -v-1d >/dev/null 2>&1; then
  SINCE_EPOCH=$(date -v-"${WEEKS}"w +%s)
  SINCE_ISO=$(date -u -v-"${WEEKS}"w +%Y-%m-%dT%H:%M:%S)
else
  SINCE_EPOCH=$(date -d "-${WEEKS} weeks" +%s)
  SINCE_ISO=$(date -u -d "-${WEEKS} weeks" +%Y-%m-%dT%H:%M:%S)
fi

BASE="https://api.${SITE}"
auth=(-H "DD-API-KEY: ${DD_API_KEY}" -H "DD-APPLICATION-KEY: ${DD_APP_KEY}")

monitors_raw=$(curl -fsS "${auth[@]}" "${BASE}/api/v1/monitor" 2>/dev/null || echo '[]')
slos_raw=$(curl -fsS "${auth[@]}" "${BASE}/api/v1/slo?limit=1000" 2>/dev/null || echo '{"data":[]}')

# Monitors: mine, changed in window. ISO strings sort lexically in UTC.
monitors=$(echo "$monitors_raw" | jq --arg me "$EMAIL" --arg since "$SINCE_ISO" '
  [ .[]? | select((.creator.email // "") == $me)
          | select(((.modified // "")[0:19]) >= $since)
          | {id, name, type, created, modified, tags,
             url: ("https://app.'"$SITE"'/monitors/" + (.id|tostring))} ]' 2>/dev/null || echo '[]')

# SLOs: mine, modified in window. modified_at is epoch seconds.
slos=$(echo "$slos_raw" | jq --arg me "$EMAIL" --argjson since "$SINCE_EPOCH" '
  [ (.data // [])[] | select((.creator.email // "") == $me)
                    | select((.modified_at // 0) >= $since)
                    | {id, name, type, created_at, modified_at,
                       url: ("https://app.'"$SITE"'/slo?slo_id=" + (.id|tostring))} ]' 2>/dev/null || echo '[]')

jq -n --arg site "$SITE" --arg since "$SINCE_ISO" \
  --argjson monitors "$monitors" --argjson slos "$slos" \
  '{skipped: false, site: $site, since: $since,
    monitors: $monitors, slos: $slos,
    counts: {monitors: ($monitors|length), slos: ($slos|length)}}'
