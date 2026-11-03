#!/usr/bin/env bash
# Check: every Deployment still has the uid recorded at the start (nothing was
# deleted and created again), and probe still has two replicas.
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

replicas="$(kubectl -n starfleet get deployment probe -o jsonpath='{.spec.replicas}' 2>/dev/null)"
if [ "$replicas" != "2" ]; then
  echo "FAIL: probe has spec.replicas ${replicas}, expected 2 (it must not change)"
  exit 1
fi

echo "PASS: no Deployment was recreated and probe is unchanged"
