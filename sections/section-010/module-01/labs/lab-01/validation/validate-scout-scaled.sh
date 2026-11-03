#!/usr/bin/env bash
# Check: scout has 4 replicas in spec, all available, and the controller has
# observed the latest generation. Waits up to 60 seconds for the controller.
set -uo pipefail

for attempt in $(seq 1 12); do
  json="$(kubectl -n starfleet get deployment scout -o json 2>/dev/null)"
  if [ -z "$json" ]; then
    echo "FAIL: the Deployment scout does not exist in starfleet"
    exit 1
  fi
  desired="$(printf '%s' "$json" | jq '.spec.replicas')"
  available="$(printf '%s' "$json" | jq '.status.availableReplicas // 0')"
  generation="$(printf '%s' "$json" | jq '.metadata.generation')"
  observed="$(printf '%s' "$json" | jq '.status.observedGeneration // 0')"
  if [ "$desired" = "4" ] && [ "$available" = "4" ] && [ "$generation" = "$observed" ]; then
    break
  fi
  sleep 5
done

if [ "$desired" != "4" ]; then
  echo "FAIL: spec.replicas of scout is ${desired}, expected 4"
  exit 1
fi
if [ "$available" != "4" ]; then
  echo "FAIL: scout has ${available} of 4 replicas available"
  exit 1
fi
if [ "$generation" != "$observed" ]; then
  echo "FAIL: observedGeneration ${observed} is not equal to generation ${generation}"
  exit 1
fi

pods="$(kubectl -n starfleet get pods -l app=scout -o json 2>/dev/null | jq '[.items[] | select(.metadata.deletionTimestamp == null)] | length')"
if [ "$pods" != "4" ]; then
  echo "FAIL: ${pods} scout pods exist, expected 4"
  exit 1
fi

echo "PASS: scout runs 4 available replicas and the controller observed generation ${generation}"
