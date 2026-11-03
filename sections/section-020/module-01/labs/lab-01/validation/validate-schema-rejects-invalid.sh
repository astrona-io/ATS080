#!/usr/bin/env bash
# Check: the schema rejects five invalid claims and accepts a valid one. Every
# request is a server-side dry run, so nothing is stored. A rejection is retried
# for up to 20 seconds, because the API server reloads a changed schema in the
# background.
set -uo pipefail

claim_with_spec() {
  printf 'apiVersion: platform.example/v1alpha1\nkind: DatabaseClaim\nmetadata:\n  name: grader-claim\n  namespace: starfleet\n%s\n' "$1"
}

dry_run_create() {
  printf '%s\n' "$1" | kubectl create --dry-run=server -f - 2>&1
}

expect_rejected() {
  local label="$1" yaml="$2" attempt
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if ! dry_run_create "$yaml" >/dev/null; then
      return 0
    fi
    sleep 2
  done
  echo "FAIL: the API server accepted a claim that must be rejected: ${label}"
  exit 1
}

expect_accepted() {
  local label="$1" yaml="$2" output
  output="$(dry_run_create "$yaml")" || {
    echo "FAIL: the API server rejected a valid claim: ${label}"
    echo "$output"
    exit 1
  }
}

expect_rejected "no spec" "$(claim_with_spec "")"
expect_rejected "no engine" "$(claim_with_spec $'spec:\n  storageGB: 20')"
expect_rejected "engine oracle" "$(claim_with_spec $'spec:\n  engine: oracle')"
expect_rejected "environment qa" "$(claim_with_spec $'spec:\n  engine: postgres\n  environment: qa')"
expect_rejected "storageGB 0" "$(claim_with_spec $'spec:\n  engine: postgres\n  storageGB: 0')"
expect_rejected "storageGB 501" "$(claim_with_spec $'spec:\n  engine: postgres\n  storageGB: 501')"

expect_accepted "postgres, 500 GB, staging" "$(claim_with_spec $'spec:\n  engine: postgres\n  storageGB: 500\n  environment: staging')"
expect_accepted "mysql with version" "$(claim_with_spec $'spec:\n  engine: mysql\n  version: "8"')"

echo "PASS: the schema rejects invalid claims and accepts valid ones"
