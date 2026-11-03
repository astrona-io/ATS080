#!/usr/bin/env bash
# Check: scout-db has a Ready condition with status "True", a reason, a
# message, a lastTransitionTime and an observedGeneration that equals
# metadata.generation, and status.observedGeneration is current too.
set -uo pipefail

claim="$(kubectl -n starfleet get databaseclaim scout-db -o json 2>/dev/null)"
if [ -z "$claim" ]; then
  echo "FAIL: the claim scout-db in starfleet does not exist"
  exit 1
fi

generation="$(printf '%s' "$claim" | jq -r '.metadata.generation')"
condition="$(printf '%s' "$claim" | jq -c '[.status.conditions[]? | select(.type == "Ready")] | first // empty')"
if [ -z "$condition" ]; then
  echo "FAIL: scout-db has no Ready condition in status.conditions"
  exit 1
fi

for field in reason message lastTransitionTime; do
  if [ -z "$(printf '%s' "$condition" | jq -r --arg f "$field" '.[$f] // ""')" ]; then
    echo "FAIL: the Ready condition has no ${field}"
    exit 1
  fi
done

if [ "$(printf '%s' "$condition" | jq -r '.status')" != "True" ]; then
  echo "FAIL: the Ready condition status is not \"True\""
  exit 1
fi

condition_generation="$(printf '%s' "$condition" | jq -r '.observedGeneration // "none"')"
if [ "$condition_generation" != "$generation" ]; then
  echo "FAIL: the Ready condition observedGeneration is ${condition_generation}, but metadata.generation is ${generation}. The condition describes an older spec"
  exit 1
fi

status_generation="$(printf '%s' "$claim" | jq -r '.status.observedGeneration // "none"')"
if [ "$status_generation" != "$generation" ]; then
  echo "FAIL: status.observedGeneration is ${status_generation}, expected ${generation}"
  exit 1
fi

echo "PASS: scout-db is Ready at generation ${generation}"
