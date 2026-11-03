#!/usr/bin/env bash
# Check: a claim that sets only the engine comes back from the API server with
# storageGB 10, environment dev and highAvailability false. The request is a
# server-side dry run, so the returned object shows the defaults.
set -uo pipefail

claim='apiVersion: platform.example/v1alpha1
kind: DatabaseClaim
metadata:
  name: grader-defaults
  namespace: starfleet
spec:
  engine: postgres'

result=""
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  result="$(printf '%s\n' "$claim" | kubectl create --dry-run=server -o json -f - 2>/dev/null \
    | jq -r '[.spec.storageGB, .spec.environment, .spec.highAvailability] | map(tostring) | join(" ")' 2>/dev/null)"
  if [ "$result" = "10 dev false" ]; then
    echo "PASS: defaults are applied (storageGB 10, environment dev, highAvailability false)"
    exit 0
  fi
  sleep 2
done

echo "FAIL: expected the defaults '10 dev false', the API server returned '${result:-nothing}'"
exit 1
