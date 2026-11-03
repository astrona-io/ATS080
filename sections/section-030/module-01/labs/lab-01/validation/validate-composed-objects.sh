#!/usr/bin/env bash
# Check: the composite resource of claim scout owns at least two provider-kubernetes
# Objects, and every Object is Synced.
set -uo pipefail

xr="$(kubectl -n starfleet get outpost scout -o jsonpath='{.spec.resourceRef.name}' 2>/dev/null)"
if [ -z "$xr" ]; then
  echo "FAIL: claim scout has no resourceRef, so no composite resource was created"
  exit 1
fi
objects="$(kubectl get objects.kubernetes.crossplane.io -l "crossplane.io/composite=${xr}" -o json 2>/dev/null)"
count="$(printf '%s' "$objects" | jq '.items | length')"
if [ "${count:-0}" -lt 2 ]; then
  echo "FAIL: composite $xr owns ${count:-0} Objects, expected at least 2"
  exit 1
fi
notsynced="$(printf '%s' "$objects" | jq -r '.items[] | select(([.status.conditions[]? | select(.type=="Synced" and .status=="True")] | length) == 0) | .metadata.name')"
if [ -n "$notsynced" ]; then
  echo "FAIL: these Objects are not Synced:"
  echo "$notsynced"
  exit 1
fi
echo "PASS: composite $xr owns $count Objects and all are Synced"
