#!/usr/bin/env bash
# Check: the stuck ConfigMap decommissioned-beacon is gone (its finalizer was
# released) and the other ConfigMap active-beacon was not touched.
set -uo pipefail

for attempt in $(seq 1 12); do
  if ! kubectl -n starfleet get configmap decommissioned-beacon >/dev/null 2>&1; then
    break
  fi
  sleep 3
done
if kubectl -n starfleet get configmap decommissioned-beacon >/dev/null 2>&1; then
  stamp="$(kubectl -n starfleet get configmap decommissioned-beacon -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null)"
  echo "FAIL: decommissioned-beacon still exists (deletionTimestamp '${stamp}'). Release its finalizer."
  exit 1
fi

site="$(kubectl -n starfleet get configmap active-beacon -o jsonpath='{.data.site}' 2>/dev/null)"
if [ "$site" != "starfleet" ]; then
  echo "FAIL: active-beacon is missing or changed. Only decommissioned-beacon may go."
  exit 1
fi
stamp="$(kubectl -n starfleet get configmap active-beacon -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null)"
if [ -n "$stamp" ]; then
  echo "FAIL: active-beacon is being deleted"
  exit 1
fi

echo "PASS: decommissioned-beacon is released and active-beacon is untouched"
