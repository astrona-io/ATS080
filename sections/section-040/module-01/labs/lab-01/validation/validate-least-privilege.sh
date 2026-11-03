#!/usr/bin/env bash
# Check: the operator service account has only the access it needs.
set -uo pipefail
fail=0
SA="system:serviceaccount:beacon-system:beacon-operator"

# expect <yes|no> <description> <kubectl auth can-i arguments...>
expect() {
  local want="$1" description="$2" got
  shift 2
  got="$(kubectl auth can-i "$@" --as="$SA" 2>/dev/null)"
  if [ "$got" != "$want" ]; then
    echo "FAIL: $description (expected $want, got ${got:-nothing})"
    fail=1
  fi
}

expect no  "the operator must not read Secrets in starfleet" get secrets -n starfleet
expect no  "the operator must not read Secrets in kube-system" get secrets -n kube-system
expect no  "the operator must not delete ConfigMaps in starfleet" delete configmaps -n starfleet
expect no  "the operator must not delete Beacons" delete beacons.ops.starfleet.example -n starfleet
expect no  "the operator must not list ConfigMaps in kube-system" list configmaps -n kube-system
expect no  "the operator must not list Beacons in every namespace" list beacons.ops.starfleet.example --all-namespaces
expect yes "the operator must patch Beacons in starfleet (finalizer)" patch beacons.ops.starfleet.example -n starfleet
expect yes "the operator must patch the status of Beacons" patch beacons.ops.starfleet.example --subresource=status -n starfleet
expect yes "the operator must delete registry entries" delete configmaps -n beacon-registry
expect yes "the operator must create ConfigMaps in starfleet" create configmaps -n starfleet
if [ "$fail" -eq 0 ]; then
  echo "PASS: the operator has least privilege"
fi
exit "$fail"
