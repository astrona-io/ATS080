#!/usr/bin/env bash
# Check: the status subresource is enabled and the status schema keeps phase and
# observedGeneration. A write through the /status endpoint must be stored, and a
# write through the main endpoint must be ignored. The check changes
# status.phase of probe-db to Ready.
set -uo pipefail

subresources="$(kubectl get crd databaseclaims.platform.example -o json 2>/dev/null \
  | jq -r '.spec.versions[] | select(.name == "v1alpha1") | .subresources | has("status")' 2>/dev/null)"
if [ "$subresources" != "true" ]; then
  echo "FAIL: version v1alpha1 of the CRD has no status subresource"
  exit 1
fi

stored=""
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  kubectl -n starfleet patch databaseclaim probe-db --subresource=status --type=merge \
    -p '{"status":{"phase":"Ready","observedGeneration":1}}' >/dev/null 2>&1
  stored="$(kubectl -n starfleet get databaseclaim probe-db -o jsonpath='{.status.phase} {.status.observedGeneration}' 2>/dev/null)"
  [ "$stored" = "Ready 1" ] && break
  sleep 2
done
if [ "$stored" != "Ready 1" ]; then
  echo "FAIL: a write to the status subresource was not stored (read back '${stored}'). Check that the status schema defines phase (string) and observedGeneration (integer)"
  exit 1
fi

kubectl -n starfleet patch databaseclaim probe-db --type=merge -p '{"status":{"phase":"Tampered"}}' >/dev/null 2>&1
phase="$(kubectl -n starfleet get databaseclaim probe-db -o jsonpath='{.status.phase}' 2>/dev/null)"
if [ "$phase" != "Ready" ]; then
  echo "FAIL: a write through the main endpoint changed status.phase to '${phase}'. The status subresource must ignore it"
  exit 1
fi

echo "PASS: status is written through /status only and the status schema keeps phase and observedGeneration"
