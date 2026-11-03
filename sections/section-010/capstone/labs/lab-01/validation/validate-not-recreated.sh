#!/usr/bin/env bash
# Check: every Deployment still has the uid recorded at the start (nothing was
# deleted and created again), and shuttle still gets answers from scout and probe.
set -uo pipefail

check_uid() {
  local namespace="$1" name="$2" key="$3"
  local expected actual
  expected="$(kubectl -n lab-support get configmap lab-baseline -o jsonpath="{.data.${key}}" 2>/dev/null)"
  actual="$(kubectl -n "$namespace" get deployment "$name" -o jsonpath='{.metadata.uid}' 2>/dev/null)"
  if [ -z "$expected" ]; then
    echo "FAIL: the baseline for ${name} is missing (lab setup problem)"
    exit 1
  fi
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: the Deployment ${name} has a different uid. It was deleted and created again."
    exit 1
  fi
}

check_uid starfleet scout scout-uid
check_uid starfleet probe probe-uid
check_uid starfleet shuttle shuttle-uid
check_uid outpost drifter drifter-uid

scout_code=""
for attempt in $(seq 1 6); do
  scout_code="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://scout.starfleet.svc.cluster.local/healthz 2>/dev/null || true)"
  [ "$scout_code" = "200" ] && break
  sleep 5
done
if [ "$scout_code" != "200" ]; then
  echo "FAIL: shuttle got HTTP '${scout_code}' from scout, expected 200"
  exit 1
fi

probe_code="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://probe.starfleet.svc.cluster.local/get 2>/dev/null || true)"
if [ "$probe_code" != "200" ]; then
  echo "FAIL: shuttle got HTTP '${probe_code}' from probe, expected 200"
  exit 1
fi

echo "PASS: no Deployment was recreated and shuttle reaches scout and probe (HTTP 200)"
