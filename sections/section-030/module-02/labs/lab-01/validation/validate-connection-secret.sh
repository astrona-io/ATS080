#!/usr/bin/env bash
# Check: Secret scout-conn in starfleet holds the key endpoint with the Service address.
set -uo pipefail

if ! kubectl -n starfleet get secret scout-conn >/dev/null 2>&1; then
  echo "FAIL: the Secret scout-conn does not exist in starfleet"
  exit 1
fi
value="$(kubectl -n starfleet get secret scout-conn -o jsonpath='{.data.endpoint}' | base64 -d 2>/dev/null)"
expected="scout.outpost-scout.svc.cluster.local:9898"
if [ "$value" != "$expected" ]; then
  echo "FAIL: key endpoint is '${value}', expected '${expected}'"
  exit 1
fi
echo "PASS: scout-conn holds endpoint=$expected"
