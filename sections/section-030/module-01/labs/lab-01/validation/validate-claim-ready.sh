#!/usr/bin/env bash
# Check: the claim scout in starfleet exists and is Synced and Ready.
set -uo pipefail

if ! kubectl -n starfleet get outpost scout >/dev/null 2>&1; then
  echo "FAIL: the Outpost claim scout does not exist in starfleet"
  exit 1
fi
synced="$(kubectl -n starfleet get outpost scout -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}')"
ready="$(kubectl -n starfleet get outpost scout -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
if [ "$synced" != "True" ] || [ "$ready" != "True" ]; then
  echo "FAIL: claim scout is Synced=${synced:-unknown} Ready=${ready:-unknown}"
  exit 1
fi
replicas="$(kubectl -n starfleet get outpost scout -o jsonpath='{.spec.replicas}')"
if [ "$replicas" != "2" ]; then
  echo "FAIL: claim scout has replicas=${replicas:-unset}, expected 2"
  exit 1
fi
echo "PASS: claim scout is Synced and Ready with replicas 2"
