#!/usr/bin/env bash
# Check with server-side dry runs: defaults are applied (replicas 1, region
# eu-north, ttlDays 14) and invalid values are rejected (unknown tier, replicas
# above 10, an owner that breaks the pattern, a missing owner).
set -uo pipefail

manifest() {
  printf 'apiVersion: platform.example/v1alpha1\nkind: Environment\nmetadata:\n  name: grader-env\n  namespace: starfleet\nspec:\n%s\n' "$1"
}

dry_run() {
  local spec="$1" attempt result
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    result="$(manifest "$spec" | kubectl create --dry-run=server -o json -f - 2>&1)"
    if [ $? -eq 0 ] || ! printf '%s' "$result" | grep -q 'no matches for kind'; then
      printf '%s' "$result"
      return
    fi
    sleep 2
  done
  printf '%s' "$result"
}

out="$(dry_run '  tier: dev
  owner: scout-team')"
if ! printf '%s' "$out" | jq -e '.kind == "Environment"' >/dev/null 2>&1; then
  echo "FAIL: a valid minimal Environment was not accepted: ${out}"
  exit 1
fi
replicas="$(printf '%s' "$out" | jq -r '.spec.replicas // "none"')"
region="$(printf '%s' "$out" | jq -r '.spec.region // "none"')"
ttl="$(printf '%s' "$out" | jq -r '.spec.ttlDays // "none"')"
if [ "$replicas" != "1" ] || [ "$region" != "eu-north" ] || [ "$ttl" != "14" ]; then
  echo "FAIL: defaults are wrong, got replicas=${replicas} region=${region} ttlDays=${ttl} (expected 1, eu-north, 14)"
  exit 1
fi

reject() {
  local label="$1" spec="$2"
  if manifest "$spec" | kubectl create --dry-run=server -f - >/dev/null 2>&1; then
    echo "FAIL: ${label} was accepted"
    exit 1
  fi
}

reject "tier qa" '  tier: qa
  owner: scout-team'
reject "replicas 11" '  tier: dev
  owner: scout-team
  replicas: 11'
reject "replicas 0" '  tier: dev
  owner: scout-team
  replicas: 0'
reject "region us-east" '  tier: dev
  owner: scout-team
  region: us-east'
reject "ttlDays 91" '  tier: dev
  owner: scout-team
  ttlDays: 91'
reject "an owner with capital letters" '  tier: dev
  owner: Scout_Team'
reject "a spec without an owner" '  tier: dev'

echo "PASS: defaults are applied and invalid values are rejected by the schema"
