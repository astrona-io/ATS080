#!/usr/bin/env bash
# Check: deleting the operator pod keeps the same objects and adds none.
set -uo pipefail
fail=0

snapshot() {
  {
    kubectl -n starfleet get configmap -l app.kubernetes.io/managed-by=beacon-operator -o jsonpath='{range .items[*]}{.metadata.name}={.metadata.uid}{"\n"}{end}'
    kubectl -n beacon-registry get configmap -l app.kubernetes.io/managed-by=beacon-operator -o jsonpath='{range .items[*]}{.metadata.name}={.metadata.uid}{"\n"}{end}'
  } | sort
}

before="$(snapshot)"
if [ -z "$before" ]; then
  echo "FAIL: no objects labeled app.kubernetes.io/managed-by=beacon-operator were found"
  exit 1
fi
kubectl -n beacon-system delete pod -l app=beacon-operator --wait=true >/dev/null 2>&1
kubectl -n beacon-system rollout status deployment/beacon-operator --timeout=120s >/dev/null 2>&1
sleep 25
after="$(snapshot)"
if [ "$before" != "$after" ]; then
  echo "FAIL: the objects changed after a restart of the operator"
  echo "before: $(echo "$before" | tr '\n' ' ')"
  echo "after:  $(echo "$after" | tr '\n' ' ')"
  fail=1
fi
if ! echo "$after" | grep -q '^starfleet-scout='; then
  echo "FAIL: the registry entry starfleet-scout is missing"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: a restart changes nothing"
fi
exit "$fail"
