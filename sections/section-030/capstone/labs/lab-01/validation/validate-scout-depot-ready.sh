#!/usr/bin/env bash
# Check: claim scout-depot is Synced and Ready, namespace depot-scout-depot exists,
# and Deployment scout there has 2 available replicas.
set -uo pipefail

synced="$(kubectl -n starfleet get depot scout-depot -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}' 2>/dev/null)"
ready="$(kubectl -n starfleet get depot scout-depot -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [ "$synced" != "True" ] || [ "$ready" != "True" ]; then
  echo "FAIL: claim scout-depot is Synced=${synced:-unknown} Ready=${ready:-unknown}"
  exit 1
fi
replicas="$(kubectl -n starfleet get depot scout-depot -o jsonpath='{.spec.replicas}')"
available="$(kubectl -n depot-scout-depot get deployment scout -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
if [ "$replicas" != "2" ] || [ "${available:-0}" != "2" ]; then
  echo "FAIL: claim replicas=$replicas, available replicas in depot-scout-depot/scout=${available:-0}"
  exit 1
fi
echo "PASS: scout-depot is Ready with 2 available replicas"
