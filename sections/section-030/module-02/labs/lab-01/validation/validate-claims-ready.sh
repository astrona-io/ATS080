#!/usr/bin/env bash
# Check: claim scout is Synced and Ready and its Deployment is available.
set -uo pipefail

synced="$(kubectl -n starfleet get outpost scout -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}' 2>/dev/null)"
ready="$(kubectl -n starfleet get outpost scout -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [ "$synced" != "True" ] || [ "$ready" != "True" ]; then
  echo "FAIL: claim scout is Synced=${synced:-unknown} Ready=${ready:-unknown}"
  exit 1
fi
available="$(kubectl -n outpost-scout get deployment scout -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
if [ "${available:-0}" -lt 1 ]; then
  echo "FAIL: Deployment outpost-scout/scout has no available replica"
  exit 1
fi
echo "PASS: claim scout is Ready and its Deployment is available"
