#!/usr/bin/env bash
# Check: the claim probe was deleted, its namespace is gone, and the ConfigMap
# record-probe is still in starfleet-records. Waits up to 120 seconds for the
# namespace to finish terminating.
set -uo pipefail

if kubectl -n starfleet get outpost probe >/dev/null 2>&1; then
  echo "FAIL: the claim probe still exists. Delete it after the record Object has deletionPolicy Orphan"
  exit 1
fi
for _ in $(seq 1 60); do
  if ! kubectl get namespace outpost-probe >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
if kubectl get namespace outpost-probe >/dev/null 2>&1; then
  echo "FAIL: namespace outpost-probe still exists"
  exit 1
fi
if ! kubectl -n starfleet-records get configmap record-probe >/dev/null 2>&1; then
  echo "FAIL: ConfigMap record-probe was deleted. It must stay in starfleet-records"
  exit 1
fi
echo "PASS: probe and outpost-probe are gone, and record-probe was kept"
