#!/usr/bin/env bash
# Check: namespace outpost-scout exists and Deployment scout there has 2 available replicas.
set -uo pipefail

if ! kubectl get namespace outpost-scout >/dev/null 2>&1; then
  echo "FAIL: namespace outpost-scout does not exist"
  exit 1
fi
desired="$(kubectl -n outpost-scout get deployment scout -o jsonpath='{.spec.replicas}' 2>/dev/null)"
available="$(kubectl -n outpost-scout get deployment scout -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
if [ "${desired:-}" != "2" ]; then
  echo "FAIL: Deployment scout has spec.replicas=${desired:-none}, expected 2"
  exit 1
fi
if [ "${available:-0}" != "2" ]; then
  echo "FAIL: Deployment scout has ${available:-0} of 2 replicas available"
  exit 1
fi
echo "PASS: outpost-scout/scout has 2 available replicas"
