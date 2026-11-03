#!/usr/bin/env bash
# Check: the Composition sets deletionPolicy Orphan on the composed resource named record.
set -uo pipefail

policy="$(kubectl get composition outpost-kubernetes -o json 2>/dev/null | jq -r '
  [.spec.pipeline[]?.input.resources[]? | select(.name == "record") | .base.spec.deletionPolicy] | first // "unset"')"
if [ "$policy" != "Orphan" ]; then
  echo "FAIL: the record resource has deletionPolicy=${policy}, expected Orphan"
  exit 1
fi
echo "PASS: the record resource sets deletionPolicy Orphan"
