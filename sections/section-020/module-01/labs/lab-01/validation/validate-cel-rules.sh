#!/usr/bin/env bash
# Check: three CEL rules work. A prod claim needs highAvailability, the engine
# of an existing claim cannot change, and storageGB cannot shrink. Each
# rejection is paired with a nearby request that must be accepted, so a claim
# that is rejected for another reason does not pass. All requests are
# server-side dry runs.
set -uo pipefail

prod_claim() {
  printf 'apiVersion: platform.example/v1alpha1\nkind: DatabaseClaim\nmetadata:\n  name: grader-prod\n  namespace: starfleet\nspec:\n  engine: postgres\n  environment: prod\n  highAvailability: %s\n' "$1"
}

rejected_within() {
  local attempt
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if ! "$@" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  return 1
}

create_claim() { printf '%s\n' "$1" | kubectl create --dry-run=server -f -; }
patch_probe() { kubectl -n starfleet patch databaseclaim probe-db --type=merge --dry-run=server -p "$1"; }

if ! kubectl -n starfleet get databaseclaim probe-db >/dev/null 2>&1; then
  echo "FAIL: the claim probe-db in starfleet does not exist"
  exit 1
fi

if ! rejected_within create_claim "$(prod_claim false)"; then
  echo "FAIL: a prod claim with highAvailability false was accepted"
  exit 1
fi
if ! create_claim "$(prod_claim true)" >/dev/null 2>&1; then
  echo "FAIL: a prod claim with highAvailability true was rejected"
  exit 1
fi

if ! rejected_within patch_probe '{"spec":{"engine":"mysql"}}'; then
  echo "FAIL: changing the engine of probe-db was accepted; the engine must be immutable"
  exit 1
fi
if ! patch_probe '{"spec":{"version":"17"}}' >/dev/null 2>&1; then
  echo "FAIL: changing only the version of probe-db was rejected"
  exit 1
fi

if ! rejected_within patch_probe '{"spec":{"storageGB":5}}'; then
  echo "FAIL: shrinking storageGB from 20 to 5 was accepted"
  exit 1
fi
if ! patch_probe '{"spec":{"storageGB":40}}' >/dev/null 2>&1; then
  echo "FAIL: growing storageGB from 20 to 40 was rejected"
  exit 1
fi

echo "PASS: prod needs a standby, the engine is immutable and storageGB never shrinks"
