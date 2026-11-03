#!/usr/bin/env bash
# Check: claim probe-depot was deleted, its namespace is gone, and the ConfigMap
# record-probe-depot is still in starfleet-records. Waits up to 120 seconds for the namespace.
set -uo pipefail

if kubectl -n starfleet get depot probe-depot >/dev/null 2>&1; then
  echo "FAIL: the claim probe-depot still exists"
  exit 1
fi
for _ in $(seq 1 60); do
  if ! kubectl get namespace depot-probe-depot >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
if kubectl get namespace depot-probe-depot >/dev/null 2>&1; then
  echo "FAIL: namespace depot-probe-depot still exists"
  exit 1
fi
if ! kubectl -n starfleet-records get configmap record-probe-depot >/dev/null 2>&1; then
  echo "FAIL: ConfigMap record-probe-depot does not exist. It must survive the deletion of the claim"
  exit 1
fi
echo "PASS: probe-depot and its namespace are gone and the record was kept"
