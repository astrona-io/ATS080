#!/usr/bin/env bash
# Check: a temporary Beacon gets a registry entry; deleting it removes entry, child and Beacon.
set -uo pipefail
fail=0
name="grader-tmp"

cleanup_beacon() {
  kubectl -n starfleet patch beacon "$name" --type=merge -p '{"metadata":{"finalizers":[]}}' >/dev/null 2>&1
  kubectl -n starfleet delete beacon "$name" --ignore-not-found --wait=false >/dev/null 2>&1
  kubectl -n beacon-registry delete configmap "starfleet-$name" --ignore-not-found >/dev/null 2>&1
}
cleanup_beacon

kubectl apply -f - >/dev/null <<YAML
apiVersion: ops.starfleet.example/v1
kind: Beacon
metadata:
  name: $name
  namespace: starfleet
spec:
  message: "temporary"
YAML

found=0
for _ in $(seq 1 30); do
  if kubectl -n beacon-registry get configmap "starfleet-$name" >/dev/null 2>&1; then
    found=1
    break
  fi
  sleep 3
done
if [ "$found" -ne 1 ]; then
  echo "FAIL: no registry entry starfleet-$name appeared in beacon-registry"
  cleanup_beacon
  exit 1
fi
finalizers="$(kubectl -n starfleet get beacon "$name" -o jsonpath='{.metadata.finalizers}' 2>/dev/null)"
if [ -z "$finalizers" ]; then
  echo "FAIL: the Beacon has no finalizer, so nothing guarantees the cleanup"
  fail=1
fi

kubectl -n starfleet delete beacon "$name" --wait=false >/dev/null 2>&1
gone=0
for _ in $(seq 1 30); do
  if ! kubectl -n starfleet get beacon "$name" >/dev/null 2>&1; then
    gone=1
    break
  fi
  sleep 3
done
if [ "$gone" -ne 1 ]; then
  echo "FAIL: the Beacon is still there after 90 seconds (the finalizer is never removed)"
  cleanup_beacon
  exit 1
fi
if kubectl -n beacon-registry get configmap "starfleet-$name" >/dev/null 2>&1; then
  echo "FAIL: the registry entry still exists after the Beacon is gone"
  kubectl -n beacon-registry delete configmap "starfleet-$name" --ignore-not-found >/dev/null 2>&1
  fail=1
fi
child_gone=0
for _ in $(seq 1 20); do
  if ! kubectl -n starfleet get configmap "beacon-$name" >/dev/null 2>&1; then
    child_gone=1
    break
  fi
  sleep 3
done
if [ "$child_gone" -ne 1 ]; then
  echo "FAIL: the child ConfigMap beacon-$name still exists (it needs an ownerReference)"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: deleting a Beacon cleans up the registry entry and the child"
fi
exit "$fail"
