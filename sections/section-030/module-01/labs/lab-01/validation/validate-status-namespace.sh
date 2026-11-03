#!/usr/bin/env bash
# Check: the composite resource of claim scout reports status.namespace=outpost-scout.
set -uo pipefail

xr="$(kubectl -n starfleet get outpost scout -o jsonpath='{.spec.resourceRef.name}' 2>/dev/null)"
if [ -z "$xr" ]; then
  echo "FAIL: claim scout has no composite resource"
  exit 1
fi
value="$(kubectl get xoutposts.platform.starfleet.example "$xr" -o jsonpath='{.status.namespace}' 2>/dev/null)"
if [ "$value" != "outpost-scout" ]; then
  echo "FAIL: status.namespace of $xr is '${value}', expected outpost-scout"
  exit 1
fi
echo "PASS: composite $xr reports status.namespace=outpost-scout"
