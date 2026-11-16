#!/usr/bin/env bash
# Collect the user's MERGED authored PRs in a time window.
# Merged-only, authored-only: no reviewed PRs, no commits (those made the run slow).
# Usage: github.sh [WEEKS] [ORG]   (no ORG: every owner; or set WORK_LOG_GH_ORG)
set -euo pipefail

WEEKS="${1:-1}"
ORG="${2:-${WORK_LOG_GH_ORG:-}}"

if ! [[ "$WEEKS" =~ ^[0-9]+$ ]] || [ "$WEEKS" -lt 1 ]; then
  echo "WEEKS must be a positive integer" >&2
  exit 2
fi

# Date math across macOS (`date -v`) and GNU (`date -d`).
shift_date() { # shift_date <weeks-ago>
  if date -v-1d >/dev/null 2>&1; then
    date -v-"$1"w +%Y-%m-%d
  else
    date -d "-$1 weeks" +%Y-%m-%d
  fi
}

SINCE=$(shift_date "$WEEKS")
TODAY=$(date +%Y-%m-%d)
ME=$(gh api user --jq .login)

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export ENRICH_DIR="$tmp"

# Search has no additions/deletions/mergedAt, so enrich each PR. One file per PR
# avoids interleaved writes when xargs runs enrichment in parallel.
enrich_one() {
  local ref="$1" repo num
  repo="${ref%%#*}"; num="${ref##*#}"
  gh pr view "$num" -R "$repo" \
    --json number,title,url,state,mergedAt,author,body,labels,headRefName,additions,deletions \
    2>/dev/null | jq -c --arg ref "$ref" '{
      ref: $ref, title, url, state, mergedAt,
      author: .author.login,
      branch: .headRefName,
      labels: [.labels[].name],
      additions, deletions,
      body: (.body // "" | .[0:2500])
    }' > "$ENRICH_DIR/${repo//\//_}_${num}.json" 2>/dev/null || true
}
export -f enrich_one

owner_flag=()
[ -n "$ORG" ] && owner_flag=(--owner="$ORG")

gh search prs "author:@me" "merged:$SINCE..$TODAY" "${owner_flag[@]}" \
  --limit 1000 --json number,repository \
  --jq '.[] | "\(.repository.nameWithOwner)#\(.number)"' | sort -u \
  | xargs -P 8 -I{} bash -c 'enrich_one "$@"' _ {}

authored=$(cat "$tmp"/*.json 2>/dev/null | jq -s '.')

jq -n \
  --arg me "$ME" --arg org "$ORG" --arg since "$SINCE" --arg weeks "$WEEKS" \
  --argjson authored "${authored:-[]}" \
  '{me: $me, org: $org, since: $since, weeks: ($weeks|tonumber), authored_prs: $authored}'
